import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/reporting.dart';
import 'package:paisaclone/core/data/validation.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/utils/dates.dart';

import 'support.dart';

Budget plan({
  String period = 'monthly',
  String mode = 'automatic',
  String type = 'expense',
  List<String> categories = const [],
  bool exclude = false,
  bool children = true,
  bool rollover = false,
  DateTime? start,
  DateTime? end,
}) => Budget(
  id: 'plan',
  name: 'Local plan',
  limitMinor: 1000,
  period: period,
  start: start ?? DateTime(2026, 1, 1),
  end: end,
  categoryIds: categories,
  mode: mode,
  transactionType: type,
  excludeCategories: exclude,
  includeSubcategories: children,
  rollover: rollover,
);
MoneyTransaction record(
  ProfileData data,
  String id,
  int amount,
  DateTime date, {
  String type = 'expense',
  String? category,
  String budget = '',
  String? account,
  String recurring = '',
}) => MoneyTransaction(
  id: id,
  name: id,
  type: type,
  amountMinor: amount,
  accountId: account ?? data.accounts.first.id,
  categoryId:
      category ??
      data.categories
          .firstWhere((c) => c.type == (type == 'transfer' ? 'expense' : type))
          .id,
  date: date,
  budgetId: budget,
  recurringId: recurring,
  toAccountId: type == 'transfer' ? 'second' : '',
  toAmountMinor: type == 'transfer' ? amount : 0,
);
Ledger ledgerWith(ProfileData data, List<MoneyTransaction> entries) =>
    Ledger(data.copyWith(transactions: entries), const AppSettings());

void main() {
  test(
    'Account labels and linked accounts persist without fabricated identifiers',
    () {
      final data = fixture(), main = fixture().accounts.first;
      final child = const Account(
        id: 'child',
        name: 'Cash',
        currency: 'USD',
        holderName: 'Household',
        lastDigits: '0123',
      ).copyWith(parentId: main.id);
      expect(Account.fromJson(child.toJson()).toJson(), child.toJson());
      expect(
        Account.fromJson({
          'id': 'legacy',
          'name': 'Old',
          'currency': 'USD',
        }).lastDigits,
        '',
      );
      validateProfile(data.copyWith(accounts: [main, child]));
      for (final invalid in [
        child.copyWith(lastDigits: '12345'),
        child.copyWith(lastDigits: '12AB'),
        child.copyWith(parentId: 'missing'),
        child.copyWith(parentId: child.id),
      ]) {
        expect(
          () => validateProfile(data.copyWith(accounts: [main, invalid])),
          throwsA(isA<FormatException>()),
        );
      }
      expect(
        () => validateProfile(
          data.copyWith(
            accounts: [
              main.copyWith(parentId: child.id),
              child,
            ],
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );
  test(
    'Old budget/category JSON remains compatible; new controls round-trip',
    () {
      final old = Budget.fromJson({
        'id': 'b',
        'name': 'Old',
        'limitMinor': 1000,
        'period': 'monthly',
        'start': '2026-01-01',
      });
      expect(old.transactionType, 'expense');
      expect(old.mode, 'automatic');
      expect(old.showOnHome, isTrue);
      expect(old.excludeCategories, isFalse);
      expect(old.includeSubcategories, isTrue);
      final revised = old.copyWith(
        transactionType: 'income',
        mode: 'manual',
        excludeCategories: true,
        includeSubcategories: false,
        showOnHome: false,
        icon: 'work',
        categoryIds: ['salary'],
      );
      expect(Budget.fromJson(revised.toJson()).toJson(), revised.toJson());
      final category = Category(
        id: 'child',
        name: 'Child',
        type: 'expense',
        parentId: 'parent',
      );
      expect(Category.fromJson(category.toJson()).parentId, 'parent');
      expect(
        Category.fromJson({'id': 'old', 'name': 'Old', 'type': 'expense'})
            .parentId,
        '',
      );
    },
  );
  test(
    'Category ancestry rejects missing parents, cycles and cross-type parents',
    () {
      final data = fixture();
      const a = Category(id: 'a', name: 'A', type: 'expense'),
          b = Category(id: 'b', name: 'B', type: 'expense', parentId: 'a');
      validateProfile(data.copyWith(categories: [...data.categories, a, b]));
      for (final categories in [
        [a.copyWith(parentId: 'missing')],
        [a.copyWith(parentId: 'a')],
        [a.copyWith(parentId: 'b'), b],
        [a, b.copyWith(type: 'income')],
      ])
        expect(
          () => validateProfile(
            data.copyWith(categories: [...data.categories, ...categories]),
          ),
          throwsA(isA<FormatException>()),
        );
    },
  );
  test(
    'Category, descendant, overall exclusion and explicit manual matching',
    () {
      final data = fixture().copyWith(
        categories: [
          ...fixture().categories,
          const Category(id: 'parent', name: 'Transport', type: 'expense'),
          const Category(
            id: 'child',
            name: 'Bus',
            type: 'expense',
            parentId: 'parent',
          ),
          const Category(
            id: 'grandchild',
            name: 'Pass',
            type: 'expense',
            parentId: 'child',
          ),
        ],
      );
      final entry = record(
        data,
        'child',
        100,
        DateTime(2026, 1, 5),
        category: 'grandchild',
      );
      final ledger = ledgerWith(data, [entry]);
      expect(ledger.matchesBudget(plan(categories: ['parent']), entry), isTrue);
      expect(
        ledger.matchesBudget(
          plan(categories: ['parent'], children: false),
          entry,
        ),
        isFalse,
      );
      expect(
        ledger.matchesBudget(
          plan(categories: ['parent'], exclude: true),
          entry,
        ),
        isFalse,
      );
      expect(
        ledger.matchesBudget(
          plan(categories: ['parent'], exclude: true, children: false),
          entry,
        ),
        isTrue,
      );
      expect(ledger.matchesBudget(plan(exclude: true), entry), isTrue);
      expect(ledger.matchesBudget(plan(mode: 'manual'), entry), isFalse);
      expect(
        ledger.matchesBudget(
          plan(mode: 'manual', categories: ['parent']),
          entry.copyWith(budgetId: 'plan'),
        ),
        isTrue,
      );
      expect(
        ledger.matchesBudget(
          plan(categories: ['unrelated']),
          entry.copyWith(budgetId: 'plan'),
        ),
        isTrue,
      );
      expect(
        ledger.matchesBudget(
          plan(type: 'income'),
          entry.copyWith(budgetId: 'plan'),
        ),
        isFalse,
      );
      expect(
        ledger.matchesBudget(
          plan(),
          entry.copyWith(type: 'transfer', budgetId: 'plan'),
        ),
        isFalse,
      );
      expect(
        ledger.matchesBudget(plan(start: DateTime(2026, 1, 6)), entry),
        isFalse,
      );
    },
  );
  test('Income targets count receipts, not expenses or transfers', () {
    final data = fixture();
    final date = DateTime(2026, 1, 5);
    final ledger = ledgerWith(data, [
      record(data, 'income', 1200, date, type: 'income'),
      record(data, 'expense', 900, date),
      record(data, 'transfer', 500, date, type: 'transfer'),
    ]);
    final status = ledger.budgetStatus(plan(type: 'income'), date);
    expect(status.spent, 1200);
    expect(status.progress, 1.2);
    expect(status.remaining, -200);
    expect(
      ledger.budgetStatus(plan(mode: 'manual', type: 'income'), date).spent,
      0,
    );
  });
  test('Daily windows and signed rollover retain surplus and overspending', () {
    final data = fixture();
    final ledger = ledgerWith(data, [
      record(data, 'one', 1500, DateTime(2026, 1, 1, 9)),
      record(data, 'two', 200, DateTime(2026, 1, 2, 9)),
      record(data, 'today', 100, DateTime(2026, 1, 3, 9)),
    ]);
    final budget = plan(
      period: 'daily',
      rollover: true,
      start: DateTime(2026, 1, 1, 12),
    );
    final first = ledger.budgetStatus(budget, DateTime(2026, 1, 1, 10));
    expect(
      first.spent,
      1500,
      reason: 'Budget starts are calendar dates, not an accidental time-of-day gate',
    );
    final second = ledger.budgetStatus(budget, DateTime(2026, 1, 2, 12));
    expect(second.carry, -500);
    expect(second.limit, 500);
    expect(second.remaining, 300);
    final third = ledger.budgetStatus(budget, DateTime(2026, 1, 3, 12));
    expect(third.carry, 300);
    expect(third.limit, 1300);
    expect(third.remaining, 1200);
  });
  test(
    'Weekly rollover ignores pre-start entries in the partial first week',
    () {
      final data = fixture();
      final ledger = ledgerWith(data, [
        record(data, 'before', 9000, DateTime(2025, 12, 30)),
        record(data, 'start', 1500, DateTime(2026, 1, 1)),
        record(data, 'next', 100, DateTime(2026, 1, 5)),
      ]);
      final status = ledger.budgetStatus(
        plan(period: 'weekly', rollover: true),
        DateTime(2026, 1, 5),
      );
      expect(status.window.start, DateTime(2026, 1, 5));
      expect(status.window.end, DateTime(2026, 1, 12));
      expect(status.carry, -500);
      expect(status.spent, 100);
      expect(status.limit, 500);
    },
  );
  test('Monthly custom start restores the original month-end anchor', () {
    final data = fixture();
    final ledger = ledgerWith(data, [
      record(data, 'jan', 1400, DateTime(2026, 1, 31)),
      record(data, 'feb', 500, DateTime(2026, 2, 28)),
      record(data, 'mar', 60, DateTime(2026, 3, 31)),
    ]);
    final budget = plan(start: DateTime(2026, 1, 31), rollover: true);
    expect(
      budgetWindow(budget, DateTime(2026, 3, 30), 1).start,
      DateTime(2026, 2, 28),
    );
    final status = ledger.budgetStatus(budget, DateTime(2026, 3, 31));
    expect(status.window.start, DateTime(2026, 3, 31));
    expect(status.window.end, DateTime(2026, 4, 30));
    expect(status.carry, 100);
    expect(status.limit, 1100);
    expect(status.spent, 60);
  });
  test(
    'Yearly leap-day anchors and negative effective allowances are retained',
    () {
      final data = fixture();
      final ledger = ledgerWith(data, [
        record(data, 'leap', 1500, DateTime(2024, 2, 29)),
        record(data, 'following', 800, DateTime(2025, 2, 28)),
      ]);
      final budget = plan(
        period: 'yearly',
        start: DateTime(2024, 2, 29),
        rollover: true,
      );
      final status = ledger.budgetStatus(budget, DateTime(2026, 2, 28));
      expect(status.window.start, DateTime(2026, 2, 28));
      expect(status.window.end, DateTime(2027, 2, 28));
      expect(status.carry, -300);
      expect(status.limit, 700);
      final negative =
          ledgerWith(data, [
            record(data, 'over', 3500, DateTime(2026, 1, 1)),
          ]).budgetStatus(
            plan(period: 'daily', rollover: true),
            DateTime(2026, 1, 2),
          );
      expect(negative.limit, -1500);
      expect(negative.remaining, -1500);
      expect(negative.label, 'Over budget');
      expect(negative.progress.isFinite, isTrue);
    },
  );
  test(
    'Custom ranges include the complete last day and never repeat rollover',
    () {
      final data = fixture();
      final ledger = ledgerWith(data, [
        record(data, 'last', 200, DateTime(2026, 1, 3, 23, 59)),
        record(data, 'after', 900, DateTime(2026, 1, 4)),
      ]);
      final budget = plan(
        period: 'custom',
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 3),
        rollover: true,
      );
      final status = ledger.budgetStatus(budget, DateTime(2026, 1, 3));
      expect(status.spent, 200);
      expect(status.carry, 0);
      expect(status.window.end, DateTime(2026, 1, 4));
      final future = ledger.budgetStatus(
        budget.copyWith(start: DateTime(2026, 1, 3)),
        DateTime(2026, 1, 2),
      );
      expect(future.spent, 0);
      expect(future.carry, 0);
    },
  );
  test(
    'Daily rollover over a century is bounded by records, not a catch-up loop',
    () {
      final data = fixture();
      final start = DateTime(1970, 1, 1), now = DateTime(2070, 1, 1);
      final status = ledgerWith(
        data,
        [],
      ).budgetStatus(plan(period: 'daily', start: start, rollover: true), now);
      expect(status.carry, calendarDaysBetween(start, now) * 1000);
      expect(status.spent, 0);
    },
  );
  test('Reports omit transfers, excluded accounts, opening balances and unposted dates', () {
    final data = fixture();
    final now = DateTime(2026, 11, 6, 12);
    final profile = data.copyWith(
      accounts: [
        ...data.accounts,
        const Account(
          id: 'second',
          name: 'Excluded',
          currency: 'USD',
          openingMinor: 999999,
          excluded: true,
        ),
      ],
    );
    final ledger = ledgerWith(profile, [
      record(profile, 'income', 7000, DateTime(2026, 11, 1), type: 'income'),
      record(profile, 'expense', 6400, DateTime(2026, 11, 3)),
      record(
        profile,
        'excluded',
        9900,
        DateTime(2026, 11, 2),
        account: 'second',
      ),
      record(
        profile,
        'transfer',
        1000,
        DateTime(2026, 11, 2),
        type: 'transfer',
      ),
      record(profile, 'later today', 500, DateTime(2026, 11, 6, 18)),
      record(profile, 'next month', 1000, DateTime(2026, 12, 1)),
    ]);
    final snapshot = ReportSnapshot(
      ledger,
      DateWindow(DateTime(2026, 11, 1), DateTime(2026, 12, 1)),
      now: now,
    );
    expect(snapshot.entries.map((e) => e.id), ['income', 'expense']);
    expect(snapshot.income, 7000);
    expect(snapshot.expense, 6400);
    expect(snapshot.net, 600);
    expect(snapshot.dailyAverage, 213);
    expect(snapshot.averageTransaction, 6400);
    expect(snapshot.largestExpense?.id, 'expense');
    expect(snapshot.peakDay, DateTime(2026, 11, 3));
    expect(snapshot.daily[5].future, isFalse);
    expect(snapshot.daily[6].future, isTrue);
    expect(snapshot.daily[2].expense, 6400);
    expect(
      ReportSnapshot(
        ledger,
        snapshot.window,
        now: now,
        selection: [],
      ).savingsRate,
      isNull,
    );
  });
  test(
    'Reports aggregate descendants and convert native amounts at manual rates',
    () {
      final data = fixture().copyWith(
        accounts: [const Account(id: 'eur', name: 'Euro', currency: 'EUR')],
        categories: [
          ...fixture().categories,
          const Category(id: 'parent', name: 'Travel', type: 'expense'),
          const Category(
            id: 'child',
            name: 'Rail',
            type: 'expense',
            parentId: 'parent',
          ),
        ],
        rates: [
          ExchangeRate(code: 'USD', perUsd: 1, updatedAt: DateTime(2026)),
          ExchangeRate(code: 'EUR', perUsd: .5, updatedAt: DateTime(2026)),
        ],
      );
      final entry = record(
        data,
        'rail',
        500,
        DateTime(2026, 1, 5),
        category: 'child',
      );
      final snapshot = ReportSnapshot(
        ledgerWith(data, [entry]),
        DateWindow(DateTime(2026, 1, 1), DateTime(2026, 2, 1)),
        now: DateTime(2026, 2, 1),
      );
      expect(snapshot.expense, 1000);
      expect(snapshot.groups().single.id, 'parent');
      expect(snapshot.groups().single.amount, 1000);
      expect(snapshot.groups().single.entries.single.id, 'rail');
      expect(snapshot.daily.length, 31);
      expect(snapshot.daily[4].expense, 1000);
    },
  );
  test(
    'Multi-tag report grouping is explicit and keeps the real matching entries',
    () {
      final data = fixture().copyWith(
        entities: [
          const NamedEntity(id: 'a', name: 'A', kind: 'label'),
          const NamedEntity(id: 'b', name: 'B', kind: 'label'),
        ],
      );
      final entry = record(
        data,
        'both',
        100,
        DateTime(2026, 1, 5),
      ).copyWith(labelIds: ['a', 'b']);
      final snapshot = ReportSnapshot(
        ledgerWith(data, [entry]),
        DateWindow(DateTime(2026, 1, 1), DateTime(2026, 2, 1)),
        now: DateTime(2026, 2, 1),
      );
      expect(snapshot.expense, 100);
      expect(snapshot.groups(dimension: 'label').map((g) => g.amount), [
        100,
        100,
      ]);
    },
  );
  test('Upcoming preview is bounded, deduplicated, disabled/end-aware and read-only', () {
    final data = fixture();
    final now = DateTime(2026, 11, 6, 12), due = DateTime(2026, 11, 7, 9);
    final rule = Recurring(
      id: 'daily',
      name: 'Local bill',
      type: 'expense',
      amountMinor: 100,
      accountId: data.accounts.first.id,
      categoryId: data.categories.first.id,
      frequency: 'daily',
      start: DateTime(2020, 1, 1, 9),
      nextDue: DateTime(2020, 1, 1, 9),
      end: DateTime(2026, 11, 7, 23, 59),
    );
    final entries = [
      record(data, 'materialized', 100, due, recurring: 'daily'),
    ];
    final profile = data.copyWith(
      transactions: entries,
      recurrings: [
        rule,
        rule.copyWith(id: 'disabled', enabled: false),
        rule.copyWith(id: 'archived', archived: true),
      ],
    );
    final snapshot = profile.toJson().toString();
    final upcoming = upcomingRecords(
      Ledger(profile, const AppSettings()),
      now,
      days: 2,
    );
    expect(upcoming.length, 1);
    expect(upcoming.single.entry?.id, 'materialized');
    expect(profile.toJson().toString(), snapshot);
    final noSaved = upcomingRecords(
      Ledger(profile.copyWith(transactions: []), const AppSettings()),
      now,
      days: 2,
    );
    expect(noSaved.length, 1);
    expect(noSaved.single.rule?.id, 'daily');
    expect(noSaved.single.date, due);
  });
  test('Batch-one layouts append the four new Home sections once, preserving order and hiding', () {
    final migrated = AppSettings.fromJson({
      'uiRevision': 2,
      'homeCards': ['templates', 'accounts', 'balance'],
      'hiddenCards': ['balance'],
      'navTabs': ['home', 'more', 'accounts'],
    });
    expect(migrated.homeCards, [
      'templates',
      'accounts',
      'balance',
      'heatmap',
      'trend',
      'trackedBudgets',
      'upcoming',
    ]);
    expect(migrated.hiddenCards, ['balance']);
    expect(migrated.navTabs, ['home', 'more', 'accounts']);
    expect(
      AppSettings.fromJson(migrated.toJson()).homeCards,
      migrated.homeCards,
    );
    final current = migrated.copyWith(homeCards: ['templates', 'accounts']);
    expect(AppSettings.fromJson(current.toJson()).homeCards, current.homeCards);
  });
}
