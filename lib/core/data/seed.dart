import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

const uuid = Uuid();
List<ExchangeRate> defaultRates() {
  // Illustrative, OFFLINE reference rates. Never represented as live market prices.
  final date = DateTime(2026, 1, 1);
  const values = {
    'USD': 1.0,
    'INR': 85.0,
    'EUR': .92,
    'GBP': .77,
    'JPY': 150.0,
    'AUD': 1.55,
    'CAD': 1.42,
    'CHF': .89,
    'CNY': 7.25,
    'SGD': 1.34,
    'AED': 3.6725,
    'SAR': 3.75,
    'BDT': 122.0,
    'PKR': 280.0,
    'NPR': 136.0,
    'LKR': 300.0,
    'KRW': 1450.0,
    'KWD': .307,
    'BHD': .376,
    'OMR': .385,
  };
  return values.entries
      .map(
        (entry) =>
            ExchangeRate(code: entry.key, perUsd: entry.value, updatedAt: date),
      )
      .toList();
}

List<Category> defaultCategories() {
  const expense = [
    ['Food & Dining', 'food', 0xffF79009],
    ['Groceries', 'groceries', 0xff12B76A],
    ['Transport', 'transport', 0xff2E90FA],
    ['Shopping', 'shopping', 0xffEE46BC],
    ['Bills & Utilities', 'bills', 0xff916CFF],
    ['Entertainment', 'entertainment', 0xffEE46BC],
    ['Health', 'health', 0xff12B76A],
    ['Education', 'education', 0xff6172F3],
    ['Travel', 'travel', 0xff15B79E],
    ['Other', 'category', 0xff8A8A96],
  ];
  const income = [
    ['Salary', 'salary', 0xff12B76A],
    ['Freelance', 'work', 0xff2E90FA],
    ['Investment income', 'asset', 0xff916CFF],
    ['Gifts', 'gift', 0xffF79009],
  ];
  return [
    for (final group in [expense, income])
      for (var i = 0; i < group.length; i++)
        Category(
          id: uuid.v4(),
          name: group[i][0] as String,
          icon: group[i][1] as String,
          color: group[i][2] as int,
          type: identical(group, expense) ? 'expense' : 'income',
          order: i,
        ),
  ];
}

ProfileData seedProfile({
  required String name,
  required String currency,
  required String accountName,
  int openingMinor = 0,
  bool demo = false,
  DateTime? clock,
}) {
  final now = clock ?? DateTime.now();
  final profile = Profile(
    id: uuid.v4(),
    name: name,
    currency: currency,
    createdAt: now,
  );
  final categories = defaultCategories();
  final everyday = Account(
    id: uuid.v4(),
    name: accountName,
    currency: currency,
    openingMinor: openingMinor,
    icon: 'bank',
  );
  var data = ProfileData(
    profile: profile,
    accounts: [everyday],
    categories: categories,
    rates: defaultRates(),
  );
  if (!demo) return data;
  // Demo amounts are scaled to an INR-like everyday purchasing power.
  final rates = data.rates;
  int amount(num inr) =>
      convertMinor(toMinor(inr, 'INR'), 'INR', currency, rates);
  final cash = Account(
    id: uuid.v4(),
    name: 'Pocket money',
    type: 'cash',
    currency: currency,
    openingMinor: amount(3500),
    icon: 'cash',
    color: 0xff916CFF,
  );
  final savings = Account(
    id: uuid.v4(),
    name: 'Rainy day fund',
    type: 'savings',
    currency: currency,
    openingMinor: amount(24000),
    icon: 'savings',
    color: 0xff2E90FA,
  );
  final accounts = [
    everyday.copyWith(
      openingMinor: openingMinor == 0 ? amount(12000) : openingMinor,
    ),
    cash,
    savings,
  ];
  final food = categories.firstWhere((item) => item.icon == 'food');
  final groceries = categories.firstWhere((item) => item.icon == 'groceries');
  final travel = categories.firstWhere((item) => item.icon == 'transport');
  final salary = categories.firstWhere((item) => item.icon == 'salary');
  final entertainment = categories.firstWhere(
    (item) => item.icon == 'entertainment',
  );
  final label = NamedEntity(
    id: uuid.v4(),
    name: 'Everyday',
    kind: 'label',
    color: 0xff12B76A,
  );
  final workLabel = NamedEntity(
    id: uuid.v4(),
    name: 'Work',
    kind: 'label',
    icon: 'work',
    color: 0xffb7c9e5,
  );
  final person = NamedEntity(
    id: uuid.v4(),
    name: 'Alex',
    kind: 'person',
    notes: 'A good friend',
  );
  final place = NamedEntity(
    id: uuid.v4(),
    name: 'Neighbourhood',
    kind: 'place',
    notes: 'Local favourites',
  );
  final random = Random(42);
  final entries = <MoneyTransaction>[];
  for (var month = 5; month >= 0; month--) {
    final first = DateTime(now.year, now.month - month, 1, 9);
    entries.add(
      MoneyTransaction(
        id: uuid.v4(),
        name: 'Monthly salary',
        type: 'income',
        amountMinor: amount(42000 + (5 - month) * 1000),
        accountId: everyday.id,
        categoryId: salary.id,
        date: first,
        labelIds: [workLabel.id],
      ),
    );
    for (var day = 1; day <= (month == 0 ? now.day : 27); day += 2) {
      final cat = [food, groceries, travel, entertainment][random.nextInt(4)];
      entries.add(
        MoneyTransaction(
          id: uuid.v4(),
          name: switch (cat.icon) {
            'food' => [
              'Morning coffee',
              'Lunch with friends',
              'Weekend dinner',
            ][random.nextInt(3)],
            'groceries' => 'Fresh market',
            'transport' => 'Metro & rides',
            _ => 'Movie night',
          },
          type: 'expense',
          amountMinor: amount(120 + random.nextInt(1450)),
          accountId: everyday.id,
          categoryId: cat.id,
          date: DateTime(first.year, first.month, day, 12, 30),
          labelIds: [label.id, if (cat.icon == 'transport') workLabel.id],
          placeId: place.id,
        ),
      );
    }
  }
  // Fictional posted records make the carousel and statistical examples
  // reproducible on every demo date. Analytics still computes from the ledger;
  // nothing is injected into its results or into a real profile.
  for (final sample in [
    ('Household repair · demo', 'bills', 8000),
    ('Learning course · demo', 'education', 1600),
  ]) {
    entries.add(
      MoneyTransaction(
        id: uuid.v4(),
        name: sample.$1,
        type: 'expense',
        amountMinor: amount(sample.$3),
        accountId: everyday.id,
        categoryId: categories.firstWhere((c) => c.icon == sample.$2).id,
        date: dayOnly(now),
        labelIds: [label.id, workLabel.id],
        notes: 'Fictional demo record. No real payment.',
      ),
    );
  }
  final goal = Goal(
    id: uuid.v4(),
    name: 'A little escape',
    targetMinor: amount(60000),
    deadline: DateTime(now.year, now.month, now.day + 180),
    icon: 'travel',
    contributions: [
      MoneyEvent(
        id: uuid.v4(),
        amountMinor: amount(22500),
        date: now,
        note: 'Getting started',
      ),
    ],
  );
  data = data.copyWith(
    accounts: accounts,
    transactions: entries,
    entities: [
      label,
      person,
      place,
      workLabel,
    ],
    budgets: [
      Budget(
        id: uuid.v4(),
        name: 'Good food, good mood',
        limitMinor: amount(7000),
        start: DateTime(now.year, now.month),
        categoryIds: [food.id, groceries.id],
      ),
      Budget(
        id: uuid.v4(),
        name: 'Getting around',
        limitMinor: amount(2500),
        start: DateTime(now.year, now.month),
        categoryIds: [travel.id],
        color: 0xff2E90FA,
      ),
    ],
    goals: [
      goal.copyWith(start: DateTime(now.year, now.month - 3, now.day)),
      Goal(
        id: uuid.v4(),
        name: 'Emergency fund',
        targetMinor: amount(30000),
        start: DateTime(now.year, now.month - 2, now.day),
        deadline: DateTime(now.year + 1, now.month, now.day),
        icon: 'bank',
        color: 0xffE9B986,
        contributions: [
          MoneyEvent(id: uuid.v4(), amountMinor: amount(4500), date: now),
        ],
      ),
    ],
    assets: [
      Asset(
        id: uuid.v4(),
        name: 'Gold savings',
        type: 'gold',
        valueMinor: amount(18000),
        purchaseMinor: amount(15000),
        icon: 'asset',
        color: 0xffE9B986,
      ),
      Asset(
        id: uuid.v4(),
        name: 'Index fund',
        type: 'mutual funds',
        valueMinor: amount(45000),
        purchaseMinor: amount(38000),
        icon: 'asset',
        history: [
          MoneyEvent(id: uuid.v4(), amountMinor: amount(45000), date: now),
        ],
      ),
    ],
    loans: [
      Loan(
        id: uuid.v4(),
        personName: 'Sam',
        principalMinor: amount(2500),
        direction: 'borrowed',
        due: DateTime(now.year, now.month, now.day + 45),
        notes: 'Shared travel booking',
      ),
      Loan(
        id: uuid.v4(),
        personName: person.name,
        personId: person.id,
        principalMinor: amount(3000),
        due: DateTime(now.year, now.month, now.day + 14),
        notes: 'Weekend trip',
      ),
    ],
    bills: [
      for (var index = 0; index < 2; index++)
        Bill(
          id: uuid.v4(),
          title: index == 0 ? 'Dinner with Alex' : 'Weekend tickets',
          totalMinor: amount(1200),
          date: DateTime(now.year, now.month, now.day - index - 1),
          paidById: 'me',
          paidByName: 'You',
          shares: [
            BillShare(
              personId: 'me',
              name: 'You',
              amountMinor: amount(600),
              settled: true,
            ),
            BillShare(
              personId: person.id,
              name: person.name,
              amountMinor: amount(1200) - amount(600),
              settled: index == 1,
            ),
          ],
        ),
    ],
    templates: [
      TransactionTemplate(
        id: uuid.v4(),
        name: 'Coffee break',
        type: 'expense',
        amountMinor: amount(180),
        accountId: everyday.id,
        categoryId: food.id,
      ),
      TransactionTemplate(
        id: uuid.v4(),
        name: 'Metro ride',
        type: 'expense',
        amountMinor: amount(50),
        accountId: everyday.id,
        categoryId: travel.id,
      ),
    ],
  );
  final overdue = DateTime(now.year, now.month, now.day - 1, 9);
  final upcoming = DateTime(now.year, now.month, now.day + 8, 9);
  final rules = [
    Recurring(
      id: uuid.v4(),
      name: 'Netflix',
      amountMinor: amount(499),
      accountId: everyday.id,
      categoryId: entertainment.id,
      start: safeMonth(overdue.year, overdue.month - 4, overdue.day),
      nextDue: overdue,
      autoPost: false,
      labelIds: [label.id],
      placeId: place.id,
      notes: 'Fictional demo subscription · manual confirmation',
    ),
    Recurring(
      id: uuid.v4(),
      name: 'Spotify',
      amountMinor: amount(119),
      accountId: cash.id,
      categoryId: categories.firstWhere((c) => c.icon == 'bills').id,
      start: safeMonth(upcoming.year, upcoming.month - 4, upcoming.day),
      nextDue: upcoming,
      autoPost: false,
      reminderDays: 1,
      notes: 'Fictional demo subscription · no payment service is connected',
    ),
  ];
  final history = <MoneyTransaction>[];
  for (final rule in rules) {
    for (var i = 4; i > 0; i--) {
      final date = safeMonth(
        rule.nextDue.year,
        rule.nextDue.month - i,
        rule.start.day,
      );
      history.add(
        MoneyTransaction(
          id: '${rule.id}@${date.toIso8601String()}',
          name: rule.name,
          type: rule.type,
          amountMinor: rule.amountMinor,
          accountId: rule.accountId,
          categoryId: rule.categoryId,
          date: date,
          recurringId: rule.id,
          labelIds: rule.labelIds,
          placeId: rule.placeId,
          notes: 'Fictional demo history',
        ),
      );
    }
  }
  return data.copyWith(
    recurrings: rules,
    transactions: [...data.transactions, ...history],
  );
}
