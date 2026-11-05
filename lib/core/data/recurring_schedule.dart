import 'dart:math' as math;

import '../models/models.dart';
import '../utils/dates.dart';

String recurrenceLabel(Recurring rule) {
  if (rule.interval == 1) {
    return switch (rule.frequency) {
      'daily' => 'Daily',
      'weekly' => 'Weekly',
      'fortnightly' => 'Every 2 weeks',
      'quarterly' => 'Every 3 months',
      'half-yearly' => 'Every 6 months',
      'yearly' => 'Yearly',
      'custom' => 'Every day',
      _ => 'Monthly',
    };
  }
  return 'Every ${rule.interval} ${switch (rule.frequency) {
    'daily' || 'custom' => 'days',
    'weekly' => 'weeks',
    'fortnightly' => 'fortnights',
    'quarterly' => 'quarters',
    'half-yearly' => 'half-years',
    'yearly' => 'years',
    _ => 'months',
  }}';
}

bool recurringActive(Recurring rule) =>
    rule.enabled &&
    !rule.archived &&
    (rule.end == null || !rule.nextDue.isAfter(rule.end!));
bool recurringDue(Recurring rule, DateTime now) =>
    recurringActive(rule) && !rule.nextDue.isAfter(now);

/// Calendar projections start at the pending occurrence, never at a processed or
/// skipped one. Jumping straight to the requested period keeps old daily rules
/// bounded, while nextOccurrence retains month-end and local-calendar anchors.
List<DateTime> projectedOccurrences(
  Recurring rule,
  DateWindow window, {
  int limit = 400,
}) {
  if (!recurringActive(rule) ||
      limit <= 0 ||
      !rule.nextDue.isBefore(window.end))
    return const [];
  var date = rule.nextDue;
  if (date.isBefore(window.start)) {
    if (['daily', 'custom', 'weekly', 'fortnightly'].contains(rule.frequency)) {
      final stride =
          rule.interval *
          switch (rule.frequency) {
            'weekly' => 7,
            'fortnightly' => 14,
            _ => 1,
          };
      final jumps = math.max(
        0,
        calendarDaysBetween(date, window.start) ~/ stride,
      );
      date = DateTime(
        date.year,
        date.month,
        date.day + jumps * stride,
        date.hour,
        date.minute,
      );
    } else {
      final stride =
          rule.interval *
          switch (rule.frequency) {
            'quarterly' => 3,
            'half-yearly' => 6,
            'yearly' => 12,
            _ => 1,
          };
      final months =
          (window.start.year - date.year) * 12 +
          window.start.month -
          date.month;
      final jumps = math.max(0, months ~/ stride);
      final month = safeMonth(
        date.year,
        date.month + jumps * stride,
        rule.start.day,
      );
      date = DateTime(
        month.year,
        month.month,
        month.day,
        rule.start.hour,
        rule.start.minute,
      );
    }
    if (date.isBefore(window.start)) date = nextOccurrence(rule, date);
  }
  final dates = <DateTime>[];
  while (date.isBefore(window.end) &&
      (rule.end == null || !date.isAfter(rule.end!)) &&
      dates.length < limit) {
    if (window.contains(date)) dates.add(date);
    final next = nextOccurrence(rule, date);
    if (!next.isAfter(date)) break;
    date = next;
  }
  return dates;
}

/// Calendar day progress, not an invented payment-completion percentage.
double occurrenceProgress(Recurring rule, DateTime now) {
  if (!now.isBefore(rule.nextDue)) return 1;
  if (now.isBefore(rule.start)) return 0;
  final next = nextOccurrence(rule, rule.nextDue);
  final span = math.max(1, calendarDaysBetween(rule.nextDue, next));
  return (1 - calendarDaysBetween(now, rule.nextDue) / span).clamp(0, 1);
}
