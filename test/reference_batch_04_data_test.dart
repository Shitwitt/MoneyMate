import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/catalog_insights.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/spending_review.dart';
import 'package:paisaclone/core/data/analytics.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/utils/dates.dart';
import 'package:paisaclone/shared/analytics_chart.dart';

import 'support.dart';

void main() {
  final now = DateTime(2026, 11, 6, 18);
  test(
    'Category subtree is ID-based, cycle-bounded and does not double count',
    () {
      final base = fixture(), account = base.accounts.first;
      const categories = [
        Category(id: 'root', name: 'Food', type: 'expense'),
        Category(
          id: 'child',
          name: 'Coffee',
          type: 'expense',
          parentId: 'root',
        ),
        Category(
          id: 'deep',
          name: 'Coffee',
          type: 'expense',
          parentId: 'child',
        ),
        Category(id: 'other', name: 'Food', type: 'expense'),
      ];
      MoneyTransaction record(
        String id,
        String category,
        int amount, {
        String? a,
        DateTime? date,
      }) => MoneyTransaction(
        id: id,
        name: id,
        type: 'expense',
        amountMinor: amount,
        accountId: a ?? account.id,
        categoryId: category,
        date: date ?? now,
      );
      final data = base.copyWith(
        categories: categories,
        accounts: [
          account,
          account.copyWith(id: 'excluded', excluded: true),
        ],
        transactions: [
          record('root', 'root', 100),
          record('child', 'child', 200),
          record('deep', 'deep', 300),
          record('other', 'other', 400),
          record('excluded', 'root', 999, a: 'excluded'),
          record('future', 'root', 999, date: DateTime(2027)),
        ],
      );
      final ledger = Ledger(data, const AppSettings());
      expect(categorySubtree(data, 'root'), {'root', 'child', 'deep'});
      expect(categoryPath(data, 'deep'), 'Food › Coffee › Coffee');
      final activity = CategoryActivity(ledger, categories.first, now);
      expect(activity.total(true), 600);
      expect(activity.entries.length, 3);
      expect(activity.breakdown.values.reduce((a, b) => a + b), 600);
      expect(
        CategoryActivity(
          ledger,
          categories.first,
          now,
          only: 'child',
        ).total(true),
        200,
      );
      expect(activity.buckets(activity.months).last, 600);
      expect(activity.buckets(activity.weeks).last, 600);
      expect(activity.average(true), 200);
      expect(activity.largest(true), 300);
      final cycle = data.copyWith(
        categories: const [
          Category(id: 'a', name: 'A', type: 'expense', parentId: 'b'),
          Category(id: 'b', name: 'B', type: 'expense', parentId: 'a'),
        ],
      );
      expect(categorySubtree(cycle, 'a'), {'a', 'b'});
    },
  );
  test(
    'People and places use exact local links, signed net and transfer zero',
    () {
      final base = fixture(), account = base.accounts.first;
      final records = [
        expense(
          base,
          amount: 200,
        ).copyWith(personIds: ['one', 'two'], placeId: 'shop'),
        expense(
          base,
          id: 'income',
          type: 'income',
          amount: 500,
        ).copyWith(personIds: ['one'], placeId: 'shop'),
        MoneyTransaction(
          id: 'transfer',
          name: 'Move',
          type: 'transfer',
          amountMinor: 999,
          accountId: account.id,
          toAccountId: 'two',
          toAmountMinor: 999,
          date: now,
          personIds: const ['one'],
        ),
      ];
      final ledger = Ledger(
        base.copyWith(
          accounts: [
            account,
            account.copyWith(id: 'two'),
          ],
          transactions: records,
        ),
        const AppSettings(),
      );
      const one = NamedEntity(id: 'one', name: 'A', kind: 'person'),
          two = NamedEntity(id: 'two', name: 'B', kind: 'person'),
          shop = NamedEntity(id: 'shop', name: 'Shop', kind: 'place');
      expect(
        transactionNet(ledger, records.where((e) => entityMatches(one, e))),
        300,
      );
      expect(
        transactionNet(ledger, records.where((e) => entityMatches(two, e))),
        -200,
      );
      expect(
        transactionNet(ledger, records.where((e) => entityMatches(shop, e))),
        300,
      );
    },
  );
  test('Chart bin centers map to the actual bar, including 18-point and tiny charts', () {
    for (final n in [1, 7, 18]) {
      for (var i = 0; i < n; i++) {
        const width = 326.0;
        final x = 42 + (i + .5) / n * (width - 48);
        expect(chartPointIndex(x, width, n, bars: true), i);
      }
    }
    expect(chartPointIndex(-30, 326, 7, bars: true), 0);
    expect(chartPointIndex(500, 326, 7, bars: true), 6);
    expect(chartPointIndex(42, 326, 6), 0);
    expect(chartPointIndex(320, 326, 6), 5);
    expect(chartPointIndex(5, 8, 1), 0);
  });
  test('Review leaves absent baselines, scores and streaks unavailable', () {
    final review = SpendingReview(Ledger(fixture(), const AppSettings()), now);
    expect(review.yearEndSurplus, isNull);
    expect(review.monthlySurplusMean, isNull);
    expect(review.streak, isNull);
    expect(review.pulse.score, isNull);
    expect(review.candidates, isEmpty);
    expect(review.challenge, isNull);
  });
  test('Signed recorded-surplus estimate excludes opening, future, transfers and excluded accounts', () {
    final base = fixture(), account = base.accounts.first;
    final history = [
      expense(base, id: 'sep', amount: 1000, date: DateTime(2026, 9, 10)),
      expense(base, id: 'oct', amount: 1050, date: DateTime(2026, 10, 10)),
    ];
    final data = base.copyWith(
      accounts: [
        account.copyWith(openingMinor: 99999999),
        account.copyWith(id: 'excluded', excluded: true),
        account.copyWith(id: 'other'),
      ],
      transactions: [
        ...history,
        expense(
          base,
          id: 'future',
          amount: 999999,
          date: DateTime(2026, 11, 7),
        ),
        expense(
          base,
          id: 'excluded',
          amount: 999999,
          date: DateTime(2026, 11, 1),
        ).copyWith(accountId: 'excluded'),
        MoneyTransaction(
          id: 'move',
          name: 'Move',
          type: 'transfer',
          amountMinor: 999999,
          accountId: account.id,
          toAccountId: 'other',
          toAmountMinor: 999999,
          date: DateTime(2026, 11, 1),
        ),
      ],
    );
    final review = SpendingReview(Ledger(data, const AppSettings()), now);
    expect(review.monthlySurplusMean, (-2050 / 6).round());
    final remaining = calendarDaysBetween(now, DateTime(2027)) - 1;
    expect(
      review.yearEndSurplus,
      -2050 + (-2050 / review.baselineDays * remaining).round(),
    );
    expect(review.yearEndSurplus, isNegative);
    expect(review.monthlySurplus.reduce((a, b) => a + b), -2050);
  });
  test('Expense-record streak requires consecutive logged dates and positive unrounded baseline', () {
    final base = fixture();
    final baseline = expense(
      base,
      id: 'baseline',
      amount: 18400,
      date: DateTime(2026, 5, 1),
    );
    final days = [
      for (var day = 4; day <= 6; day++)
        expense(base, id: 'day$day', amount: 50, date: DateTime(2026, 11, day)),
    ];
    SpendingReview review(List<MoneyTransaction> entries) => SpendingReview(
      Ledger(
        base.copyWith(transactions: [baseline, ...entries]),
        const AppSettings(),
      ),
      now,
    );
    expect(review(days).baselineDailyExpense, 100);
    expect(review(days).streak, (3, 3));
    expect(review([days.first, days.last]).streak, (1, 1));
    expect(review(days.take(2).toList()).streak, (0, 2));
  });
  test('Monthly repeat candidates are current, consecutive, unique and explicitly not saved rules', () {
    final base = fixture(), account = base.accounts.first;
    final entries = [
      expense(
        base,
        id: 'sep',
        amount: 1000,
        date: DateTime(2026, 9, 10),
      ).copyWith(name: 'Reading Club'),
      expense(
        base,
        id: 'oct',
        amount: 1050,
        date: DateTime(2026, 10, 10),
      ).copyWith(name: ' reading   club '),
    ];
    SpendingReview review(ProfileData data) =>
        SpendingReview(Ledger(data, const AppSettings(monthStart: 10)), now);
    final data = base.copyWith(transactions: entries);
    final candidate = review(data).candidates.single;
    expect(candidate.nativeMinor, 1025);
    expect(candidate.baseMinor, 1025);
    expect(candidate.months, 2);
    expect(candidate.next, DateTime(2026, 11, 10));
    expect(review(data).possibleDailyCost, (1025 * 12 / 365).round());
    expect(
      review(
        data.copyWith(
          transactions: [
            ...entries,
            entries.last.copyWith(id: 'duplicate'),
          ],
        ),
      ).candidates,
      isEmpty,
    );
    expect(
      review(
        data.copyWith(
          transactions: [
            entries.first.copyWith(date: DateTime(2026, 8, 10)),
            entries.last,
          ],
        ),
      ).candidates,
      isEmpty,
    );
    expect(
      review(
        data.copyWith(
          transactions: [
            entries.first,
            entries.last.copyWith(amountMinor: 5000),
          ],
        ),
      ).candidates,
      isEmpty,
    );
    expect(
      review(data.copyWith(accounts: [account.copyWith(archived: true)]))
          .candidates,
      isEmpty,
    );
    expect(
      review(
        data.copyWith(
          recurrings: [
            Recurring(
              id: 'known',
              name: 'Reading Club',
              amountMinor: 1000,
              accountId: account.id,
              categoryId: entries.first.categoryId,
              start: DateTime(2026, 9, 10),
              nextDue: DateTime(2026, 11, 10),
              archived: true,
            ),
          ],
        ),
      ).candidates,
      isEmpty,
    );
  });
  test('Drilldown copies preserve every scope and normalized exact names', () {
    final base = fixture(),
        source = expense(
          base,
          id: 'match',
          date: DateTime(2026, 11, 5),
        ).copyWith(name: ' Reading   Club ');
    final outside = base.accounts.first.copyWith(id: 'outside', excluded: true);
    final ledger = Ledger(
      base.copyWith(
        accounts: [...base.accounts, outside],
        transactions: [
          source,
          source.copyWith(id: 'not-exact', name: 'Reading Club Store'),
          source.copyWith(id: 'excluded', accountId: 'outside'),
          source.copyWith(id: 'future', date: DateTime(2027)),
        ],
      ),
      const AppSettings(),
    );
    final filter = TransactionFilter(
      exactName: 'reading club',
      postedOnly: true,
      includedOnly: true,
      cashFlowOnly: true,
      weekday: source.date.toLocal().weekday % 7,
    );
    expect(
      filter
          .withDates(DateWindow(DateTime(2026, 11), DateTime(2026, 12)))
          .apply(ledger, now: now)
          .map((e) => e.id),
      ['match'],
    );
    final copied = filter.withDates(null);
    expect(copied.exactName, filter.exactName);
    expect(copied.postedOnly, isTrue);
    expect(copied.includedOnly, isTrue);
    expect(copied.cashFlowOnly, isTrue);
    expect(copied.weekday, filter.weekday);
    expect(copied.active, isTrue);
  });
  test('UTC transaction instants use local calendar weekdays and seven-day buckets', () {
    final base = fixture();
    final instant = DateTime.parse('2026-11-01T02:30:00Z'),
        local = DateTime.parse('2026-11-01T02:30:00Z').toLocal();
    final now = local.add(const Duration(hours: 1));
    final ledger = Ledger(
      base.copyWith(transactions: [expense(base, amount: 123, date: instant)]),
      const AppSettings(),
    );
    final analytics = AnalyticsSnapshot(ledger, now);
    expect(analytics.weekdays[local.weekday % 7], 123);
    expect(analytics.lastSeven.reduce((a, b) => a + b), 123);
    expect(
      TransactionFilter(weekday: local.weekday % 7).apply(ledger).length,
      1,
    );
  });
  test('Repayment cutoffs honor an explicit snapshot clock', () {
    final data = fixture();
    final loan = Loan(
      id: 'later-repayment',
      personName: 'Borrowed',
      direction: 'borrowed',
      principalMinor: 1000,
      due: DateTime(2026, 12),
      repayments: [
        MoneyEvent(id: 'paid', amountMinor: 1000, date: DateTime(2026, 11, 5)),
      ],
    );
    final ledger = Ledger(data.copyWith(loans: [loan]), const AppSettings());
    expect(ledger.loanRemaining(loan, now: DateTime(2026, 11, 2)), 1000);
    expect(ledger.loanRemaining(loan, now: DateTime(2026, 11, 6)), 0);
  });
}
