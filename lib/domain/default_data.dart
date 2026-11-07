import 'package:flutter/material.dart';

import '../core/constants/icons.dart';
import '../core/enum/filter_enums.dart';
import '../data/models/account_model.dart';
import '../data/models/category_model.dart';

/// A default account definition — the persisted [AccountModel] is built from
/// this at seed time, keeping onboarding data declarative.
@immutable
class SeedAccount {
  const SeedAccount({
    required this.id,
    required this.name,
    required this.bankName,
    required this.number,
    required this.cardType,
    required this.initialAmount,
    required this.color,
    required this.isDefault,
  });

  final String id;
  final String name;
  final String bankName;
  final String number;
  final AccountType cardType;
  final double initialAmount;
  final int color;
  final bool isDefault;

  /// Builds the persisted model.
  AccountModel toModel() {
    return AccountModel(
      id: id,
      name: name,
      bankName: bankName,
      number: number,
      cardType: cardType,
      initialAmount: initialAmount,
      color: color,
      isDefault: isDefault,
    );
  }
}

/// The out-of-the-box data Paisa seeds during onboarding.
///
/// Category ids are deterministic (`seed-category-food`) so re-running the seed
/// is idempotent: existing rows are reused instead of duplicated. Icons are
/// resolved from [categoryIcons] at runtime, so the stored `codePoint` is always
/// one the release icon tree-shaker kept.
class DefaultData {
  const DefaultData._();

  // ---------------------------------------------------------------------
  // Default accounts
  // ---------------------------------------------------------------------

  /// Stable ids for the two accounts every new user starts with.
  static const String cashAccountId = 'seed-account-cash';
  static const String bankAccountId = 'seed-account-bank';

  /// `Cash` in hand — the default account.
  static const SeedAccount cashAccount = SeedAccount(
    id: cashAccountId,
    name: 'Cash',
    bankName: 'Cash in Hand',
    number: '',
    cardType: AccountType.cash,
    initialAmount: 0,
    color: 0xFF43A047,
    isDefault: true,
  );

  /// A generic savings account the user renames during onboarding.
  static const SeedAccount bankAccount = SeedAccount(
    id: bankAccountId,
    name: 'Primary Account',
    bankName: 'Savings Account',
    number: '',
    cardType: AccountType.bank,
    initialAmount: 0,
    color: 0xFF1E88E5,
    isDefault: false,
  );

  static List<SeedAccount> get accounts =>
      <SeedAccount>[cashAccount, bankAccount];

  static List<AccountModel> get accountModels =>
      accounts.map((SeedAccount seed) => seed.toModel()).toList(growable: false);

  // ---------------------------------------------------------------------
  // Default categories
  // ---------------------------------------------------------------------

  static CategoryModel _expenseCategory({
    required String id,
    required String name,
    required String description,
    required String iconKey,
    required int color,
    required double budget,
    bool isBudgetActive = true,
  }) {
    return CategoryModel(
      id: id,
      name: name,
      description: description,
      icon: ICONS.codePointForKey(iconKey),
      color: color,
      budget: budget,
      isBudgetActive: isBudgetActive,
      isDefault: true,
    );
  }

  /// Fourteen Indian-market expense categories with vibrant ARGB colours that
  /// also read well as chart slices.
  static List<CategoryModel> get categories => <CategoryModel>[
        _expenseCategory(
          id: 'seed-category-food',
          name: 'Food & Dining',
          description: 'Restaurants, Swiggy, Zomato, groceries',
          iconKey: 'food',
          color: 0xFFF4511E,
          budget: 6000,
        ),
        _expenseCategory(
          id: 'seed-category-transport',
          name: 'Transport',
          description: 'Fuel, Ola, Uber, metro, auto',
          iconKey: 'transport',
          color: 0xFF1E88E5,
          budget: 3000,
        ),
        _expenseCategory(
          id: 'seed-category-groceries',
          name: 'Groceries',
          description: 'Kirana, BigBasket, DMart, vegetables',
          iconKey: 'groceries',
          color: 0xFF43A047,
          budget: 8000,
        ),
        _expenseCategory(
          id: 'seed-category-bills',
          name: 'Bills & Utilities',
          description: 'Electricity, water, gas, broadband, mobile',
          iconKey: 'bills',
          color: 0xFFFB8C00,
          budget: 4000,
        ),
        _expenseCategory(
          id: 'seed-category-rent',
          name: 'Rent & EMI',
          description: 'House rent, home loan EMI',
          iconKey: 'rent',
          color: 0xFF8E24AA,
          budget: 20000,
        ),
        _expenseCategory(
          id: 'seed-category-shopping',
          name: 'Shopping',
          description: 'Amazon, Flipkart, Myntra, clothes',
          iconKey: 'shopping',
          color: 0xFFD81B60,
          budget: 5000,
        ),
        _expenseCategory(
          id: 'seed-category-health',
          name: 'Health',
          description: 'Medicines, doctor, gym, health insurance',
          iconKey: 'health',
          color: 0xFFE53935,
          budget: 2500,
        ),
        _expenseCategory(
          id: 'seed-category-education',
          name: 'Education',
          description: 'Tuition, courses, books, school fees',
          iconKey: 'education',
          color: 0xFF3949AB,
          budget: 3000,
        ),
        _expenseCategory(
          id: 'seed-category-entertainment',
          name: 'Entertainment',
          description: 'Movies, Netflix, Spotify, games',
          iconKey: 'movie',
          color: 0xFF5E35B1,
          budget: 2000,
        ),
        _expenseCategory(
          id: 'seed-category-travel',
          name: 'Travel',
          description: 'Flights, trains, hotels, trips',
          iconKey: 'flight',
          color: 0xFF00ACC1,
          budget: 5000,
          isBudgetActive: false,
        ),
        _expenseCategory(
          id: 'seed-category-recharge',
          name: 'Recharge',
          description: 'Mobile, DTH, FASTag',
          iconKey: 'phone',
          color: 0xFF7CB342,
          budget: 1000,
          isBudgetActive: false,
        ),
        _expenseCategory(
          id: 'seed-category-investment',
          name: 'Investments',
          description: 'SIP, stocks, mutual funds, gold',
          iconKey: 'investment',
          color: 0xFF00897B,
          budget: 0,
          isBudgetActive: false,
        ),
        _expenseCategory(
          id: 'seed-category-gifts',
          name: 'Gifts & Donations',
          description: 'Presents, festivals, charity',
          iconKey: 'gift',
          color: 0xFFFDD835,
          budget: 1500,
          isBudgetActive: false,
        ),
        _expenseCategory(
          id: 'seed-category-other',
          name: 'Other',
          description: 'Everything else',
          iconKey: 'other',
          color: 0xFF6F7473,
          budget: 0,
          isBudgetActive: false,
        ),
      ];

  // ---------------------------------------------------------------------
  // Income categories
  // ---------------------------------------------------------------------

  static const String salaryCategoryId = 'seed-category-salary';
  static const String refundCategoryId = 'seed-category-refund';

  static CategoryModel _incomeCategory({
    required String id,
    required String name,
    required String description,
    required String iconKey,
    required int color,
  }) {
    return CategoryModel(
      id: id,
      name: name,
      description: description,
      icon: ICONS.codePointForKey(iconKey),
      color: color,
      budget: 0,
      isBudgetActive: false,
      isDefault: true,
    );
  }

  /// Income categories, seeded only when the user enables income tracking so
  /// the expense picker stays short for pure expense users.
  static List<CategoryModel> get incomeCategories => <CategoryModel>[
        _incomeCategory(
          id: salaryCategoryId,
          name: 'Salary',
          description: 'Monthly salary, incentives, bonus',
          iconKey: 'salary',
          color: 0xFF1B7F4B,
        ),
        _incomeCategory(
          id: refundCategoryId,
          name: 'Refunds & Cashback',
          description: 'Refunds, cashback, reimbursements',
          iconKey: 'refund',
          color: 0xFF00897B,
        ),
      ];

  // ---------------------------------------------------------------------
  // Icon & colour options offered by the category editor
  // ---------------------------------------------------------------------

  /// Icons a user can pick for a custom category (the full tree-shake-safe
  /// registry lives in [ICONS]).
  static Map<String, IconData> get categoryIcons => ICONS.all;

  /// Icons reserved for accounts.
  static const List<String> accountIconKeys = ICONS.accountIconKeys;

  /// Colours offered by the category and account editors.
  static const List<int> palette = <int>[
    0xFFF4511E,
    0xFFFB8C00,
    0xFFFDD835,
    0xFF7CB342,
    0xFF43A047,
    0xFF00897B,
    0xFF00ACC1,
    0xFF1E88E5,
    0xFF3949AB,
    0xFF5E35B1,
    0xFF8E24AA,
    0xFFD81B60,
    0xFFE53935,
    0xFF6F7473,
  ];
}
