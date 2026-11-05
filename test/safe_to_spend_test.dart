import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/models/models.dart';

import 'support.dart';

void main() {
  final now = DateTime(2026, 1, 15);
  test('Safe to spend is not investment-inclusive net worth', () {
    final data = fixture();
    final profile = data.copyWith(
      accounts: [
        ...data.accounts,
        const Account(
          id: 'savings',
          name: 'Protected',
          currency: 'USD',
          type: 'savings',
          openingMinor: 50000,
        ),
        const Account(
          id: 'investment',
          name: 'Future',
          currency: 'USD',
          type: 'investment',
          openingMinor: 250000,
        ),
        const Account(
          id: 'excluded',
          name: 'Excluded',
          currency: 'USD',
          excluded: true,
          openingMinor: 90000,
        ),
        const Account(
          id: 'archived',
          name: 'Archived',
          currency: 'USD',
          archived: true,
          openingMinor: 20000,
        ),
        const Account(
          id: 'credit',
          name: 'Card debt',
          currency: 'USD',
          type: 'credit card',
          openingMinor: -20000,
        ),
      ],
    );
    final ledger = Ledger(profile, const AppSettings());
    expect(ledger.safeToSpend(now).available, 80000);
    expect(ledger.netWorth, isNot(80000));
  });
  test('Future income is not available today', () {
    final data = fixture();
    final ledger = Ledger(
      data.copyWith(
        transactions: [
          expense(
            data,
            type: 'income',
            date: DateTime(2026, 1, 16),
            amount: 50000,
          ),
        ],
      ),
      const AppSettings(),
    );
    expect(ledger.safeToSpend(now).available, 100000);
  });
  test('Recorded future expenses are reserved', () {
    final data = fixture();
    final summary = Ledger(
      data.copyWith(
        transactions: [
          expense(data, date: DateTime(2026, 1, 16), amount: 1200),
        ],
      ),
      const AppSettings(),
    ).safeToSpend(now);
    expect(summary.balance, 100000);
    expect(summary.upcoming, 1200);
    expect(summary.available, 98800);
  });
  test('All weekly occurrences through period end are reserved', () {
    final data = fixture();
    final rule = Recurring(
      id: 'weekly',
      name: 'Weekly',
      amountMinor: 1000,
      accountId: data.accounts.first.id,
      categoryId: data.categories.first.id,
      start: DateTime(2026, 1, 16),
      nextDue: DateTime(2026, 1, 16),
      frequency: 'weekly',
    );
    final summary = Ledger(
      data.copyWith(recurrings: [rule]),
      const AppSettings(),
    ).safeToSpend(now);
    expect(summary.upcoming, 3000);
    expect(summary.available, 97000);
    final custom = Ledger(
      data.copyWith(recurrings: [rule]),
      const AppSettings(monthStart: 20),
    ).safeToSpend(now);
    expect(custom.end, DateTime(2026, 1, 20));
    expect(custom.upcoming, 1000);
  });
  test('Disabled and income rules never reserve outgoing money', () {
    final data = fixture();
    final rule = Recurring(
      id: 'weekly',
      name: 'Weekly',
      amountMinor: 1000,
      accountId: data.accounts.first.id,
      categoryId: data.categories.first.id,
      start: DateTime(2026, 1, 16),
      nextDue: DateTime(2026, 1, 16),
    );
    expect(
      Ledger(
        data.copyWith(
          recurrings: [
            rule.copyWith(enabled: false),
            rule.copyWith(id: 'income', type: 'income'),
          ],
        ),
        const AppSettings(),
      ).safeToSpend(now).reserved,
      0,
    );
  });
  test('Manual goal allocations and due loan balances are protected', () {
    final data = fixture();
    final goal = Goal(
      id: 'goal',
      name: 'A new start',
      targetMinor: 10000,
      deadline: DateTime(2027),
      contributions: [
        MoneyEvent(id: 'c', amountMinor: 2000, date: DateTime(2026, 1, 10)),
      ],
    );
    final loan = Loan(
      id: 'loan',
      personName: 'Friend',
      principalMinor: 5000,
      interestPercent: 10,
      direction: 'borrowed',
      due: DateTime(2026, 1, 20),
      repayments: [
        MoneyEvent(id: 'r', amountMinor: 1000, date: DateTime(2026, 1, 10)),
      ],
    );
    final summary = Ledger(
      data.copyWith(goals: [goal], loans: [loan]),
      const AppSettings(),
    ).safeToSpend(now);
    expect(summary.goals, 2000);
    expect(summary.loans, 4500);
    expect(summary.available, 93500);
  });
  test('Linked savings goals are not reserved twice', () {
    final data = fixture();
    final profile = data.copyWith(
      accounts: [
        ...data.accounts,
        const Account(
          id: 'saved',
          name: 'Saved',
          currency: 'USD',
          type: 'savings',
          openingMinor: 30000,
        ),
      ],
      goals: [
        Goal(
          id: 'linked',
          name: 'Trip',
          targetMinor: 40000,
          deadline: DateTime(2027),
          accountId: 'saved',
        ),
      ],
    );
    final summary = Ledger(profile, const AppSettings()).safeToSpend(now);
    expect(summary.goals, 0);
    expect(summary.available, 100000);
  });
  test('Transfers between spendable accounts do not inflate reservations', () {
    final data = fixture();
    final cash = Account(
      id: 'cash',
      name: 'Cash',
      currency: 'USD',
      type: 'cash',
    );
    final transfer = MoneyTransaction(
      id: 'transfer',
      name: 'Pocket money',
      type: 'transfer',
      amountMinor: 10000,
      accountId: data.accounts.first.id,
      toAccountId: 'cash',
      toAmountMinor: 10000,
      date: DateTime(2026, 1, 16),
    );
    final summary = Ledger(
      data.copyWith(
        accounts: [...data.accounts, cash],
        transactions: [transfer],
      ),
      const AppSettings(),
    ).safeToSpend(now);
    expect(summary.upcoming, 0);
    expect(summary.available, 100000);
  });
  test(
    'An exceptionally old recurring schedule cannot overstate availability',
    () {
      final data = fixture();
      final rule = Recurring(
        id: 'ancient',
        name: 'Old daily',
        amountMinor: 1,
        accountId: data.accounts.first.id,
        categoryId: data.categories.first.id,
        start: DateTime(2020),
        nextDue: DateTime(2020),
        frequency: 'daily',
      );
      final summary = Ledger(
        data.copyWith(recurrings: [rule]),
        const AppSettings(),
      ).safeToSpend(now);
      expect(summary.complete, false);
      expect(summary.available, 0);
    },
  );
  test('Legacy default migrates, custom settings and backup schema remain', () {
    final old = AppSettings.fromJson({
      'accent': 0xff557c36,
      'dynamicColors': true,
    });
    expect(old.accent, 0xffffb59a);
    expect(old.dynamicColors, false);
    final custom = AppSettings.fromJson({
      'accent': 0xff2E90FA,
      'dynamicColors': true,
    });
    expect(custom.accent, 0xff2E90FA);
    expect(custom.dynamicColors, true);
  });
}
