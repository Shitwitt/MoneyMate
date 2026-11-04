import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/models/models.dart';
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
}
