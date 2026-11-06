import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/analytics.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/data/validation.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/features/catalog/labels_screen.dart';
import 'package:paisaclone/features/transactions/grouped_transactions.dart';

import 'support.dart';

Loan agreement({String direction = 'lent'}) => Loan(
  id: 'loan',
  personName: 'A local agreement',
  principalMinor: 10000,
  due: DateTime(2027, 12, 31),
  direction: direction,
);
ProfileData current(AppController c) => c.snapshot.profiles.first;
Ledger book(AppController c) => Ledger(current(c), c.snapshot.settings);

List<ExchangeRate> euroRate(List<ExchangeRate> rates, double value) => [
  for (final rate in rates)
    rate.code == 'EUR' ? rate.copyWith(perUsd: value) : rate,
];

void main() {
  test('Legacy loans, goals, entities and events migrate without inventing start dates or links', () {
    final loan = Loan.fromJson({
      'id': 'old',
      'personName': 'Old agreement',
      'principalMinor': 10000,
      'due': '2027-01-01',
    });
    expect(loan.start, isNull);
    expect(loan.accountId, isEmpty);
    expect(loan.categoryId, isEmpty);
    expect(loan.completed, isFalse);
    expect(
      Loan.fromJson(
        loan
            .copyWith(
              start: DateTime(2026, 1, 1),
              color: 0xff009688,
              icon: 'bank',
              completed: true,
            )
            .toJson(),
      ).completed,
      isTrue,
    );
    final goal = Goal.fromJson({
      'id': 'goal',
      'name': 'Plan',
      'targetMinor': 10000,
      'deadline': '2027-01-01',
    });
    expect(goal.start, isNull);
    expect(goal.photoBase64, isEmpty);
    expect(Goal.fromJson(goal.toJson()).toJson(), goal.toJson());
    final label = NamedEntity.fromJson({
      'id': 'label',
      'kind': 'label',
      'name': 'Local',
    });
    expect(label.icon, isEmpty);
    expect(
      NamedEntity.fromJson(label.copyWith(icon: 'bank').toJson()).icon,
      'bank',
    );
    expect(
      MoneyEvent.fromJson({
        'id': 'payment',
        'amountMinor': 100,
        'date': '2026-01-01',
      }).transactionId,
      isEmpty,
    );
  });
  for (final direction in ['lent', 'borrowed']) {
    test(
      '$direction partial/full repayment, native entry, auto-completion and retained history',
      () async {
        final c = AppController(MemoryRepository(appFor(fixture())));
        // Use the controller's actual IDs, never a second randomized fixture.
        addTearDown(c.dispose);
        final account = current(c).accounts.first;
        await c.upsertLoan(
          agreement(direction: direction),
          disburseAccountId: account.id,
        );
        expect(
          current(c).transactions.single.type,
          direction == 'lent' ? 'expense' : 'income',
        );
        expect(book(c).loanRemaining(current(c).loans.single), 10000);
        await c.repayLoan('loan', 2500, 'Partial', accountId: account.id);
        final payment = current(c).transactions.last,
            event = current(c).loans.single.repayments.single;
        expect(event.transactionId, payment.id);
        expect(payment.createdAt, isNotNull);
        expect(payment.type, direction == 'lent' ? 'income' : 'expense');
        expect(book(c).loanRemaining(current(c).loans.single), 7500);
        await c.repayLoan('loan', 7500, 'Final');
        expect(book(c).loanRemaining(current(c).loans.single), 0);
        expect(book(c).loanPaid(current(c).loans.single), 10000);
        final before = book(c).accountBalance(account.id);
        await c.deleteLoan('loan');
        expect(current(c).loans, isEmpty);
        expect(current(c).transactions.length, 2);
        expect(current(c).transactions.every((e) => e.loanId.isEmpty), isTrue);
        expect(book(c).accountBalance(account.id), before);
      },
    );
  }
  test(
    'Manual close/reopen is not a fabricated repayment or cash movement',
    () async {
      final c = AppController(MemoryRepository(appFor(fixture())));
      addTearDown(c.dispose);
      await c.upsertLoan(agreement());
      await c.repayLoan('loan', 2000, 'Tracking only');
      await c.setLoanCompleted('loan', true);
      final loan = current(c).loans.single;
      expect(book(c).toReceive, 0);
      expect(book(c).loanPaid(loan), 2000);
      expect(book(c).loanUnpaid(loan), 8000);
      expect(current(c).transactions, isEmpty);
      await expectLater(c.repayLoan('loan', 1000, ''), throwsFormatException);
      await c.setLoanCompleted('loan', false);
      expect(book(c).toReceive, 8000);
    },
  );
  test(
    'Linked repayment edits, unlink and delete update the debt atomically',
    () async {
      final c = AppController(MemoryRepository(appFor(fixture())));
      addTearDown(c.dispose);
      await c.upsertLoan(agreement());
      await c.repayLoan(
        'loan',
        2000,
        '',
        accountId: current(c).accounts.first.id,
      );
      final entry = current(c).transactions.single;
      await c.saveTransaction(
        entry.copyWith(amountMinor: 4000, notes: 'Corrected'),
      );
      expect(book(c).loanPaid(current(c).loans.single), 4000);
      expect(current(c).loans.single.repayments.single.note, 'Corrected');
      await expectLater(
        c.saveTransaction(entry.copyWith(amountMinor: 11000)),
        throwsFormatException,
      );
      expect(current(c).transactions.single.amountMinor, 4000);
      expect(book(c).toReceive, 6000);
      await c.deleteTransactions({entry.id});
      expect(current(c).loans.single.repayments, isEmpty);
      expect(book(c).toReceive, 10000);
      await c.repayLoan(
        'loan',
        1000,
        '',
        accountId: current(c).accounts.first.id,
      );
      await c.saveTransaction(
        current(c).transactions.single.copyWith(loanId: ''),
      );
      expect(current(c).loans.single.repayments, isEmpty);
      expect(current(c).transactions.single.loanId, isEmpty);
    },
  );
  test('Unrelated writes or note edits do not silently revalue an old FX repayment', () async {
    final base = fixture();
    final data = base.copyWith(
      accounts: [
        base.accounts.first,
        const Account(id: 'eur', name: 'Euro book', currency: 'EUR'),
      ],
      rates: euroRate(base.rates, .5),
    );
    final c = AppController(MemoryRepository(appFor(data)));
    addTearDown(c.dispose);
    await c.upsertLoan(agreement());
    await c.repayLoan('loan', 2000, '', accountId: 'eur');
    final entry = current(c).transactions.single;
    expect(entry.amountMinor, 1000);
    await c.updateProfile(
      (p, _) => p.copyWith(rates: euroRate(p.rates, .25)),
    );
    await c.saveTransaction(expense(current(c), id: 'unrelated'));
    expect(book(c).loanPaid(current(c).loans.single), 2000);
    await c.saveTransaction(entry.copyWith(notes: 'A note only'));
    expect(book(c).loanPaid(current(c).loans.single), 2000);
    await c.saveTransaction(entry.copyWith(amountMinor: 500));
    expect(book(c).loanPaid(current(c).loans.single), 2000);
  });
  test('Future-dated repayment is scheduled, not already paid', () async {
    final c = AppController(MemoryRepository(appFor(fixture())));
    addTearDown(c.dispose);
    await c.upsertLoan(agreement());
    await c.repayLoan(
      'loan',
      2000,
      '',
      accountId: current(c).accounts.first.id,
    );
    await c.saveTransaction(
      current(c).transactions.single
          .copyWith(date: DateTime.now().add(const Duration(days: 2))),
    );
    expect(book(c).loanPaid(current(c).loans.single), 0);
    expect(book(c).toReceive, 10000);
  });
  test('Loan-tagged income is not an implicit repayment; editing tracker does not duplicate cash', () async {
    final c = AppController(MemoryRepository(appFor(fixture())));
    addTearDown(c.dispose);
    await c.upsertLoan(
      agreement(),
      disburseAccountId: current(c).accounts.first.id,
    );
    await c.saveTransaction(
      expense(
        current(c),
        id: 'tagged',
        type: 'income',
      ).copyWith(loanId: 'loan'),
    );
    await c.upsertLoan(
      current(c).loans.single.copyWith(principalMinor: 20000),
      disburseAccountId: current(c).accounts.first.id,
    );
    expect(current(c).transactions.length, 2);
    expect(book(c).loanPaid(current(c).loans.single), 0);
    expect(book(c).toReceive, 20000);
  });
  test(
    'Failed repayment persistence publishes neither payment nor account entry',
    () async {
      final repo = MemoryRepository(appFor(fixture()));
      final controller = AppController(repo);
      addTearDown(controller.dispose);
      await controller.upsertLoan(agreement());
      repo.failNext = true;
      await expectLater(
        controller.repayLoan(
          'loan',
          1000,
          '',
          accountId: current(controller).accounts.first.id,
        ),
        throwsStateError,
      );
      expect(current(controller).transactions, isEmpty);
      expect(current(controller).loans.single.repayments, isEmpty);
      await controller.repayLoan('loan', 1000, '');
      expect(book(controller).toReceive, 9000);
    },
  );
  test(
    'Loan/goal date order and dangling or wrong-type preferences are rejected',
    () {
      final data = fixture(), loan = agreement();
      for (final invalid in [
        loan.copyWith(start: DateTime(2028)),
        loan.copyWith(personId: 'missing'),
        loan.copyWith(accountId: 'missing'),
        loan.copyWith(
          categoryId: data.categories.firstWhere((c) => c.type == 'income').id,
        ),
      ]) {
        expect(
          () => validateProfile(data.copyWith(loans: [invalid])),
          throwsFormatException,
        );
      }
      expect(
        () => validateProfile(
          data.copyWith(
            goals: [
              Goal(
                id: 'g',
                name: 'Invalid dates',
                targetMinor: 100,
                deadline: DateTime(2026),
                start: DateTime(2027),
              ),
            ],
          ),
        ),
        throwsFormatException,
      );
    },
  );
  test('Signed linked-goal balance, all transfer sides and manual-only source are preserved', () {
    final data = fixture();
    final goal = Goal(
      id: 'goal',
      name: 'Linked target',
      targetMinor: 10000,
      deadline: DateTime(2027),
      accountId: data.accounts.first.id,
      contributions: [
        MoneyEvent(id: 'allocation', amountMinor: 500, date: DateTime(2026)),
      ],
    );
    final negative = data.copyWith(
      accounts: [data.accounts.first.copyWith(openingMinor: -2500)],
      goals: [goal],
    );
    expect(Ledger(negative, const AppSettings()).goalSaved(goal), -2500);
    expect(
      goal.targetMinor - Ledger(negative, const AppSettings()).goalSaved(goal),
      12500,
    );
    expect(
      Ledger(
        negative,
        const AppSettings(),
      ).goalSaved(goal.copyWith(accountId: '')),
      500,
    );
    final withTransfer = negative.copyWith(
      accounts: [
        ...negative.accounts,
        const Account(id: 'other', name: 'Other', currency: 'USD'),
      ],
      transactions: [
        MoneyTransaction(
          id: 'move',
          name: 'Move',
          type: 'transfer',
          amountMinor: 1000,
          accountId: 'other',
          toAccountId: data.accounts.first.id,
          toAmountMinor: 1000,
          date: DateTime(2026),
        ),
      ],
    );
    expect(Ledger(withTransfer, const AppSettings()).goalSaved(goal), -1500);
  });
  test('Labels are many-to-many; transfers count as records but not net, deletion preserves others', () async {
    final data = fixture();
    final labels = [
      const NamedEntity(id: 'a', name: 'A', kind: 'label'),
      const NamedEntity(id: 'b', name: 'B', kind: 'label'),
    ];
    final c = AppController(
      MemoryRepository(
        appFor(
          data.copyWith(
            entities: labels,
            transactions: [
              expense(
                data,
                id: 'purchase',
                amount: 300,
              ).copyWith(labelIds: ['a', 'b']),
              expense(
                data,
                id: 'salary',
                amount: 1000,
                type: 'income',
              ).copyWith(labelIds: ['a']),
            ],
          ),
        ),
      ),
    );
    addTearDown(c.dispose);
    expect(TransactionFilter(labels: {'a'}).apply(book(c)).length, 2);
    expect(
      labelNet(book(c), TransactionFilter(labels: {'a'}).apply(book(c))),
      700,
    );
    expect(
      labelNet(book(c), TransactionFilter(labels: {'b'}).apply(book(c))),
      -300,
    );
    await c.deleteEntity('a');
    expect(current(c).transactions.length, 2);
    expect(current(c).transactions.first.labelIds, ['b']);
    final transfer = MoneyTransaction(
      id: 'transfer',
      name: 'Transfer',
      type: 'transfer',
      amountMinor: 999,
      accountId: data.accounts.first.id,
      toAccountId: 'other',
      toAmountMinor: 999,
      date: DateTime(2026),
    );
    expect(labelNet(book(c), [transfer]), 0);
  });
  test('Grouping uses calendar boundaries and configured week start without filtering', () {
    final date = DateTime(2026, 11, 1, 23, 59);
    expect(transactionGroup(date, 0, 1), DateTime(2026, 11, 1));
    expect(transactionGroup(date, 1, 1), DateTime(2026, 10, 26));
    expect(transactionGroup(date, 1, 7), DateTime(2026, 11, 1));
    expect(transactionGroup(date, 2, 1), DateTime(2026, 11));
    expect(transactionGroup(date, 3, 1), DateTime(2026));
  });
  test('Analytics excludes future, excluded accounts, transfers and income; saved FX is honored', () {
    final data = fixture(), now = DateTime(2026, 11, 6, 12);
    final entries = [
      expense(data, id: 'now', amount: 600, date: DateTime(2026, 11, 3)),
      expense(data, id: 'future', amount: 10000, date: DateTime(2026, 11, 7)),
      expense(data, id: 'income', amount: 100000, type: 'income', date: now),
      expense(
        data,
        id: 'hidden',
        amount: 50000,
        date: now,
      ).copyWith(accountId: 'excluded'),
      expense(
        data,
        id: 'euro',
        amount: 1000,
        date: now,
      ).copyWith(accountId: 'eur'),
    ];
    final ledger = Ledger(
      data.copyWith(
        accounts: [
          data.accounts.first,
          const Account(
            id: 'excluded',
            name: 'Excluded',
            currency: 'USD',
            excluded: true,
          ),
          const Account(id: 'eur', name: 'Euro', currency: 'EUR'),
        ],
        rates: euroRate(data.rates, .5),
        transactions: entries,
      ),
      const AppSettings(),
    );
    final snapshot = AnalyticsSnapshot(ledger, now);
    expect(snapshot.spending, 2600);
    expect(snapshot.total, 2600);
    expect(snapshot.history.length, 2);
    expect(snapshot.elapsed, 6);
    expect(snapshot.remaining, 24);
    expect(snapshot.weeklyBurn, (2600 / 6 * 7).round());
    expect(snapshot.projected, 13000);
    expect(snapshot.lastSeven.reduce((a, b) => a + b), 2600);
    expect(snapshot.change, isNull);
    expect(snapshot.average, isNull);
    expect(snapshot.predicted, 13000);
  });
  test('Analytics average is six completed months, forecast is floored, latest chart point is partial', () {
    final data = fixture(), now = DateTime(2026, 11, 6, 12);
    final ledger = Ledger(
      data.copyWith(
        transactions: [
          expense(data, id: 'old', amount: 6000, date: DateTime(2026, 10, 4)),
          expense(
            data,
            id: 'current',
            amount: 600,
            date: DateTime(2026, 11, 4),
          ),
        ],
      ),
      const AppSettings(),
    );
    final snapshot = AnalyticsSnapshot(ledger, now);
    expect(snapshot.average, 1000);
    expect(snapshot.predicted, 2000);
    expect(snapshot.monthly, [0, 0, 0, 0, 6000, 600]);
    expect(snapshot.change, -90);
    expect(snapshot.baselineMonths.last.start, DateTime(2026, 10));
    expect(snapshot.months.last.start, DateTime(2026, 11));
    final end = AnalyticsSnapshot(ledger, DateTime(2026, 11, 30, 23));
    expect(end.elapsed, 30);
    expect(end.remaining, 0);
    expect(end.predicted, greaterThanOrEqualTo(end.spending));
  });
  test('Analytics renewal-day and DST day counts are calendar based', () {
    final data = fixture(),
        ledger = Ledger(data, const AppSettings(monthStart: 20));
    final s = AnalyticsSnapshot(ledger, DateTime(2026, 11, 6));
    expect(s.current.start, DateTime(2026, 10, 20));
    expect(s.elapsed, 18);
    expect(s.current.days, 31);
    expect(s.remaining, 13);
    final dst = AnalyticsSnapshot(
      Ledger(data, const AppSettings()),
      DateTime(2026, 3, 9),
    );
    expect(dst.elapsed, 9);
    expect(dst.remaining, 22);
  });
  test('Undefined comparisons, empty weekday extremes and sparse outliers stay unavailable', () {
    final s = AnalyticsSnapshot(
      Ledger(fixture(), const AppSettings()),
      DateTime(2026, 11, 6),
    );
    expect(percentageChange(100, 0), isNull);
    expect(percentageChange(0, 0), isNull);
    expect(s.peakWeekday, isNull);
    expect(s.lowestWeekday, isNull);
    expect(s.unusual, isEmpty);
    expect(s.velocityStatus, 'No baseline');
    final data = fixture(),
        ledger = Ledger(
          data.copyWith(
            transactions: [
              for (var i = 0; i < 3; i++)
                expense(
                  data,
                  id: '$i',
                  amount: i == 2 ? 100000 : 100,
                  date: DateTime(2026, 10, i + 1),
                ),
            ],
          ),
          const AppSettings(),
        );
    expect(AnalyticsSnapshot(ledger, DateTime(2026, 11, 6)).unusual, isEmpty);
  });
  test('Outliers use per-category interpolated quartiles and weekdays use actual expense dates', () {
    final data = fixture(),
        ledger = Ledger(
          data.copyWith(
            transactions: [
              for (var i = 0; i < 4; i++)
                expense(
                  data,
                  id: '$i',
                  amount: i == 3 ? 10000 : 100,
                  date: DateTime(2026, 11, i + 1),
                ),
            ],
          ),
          const AppSettings(),
        );
    final s = AnalyticsSnapshot(ledger, DateTime(2026, 11, 6));
    expect(quantile([100, 100, 100, 10000], .75), 2575);
    expect(s.unusual.map((e) => e.id), ['3']);
    expect(s.weekdays, [100, 100, 100, 10000, 0, 0, 0]);
    expect(s.peakWeekday, 3);
    expect(s.lowestWeekday, 4);
  });
}
