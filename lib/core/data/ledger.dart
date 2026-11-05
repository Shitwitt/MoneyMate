import 'dart:math' as math;

import '../models/models.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

class Ledger {
  final ProfileData data;
  final AppSettings settings;
  const Ledger(this.data, this.settings);
  String get currency => data.profile.currency;
  Account account(String id) =>
      data.accounts.firstWhere((item) => item.id == id);
  Category? category(String id) =>
      data.categories.where((item) => item.id == id).firstOrNull;
  int inBase(int minor, String from) =>
      convertMinor(minor, from, currency, data.rates);
  int entryValue(MoneyTransaction entry) =>
      inBase(entry.amountMinor, account(entry.accountId).currency);

  /// Balance is a projection of the ledger, never a second mutable source of truth.
  /// A transfer is ONE persisted record: deleting/editing it changes both sides together.
  int accountBalance(String id, {DateTime? before}) {
    final item = account(id);
    var result = item.openingMinor;
    for (final entry in data.transactions) {
      if (before != null && !entry.date.isBefore(before)) continue;
      if (entry.accountId == id) {
        result += entry.type == 'income'
            ? entry.amountMinor
            : -entry.amountMinor;
      }
      if (entry.type == 'transfer' && entry.toAccountId == id) {
        result += entry.toAmountMinor;
      }
    }
    return result;
  }

  int get accountsTotal => data.accounts
      .where((item) => !item.excluded)
      .fold(
        0,
        (sum, item) => sum + inBase(accountBalance(item.id), item.currency),
      );
  int get assetsTotal =>
      data.assets.fold(0, (sum, item) => sum + item.valueMinor);
  int loanRemaining(Loan loan) => math.max(
    0,
    (loan.principalMinor * (1 + loan.interestPercent / 100)).round() -
        loan.repayments.fold<int>(0, (sum, event) => sum + event.amountMinor),
  );
  int get toReceive => data.loans
      .where((loan) => loan.direction == 'lent')
      .fold(0, (sum, loan) => sum + loanRemaining(loan));
  int get toPay => data.loans
      .where((loan) => loan.direction == 'borrowed')
      .fold(0, (sum, loan) => sum + loanRemaining(loan));

  /// Conservative planning estimate, not a bank-confirmed spendable balance.
  /// Investments/savings and future-dated credits cannot fund today's spending.
  SafeToSpendSummary safeToSpend(DateTime now) {
    final end = financialMonth(now, settings.monthStart).end;
    final liquid = data.accounts
        .where(
          (item) =>
              !item.excluded &&
              !item.archived &&
              !['investment', 'savings'].contains(item.type),
        )
        .toList();
    final ids = liquid.map((item) => item.id).toSet();
    final balance = liquid.fold<int>(
      0,
      (sum, item) =>
          sum + inBase(accountBalance(item.id, before: now), item.currency),
    );
    var upcoming = 0;
    var complete = true;
    for (final rule in data.recurrings.where(
      (rule) =>
          rule.enabled &&
          !rule.archived &&
          rule.type == 'expense' &&
          ids.contains(rule.accountId),
    )) {
      var cursor = rule.nextDue;
      var count = 0;
      while (cursor.isBefore(end) &&
          (rule.end == null || !cursor.isAfter(rule.end!))) {
        if (++count > 1000) {
          complete = false;
          break;
        }
        upcoming += inBase(rule.amountMinor, account(rule.accountId).currency);
        cursor = nextOccurrence(rule, cursor);
      }
    }
    upcoming += data.transactions
        .where(
          (entry) =>
              !entry.date.isBefore(now) &&
              entry.date.isBefore(end) &&
              ids.contains(entry.accountId) &&
              (entry.type == 'expense' ||
                  (entry.type == 'transfer' &&
                      !ids.contains(entry.toAccountId))),
        )
        .fold<int>(0, (sum, entry) => sum + entryValue(entry));
    final loans = data.loans
        .where((loan) => loan.direction == 'borrowed' && loan.due.isBefore(end))
        .fold<int>(0, (sum, loan) => sum + loanRemaining(loan));
    final goals = data.goals
        .where((goal) => goal.accountId.isEmpty && !goal.archived)
        .fold<int>(
          0,
          (sum, goal) => sum + math.min(goal.targetMinor, goalSaved(goal)),
        );
    return SafeToSpendSummary(
      balance: balance,
      upcoming: upcoming,
      loans: loans,
      goals: goals,
      complete: complete,
      end: end,
    );
  }

  int get netWorth => accountsTotal + assetsTotal + toReceive - toPay;
  int netWorthBefore(DateTime before) =>
      data.accounts
          .where((item) => !item.excluded)
          .fold<int>(
            0,
            (sum, item) =>
                sum +
                inBase(accountBalance(item.id, before: before), item.currency),
          ) +
      assetsTotal +
      toReceive -
      toPay;

  int total(
    String type,
    DateWindow window, {
    Iterable<MoneyTransaction>? entries,
  }) => (entries ?? data.transactions)
      .where((entry) => entry.type == type && window.contains(entry.date))
      .fold(0, (sum, entry) => sum + entryValue(entry));
  int goalSaved(Goal goal) => goal.accountId.isNotEmpty
      ? math.max(
          0,
          inBase(
            accountBalance(goal.accountId),
            account(goal.accountId).currency,
          ),
        )
      : goal.contributions.fold(0, (sum, item) => sum + item.amountMinor) +
            data.transactions
                .where(
                  (entry) => entry.goalId == goal.id && entry.type == 'income',
                )
                .fold(0, (sum, entry) => sum + entryValue(entry));
  int spentFor(Budget budget, DateWindow window) => data.transactions
      .where(
        (entry) =>
            entry.type == 'expense' &&
            window.contains(entry.date) &&
            !entry.date.isBefore(dayOnly(budget.start)) &&
            (entry.budgetId == budget.id ||
                budget.categoryIds.isEmpty ||
                budget.categoryIds.contains(entry.categoryId)),
      )
      .fold(0, (sum, entry) => sum + entryValue(entry));

  BudgetStatus budgetStatus(Budget budget, DateTime now) {
    final window = budgetWindow(budget, now, settings.weekStart);
    var carry = 0;
    // Rollover is the sum of prior limits minus actual spend, including overspend.
    // Walk forward from inception; using signed carry avoids "forgiving" debt.
    if (budget.rollover &&
        budget.period != 'custom' &&
        !now.isBefore(budget.start)) {
      var cursor = budgetWindow(budget, budget.start, settings.weekStart);
      while (cursor.end.isBefore(window.start) ||
          cursor.end.isAtSameMomentAs(window.start)) {
        carry += budget.limitMinor - spentFor(budget, cursor);
        cursor = budgetWindow(
          budget,
          cursor.end.add(const Duration(hours: 12)),
          settings.weekStart,
        );
      }
    }
    final spent = now.isBefore(budget.start) ? 0 : spentFor(budget, window);
    final limit = budget.limitMinor + carry;
    return BudgetStatus(
      window: window,
      spent: spent,
      limit: limit,
      carry: carry,
    );
  }

  double monthlyCost(Recurring rule) {
    final value = inBase(
      rule.amountMinor,
      account(rule.accountId).currency,
    ).toDouble();
    return switch (rule.frequency) {
      'daily' || 'custom' => value * 365.25 / 12 / rule.interval,
      'weekly' => value * 52.1775 / 12 / rule.interval,
      'fortnightly' => value * 26.08875 / 12 / rule.interval,
      'quarterly' => value / 3 / rule.interval,
      'half-yearly' => value / 6 / rule.interval,
      'yearly' => value / 12 / rule.interval,
      _ => value / rule.interval,
    };
  }

  int get monthlyBurn => data.recurrings
      .where((rule) => rule.enabled && !rule.archived && rule.type == 'expense')
      .fold<double>(0, (sum, rule) => sum + monthlyCost(rule))
      .round();
  Map<String, int> breakdown(
    Iterable<MoneyTransaction> entries,
    String dimension,
  ) {
    final result = <String, int>{};
    for (final entry in entries.where((entry) => entry.type != 'transfer')) {
      final key = switch (dimension) {
        'account' => account(entry.accountId).name,
        'name' => entry.name,
        _ => category(entry.categoryId)?.name ?? 'Uncategorized',
      };
      result[key] = (result[key] ?? 0) + entryValue(entry);
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}

class SafeToSpendSummary {
  final int balance, upcoming, loans, goals;
  final bool complete;
  final DateTime end;
  const SafeToSpendSummary({
    required this.balance,
    required this.upcoming,
    required this.loans,
    required this.goals,
    required this.complete,
    required this.end,
  });
  int get reserved => upcoming + loans + goals;
  int get available => complete ? math.max(0, balance - reserved) : 0;
}

class BudgetStatus {
  final DateWindow window;
  final int spent;
  final int limit;
  final int carry;
  const BudgetStatus({
    required this.window,
    required this.spent,
    required this.limit,
    required this.carry,
  });
  int get remaining => limit - spent;
  double get progress => limit <= 0 ? (spent > 0 ? 1 : 0) : spent / limit;
  String get label => remaining < 0
      ? 'Over budget'
      : progress >= .8
      ? 'Getting close'
      : 'On track';
}

class TransactionFilter {
  final String query;
  final DateWindow? dates;
  final Set<String> accounts;
  final Set<String> categories;
  final Set<String> labels;
  final Set<String> people;
  final Set<String> places;
  final String type;
  final int? minMinor;
  final int? maxMinor;
  final String sort;
  const TransactionFilter({
    this.query = '',
    this.dates,
    this.accounts = const {},
    this.categories = const {},
    this.labels = const {},
    this.people = const {},
    this.places = const {},
    this.type = 'all',
    this.minMinor,
    this.maxMinor,
    this.sort = 'newest',
  });
  bool get active =>
      dates != null ||
      accounts.isNotEmpty ||
      categories.isNotEmpty ||
      labels.isNotEmpty ||
      people.isNotEmpty ||
      places.isNotEmpty ||
      type != 'all' ||
      minMinor != null ||
      maxMinor != null;
  List<MoneyTransaction> apply(Ledger ledger) {
    final needle = query.trim().toLowerCase();
    final result = ledger.data.transactions.where((entry) {
      if (dates != null && !dates!.contains(entry.date)) return false;
      if (accounts.isNotEmpty &&
          !accounts.contains(entry.accountId) &&
          !accounts.contains(entry.toAccountId)) {
        return false;
      }
      if (categories.isNotEmpty && !categories.contains(entry.categoryId)) {
        return false;
      }
      if (labels.isNotEmpty && !entry.labelIds.any(labels.contains)) {
        return false;
      }
      if (people.isNotEmpty && !entry.personIds.any(people.contains)) {
        return false;
      }
      if (places.isNotEmpty && !places.contains(entry.placeId)) return false;
      if (type != 'all' && type != entry.type) return false;
      final value = ledger.entryValue(entry);
      if (minMinor != null && value < minMinor!) return false;
      if (maxMinor != null && value > maxMinor!) return false;
      if (needle.isNotEmpty) {
        final extra = ledger.data.entities
            .where(
              (item) =>
                  entry.labelIds.contains(item.id) ||
                  entry.personIds.contains(item.id) ||
                  entry.placeId == item.id,
            )
            .map((item) => item.name)
            .join(' ');
        if (!'${entry.name} ${entry.notes} ${ledger.account(entry.accountId).name} ${ledger.category(entry.categoryId)?.name ?? ''} $extra'
            .toLowerCase()
            .contains(needle)) {
          return false;
        }
      }
      return true;
    }).toList();
    result.sort(
      (a, b) => switch (sort) {
        'oldest' => a.date.compareTo(b.date),
        'largest' => ledger.entryValue(b).compareTo(ledger.entryValue(a)),
        'smallest' => ledger.entryValue(a).compareTo(ledger.entryValue(b)),
        _ => b.date.compareTo(a.date),
      },
    );
    return result;
  }
}

/// Largest-remainder allocation guarantees that integer minor-unit splits sum
/// EXACTLY to the bill, including 100 / 3. No silent cent loss or duplicate debt.
List<int> splitWeighted(int total, List<double> weights) {
  if (total <= 0 ||
      weights.isEmpty ||
      weights.any((weight) => !weight.isFinite || weight < 0)) {
    throw const FormatException('Enter a positive bill and valid shares');
  }
  final sum = weights.fold<double>(0, (a, b) => a + b);
  if (sum <= 0) {
    throw const FormatException('At least one share must be positive');
  }
  final raw = weights.map((weight) => total * weight / sum).toList();
  final result = raw.map((value) => value.floor()).toList();
  final order = List.generate(weights.length, (index) => index)
    ..sort((a, b) => (raw[b] - result[b]).compareTo(raw[a] - result[a]));
  final missing = total - result.fold<int>(0, (a, b) => a + b);
  for (var i = 0; i < missing; i++) {
    result[order[i]]++;
  }
  return result;
}
