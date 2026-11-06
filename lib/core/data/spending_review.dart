import 'dart:math' as math;

import '../models/models.dart';
import '../utils/dates.dart';
import 'analytics.dart';
import 'financial_pulse.dart';
import 'ledger.dart';

class RepeatCandidate {
  final String name, accountId, categoryId;
  final int nativeMinor, baseMinor, months;
  final DateTime first, last;
  const RepeatCandidate({
    required this.name,
    required this.accountId,
    required this.categoryId,
    required this.nativeMinor,
    required this.baseMinor,
    required this.months,
    required this.first,
    required this.last,
  });
  DateTime get next => safeMonth(last.year, last.month + 1, first.day);
}

/// Every insight is derived from posted, included-account records. Missing
/// logging is unknown, not proof of a no-spend day or financial well-being.
class SpendingReview {
  final Ledger ledger;
  final DateTime now;
  final AnalyticsSnapshot analytics;
  final FinancialPulse pulse;
  final List<MoneyTransaction> posted;
  SpendingReview(this.ledger, this.now)
    : analytics = AnalyticsSnapshot(ledger, now),
      pulse = FinancialPulse.fromLedger(ledger, now),
      posted = ledger.data.transactions
          .where(
            (e) =>
                !e.date.isAfter(now) &&
                !ledger.account(e.accountId).excluded &&
                e.type != 'transfer',
          )
          .toList();
  int net(DateWindow window) => posted
      .where((e) => window.contains(e.date))
      .fold<int>(
        0,
        (s, e) => s + ledger.entryValue(e) * (e.type == 'income' ? 1 : -1),
      );
  List<int> get monthlySurplus => analytics.months.map(net).toList();
  int get baselineSurplus =>
      analytics.baselineMonths.fold<int>(0, (s, w) => s + net(w));
  int get baselineDays =>
      analytics.baselineMonths.fold<int>(0, (s, w) => s + w.days);
  bool get hasSurplusBaseline => posted.any(
    (e) => analytics.baselineMonths.any((w) => w.contains(e.date)),
  );
  int? get monthlySurplusMean =>
      hasSurplusBaseline ? (baselineSurplus / 6).round() : null;
  int? get yearEndSurplus {
    if (!hasSurplusBaseline) return null;
    final days = math.max(
      0,
      calendarDaysBetween(now, DateTime(now.year + 1)) - 1,
    );
    return net(DateWindow(DateTime(now.year), DateTime(now.year + 1))) +
        (baselineSurplus / baselineDays * days).round();
  }

  double? get baselineDailyExpense {
    final records = analytics.history.where(
      (e) => analytics.baselineMonths.any((w) => w.contains(e.date)),
    );
    if (records.isEmpty) return null;
    final total = records.fold<int>(0, (s, e) => s + ledger.entryValue(e));
    return total == 0 ? null : total / baselineDays;
  }

  Map<DateTime, int> get dailyExpense {
    final result = <DateTime, int>{};
    for (final e in analytics.history) {
      final date = dayOnly(e.date.toLocal());
      result.update(
        date,
        (n) => n + ledger.entryValue(e),
        ifAbsent: () => ledger.entryValue(e),
      );
    }
    return result;
  }

  (int, int)? get streak {
    final threshold = baselineDailyExpense;
    if (threshold == null) return null;
    final days =
        dailyExpense.entries
            .where((e) => !e.key.isBefore(analytics.baselineMonths.first.start))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    var current = 0, best = 0;
    DateTime? previous;
    for (final day in days) {
      if (previous == null || calendarDaysBetween(previous, day.key) != 1)
        current = 0;
      current = day.value < threshold ? current + 1 : 0;
      best = math.max(best, current);
      previous = day.key;
    }
    return (previous == dayOnly(now) ? current : 0, best);
  }

  AnalyticsCategory? get challenge {
    final eligible = analytics.categories.where((c) => c.previous > 0).toList()
      ..sort((a, b) => b.previous.compareTo(a.previous));
    return eligible.firstOrNull;
  }

  int? get challengeTarget => challenge == null
      ? null
      : math.max(1, (challenge!.previous * .85).round());
  double? get lastWeekShare {
    if (analytics.total == 0) return null;
    final last = analytics.history
        .where((e) {
          final d = e.date.toLocal();
          return d.day > DateTime(d.year, d.month + 1, 0).day - 7;
        })
        .fold<int>(0, (s, e) => s + ledger.entryValue(e));
    return last / analytics.total;
  }

  Map<DateTime, (int, int)> get dailyCashFlow {
    final values = <DateTime, (int, int)>{};
    for (final e in posted) {
      final date = dayOnly(e.date.toLocal()), amount = ledger.entryValue(e);
      final old = values[date] ?? (0, 0);
      values[date] = e.type == 'income'
          ? (old.$1 + amount, old.$2)
          : (old.$1, old.$2 + amount);
    }
    return values;
  }

  late final List<RepeatCandidate> candidates = _candidates();
  List<RepeatCandidate> _candidates() {
    String key(String name) =>
        name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final groups = <(String, String, String), List<MoneyTransaction>>{};
    final completedCalendar = DateWindow(
      DateTime(now.year, now.month - 6),
      DateTime(now.year, now.month),
    );
    for (final e in analytics.history.where(
      (e) =>
          e.recurringId.isEmpty &&
          !ledger.account(e.accountId).archived &&
          completedCalendar.contains(e.date),
    )) {
      final id = (key(e.name), e.accountId, e.categoryId);
      (groups[id] ??= []).add(e);
    }
    final result = <RepeatCandidate>[];
    for (final group in groups.entries) {
      final records = [...group.value]
        ..sort((a, b) => a.date.compareTo(b.date));
      if (records.length < 2 ||
          ledger.data.recurrings.any(
            (r) =>
                r.type == 'expense' &&
                r.accountId == group.key.$2 &&
                key(r.name) == group.key.$1,
          ))
        continue;
      final months =
          records
              .map((e) {
                final d = e.date.toLocal();
                return d.year * 12 + d.month;
              })
              .toSet()
              .toList()
            ..sort();
      final previousCalendarMonth = DateTime(now.year, now.month - 1);
      if (months.length != records.length ||
          months.last - months.first != months.length - 1 ||
          months.last !=
              previousCalendarMonth.year * 12 + previousCalendarMonth.month)
        continue;
      final days = records.map((e) => e.date.toLocal().day).toList()..sort();
      if (days.last - days.first > 3) continue;
      final amounts = records.map((e) => e.amountMinor.toDouble()).toList()
        ..sort();
      final median = quantile(amounts, .5);
      if (median <= 0 || amounts.any((a) => (a - median).abs() / median > .2))
        continue;
      final native = median.round(),
          base = ledger.inBase(
            median.round(),
            ledger.account(records.first.accountId).currency,
          );
      if (base <= 0) continue;
      result.add(
        RepeatCandidate(
          name: records.last.name,
          accountId: records.first.accountId,
          categoryId: records.first.categoryId,
          nativeMinor: native,
          baseMinor: base,
          months: months.length,
          first: records.first.date.toLocal(),
          last: records.last.date.toLocal(),
        ),
      );
    }
    return result..sort((a, b) => b.baseMinor.compareTo(a.baseMinor));
  }

  int get possibleMonthlyTotal =>
      candidates.fold<int>(0, (s, c) => s + c.baseMinor);
  int get possibleDailyCost =>
      (possibleMonthlyTotal *
              12 /
              calendarDaysBetween(DateTime(now.year), DateTime(now.year + 1)))
          .round();
}
