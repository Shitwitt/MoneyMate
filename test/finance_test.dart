import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/currency_rebase.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/data/validation.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/utils/dates.dart';
import 'package:paisaclone/core/utils/money.dart';
import 'support.dart';

void main() {
  group('Money and reference conversion', () {
    test('Fixed-point amounts respect ISO minor units', () {
      expect(toMinor(10.235, 'USD'), 1024);
      expect(toMinor(100.7, 'JPY'), 101);
      expect(toMinor(1.2345, 'KWD'), 1235);
      expect(fromMinor(12345, 'INR'), 123.45);
      expect(() => toMinor(double.infinity, 'USD'), throwsFormatException);
    });
    test('Calculator only accepts finite positive arithmetic', () {
      expect(evaluateAmount('(120 + 80) × 10%'), 20);
      expect(evaluateAmount('120 + 45 / 2'), 142.5);
      for (final input in [
        '1/0',
        '0',
        '-1',
        'sin(1)',
        'import(1)',
        '1..2',
        '',
      ]) {
        expect(() => evaluateAmount(input), throwsA(anything));
      }
    });
    test('Indian grouping and hidden values', () {
      expect(money(123456789, 'INR', indian: true), contains('12,34,567.89'));
      expect(money(100, 'USD', hidden: true), '••••');
    });
    test('Missing rates fail instead of inventing a rate', () {
      final data = fixture();
      expect(convertMinor(10000, 'USD', 'JPY', data.rates), 15000);
      expect(
        () => convertMinor(100, 'USD', 'XYZ', data.rates),
        throwsFormatException,
      );
    });
  });
  group('Atomic repository and isolated profiles', () {
    test('Concurrent writes serialize without lost transactions', () async {
      final data = fixture();
      final repo = MemoryRepository(appFor(data));
      final controller = AppController(repo);
      addTearDown(controller.dispose);
      await Future.wait([
        for (var i = 0; i < 20; i++)
          controller.saveTransaction(expense(data, id: '$i', amount: 100)),
      ]);
      final profile = controller.snapshot.profiles.first;
      expect(profile.transactions.length, 20);
      expect(
        Ledger(
          profile,
          const AppSettings(),
        ).accountBalance(data.accounts.first.id),
        98000,
      );
      expect(repo.persisted!.profiles.first.transactions.length, 20);
    });
    test('A failed save leaves state unchanged and queue recovers', () async {
      final data = fixture();
      final repo = MemoryRepository(appFor(data));
      final controller = AppController(repo);
      addTearDown(controller.dispose);
      repo.failNext = true;
      await expectLater(
        controller.saveTransaction(expense(data)),
        throwsStateError,
      );
      expect(controller.snapshot.profiles.first.transactions, isEmpty);
      await controller.saveTransaction(expense(data, id: 'retry'));
      expect(
        controller.snapshot.profiles.first.transactions.single.id,
        'retry',
      );
    });
    test('One transfer updates both accounts and reverses on delete', () async {
      var data = fixture();
      final source = data.accounts.first;
      const target = Account(id: 'yen', name: 'Travel', currency: 'JPY');
      data = data.copyWith(accounts: [source, target]);
      final controller = AppController(MemoryRepository(appFor(data)));
      addTearDown(controller.dispose);
      final transfer = MoneyTransaction(
        id: 'transfer',
        name: 'Travel fund',
        type: 'transfer',
        amountMinor: 1000,
        accountId: source.id,
        toAccountId: target.id,
        toAmountMinor: 1500,
        date: DateTime(2026, 1, 4),
      );
      await controller.saveTransaction(transfer);
      var ledger = Ledger(
        controller.snapshot.profiles.first,
        const AppSettings(),
      );
      expect(ledger.accountBalance(source.id), 99000);
      expect(ledger.accountBalance(target.id), 1500);
      expect(
        ledger.total('expense', DateWindow(DateTime(2026), DateTime(2027))),
        0,
      );
      await controller.setRate(
        ExchangeRate(code: 'JPY', perUsd: 200, updatedAt: DateTime.now()),
      );
      ledger = Ledger(controller.snapshot.profiles.first, const AppSettings());
      expect(ledger.accountBalance(target.id), 1500);
      await controller.deleteTransactions({'transfer'});
      ledger = Ledger(controller.snapshot.profiles.first, const AppSettings());
      expect(ledger.accountBalance(source.id), 100000);
      expect(ledger.accountBalance(target.id), 0);
    });
    test('Self-transfers cannot commit', () async {
      final data = fixture();
      final controller = AppController(MemoryRepository(appFor(data)));
      addTearDown(controller.dispose);
      await expectLater(
        controller.saveTransaction(
          MoneyTransaction(
            id: 'bad',
            name: 'Invalid',
            type: 'transfer',
            amountMinor: 100,
            accountId: data.accounts.first.id,
            toAccountId: data.accounts.first.id,
            toAmountMinor: 100,
            date: DateTime.now(),
          ),
        ),
        throwsFormatException,
      );
      expect(controller.snapshot.profiles.first.transactions, isEmpty);
    });
    test('Profiles never share ledger records', () async {
      final data = fixture();
      final controller = AppController(MemoryRepository(appFor(data)));
      addTearDown(controller.dispose);
      await controller.saveTransaction(expense(data));
      await controller.createProfile(
        name: 'Work',
        currency: 'INR',
        accountName: 'Business',
      );
      expect(controller.snapshot.profiles.last.transactions, isEmpty);
      expect(controller.snapshot.profiles.first.transactions.length, 1);
      await controller.switchProfile(data.profile.id);
      expect(controller.snapshot.activeProfileId, data.profile.id);
    });
    test('Free limits are enforced in repository, not only UI', () async {
      final data = fixture();
      final controller = AppController(MemoryRepository(appFor(data)));
      addTearDown(controller.dispose);
      for (var i = 0; i < 3; i++) {
        await controller.upsertBudget(
          Budget(
            id: '$i',
            name: 'Budget $i',
            limitMinor: 10000,
            start: DateTime(2026, 1, 1),
          ),
        );
      }
      await expectLater(
        controller.upsertBudget(
          Budget(
            id: 'four',
            name: 'Fourth',
            limitMinor: 10000,
            start: DateTime(2026, 1, 1),
          ),
        ),
        throwsA(isA<PremiumRequired>()),
      );
      await controller.settings((s) => s.copyWith(isPro: true));
      await controller.upsertBudget(
        Budget(
          id: 'four',
          name: 'Fourth',
          limitMinor: 10000,
          start: DateTime(2026, 1, 1),
        ),
      );
      expect(controller.snapshot.profiles.first.budgets.length, 4);
    });
  });
  group('Calendar, rollover and recurrence', () {
    test('Financial month handles 31st and leap days', () {
      final window = financialMonth(DateTime(2024, 2, 20), 31);
      expect(window.start, DateTime(2024, 1, 31));
      expect(window.end, DateTime(2024, 2, 29));
      expect(window.contains(DateTime(2024, 2, 28, 23, 59)), isTrue);
      expect(window.contains(window.end), isFalse);
    });
    test('Rollover carries signed underspending and overspending', () {
      var data = fixture();
      final budget = Budget(
        id: 'b',
        name: 'Everyday',
        limitMinor: 10000,
        start: DateTime(2026, 1, 1),
        rollover: true,
      );
      data = data.copyWith(
        transactions: [
          expense(data, amount: 12000, date: DateTime(2026, 1, 5)),
          expense(data, id: 'feb', amount: 1500, date: DateTime(2026, 2, 5)),
        ],
      );
      final status = Ledger(
        data,
        const AppSettings(),
      ).budgetStatus(budget, DateTime(2026, 2, 10));
      expect(status.carry, -2000);
      expect(status.limit, 8000);
      expect(status.remaining, 6500);
    });
    test('Monthly recurrence anchors to original day', () {
      final data = fixture();
      final rule = Recurring(
        id: 'r',
        name: 'Rent',
        amountMinor: 10000,
        accountId: data.accounts.first.id,
        categoryId: data.categories.first.id,
        start: DateTime(2026, 1, 31, 9),
        nextDue: DateTime(2026, 1, 31, 9),
      );
      final feb = nextOccurrence(rule, rule.start);
      final march = nextOccurrence(rule, feb);
      expect(feb, DateTime(2026, 2, 28, 9));
      expect(march, DateTime(2026, 3, 31, 9));
    });
    test(
      'Catch-up is idempotent and reminder-only rules do not post',
      () async {
        var data = fixture();
        final rule = Recurring(
          id: 'r',
          name: 'Rent',
          amountMinor: 1000,
          accountId: data.accounts.first.id,
          categoryId: data.categories.first.id,
          start: DateTime(2026, 1, 31),
          nextDue: DateTime(2026, 1, 31),
        );
        data = data.copyWith(
          recurrings: [
            rule,
            rule.copyWith(id: 'remind', autoPost: false),
          ],
        );
        final controller = AppController(MemoryRepository(appFor(data)));
        addTearDown(controller.dispose);
        await controller.processRecurring(clock: DateTime(2026, 3, 31, 12));
        await controller.processRecurring(clock: DateTime(2026, 3, 31, 12));
        expect(controller.snapshot.profiles.first.transactions.length, 3);
        await controller.processRecurring(
          clock: DateTime(2026, 3, 31, 12),
          recordNowId: 'remind',
        );
        expect(controller.snapshot.profiles.first.transactions.length, 4);
      },
    );
  });
  group('Plans, tags and bills', () {
    test('Bill allocation has no rounding leakage', () {
      for (var total = 1; total < 250; total++) {
        final split = splitWeighted(total, [1, 1, 1]);
        expect(split.reduce((a, b) => a + b), total);
        expect(
          split.reduce((a, b) => a > b ? a : b) -
              split.reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(1),
        );
      }
      expect(splitWeighted(100, [2, 1]), [67, 33]);
      expect(() => splitWeighted(100, [0, 0]), throwsFormatException);
    });
    test('Debt repayment and account posting preserve net worth', () async {
      final data = fixture();
      final controller = AppController(MemoryRepository(appFor(data)));
      addTearDown(controller.dispose);
      final loan = Loan(
        id: 'l',
        personName: 'Alex',
        principalMinor: 10000,
        due: DateTime(2026, 5, 1),
      );
      await controller.upsertLoan(
        loan,
        disburseAccountId: data.accounts.first.id,
      );
      final before = Ledger(
        controller.snapshot.profiles.first,
        const AppSettings(),
      ).netWorth;
      await controller.repayLoan(
        'l',
        2500,
        'Partial',
        accountId: data.accounts.first.id,
      );
      final after = Ledger(
        controller.snapshot.profiles.first,
        const AppSettings(),
      );
      expect(after.netWorth, before);
      expect(after.loanRemaining(after.data.loans.single), 7500);
      await expectLater(
        controller.repayLoan('l', 8000, 'Too much'),
        throwsFormatException,
      );
    });
    test('Currency rebase converts plans, not native ledger amounts', () {
      var data = fixture();
      data = data.copyWith(
        transactions: [expense(data)],
        budgets: [
          Budget(
            id: 'b',
            name: 'Food',
            limitMinor: 10000,
            start: DateTime(2026),
          ),
        ],
        bills: [
          Bill(
            id: 'bill',
            title: 'Dinner',
            totalMinor: 100,
            date: DateTime(2026),
            paidById: 'me',
            paidByName: 'You',
            shares: const [
              BillShare(personId: 'me', name: 'You', amountMinor: 34),
              BillShare(personId: 'a', name: 'A', amountMinor: 33),
              BillShare(personId: 'b', name: 'B', amountMinor: 33),
            ],
          ),
        ],
      );
      final rebased = rebaseProfile(data, 'JPY');
      validateProfile(rebased);
      expect(rebased.transactions.single.amountMinor, 1250);
      expect(rebased.accounts.first.currency, 'USD');
      expect(rebased.budgets.single.limitMinor, 15000);
      expect(
        rebased.bills.single.shares.fold<int>(
          0,
          (sum, share) => sum + share.amountMinor,
        ),
        rebased.bills.single.totalMinor,
      );
    });
    test('Combined filters match tags, type, account and amount', () {
      var data = fixture();
      const label = NamedEntity(id: 'tag', name: 'Work', kind: 'label');
      data = data.copyWith(
        entities: [label],
        transactions: [
          expense(data, amount: 2000).copyWith(labelIds: ['tag']),
          expense(data, id: 'second', amount: 500),
        ],
      );
      final filter = TransactionFilter(
        labels: {'tag'},
        accounts: {data.accounts.first.id},
        minMinor: 1000,
        maxMinor: 2500,
        query: 'work',
        type: 'expense',
      );
      expect(
        filter.apply(Ledger(data, const AppSettings())).single.id,
        'expense',
      );
    });
  });
}
