import 'extensions.dart';

/// Calendar periods supported by budgets, reports and filters.
enum PeriodType { day, week, month, year, custom }

/// A half-open date range: [start] inclusive, [end] exclusive.
///
/// Half-open ranges make adjacent periods tile without gaps or overlaps,
/// which keeps budget/report maths exact.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// True when [value] is inside the range (start inclusive, end exclusive).
  bool contains(DateTime value) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  Duration get length => end.difference(start);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start, $end)';
}

/// Number of days in the given month (handles leap years).
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Returns the calendar range for [type] containing [reference].
///
/// - [weekStartDay] uses [DateTime] weekday constants (default Monday).
/// - [monthStartDay] shifts the month boundary (e.g. 15 means the 15th to
///   the 14th of the next month). Values are clamped to the month length.
/// - [PeriodType.custom] throws [ArgumentError]; construct a [DateRange]
///   directly for custom ranges.
DateRange rangeForPeriod(
  PeriodType type,
  DateTime reference, {
  int weekStartDay = DateTime.monday,
  int monthStartDay = 1,
}) {
  switch (type) {
    case PeriodType.day:
      final DateTime start = reference.startOfDay;
      return DateRange(start: start, end: start.add(const Duration(days: 1)));
    case PeriodType.week:
      final DateTime dayStart = reference.startOfDay;
      final int daysSinceStart = (reference.weekday - weekStartDay + 7) % 7;
      final DateTime start = dayStart.subtract(Duration(days: daysSinceStart));
      return DateRange(start: start, end: start.add(const Duration(days: 7)));
    case PeriodType.month:
      return _monthRange(reference, monthStartDay);
    case PeriodType.year:
      final DateTime start = DateTime(reference.year, 1, 1);
      final DateTime end = DateTime(reference.year + 1, 1, 1);
      return DateRange(start: start, end: end);
    case PeriodType.custom:
      throw ArgumentError(
        'Custom periods need an explicit DateRange',
      );
  }
}

DateRange _monthRange(DateTime reference, int monthStartDay) {
  final int clampedDay = monthStartDay.clamp(1, 31);
  // Candidate start inside the reference month.
  int dayInMonth = clampedDay;
  final int daysInRefMonth = daysInMonth(reference.year, reference.month);
  if (dayInMonth > daysInRefMonth) {
    dayInMonth = daysInRefMonth;
  }
  DateTime start = DateTime(reference.year, reference.month, dayInMonth);
  // If the reference is before the candidate start, the period began last
  // month (e.g. monthStartDay=15 and reference is the 10th).
  if (reference.startOfDay.isBefore(start)) {
    final DateTime prevMonth = DateTime(reference.year, reference.month - 1, 1);
    int prevDay = clampedDay;
    final int daysInPrev = daysInMonth(prevMonth.year, prevMonth.month);
    if (prevDay > daysInPrev) {
      prevDay = daysInPrev;
    }
    start = DateTime(prevMonth.year, prevMonth.month, prevDay);
  }
  // End is the same day next month, clamped to that month's length.
  final DateTime nextMonth = DateTime(start.year, start.month + 1, 1);
  int endDay = start.day;
  final int daysInNext = daysInMonth(nextMonth.year, nextMonth.month);
  if (endDay > daysInNext) {
    endDay = daysInNext;
  }
  final DateTime end = DateTime(nextMonth.year, nextMonth.month, endDay);
  return DateRange(start: start, end: end);
}
