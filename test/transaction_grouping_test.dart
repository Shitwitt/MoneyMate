import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/constants/currencies.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/core/utils/currency_formatter.dart';
import 'package:moneymate/data/models/transaction_model.dart';
import 'package:moneymate/screens/home/home_screen.dart';

TransactionModel _tx({
  required String id,
  required double amount,
  required DateTime time,
  TransactionType type = TransactionType.expense,
  String? categoryId = 'seed-category-food',
}) {
  return TransactionModel(
    id: id,
    name: 'Entry $id',
    amount: amount,
    time: time,
    type: type,
    accountId: 'acct',
    categoryId: type == TransactionType.transfer ? null : categoryId,
  );
}

void main() {
  final CurrencyFormatter formatter = CurrencyFormatter(
    currency: CurrencyTable.inr,
  );

  group('groupTransactionsByDay', () {
    test('buckets by calendar day, newest day first', () {
      final DateTime now = DateTime(2026, 11, 7, 21, 30);
      final List<TransactionDayGroup> groups = groupTransactionsByDay(
        <TransactionModel>[
          _tx(id: 'a', amount: 500, time: DateTime(2026, 11, 7, 9)),
          _tx(id: 'b', amount: 200, time: DateTime(2026, 11, 6, 10)),
          _tx(id: 'c', amount: 100, time: DateTime(2026, 10, 30, 10)),
        ],
        formatter: formatter,
        now: now,
      );

      expect(groups.length, 3);
      expect(groups[0].label, 'Today');
      expect(groups[1].label, 'Yesterday');
      expect(groups[2].label, '30 Oct 2026');
    });

    test('sorts entries inside a day newest first', () {
      final List<TransactionDayGroup> groups = groupTransactionsByDay(
        <TransactionModel>[
          _tx(id: 'early', amount: 10, time: DateTime(2026, 11, 7, 8)),
          _tx(id: 'late', amount: 20, time: DateTime(2026, 11, 7, 20)),
        ],
        formatter: formatter,
        now: DateTime(2026, 11, 7, 22),
      );

      expect(groups.single.transactions.first.id, 'late');
      expect(groups.single.transactions.last.id, 'early');
    });

    test('day net is income minus expense and ignores transfers', () {
      final List<TransactionDayGroup> groups = groupTransactionsByDay(
        <TransactionModel>[
          _tx(
            id: 'in',
            amount: 2000,
            time: DateTime(2026, 11, 7, 9),
            type: TransactionType.income,
            categoryId: 'seed-category-salary',
          ),
          _tx(id: 'out', amount: 500, time: DateTime(2026, 11, 7, 10)),
          _tx(
            id: 'move',
            amount: 999,
            time: DateTime(2026, 11, 7, 11),
            type: TransactionType.transfer,
          ),
        ],
        formatter: formatter,
        now: DateTime(2026, 11, 7, 22),
      );

      expect(groups.single.net, 1500);
    });

    test('an empty ledger produces no groups', () {
      expect(
        groupTransactionsByDay(
          const <TransactionModel>[],
          formatter: formatter,
        ),
        isEmpty,
      );
    });
  });
}
