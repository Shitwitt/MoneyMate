import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/financial_pulse.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/models/models.dart';

import 'support.dart';

void main() {
  test('Pulse spending and coverage omit excluded accounts without changing the ledger', () {
    final data = fixture();
    const excluded = Account(
      id: 'excluded',
      name: 'Outside reporting',
      currency: 'USD',
      excluded: true,
      openingMinor: 9000000,
    );
    final records = [
      expense(data, id: 'salary', type: 'income', amount: 10000),
      expense(data, id: 'coffee', amount: 2000),
      expense(
        data,
        id: 'excluded-income',
        type: 'income',
        amount: 1000000,
        date: DateTime(2026, 1, 10),
      ).copyWith(accountId: excluded.id),
      expense(
        data,
        id: 'excluded-expense',
        amount: 900000,
        date: DateTime(2026, 1, 11),
      ).copyWith(accountId: excluded.id),
    ];
    final ledger = Ledger(
      data.copyWith(
        accounts: [...data.accounts, excluded],
        transactions: records,
      ),
      const AppSettings(),
    );
    final pulse = FinancialPulse.fromLedger(ledger, DateTime(2026, 1, 20));
    expect(pulse.metrics.firstWhere((m) => m.label == 'Spending').value, 80);
    expect(
      pulse.metrics.firstWhere((m) => m.label == 'Record coverage').value,
      closeTo(100 / 28, .000001),
    );
    expect(ledger.data.transactions, hasLength(4));
  });
  test(
    'Record coverage uses 28 calendar days across the spring DST boundary',
    () {
      final data = fixture();
      final entries = [
        expense(data, id: 'outside', date: DateTime(2026, 2, 28, 12)),
        expense(data, id: 'first-day', date: DateTime(2026, 3, 1, 12)),
        expense(data, id: 'after-clock-change', date: DateTime(2026, 3, 9, 12)),
      ];
      final pulse = FinancialPulse.fromLedger(
        Ledger(data.copyWith(transactions: entries), const AppSettings()),
        DateTime(2026, 3, 28, 18),
      );
      expect(
        pulse.metrics.firstWhere((m) => m.label == 'Record coverage').value,
        closeTo(2 / 28 * 100, .000001),
      );
    },
  );
}
