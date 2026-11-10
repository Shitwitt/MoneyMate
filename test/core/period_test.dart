import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/period.dart';

void main() {
  group('rangeForPeriod day', () {
    test('returns the calendar day containing the reference', () {
      final DateRange range = rangeForPeriod(
        PeriodType.day,
        DateTime(2026, 10, 12, 15, 30),
      );
      expect(range.start, DateTime(2026, 10, 12));
      expect(range.end, DateTime(2026, 10, 13));
      expect(range.contains(DateTime(2026, 10, 12, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 10, 13)), isFalse);
    });
  });

  group('rangeForPeriod week', () {
    test('Monday start by default', () {
      // 2026-10-12 is a Monday.
      final DateRange range = rangeForPeriod(
        PeriodType.week,
        DateTime(2026, 10, 14),
      );
      expect(range.start, DateTime(2026, 10, 12));
      expect(range.end, DateTime(2026, 10, 19));
    });

    test('Sunday start when requested', () {
      final DateRange range = rangeForPeriod(
        PeriodType.week,
        DateTime(2026, 10, 14),
        weekStartDay: DateTime.sunday,
      );
      expect(range.start, DateTime(2026, 10, 11));
      expect(range.end, DateTime(2026, 10, 18));
    });

    test('spans month boundary', () {
      final DateRange range = rangeForPeriod(
        PeriodType.week,
        DateTime(2026, 10, 31),
      );
      expect(range.start, DateTime(2026, 10, 26));
      expect(range.end, DateTime(2026, 11, 2));
    });
  });

  group('rangeForPeriod month', () {
    test('calendar month by default', () {
      final DateRange range = rangeForPeriod(
        PeriodType.month,
        DateTime(2026, 10, 12),
      );
      expect(range.start, DateTime(2026, 10, 1));
      expect(range.end, DateTime(2026, 11, 1));
    });

    test('shifted month start (15th to 14th)', () {
      final DateRange range = rangeForPeriod(
        PeriodType.month,
        DateTime(2026, 10, 20),
        monthStartDay: 15,
      );
      expect(range.start, DateTime(2026, 10, 15));
      expect(range.end, DateTime(2026, 11, 15));
    });

    test('reference before shifted start belongs to previous period', () {
      final DateRange range = rangeForPeriod(
        PeriodType.month,
        DateTime(2026, 10, 10),
        monthStartDay: 15,
      );
      expect(range.start, DateTime(2026, 9, 15));
      expect(range.end, DateTime(2026, 10, 15));
    });

    test('clamps month start day to month length (Feb)', () {
      final DateRange range = rangeForPeriod(
        PeriodType.month,
        DateTime(2026, 2, 10),
        monthStartDay: 31,
      );
      // The 31st clamps to each month's last day, so Feb 10 belongs to the
      // period that started on Jan 31 and ends (exclusive) on Feb 28.
      expect(range.start, DateTime(2026, 1, 31));
      expect(range.end, DateTime(2026, 2, 28));
    });

    test('handles December to January rollover', () {
      final DateRange range = rangeForPeriod(
        PeriodType.month,
        DateTime(2026, 12, 20),
      );
      expect(range.start, DateTime(2026, 12, 1));
      expect(range.end, DateTime(2027, 1, 1));
    });
  });

  group('rangeForPeriod year and custom', () {
    test('calendar year', () {
      final DateRange range = rangeForPeriod(
        PeriodType.year,
        DateTime(2026, 6, 15),
      );
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2027, 1, 1));
    });

    test('custom throws (needs an explicit range)', () {
      expect(
        () => rangeForPeriod(PeriodType.custom, DateTime(2026, 1, 1)),
        throwsArgumentError,
      );
    });
  });

  group('daysInMonth', () {
    test('leap and non-leap February', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2026, 1), 31);
      expect(daysInMonth(2026, 4), 30);
    });
  });
}
