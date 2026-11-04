import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/data/validation.dart';
import 'package:paisaclone/core/services/csv_service.dart';
import 'package:paisaclone/core/utils/dates.dart';

import 'support.dart';

void main() {
  test('Integer storage rejects accidental fractional minor units', () {
    expect(readInt(123), 123);
    expect(() => readInt(123.5), throwsFormatException);
  });
  test('Strict date parser rejects normalized impossible dates', () {
    for (final value in [
      '2026-02-31',
      '2026-13-01',
      '2026-11-04T25:00:00',
      '2026-11-04T12:60:00',
    ]) {
      expect(() => readDate(value), throwsFormatException);
    }
    expect(readDate('2024-02-29').day, 29);
    expect(readDate('2026-11-04T12:30:00.123456').microsecond, 456);
  });
  test('Financial-month chart ends in active period before renewal day', () {
    final windows = monthlyWindows(DateTime(2026, 11, 4), 20, 6);
    expect(windows.length, 6);
    expect(windows.first.start, DateTime(2026, 5, 20));
    expect(windows.last.start, DateTime(2026, 10, 20));
    expect(windows.last.end, DateTime(2026, 11, 20));
  });
  test('Calendar counts and exclusive next day are DST-safe', () {
    final start = DateTime(2026, 3, 8), end = DateTime(2026, 3, 9);
    expect(DateWindow(start, end).days, 1);
    expect(nextDay(start), end);
    expect(calendarDaysBetween(DateTime(2026, 3, 1), DateTime(2026, 4, 1)), 31);
  });
  test('CSV preview rejects impossible calendar dates before commit', () {
    final csv = CsvDocument.parse(
      Uint8List.fromList(
        utf8.encode('date,type,name,amount\n2026-02-31,expense,Coffee,4.50\n'),
      ),
    );
    final result = csv.preview(fixture(), {
      'date': 0,
      'type': 1,
      'name': 2,
      'amount': 3,
    });
    expect(result.valid, isEmpty);
    expect(result.errors.length, 1);
  });
  test('Backup settings reject unsupported locale and number format', () {
    final app = appFor(fixture());
    expect(
      () => validateData(
        app.copyWith(settings: app.settings.copyWith(locale: 'missing')),
      ),
      throwsFormatException,
    );
    expect(
      () => validateData(
        app.copyWith(settings: app.settings.copyWith(numberFormat: 'unknown')),
      ),
      throwsFormatException,
    );
  });
  test(
    'Receipt validation checks raster signatures rather than extensions',
    () {
      final data = fixture();
      final fake = Receipt(
        id: 'fake',
        name: 'receipt.jpg',
        mime: 'image/jpeg',
        data: base64Encode(utf8.encode('<html>Not an image</html>')),
      );
      expect(
        () => validateData(
          appFor(
            data.copyWith(
              transactions: [
                expense(data).copyWith(receipts: [fake]),
              ],
            ),
          ),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'Bill settlement is idempotent and cannot be rewritten or doubled',
    () async {
      final data = fixture();
      final controller = AppController(MemoryRepository(appFor(data)));
      addTearDown(controller.dispose);
      final bill = Bill(
        id: 'bill',
        title: 'Lunch',
        totalMinor: 100,
        date: DateTime(2026, 11, 4),
        paidById: 'me',
        paidByName: 'You',
        shares: const [
          BillShare(
            personId: 'me',
            name: 'You',
            amountMinor: 50,
            settled: true,
          ),
          BillShare(personId: 'quick-friend', name: 'Friend', amountMinor: 50),
        ],
      );
      await controller.upsertBill(bill);
      await controller.settleBill('bill', 'quick-friend', createLoan: true);
      expect(controller.snapshot.profiles.first.loans.single.personId, isEmpty);
      expect(
        controller.snapshot.profiles.first.loans.single.principalMinor,
        50,
      );
      await expectLater(
        controller.settleBill('bill', 'quick-friend', createLoan: true),
        throwsFormatException,
      );
      await expectLater(
        controller.upsertBill(
          bill.copyWith(
            shares: const [
              BillShare(
                personId: 'me',
                name: 'You',
                amountMinor: 40,
                settled: true,
              ),
              BillShare(
                personId: 'quick-friend',
                name: 'Friend',
                amountMinor: 60,
                settled: true,
              ),
            ],
          ),
        ),
        throwsFormatException,
      );
      expect(controller.snapshot.profiles.first.loans.length, 1);
    },
  );
}
