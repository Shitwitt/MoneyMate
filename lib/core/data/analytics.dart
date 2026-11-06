import 'dart:math' as math;

import '../models/models.dart';
import '../utils/dates.dart';
import 'ledger.dart';
import 'reporting.dart';

/// Local estimates only. Never treats transfers, opening balances, excluded
/// accounts or future records as posted spending. All amounts use saved FX.
class AnalyticsSnapshot {
  final Ledger ledger;
  final DateTime now;
  final DateWindow current, previous;
  final List<DateWindow> months, baselineMonths;
  final List<MoneyTransaction> history;
  final List<AnalyticsCategory> categories;
  const AnalyticsSnapshot._(
    this.ledger,
    this.now,
    this.current,
    this.previous,
    this.months,
    this.baselineMonths,
    this.history,
    this.categories,
  );
  factory AnalyticsSnapshot(Ledger ledger, DateTime now) {
    final current = financialMonth(now, ledger.settings.monthStart),
        previous = previousMonth(now, ledger.settings.monthStart);
    final months = monthlyWindows(now, ledger.settings.monthStart, 6);
    final baseline = monthlyWindows(
      current.start.subtract(const Duration(microseconds: 1)),
      ledger.settings.monthStart,
      6,
    );
    final history = ReportSnapshot(
      ledger,
      DateWindow(DateTime(1970), nextDay(now)),
      now: now,
    ).expenses;
    final groups = <String, List<MoneyTransaction>>{};
    for (final e in history) {
      (groups[e.categoryId] ??= []).add(e);
    }
    int total(Iterable<MoneyTransaction> entries, DateWindow window) => entries
        .where((e) => window.contains(e.date))
        .fold(0, (s, e) => s + ledger.entryValue(e));
    final categories = [
      for (final group in groups.entries)
        AnalyticsCategory(
          group.key,
          ledger.category(group.key),
          group.value,
          group.value.fold<int>(0, (s, e) => s + ledger.entryValue(e)),
          total(group.value, current),
          total(group.value, previous),
          months.map((w) => total(group.value, w)).toList(),
          baseline.map((w) => total(group.value, w)).toList(),
          group.value.where((e) => current.contains(e.date)).length,
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
    return AnalyticsSnapshot._(
      ledger,
      now,
      current,
      previous,
      months,
      baseline,
      history,
      categories,
    );
  }
  int get elapsed => (calendarDaysBetween(current.start, now) + 1)
      .clamp(1, current.days)
      .toInt();
  int get remaining => current.days - elapsed;
  int get spending => categories.fold(0, (s, c) => s + c.current);
  int get previousSpending => categories.fold(0, (s, c) => s + c.previous);
  int get total => categories.fold(0, (s, c) => s + c.total);
  int get daily => (spending / elapsed).round();
  int get weeklyBurn => (spending / elapsed * 7).round();
  int get projected => (spending / elapsed * current.days).round();
  double? get change => percentageChange(spending, previousSpending);
  List<int> get monthly => List.generate(
    6,
    (i) => categories.fold<int>(0, (s, c) => s + c.monthly[i]),
  );
  int? get average {
    final sum = categories.fold<int>(
      0,
      (s, c) => s + c.baseline.fold<int>(0, (s, n) => s + n),
    );
    return sum == 0 ? null : (sum / 6).round();
  }

  /// Blend the six-completed-month mean and current pace, never predicting less
  /// than already posted. With no baseline, disclose a pace-only projection.
  int get predicted => categories.fold<int>(0, (sum, c) => sum + prediction(c));
  int prediction(AnalyticsCategory category) {
    final pace = category.current / elapsed * current.days;
    final sum = category.baseline.fold<int>(0, (s, n) => s + n);
    return math.max(
      category.current,
      sum == 0 ? pace.round() : ((pace + sum / 6) / 2).round(),
    );
  }

  String get velocityStatus => previousSpending == 0
      ? 'No baseline'
      : spending / elapsed > previousSpending / previous.days * 1.2
      ? 'Faster'
      : spending / elapsed < previousSpending / previous.days * .8
      ? 'Slower'
      : 'Steady';
  List<int> get lastSeven => List.generate(7, (i) {
    final day = DateTime(now.year, now.month, now.day - 6 + i);
    return history
        .where((e) => dayOnly(e.date.toLocal()) == day)
        .fold<int>(0, (s, e) => s + ledger.entryValue(e));
  });
  List<AnalyticsCategory> get trends =>
      categories.where((c) => c.currentCount > 0).toList()
        ..sort((a, b) => b.current.compareTo(a.current));
  List<AnalyticsCategory> get insights =>
      trends.where((c) => c.current > c.previous).toList()..sort(
        (a, b) => (b.current - b.previous).compareTo(a.current - a.previous),
      );
  List<int> get weekdays => List.generate(
    7,
    (i) => history
        .where((e) => e.date.toLocal().weekday % 7 == i)
        .fold<int>(0, (s, e) => s + ledger.entryValue(e)),
  );
  int? get peakWeekday =>
      total == 0 ? null : weekdays.indexOf(weekdays.reduce(math.max));
  int? get lowestWeekday =>
      total == 0 ? null : weekdays.indexOf(weekdays.reduce(math.min));

  /// Tukey upper fence per exact category, minimum four observations. Not fraud
  /// detection: a sparse category is unavailable, not automatically unusual.
  List<MoneyTransaction> get unusual {
    final found = <MoneyTransaction>[];
    for (final c in categories.where((c) => c.entries.length >= 4)) {
      final values =
          c.entries.map((e) => ledger.entryValue(e).toDouble()).toList()
            ..sort();
      final q1 = quantile(values, .25), q3 = quantile(values, .75);
      found.addAll(
        c.entries.where((e) => ledger.entryValue(e) > q3 + 1.5 * (q3 - q1)),
      );
    }
    return found
      ..sort((a, b) => ledger.entryValue(b).compareTo(ledger.entryValue(a)));
  }
}

class AnalyticsCategory {
  final String id;
  final Category? category;
  final List<MoneyTransaction> entries;
  final int total, current, previous, currentCount;
  final List<int> monthly, baseline;
  const AnalyticsCategory(
    this.id,
    this.category,
    this.entries,
    this.total,
    this.current,
    this.previous,
    this.monthly,
    this.baseline,
    this.currentCount,
  );
  String get name => category?.name ?? 'Uncategorized';
  String get icon => category?.icon ?? 'category';
  int get color => category?.color ?? 0xffffb59a;
  int get average => (baseline.fold<int>(0, (s, n) => s + n) / 6).round();
  double? get change => percentageChange(current, previous);
}

double? percentageChange(int current, int previous) =>
    previous == 0 ? null : (current - previous) / previous * 100;
double quantile(List<double> sorted, double fraction) {
  if (sorted.isEmpty) return 0;
  final at = (sorted.length - 1) * fraction, lo = at.floor(), hi = at.ceil();
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (at - lo);
}
