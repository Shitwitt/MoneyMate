import 'package:flutter/foundation.dart';

import '../../core/constants/currencies.dart';
import '../../core/enum/filter_enums.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';

/// The draft a user builds across the five onboarding pages.
///
/// Held by [OnboardingScreen] as plain state — nothing is written to Hive until
/// the final "Open MoneyMate" tap, so backing out leaves the database untouched.
@immutable
class OnboardingState {
  const OnboardingState({
    this.languageCode = 'en',
    this.name = '',
    this.avatarIndex = 0,
    this.customImagePath,
    this.selectedAccountType = AccountPreset.bank,
    this.initialBalances = const <AccountPreset, double>{},
    this.selectedCategoryIds = const <String>{},
    this.currencyCode = 'INR',
  });

  final String languageCode;
  final String name;
  final int avatarIndex;
  final String? customImagePath;

  /// Which preset account card is currently toggled on.
  final AccountPreset selectedAccountType;

  /// Opening balance entered per preset (defaults to 0 when absent).
  final Map<AccountPreset, double> initialBalances;

  /// Ids of the [OnboardingCategories] rows the user picked.
  final Set<String> selectedCategoryIds;

  final String currencyCode;

  String get trimmedName => name.trim();

  bool get hasValidName => trimmedName.isNotEmpty;

  bool get hasAccount => true; // [selectedAccountType] is never null

  bool get hasCategories => selectedCategoryIds.isNotEmpty;

  CurrencyDefinition get currency => CurrencyTable.byCode(currencyCode);

  double balanceFor(AccountPreset preset) => initialBalances[preset] ?? 0;

  OnboardingState copyWith({
    String? languageCode,
    String? name,
    int? avatarIndex,
    String? customImagePath,
    bool clearCustomImagePath = false,
    AccountPreset? selectedAccountType,
    Map<AccountPreset, double>? initialBalances,
    Set<String>? selectedCategoryIds,
    String? currencyCode,
  }) {
    return OnboardingState(
      languageCode: languageCode ?? this.languageCode,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      customImagePath: clearCustomImagePath
          ? null
          : (customImagePath ?? this.customImagePath),
      selectedAccountType:
          selectedAccountType ?? this.selectedAccountType,
      initialBalances: initialBalances ?? this.initialBalances,
      selectedCategoryIds:
          selectedCategoryIds ?? this.selectedCategoryIds,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  // ---------------------------------------------------------------------
  // Conversion to persisted models
  // ---------------------------------------------------------------------

  /// Builds the single [AccountModel] this draft creates.
  ///
  /// Onboarding deliberately seeds **one** account: creating three accounts with
  /// invented balances is how trackers end up with wrong opening balances. The
  /// user adds more from Accounts once they have real figures.
  AccountModel buildAccount() {
    final AccountPreset preset = selectedAccountType;
    final double initial = balanceFor(preset);
    return AccountModel(
      id: preset.accountId,
      name: trimmedName.isEmpty ? 'Me' : trimmedName,
      bankName: preset.defaultTitle,
      number: '',
      cardType: preset.cardType,
      initialAmount: initial < 0 ? 0 : initial,
      color: preset.color,
      isDefault: true,
    );
  }

  /// The picked categories, in the canonical on-screen order.
  List<CategoryModel> buildCategories() {
    final List<CategoryModel> picked = <CategoryModel>[];
    for (final OnboardingCategory definition in OnboardingCategories.all) {
      if (!selectedCategoryIds.contains(definition.model.id)) continue;
      picked.add(definition.model);
    }
    return picked;
  }

  OnboardingState toggleCategory(String id) {
    final Set<String> next = Set<String>.of(selectedCategoryIds);
    if (!next.remove(id)) next.add(id);
    return copyWith(selectedCategoryIds: next);
  }

  OnboardingState withBalance(AccountPreset preset, double amount) {
    final Map<AccountPreset, double> next =
        Map<AccountPreset, double>.of(initialBalances);
    next[preset] = amount < 0 ? 0 : amount;
    return copyWith(initialBalances: next);
  }
}

/// The three account presets offered on page 3.
enum AccountPreset { cash, bank, card }

extension AccountPresetX on AccountPreset {
  /// Deterministic id so re-running onboarding cannot duplicate the account.
  String get accountId => 'onboarding-account-${name}';

  String get defaultTitle {
    switch (this) {
      case AccountPreset.cash:
        return 'Cash Wallet';
      case AccountPreset.bank:
        return 'Bank Account';
      case AccountPreset.card:
        return 'Credit Card';
    }
  }

  String get emoji {
    switch (this) {
      case AccountPreset.cash:
        return '💵';
      case AccountPreset.bank:
        return '🏦';
      case AccountPreset.card:
        return '💳';
    }
  }

  String get description {
    switch (this) {
      case AccountPreset.cash:
        return 'Notes and coins you carry';
      case AccountPreset.bank:
        return 'Savings or salary account';
      case AccountPreset.card:
        return 'Credit card, paid later';
    }
  }

  int get color {
    switch (this) {
      case AccountPreset.cash:
        return 0xFF43A047;
      case AccountPreset.bank:
        return 0xFF1E88E5;
      case AccountPreset.card:
        return 0xFF8E24AA;
    }
  }

  AccountType get cardType {
    switch (this) {
      case AccountPreset.cash:
        return AccountType.cash;
      case AccountPreset.bank:
        return AccountType.bank;
      case AccountPreset.card:
        return AccountType.card;
    }
  }

  /// Localization key for the preset title.
  String get labelKey {
    switch (this) {
      case AccountPreset.cash:
        return 'accountCash';
      case AccountPreset.bank:
        return 'accountBank';
      case AccountPreset.card:
        return 'accountCard';
    }
  }
}

/// One row in the page-4 category grid.
@immutable
class OnboardingCategory {
  const OnboardingCategory({required this.model, required this.monthlyBudget});

  final CategoryModel model;

  /// Budget seeded alongside the category (0 = no budget).
  final double monthlyBudget;

  String get id => model.id;
  String get name => model.name;
}

/// The twelve default categories the spec asks for, mapped onto the ids seeded
/// by `DefaultData` so duplicates can never be created.
class OnboardingCategories {
  const OnboardingCategories._();

  static const List<OnboardingCategory> all = <OnboardingCategory>[
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-food',
        name: 'Food & Dining',
        description: 'Restaurants, Swiggy, Zomato, groceries',
        icon: 0xe56c, // Icons.restaurant_rounded
        color: 0xFFF4511E,
        budget: 6000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 6000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-groceries',
        name: 'Groceries',
        description: 'Kirana, BigBasket, DMart, vegetables',
        icon: 0xf04b, // Icons.shopping_basket_rounded
        color: 0xFF43A047,
        budget: 8000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 8000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-shopping',
        name: 'Shopping',
        description: 'Amazon, Flipkart, Myntra, clothes',
        icon: 0xf05a, // Icons.shopping_bag_rounded
        color: 0xFFD81B60,
        budget: 5000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 5000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-transport',
        name: 'Transport & Fuel',
        description: 'Fuel, Ola, Uber, metro, auto',
        icon: 0xe1d7, // Icons.directions_car_filled_rounded
        color: 0xFF1E88E5,
        budget: 3000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 3000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-bills',
        name: 'Bills & Utilities',
        description: 'Electricity, water, gas, broadband, mobile',
        icon: 0xf04d, // Icons.receipt_long_rounded
        color: 0xFFFB8C00,
        budget: 4000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 4000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-salary',
        name: 'Salary',
        description: 'Monthly salary, incentives, bonus',
        icon: 0xf04b, // Icons.account_balance_wallet_rounded
        color: 0xFF1B7F4B,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
      monthlyBudget: 0,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-investment',
        name: 'Investments',
        description: 'SIP, stocks, mutual funds, gold',
        icon: 0xe2c4, // Icons.trending_up_rounded
        color: 0xFF00897B,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
      monthlyBudget: 0,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-health',
        name: 'Health',
        description: 'Medicines, doctor, gym, health insurance',
        icon: 0xe548, // Icons.favorite_rounded
        color: 0xFFE53935,
        budget: 2500,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 2500,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-entertainment',
        name: 'Entertainment',
        description: 'Movies, Netflix, Spotify, games',
        icon: 0xe40a, // Icons.movie_rounded
        color: 0xFF5E35B1,
        budget: 2000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 2000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-education',
        name: 'Education',
        description: 'Tuition, courses, books, school fees',
        icon: 0xe80c, // Icons.school_rounded
        color: 0xFF3949AB,
        budget: 3000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 3000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-rent',
        name: 'Loan EMI',
        description: 'EMIs, interest, loan repayments',
        icon: 0xe88a, // Icons.home_rounded
        color: 0xFF8E24AA,
        budget: 20000,
        isBudgetActive: true,
        isDefault: true,
      ),
      monthlyBudget: 20000,
    ),
    OnboardingCategory(
      model: CategoryModel(
        id: 'seed-category-other',
        name: 'Others',
        description: 'Everything else',
        icon: 0xe6c4, // Icons.more_horiz_rounded
        color: 0xFF6F7473,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
      monthlyBudget: 0,
    ),
  ];

  /// Ids preselected on first open: the six an average user will actually use.
  static const Set<String> defaultSelected = <String>{
    'seed-category-food',
    'seed-category-groceries',
    'seed-category-transport',
    'seed-category-bills',
    'seed-category-shopping',
    'seed-category-salary',
  };

  static OnboardingCategory? byId(String id) {
    for (final OnboardingCategory category in all) {
      if (category.id == id) return category;
    }
    return null;
  }
}
