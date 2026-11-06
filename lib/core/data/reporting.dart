import 'dart:math' as math;

import '../models/models.dart';
import '../utils/dates.dart';
import 'ledger.dart';
import 'recurring_schedule.dart';

/// Reports never count opening balances, transfers, excluded accounts or
/// future-dated records as posted income/expense. Rates remain user-supplied.
class ReportSnapshot {
  final Ledger ledger;
  final DateWindow window;
  final DateTime asOf;
  final List<MoneyTransaction> entries;

  factory ReportSnapshot(
    Ledger ledger,
    DateWindow window, {
    DateTime? now,
    Iterable<MoneyTransaction>? selection,
  }) {
    final asOf = now ?? DateTime.now();
    final entries = (selection ?? ledger.data.transactions)
        .where(
          (entry) =>
              entry.type != 'transfer' &&
              window.contains(entry.date) &&
              !entry.date.isAfter(asOf) &&
              !ledger.account(entry.accountId).excluded,
        )
        .toList();
    return ReportSnapshot._(ledger, window, asOf, entries);
  }
  ReportSnapshot._(this.ledger, this.window, this.asOf, this.entries);

  int total(String type) => entries
      .where((e) => e.type == type)
      .fold(0, (sum, e) => sum + ledger.entryValue(e));
  int get income => total('income');
  int get expense => total('expense');
  int get net => income - expense;
  List<MoneyTransaction> get expenses =>
      entries.where((e) => e.type == 'expense').toList();
  double? get savingsRate => income == 0 ? null : net / income * 100;
  int get dailyAverage => (expense / window.days).round();
  int get averageTransaction =>
      expenses.isEmpty ? 0 : (expense / expenses.length).round();
  MoneyTransaction? get largestExpense {
    final sorted = [...expenses]
      ..sort((a, b) => ledger.entryValue(b).compareTo(ledger.entryValue(a)));
    return sorted.firstOrNull;
  }

  Map<DateTime, int> get dailyExpenses {
    final result = <DateTime, int>{};
    for (final e in expenses)
      result.update(
        dayOnly(e.date),
        (v) => v + ledger.entryValue(e),
        ifAbsent: () => ledger.entryValue(e),
      );
    return result;
  }

  DateTime? get peakDay {
    final sorted = dailyExpenses.entries.toList()
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        return byValue == 0 ? a.key.compareTo(b.key) : byValue;
      });
    return sorted.firstOrNull?.key;
  }

  List<ReportGroup> groups({
    String type = 'expense',
    String dimension = 'category',
  }) {
    final groups = <String, List<MoneyTransaction>>{};
    for (final e in entries.where((e) => e.type == type)) {
      final keys = switch (dimension) {
        'account' => [e.accountId],
        'label' => e.labelIds.isEmpty ? [''] : e.labelIds,
        'person' => e.personIds.isEmpty ? [''] : e.personIds,
        'place' => [e.placeId],
        _ => [rootCategory(e.categoryId)],
      };
      for (final key in keys) (groups[key] ??= []).add(e);
    }
    final result = <ReportGroup>[];
    for (final group in groups.entries) {
      final category = ledger.category(group.key);
      final entity = ledger.data.entities
          .where((e) => e.id == group.key)
          .firstOrNull;
      final account = ledger.data.accounts
          .where((e) => e.id == group.key)
          .firstOrNull;
      result.add(
        ReportGroup(
          id: group.key,
          name: dimension == 'account'
              ? account?.name ?? 'Unknown account'
              : dimension == 'category'
              ? category?.name ?? 'Uncategorized'
              : entity?.name ?? 'Untagged',
          icon: dimension == 'account'
              ? account?.icon ?? 'bank'
              : dimension == 'category'
              ? category?.icon ?? 'category'
              : dimension,
          color: dimension == 'account'
              ? account?.color ?? 0xffffb59a
              : dimension == 'category'
              ? category?.color ?? 0xffffb59a
              : entity?.color ?? 0xffffb59a,
          amount: group.value.fold(0, (sum, e) => sum + ledger.entryValue(e)),
          entries: group.value,
        ),
      );
    }
    return result..sort((a, b) => b.amount.compareTo(a.amount));
  }

  String rootCategory(String id) {
    final visited = <String>{};
    var cursor = id;
    while (visited.add(cursor)) {
      final parent = ledger.category(cursor)?.parentId ?? '';
      if (parent.isEmpty) break;
      cursor = parent;
    }
    return cursor;
  }

  List<DailyFlow> get daily {
    final income = <DateTime, int>{}, expense = <DateTime, int>{};
    for (final entry in entries) {
      final map = entry.type == 'income' ? income : expense,
          date = dayOnly(entry.date);
      map.update(
        date,
        (n) => n + ledger.entryValue(entry),
        ifAbsent: () => ledger.entryValue(entry),
      );
    }
    return List.generate(math.min(window.days, 366), (i) {
      final date = DateTime(
        window.start.year,
        window.start.month,
        window.start.day + i,
      );
      return DailyFlow(
        date,
        income[date] ?? 0,
        expense[date] ?? 0,
        date.isAfter(dayOnly(asOf)),
      );
    });
  }
}

class ReportGroup {
  final String id, name, icon;
  final int color, amount;
  final List<MoneyTransaction> entries;
  const ReportGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.entries,
  });
}

class DailyFlow {
  final DateTime date;
  final int income, expense;
  final bool future;
  const DailyFlow(this.date, this.income, this.expense, this.future);
  int get net => income - expense;
}

class UpcomingRecord {
  final DateTime date;
  final MoneyTransaction? entry;
  final Recurring? rule;
  const UpcomingRecord(this.date, {this.entry, this.rule});
  String get name => entry?.name ?? rule!.name;
  String get accountId => entry?.accountId ?? rule!.accountId;
  String get type => entry?.type ?? rule!.type;
  int get amountMinor => entry?.amountMinor ?? rule!.amountMinor;
}

/// A preview only. Does not materialize transactions or write to a repository.
List<UpcomingRecord> upcomingRecords(
  Ledger ledger,
  DateTime now, {
  int days = 60,
}) {
  final window = DateWindow(now, DateTime(now.year, now.month, now.day + days));
  final result = <UpcomingRecord>[
    for (final entry in ledger.data.transactions)
      if (entry.date.isAfter(now) && window.contains(entry.date))
        UpcomingRecord(entry.date, entry: entry),
  ];
  for (final rule in ledger.data.recurrings.where(recurringActive)) {
    for (final date in projectedOccurrences(rule, window, limit: 120)) {
      if (!date.isAfter(now)) continue;
      if (ledger.data.transactions.any(
        (e) => e.recurringId == rule.id && e.date.isAtSameMomentAs(date),
      ))
        continue;
      result.add(UpcomingRecord(date, rule: rule));
    }
  }
  return result..sort((a, b) => a.date.compareTo(b.date));
}
