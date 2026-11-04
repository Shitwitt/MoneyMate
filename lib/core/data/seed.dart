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
    ['Food & Dining', 'food', 0xfff2b88f],
    ['Groceries', 'groceries', 0xffa4ca6a],
    ['Transport', 'transport', 0xff88bacc],
    ['Shopping', 'shopping', 0xffb6a5e8],
    ['Bills & Utilities', 'bills', 0xffe4c569],
    ['Entertainment', 'entertainment', 0xffed9c9b],
    ['Health', 'health', 0xff88c7b5],
    ['Education', 'education', 0xffa5addd],
    ['Travel', 'travel', 0xffdbadd1],
    ['Other', 'category', 0xffb9b7aa],
  ];
  const income = [
    ['Salary', 'salary', 0xffa4ca6a],
    ['Freelance', 'work', 0xff88bacc],
    ['Investment income', 'asset', 0xffb6a5e8],
    ['Gifts', 'gift', 0xfff2b88f],
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
    color: 0xffb6a5e8,
  );
  final savings = Account(
    id: uuid.v4(),
    name: 'Rainy day fund',
    type: 'savings',
    currency: currency,
    openingMinor: amount(24000),
    icon: 'savings',
    color: 0xff88bacc,
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
    color: 0xffa4ca6a,
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
          labelIds: [label.id],
          placeId: place.id,
        ),
      );
    }
  }
  final goal = Goal(
    id: uuid.v4(),
    name: 'A little escape',
    targetMinor: amount(60000),
    deadline: now.add(const Duration(days: 180)),
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
    entities: [label, person, place],
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
        color: 0xff88bacc,
      ),
    ],
    goals: [goal],
    assets: [
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
        personName: person.name,
        personId: person.id,
        principalMinor: amount(3000),
        due: now.add(const Duration(days: 14)),
        notes: 'Weekend trip',
      ),
    ],
    recurrings: [
      Recurring(
        id: uuid.v4(),
        name: 'Music subscription',
        amountMinor: amount(119),
        accountId: everyday.id,
        categoryId: entertainment.id,
        start: safeMonth(now.year, now.month + 1, 8),
        nextDue: safeMonth(now.year, now.month + 1, 8),
      ),
      Recurring(
        id: uuid.v4(),
        name: 'Internet',
        amountMinor: amount(799),
        accountId: everyday.id,
        categoryId: categories.firstWhere((item) => item.icon == 'bills').id,
        start: safeMonth(now.year, now.month + 1, 5),
        nextDue: safeMonth(now.year, now.month + 1, 5),
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
  return data;
}
