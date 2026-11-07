import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/data/models/transaction_model.dart';

/// A miniature of `_SearchScreenState._results`: same rules, no widgets.
///
/// Keeping the predicate in a testable shape proves the search semantics
/// (title / notes / amount / category + type / account / category filters)
/// without pumping the whole app shell.
List<TransactionModel> searchTransactions(
  List<TransactionModel> source, {
  required String query,
  TransactionType? type,
  String? accountId,
  String? categoryId,
  String Function(String?) categoryName = _fallbackCategoryName,
}) {
  final String needle = query.trim().toLowerCase();
  final double? amountNeedle =
      needle.isEmpty ? null : double.tryParse(needle.replaceAll(',', ''));

  return source.where((TransactionModel transaction) {
    if (type != null && transaction.type != type) return false;
    if (accountId != null &&
        transaction.accountId != accountId &&
        transaction.toAccountId != accountId) {
      return false;
    }
    if (categoryId != null && transaction.categoryId != categoryId) {
      return false;
    }
    if (needle.isEmpty) return true;

    final String title = transaction.name.toLowerCase();
    final String notes = (transaction.description ?? '').toLowerCase();
    final String category = categoryName(transaction.categoryId).toLowerCase();
    final String amountText = transaction.amount.toStringAsFixed(2);
    final String amountWhole = transaction.amount.round().toString();
    final String digits = needle.replaceAll(',', '');

    final bool textHit =
        title.contains(needle) || notes.contains(needle) || category.contains(needle);
    final bool amountHit = amountNeedle != null &&
        (transaction.amount == amountNeedle ||
            amountWhole.contains(digits) ||
            amountText.contains(digits));
    return textHit || amountHit;
  }).toList(growable: false);
}

String _fallbackCategoryName(String? id) => id == 'food' ? 'Food & Dining' : '';

TransactionModel _tx({
  required String id,
  String name = 'Coffee',
  String? description,
  double amount = 250,
  DateTime? time,
  TransactionType type = TransactionType.expense,
  String accountId = 'cash',
  String? toAccountId,
  String? categoryId = 'food',
}) {
  return TransactionModel(
    id: id,
    name: name,
    amount: amount,
    time: time ?? DateTime(2026, 11, 7, 10),
    type: type,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    description: description,
  );
}

void main() {
  final List<TransactionModel> ledger = <TransactionModel>[
    _tx(id: '1', name: 'Filter coffee', amount: 60),
    _tx(id: '2', name: 'Metro card', amount: 450, categoryId: 'transport'),
    _tx(
      id: '3',
      name: 'November salary',
      amount: 75000,
      type: TransactionType.income,
      accountId: 'bank',
      categoryId: 'salary',
    ),
    _tx(
      id: '4',
      name: 'Moved to savings',
      amount: 1000,
      type: TransactionType.transfer,
      accountId: 'bank',
      toAccountId: 'cash',
      categoryId: null,
    ),
    _tx(
      id: '5',
      name: 'Dinner',
      description: 'Anniversary dinner with family',
      amount: 1200,
    ),
  ];

  test('an empty query returns everything', () {
    expect(searchTransactions(ledger, query: '').length, ledger.length);
  });

  test('matches the title, case-insensitively', () {
    expect(
      searchTransactions(ledger, query: 'COFFEE').single.id,
      '1',
    );
  });

  test('matches notes', () {
    expect(
      searchTransactions(ledger, query: 'anniversary').single.id,
      '5',
    );
  });

  test('matches the category name', () {
    expect(
      searchTransactions(ledger, query: 'food').map((TransactionModel t) => t.id),
      containsAll(<String>['1', '5']),
    );
  });

  test('matches an exact amount and a partial amount', () {
    expect(searchTransactions(ledger, query: '450').single.id, '2');
    expect(searchTransactions(ledger, query: '120').single.id, '5');
  });

  test('type filter narrows to income or expense', () {
    expect(
      searchTransactions(ledger, query: '', type: TransactionType.income)
          .single
          .id,
      '3',
    );
    expect(
      searchTransactions(ledger, query: 'moved', type: TransactionType.expense),
      isEmpty,
    );
  });

  test('account filter matches either side of a transfer', () {
    expect(
      searchTransactions(
        ledger,
        query: '',
        accountId: 'cash',
        type: TransactionType.transfer,
      ).single.id,
      '4',
    );
  });

  test('category filter excludes uncategorised rows', () {
    expect(
      searchTransactions(ledger, query: '', categoryId: 'transport').single.id,
      '2',
    );
    expect(searchTransactions(ledger, query: '', categoryId: 'nope'), isEmpty);
  });

  test('query and filters compose', () {
    expect(
      searchTransactions(ledger, query: 'nove', type: TransactionType.income)
          .single
          .id,
      '3',
    );
  });
}
