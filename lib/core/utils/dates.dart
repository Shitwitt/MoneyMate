import 'dart:math' as math;

import '../models/models.dart';

DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime nextDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);
int calendarDaysBetween(DateTime start, DateTime end) => DateTime.utc(
  end.year,
  end.month,
  end.day,
).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
DateTime safeMonth(int year, int month, int day) {
  final first = DateTime(year, month);
  return DateTime(
    first.year,
    first.month,
    math.min(day, DateTime(first.year, first.month + 1, 0).day),
  );
}

class DateWindow {
  final DateTime start;
  final DateTime
  end; // Exclusive: includes every time on the final selected day.
  const DateWindow(this.start, this.end);
  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);
  int get days => math.max(1, calendarDaysBetween(start, end));
}

DateWindow financialMonth(DateTime now, int startDay) {
  final thisStart = safeMonth(now.year, now.month, startDay.clamp(1, 31));
  final start = now.isBefore(thisStart)
      ? safeMonth(now.year, now.month - 1, startDay)
      : thisStart;
  return DateWindow(start, safeMonth(start.year, start.month + 1, startDay));
}

DateWindow previousMonth(DateTime now, int startDay) {
  final current = financialMonth(now, startDay);
  return DateWindow(
    safeMonth(current.start.year, current.start.month - 1, startDay),
    current.start,
  );
}

DateWindow budgetWindow(Budget budget, DateTime date, int weekStart) {
  final day = dayOnly(date);
  if (budget.period == 'custom') {
    return DateWindow(
      dayOnly(budget.start),
      nextDay(budget.end ?? budget.start),
    );
  }
  if (budget.period == 'weekly') {
    final offset = (day.weekday - weekStart + 7) % 7;
    final start = DateTime(day.year, day.month, day.day - offset);
    return DateWindow(start, DateTime(start.year, start.month, start.day + 7));
  }
  if (budget.period == 'yearly') {
    var start = safeMonth(day.year, budget.start.month, budget.start.day);
    if (day.isBefore(start)) {
      start = safeMonth(day.year - 1, budget.start.month, budget.start.day);
    }
    return DateWindow(
      start,
      safeMonth(start.year + 1, budget.start.month, budget.start.day),
    );
  }
  final startDay = budget.start.day;
  final thisStart = safeMonth(day.year, day.month, startDay);
  final start = day.isBefore(thisStart)
      ? safeMonth(day.year, day.month - 1, startDay)
      : thisStart;
  return DateWindow(start, safeMonth(start.year, start.month + 1, startDay));
}

/// Anchor monthly/yearly occurrences to the original date. Jan 31 → Feb 28 → Mar 31,
/// rather than drifting permanently to the 28th. The original time is retained.
DateTime nextOccurrence(Recurring rule, DateTime current) {
  final step = math.max(1, rule.interval);
  DateTime result;
  switch (rule.frequency) {
    case 'weekly':
      return DateTime(
        current.year,
        current.month,
        current.day + 7 * step,
        current.hour,
        current.minute,
      );
    case 'daily':
    case 'custom':
      return DateTime(
        current.year,
        current.month,
        current.day + step,
        current.hour,
        current.minute,
      );
    case 'yearly':
      result = safeMonth(current.year + step, rule.start.month, rule.start.day);
    default:
      result = safeMonth(current.year, current.month + step, rule.start.day);
  }
  return DateTime(
    result.year,
    result.month,
    result.day,
    rule.start.hour,
    rule.start.minute,
  );
}

/// Monthly chart buckets are anchored to the ACTIVE financial period, not the
/// calendar month. Before payday a 20th-start chart must not invent next month.
List<DateWindow> monthlyWindows(DateTime anchor, int startDay, int count) {
  final current = financialMonth(anchor, startDay);
  return List.generate(count, (i) {
    final start = safeMonth(
      current.start.year,
      current.start.month - count + 1 + i,
      startDay,
    );
    return DateWindow(start, safeMonth(start.year, start.month + 1, startDay));
  });
}
