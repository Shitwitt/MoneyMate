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
