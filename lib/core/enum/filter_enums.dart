/// Core filter and classification enums used by the Paisa data layer.
///
/// These enums are serialized by name in Hive. Keeping the persisted values as
/// strings avoids generated `.g.dart` adapters and makes backups portable.

/// The direction of a ledger entry.
enum TransactionType {
  expense,
  income,
  transfer,
}

/// The kind of account that holds a balance.
enum AccountType {
  cash,
  bank,
  card,
}

/// The direction of a debt.
///
/// [debt] means money lent to another person or institution.
/// [credit] means money borrowed from another person, a bank, a loan, or an EMI.
enum DebtType {
  debt,
  credit,
}

/// Time buckets used by reports, budgets, and home-screen filters.
enum FilterExpense {
  daily,
  weekly,
  monthly,
  yearly,
  all,
}

/// Human-readable labels shared by UI and export code.
extension TransactionTypeLabel on TransactionType {
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
}

extension AccountTypeLabel on AccountType {
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
}

extension DebtTypeLabel on DebtType {
  String get label {
    switch (this) {
      case DebtType.debt:
        return 'Money lent';
      case DebtType.credit:
        return 'Money borrowed';
    }
  }
}

extension FilterExpenseLabel on FilterExpense {
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
