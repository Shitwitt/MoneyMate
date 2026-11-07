import 'package:flutter/foundation.dart';

import '../../core/enum/filter_enums.dart';
import 'category_model.dart';

/// One x-axis point of the income-vs-expense line chart.
///
/// A point is either a **day** (week / month windows) or a **month** (year /
/// all-time windows). [label] is the axis label that belongs to that bucket, so
/// the widget never has to know how to format dates.
@immutable
class FlowPoint {
  const FlowPoint({
    required this.date,
    required this.label,
    this.income = 0,
    this.expense = 0,
    this.monthBucket = false,
  });

  /// First moment of the bucket (midnight for days, the 1st for months).
  final DateTime date;

  /// Axis label, e.g. `Mon`, `07`, `Nov`.
  final String label;

  /// Money received in the bucket.
  final double income;

  /// Money spent in the bucket.
  final double expense;

  /// True when the bucket aggregates a whole month rather than a single day.
  final bool monthBucket;

  /// Signed money movement.
  double get net => income - expense;

  /// True when the bucket has no money movement at all.
  bool get isEmpty => income == 0 && expense == 0;

  FlowPoint copyWith({double? income, double? expense}) => FlowPoint(
        date: date,
        label: label,
        income: income ?? this.income,
        expense: expense ?? this.expense,
        monthBucket: monthBucket,
      );

  @override
  bool operator ==(Object other) =>
      other is FlowPoint &&
      other.date == date &&
      other.label == label &&
      other.income == income &&
      other.expense == expense &&
      other.monthBucket == monthBucket;

  @override
  int get hashCode => Object.hash(date, label, income, expense, monthBucket);

  @override
  String toString() => 'FlowPoint($label, in: $income, out: $expense)';
}

/// One slice of the category donut, already ranked by amount (descending).
@immutable
class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.amount,
    required this.count,
    required this.share,
  });

  /// The category the money went to. Rows whose category was deleted are folded
  /// into the provider's synthetic "Uncategorised" category so every slice stays
  /// drawable and the shares always add up to 100%.
  final CategoryModel category;

  /// Total amount for this category inside the analysed window.
  final double amount;

  /// How many transactions make up [amount].
  final int count;

  /// `amount / totalExpense`, clamped to `0..1`.
  final double share;

  String get name => category.name;

  /// ARGB colour used for the slice and the leaderboard chip.
  int get colorValue => category.color;

  /// Icon code point used for the leaderboard chip.
  int get iconCodePoint => category.icon;

  String get categoryId => category.id;

  @override
  bool operator ==(Object other) =>
      other is CategorySlice &&
      other.category == category &&
      other.amount == amount &&
      other.count == count &&
      other.share == share;

  @override
  int get hashCode => Object.hash(category, amount, count, share);

  @override
  String toString() => 'CategorySlice($name, $amount, ${count}x)';
}

/// One month of income vs expense — a group in the grouped bar chart.
@immutable
class MonthlyFlow {
  const MonthlyFlow({
    required this.month,
    required this.label,
    this.income = 0,
    this.expense = 0,
  });

  /// First day of the month.
  final DateTime month;

  /// Axis label, e.g. `Nov`.
  final String label;

  final double income;
  final double expense;

  double get net => income - expense;

  @override
  bool operator ==(Object other) =>
      other is MonthlyFlow &&
      other.month == month &&
      other.label == label &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(month, label, income, expense);

  @override
  String toString() => 'MonthlyFlow($label, in: $income, out: $expense)';
}

/// Money spent from (or received into) one account during the analysed window.
@immutable
class AccountShare {
  const AccountShare({
    required this.accountId,
    required this.title,
    required this.type,
    required this.colorValue,
    required this.amount,
    required this.count,
    required this.share,
  });

  final String accountId;

  /// Account title (`HDFC Savings`, `Cash`).
  final String title;

  /// Cash / bank / card — used for the grouped percentage summary.
  final AccountType type;

  /// ARGB colour of the account tile.
  final int colorValue;

  final double amount;
  final int count;

  /// `amount / analysedTotal`, clamped to `0..1`.
  final double share;

  @override
  bool operator ==(Object other) =>
      other is AccountShare &&
      other.accountId == accountId &&
      other.amount == amount &&
      other.count == count &&
      other.share == share;

  @override
  int get hashCode => Object.hash(accountId, amount, count, share);

  @override
  String toString() => 'AccountShare($title, $amount)';
}

/// One account *kind* share (`Cash` / `Bank` / `Cards`) of the distributed
/// total, used by the stacked bar's caption row.
@immutable
class AccountTypeShare {
  const AccountTypeShare({
    required this.type,
    required this.amount,
    required this.share,
  });

  final AccountType type;
  final double amount;
  final double share;

  @override
  bool operator ==(Object other) =>
      other is AccountTypeShare &&
      other.type == type &&
      other.amount == amount &&
      other.share == share;

  @override
  int get hashCode => Object.hash(type, amount, share);

  @override
  String toString() => 'AccountTypeShare(${type.name}, $amount)';
}

/// Everything the analytics screen renders, computed once per rebuild from the
/// real ledger.
///
/// The provider is the only place that knows how to bucket transactions, so
/// every number here is derived from persisted records — there is no literal
/// chart data anywhere in the UI layer.
@immutable
class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.range,
    required this.type,
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.transactionCount,
    required this.elapsedDays,
    required this.highestSpendingDay,
    required this.flowPoints,
    required this.categorySlices,
    required this.monthlyFlows,
    required this.accountShares,
    required this.typeShares,
    required this.monthsShown,
    required this.scopeLabel,
  });

  /// The window the user picked.
  final AnalyticsRange range;

  /// The transaction types the user picked.
  final AnalyticsTypeFilter type;

  /// First day of the window (inclusive).
  final DateTime start;

  /// Last day of the window (inclusive).
  final DateTime end;

  /// Income counted in the window (0 when the type filter hides income).
  final double income;

  /// Expense counted in the window (0 when the type filter hides expense).
  final double expense;

  /// Number of counted transactions.
  final int transactionCount;

  /// Whole days from [start] to today (or to [end] for past windows).
  final int elapsedDays;

  /// The single day with the highest outflow, or `null` when nothing was spent.
  final FlowPoint? highestSpendingDay;

  /// Line-chart points: one per day (week / month) or per month (year / all).
  final List<FlowPoint> flowPoints;

  /// Donut slices, ranked by amount descending.
  final List<CategorySlice> categorySlices;

  /// Grouped-bar groups, oldest month first.
  final List<MonthlyFlow> monthlyFlows;

  /// Account breakdown, ranked by amount descending.
  final List<AccountShare> accountShares;

  /// Cash / bank / card roll-up.
  final List<AccountTypeShare> typeShares;

  /// How many months the bar chart shows (6 or 12).
  final int monthsShown;

  /// Human description of the analysed window, e.g. `01 Nov – 30 Nov`.
  final String scopeLabel;

  /// Income minus expense.
  double get net => income - expense;

  /// `net / income` as a fraction; `0` when there is no income to compare to.
  double get savingsRate {
    if (income <= 0) return 0;
    return net / income;
  }

  /// Expense per elapsed day.
  double get averageDailySpend {
    if (elapsedDays <= 0) return 0;
    return expense / elapsedDays;
  }

  /// Total money inside the donut / account breakdown. Both charts distribute
  /// the same denominator so their percentages agree.
  double get analysedTotal =>
      type == AnalyticsTypeFilter.income ? income : expense;

  /// True when the window contains no countable transaction.
  bool get isEmpty => transactionCount == 0;

  /// True when the line chart has at least one non-empty bucket.
  bool get hasFlow => flowPoints.any((FlowPoint point) => !point.isEmpty);

  /// True when the bar chart has at least one month with movement.
  bool get hasMonthlyFlow => monthlyFlows
      .any((MonthlyFlow flow) => flow.income > 0 || flow.expense > 0);

  /// True when money is distributed across at least one account.
  bool get hasAccountSplit =>
      accountShares.any((AccountShare share) => share.amount > 0);

  @override
  String toString() =>
      'AnalyticsSnapshot(${range.name}, ${type.name}, in: $income, out: $expense)';
}
