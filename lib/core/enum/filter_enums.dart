import 'package:flutter/material.dart';

/// The direction of money movement for a single record.
enum TransactionType {
  /// Money leaving the user's pocket.
  expense,

  /// Money coming into an account.
  income,

  /// Money moving between two of the user's own accounts. Never changes the
  /// total net worth, only the distribution across accounts.
  transfer,
}

/// The kind of account a transaction can be paid from / received into.
enum AccountType {
  /// Physical cash in hand / wallet.
  cash,

  /// Savings / current bank account.
  bank,

  /// Credit or debit card.
  card,
}

/// The two sides of a lending relationship.
enum DebtType {
  /// Money Lent to others — someone owes the user.
  debt,

  /// Money Borrowed / Loan / EMI — the user owes the lender.
  credit,
}

/// Time windows used by the home screen chart filters and the transaction
/// history filters.
enum FilterExpense {
  daily,
  weekly,
  monthly,
  yearly,
  all,
}

// ---------------------------------------------------------------------------
// Presentation helpers. These live next to the enums so every layer of the app
// (UI, providers, exports, backup files) resolves labels the exact same way.
// ---------------------------------------------------------------------------

extension TransactionTypeX on TransactionType {
  /// Persisted value — never rename these strings, backups depend on them.
  String get key => name;

  /// Resolves a persisted/invalid value safely, defaulting to [expense].
  static TransactionType fromKey(String? key) {
    return TransactionType.values.firstWhere(
      (TransactionType value) => value.name == key,
      orElse: () => TransactionType.expense,
    );
  }

  String get label {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  /// Prefix used when rendering signed amounts.
  String get signPrefix {
    switch (this) {
      case TransactionType.expense:
        return '-';
      case TransactionType.income:
        return '+';
      case TransactionType.transfer:
        return '';
    }
  }
}

extension AccountTypeX on AccountType {
  String get key => name;

  static AccountType fromKey(String? key) {
    return AccountType.values.firstWhere(
      (AccountType value) => value.name == key,
      orElse: () => AccountType.cash,
    );
  }

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank';
      case AccountType.card:
        return 'Card';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.card:
        return Icons.credit_card_rounded;
    }
  }
}

extension DebtTypeX on DebtType {
  String get key => name;

  static DebtType fromKey(String? key) {
    return DebtType.values.firstWhere(
      (DebtType value) => value.name == key,
      orElse: () => DebtType.debt,
    );
  }

  /// Full sentence shown in debt forms.
  String get label {
    switch (this) {
      case DebtType.debt:
        return 'Money Lent';
      case DebtType.credit:
        return 'Money Borrowed';
    }
  }

  /// Short badge label used in lists.
  String get shortLabel {
    switch (this) {
      case DebtType.debt:
        return 'Lent';
      case DebtType.credit:
        return 'Borrowed';
    }
  }

  String get description {
    switch (this) {
      case DebtType.debt:
        return 'Money you gave to someone else';
      case DebtType.credit:
        return 'Loan / EMI you have to repay';
    }
  }

  IconData get icon {
    switch (this) {
      case DebtType.debt:
        return Icons.call_made_rounded;
      case DebtType.credit:
        return Icons.call_received_rounded;
    }
  }

  /// Positive for lent money (an asset), negative for borrowed money.
  double get netWorthSign {
    switch (this) {
      case DebtType.debt:
        return 1;
      case DebtType.credit:
        return -1;
    }
  }
}

extension FilterExpenseX on FilterExpense {
  String get key => name;

  static FilterExpense fromKey(String? key) {
    return FilterExpense.values.firstWhere(
      (FilterExpense value) => value.name == key,
      orElse: () => FilterExpense.monthly,
    );
  }

  String get label {
    switch (this) {
      case FilterExpense.daily:
        return 'Daily';
      case FilterExpense.weekly:
        return 'Weekly';
      case FilterExpense.monthly:
        return 'Monthly';
      case FilterExpense.yearly:
        return 'Yearly';
      case FilterExpense.all:
        return 'All';
    }
  }
}

/// Which transaction types an analytics view counts.
///
/// The analytics screen needs a *type* filter on top of the time filter: a user
/// studying spending wants expenses only, while someone reconciling a salary
/// wants income only. Transfers are always excluded from money-flow maths (they
/// only move money between the user's own accounts), so they are never a
/// choice here.
enum AnalyticsTypeFilter {
  /// Both income and expense transactions.
  all,

  /// Expenses only.
  expense,

  /// Income only.
  income;

  String get key => name;

  /// Statics must live on the enum itself: `AnalyticsTypeFilter.fromKey` is not
  /// reachable when they are declared in a separate extension, unlike the
  /// instance members below.
  static AnalyticsTypeFilter fromKey(String? key) {
    return AnalyticsTypeFilter.values.firstWhere(
      (AnalyticsTypeFilter value) => value.name == key,
      orElse: () => AnalyticsTypeFilter.all,
    );
  }
}

extension AnalyticsTypeFilterX on AnalyticsTypeFilter {
  /// Segmented-button label.
  String get label {
    switch (this) {
      case AnalyticsTypeFilter.all:
        return 'All';
      case AnalyticsTypeFilter.expense:
        return 'Expense Only';
      case AnalyticsTypeFilter.income:
        return 'Income Only';
    }
  }

  /// Short label for tight layouts.
  String get shortLabel {
    switch (this) {
      case AnalyticsTypeFilter.all:
        return 'All';
      case AnalyticsTypeFilter.expense:
        return 'Expense';
      case AnalyticsTypeFilter.income:
        return 'Income';
    }
  }

  /// Whether income records are counted.
  bool get includesIncome => this != AnalyticsTypeFilter.expense;

  /// Whether expense records are counted.
  bool get includesExpense => this != AnalyticsTypeFilter.income;
}

/// The four time windows offered by the analytics filter bar.
///
/// Deliberately coarse: the charts aggregate by day or by month, so a
/// "yesterday" style window would produce a single unreadable point. Each
/// window knows how to resolve itself into an inclusive `(start, end)` range so
/// the provider can bucket transactions without the UI doing date maths.
enum AnalyticsRange {
  thisWeek,
  thisMonth,
  thisYear,
  allTime;

  String get key => name;

  static AnalyticsRange fromKey(String? key) {
    return AnalyticsRange.values.firstWhere(
      (AnalyticsRange value) => value.name == key,
      orElse: () => AnalyticsRange.thisMonth,
    );
  }

  /// Chip label, e.g. `This Month`.
  String get label {
    switch (this) {
      case AnalyticsRange.thisWeek:
        return 'This Week';
      case AnalyticsRange.thisMonth:
        return 'This Month';
      case AnalyticsRange.thisYear:
        return 'This Year';
      case AnalyticsRange.allTime:
        return 'All Time';
    }
  }

  /// Icon shown on the chart legend / filter summary.
  IconData get icon {
    switch (this) {
      case AnalyticsRange.thisWeek:
        return Icons.view_week_rounded;
      case AnalyticsRange.thisMonth:
        return Icons.calendar_month_rounded;
      case AnalyticsRange.thisYear:
        return Icons.calendar_today_rounded;
      case AnalyticsRange.allTime:
        return Icons.all_inclusive_rounded;
    }
  }

  /// Whether this is a rolling multi-month window (used to decide whether the
  /// line chart plots days or months).
  bool get isLongWindow =>
      this == AnalyticsRange.thisYear || this == AnalyticsRange.allTime;
}

extension AnalyticsRangeRange on AnalyticsRange {
  /// Inclusive `(start, end)` day window ending today.
  ///
  /// [oldest] is the earliest transaction date the caller knows about; it only
  /// matters for [AnalyticsRange.allTime], which falls back to the first day of
  /// the current month when the ledger is empty (so an empty state still has a
  /// sensible axis instead of a 1970-style span).
  (DateTime, DateTime) resolve({
    required DateTime now,
    DateTime? oldest,
    bool weekStartsMonday = true,
  }) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case AnalyticsRange.thisWeek:
        final int weekday = today.weekday; // Mon = 1 … Sun = 7
        final int offset = weekStartsMonday ? weekday - 1 : weekday % 7;
        final DateTime start = today.subtract(Duration(days: offset));
        return (start, start.add(const Duration(days: 6)));
      case AnalyticsRange.thisMonth:
        return (
          DateTime(today.year, today.month),
          DateTime(today.year, today.month + 1, 0),
        );
      case AnalyticsRange.thisYear:
        return (DateTime(today.year), DateTime(today.year, 12, 31));
      case AnalyticsRange.allTime:
        final DateTime first = oldest == null
            ? DateTime(today.year, today.month)
            : DateTime(oldest.year, oldest.month);
        return (first, today);
    }
  }
}
