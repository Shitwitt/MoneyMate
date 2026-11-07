import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../core/enum/filter_enums.dart';
import '../core/theme/paisa_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../data/local/hive_storage.dart';
import '../data/models/account_model.dart';
import '../data/models/category_model.dart';
import '../data/models/debt_model.dart';
import '../data/models/debt_transaction_model.dart';
import '../data/models/transaction_model.dart';

/// Settings keys owned by the reactive provider layer.
abstract final class PaisaProviderKeys {
  static const String userName = 'paisa.profile.name';
  static const String userAvatarIndex = 'paisa.profile.avatar';
  static const String customImagePath = 'paisa.profile.image';
  static const String languageCode = 'paisa.language.code';
  static const String localeTag = 'paisa.language.locale';
  static const String selectedTimeFilter = 'paisa.filters.time';
}

/// Language metadata carried over from the existing 35-language engine.
@immutable
class PaisaLanguage {
  const PaisaLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.localeTag,
    this.isRtl = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String localeTag;
  final bool isRtl;

  Locale get locale {
    final List<String> parts = localeTag
        .split(RegExp(r'[_-]'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return const Locale('en', 'US');
    if (parts.length == 1) return Locale(parts.first);
    return Locale(parts[0], parts[1]);
  }

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PaisaLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'PaisaLanguage($code, $nativeName)';
}

abstract final class PaisaLanguages {
  static const PaisaLanguage english = PaisaLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
    localeTag: 'en_IN',
  );

  static const List<PaisaLanguage> featured = <PaisaLanguage>[
    english,
    PaisaLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', localeTag: 'hi_IN'),
    PaisaLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪', localeTag: 'de_DE'),
    PaisaLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸', localeTag: 'es_ES'),
    PaisaLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷', localeTag: 'fr_FR'),
  ];

  static const List<PaisaLanguage> all = <PaisaLanguage>[
    english,
    PaisaLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸', localeTag: 'es_ES'),
    PaisaLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷', localeTag: 'fr_FR'),
    PaisaLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪', localeTag: 'de_DE'),
    PaisaLanguage(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳', localeTag: 'zh_CN'),
    PaisaLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵', localeTag: 'ja_JP'),
    PaisaLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', localeTag: 'hi_IN'),
    PaisaLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', localeTag: 'ar_SA', isRtl: true),
    PaisaLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹', localeTag: 'pt_PT'),
    PaisaLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺', localeTag: 'ru_RU'),
    PaisaLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹', localeTag: 'it_IT'),
    PaisaLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷', localeTag: 'ko_KR'),
    PaisaLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷', localeTag: 'tr_TR'),
    PaisaLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱', localeTag: 'nl_NL'),
    PaisaLanguage(code: 'pl', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱', localeTag: 'pl_PL'),
    PaisaLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩', localeTag: 'bn_BD'),
    PaisaLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳', localeTag: 'ta_IN'),
    PaisaLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳', localeTag: 'te_IN'),
    PaisaLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳', localeTag: 'mr_IN'),
    PaisaLanguage(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳', localeTag: 'gu_IN'),
    PaisaLanguage(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', flag: '🇮🇳', localeTag: 'pa_IN'),
    PaisaLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰', localeTag: 'ur_PK', isRtl: true),
    PaisaLanguage(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳', localeTag: 'kn_IN'),
    PaisaLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳', localeTag: 'ml_IN'),
    PaisaLanguage(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ', flag: '🇮🇳', localeTag: 'or_IN'),
    PaisaLanguage(code: 'as', name: 'Assamese', nativeName: 'অসমীয়া', flag: '🇮🇳', localeTag: 'as_IN'),
    PaisaLanguage(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩', localeTag: 'id_ID'),
    PaisaLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳', localeTag: 'vi_VN'),
    PaisaLanguage(code: 'th', name: 'Thai', nativeName: 'ไทย', flag: '🇹🇭', localeTag: 'th_TH'),
    PaisaLanguage(code: 'sv', name: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪', localeTag: 'sv_SE'),
    PaisaLanguage(code: 'no', name: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴', localeTag: 'nb_NO'),
    PaisaLanguage(code: 'da', name: 'Danish', nativeName: 'Dansk', flag: '🇩🇰', localeTag: 'da_DK'),
    PaisaLanguage(code: 'fi', name: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮', localeTag: 'fi_FI'),
    PaisaLanguage(code: 'el', name: 'Greek', nativeName: 'Ελληνικά', flag: '🇬🇷', localeTag: 'el_GR'),
    PaisaLanguage(code: 'he', name: 'Hebrew', nativeName: 'עברית', flag: '🇮🇱', localeTag: 'he_IL', isRtl: true),
  ];

  static final List<Locale> supportedLocales =
      all.map((PaisaLanguage language) => language.locale).toList(growable: false);

  static PaisaLanguage byCode(String? code) {
    if (code == null) return english;
    for (final PaisaLanguage language in all) {
      if (language.code == code) return language;
    }
    return english;
  }
}

/// One-tap account option shown during onboarding.
@immutable
class PaisaAccountPreset {
  const PaisaAccountPreset({
    required this.id,
    required this.name,
    required this.bankName,
    required this.number,
    required this.cardType,
    required this.color,
    this.initialAmount = 0,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String bankName;
  final String number;
  final AccountType cardType;
  final int color;
  final double initialAmount;
  final bool isDefault;

  PaisaAccountPreset copyWith({
    String? id,
    String? name,
    String? bankName,
    String? number,
    AccountType? cardType,
    int? color,
    double? initialAmount,
    bool? isDefault,
  }) {
    return PaisaAccountPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      number: number ?? this.number,
      cardType: cardType ?? this.cardType,
      color: color ?? this.color,
      initialAmount: initialAmount ?? this.initialAmount,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

abstract final class PaisaAccountPresets {
  static const List<PaisaAccountPreset> defaults = <PaisaAccountPreset>[
    PaisaAccountPreset(
      id: 'cash-wallet',
      name: 'Cash Wallet',
      bankName: 'Cash in hand',
      number: '0000',
      cardType: AccountType.cash,
      color: 0xFFFBB69D,
      initialAmount: 12500,
      isDefault: true,
    ),
    PaisaAccountPreset(
      id: 'bank-account',
      name: 'Bank Account',
      bankName: 'HDFC Bank',
      number: '4417',
      cardType: AccountType.bank,
      color: 0xFF6C8CD5,
      initialAmount: 855933.46,
      isDefault: false,
    ),
    PaisaAccountPreset(
      id: 'credit-card',
      name: 'Credit Card',
      bankName: 'State Bank of India',
      number: '7781',
      cardType: AccountType.card,
      color: 0xFF8D6E63,
      initialAmount: -18500,
      isDefault: false,
    ),
  ];
}

/// Onboarding category option, with colors and icons taken from the existing
/// MoneyMate category catalog.
@immutable
class PaisaCategoryPreset {
  const PaisaCategoryPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.color,
    required this.budget,
    required this.isBudgetActive,
    this.isIncome = false,
  });

  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final int color;
  final double budget;
  final bool isBudgetActive;
  final bool isIncome;

  PaisaCategoryPreset copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCodePoint,
    int? color,
    double? budget,
    bool? isBudgetActive,
    bool? isIncome,
  }) {
    return PaisaCategoryPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      color: color ?? this.color,
      budget: budget ?? this.budget,
      isBudgetActive: isBudgetActive ?? this.isBudgetActive,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}

abstract final class PaisaCategoryPresets {
  static const List<PaisaCategoryPreset> defaults = <PaisaCategoryPreset>[
    PaisaCategoryPreset(id: 'food', name: 'Food & Dining', description: 'Restaurants, cafés, and delivery', iconCodePoint: 0xe56c, color: 0xFFF9A825, budget: 6000, isBudgetActive: true),
    PaisaCategoryPreset(id: 'groceries', name: 'Groceries', description: 'Kirana and household supplies', iconCodePoint: 0xe59e, color: 0xFF8E24AA, budget: 5000, isBudgetActive: true),
    PaisaCategoryPreset(id: 'shopping', name: 'Shopping', description: 'Clothing, electronics, and more', iconCodePoint: 0xe8cc, color: 0xFF1E88E5, budget: 4000, isBudgetActive: true),
    PaisaCategoryPreset(id: 'transport-fuel', name: 'Transport & Fuel', description: 'Commute, fuel, and parking', iconCodePoint: 0xe1d5, color: 0xFFD32F2F, budget: 3500, isBudgetActive: true),
    PaisaCategoryPreset(id: 'bills', name: 'Bills & Utilities', description: 'Electricity, water, gas, and internet', iconCodePoint: 0xe06f, color: 0xFF009688, budget: 3000, isBudgetActive: true),
    PaisaCategoryPreset(id: 'salary', name: 'Salary', description: 'Monthly salary credits', iconCodePoint: 0xe58f, color: 0xFFAD1457, budget: 0, isBudgetActive: false, isIncome: true),
    PaisaCategoryPreset(id: 'investments', name: 'Investments', description: 'Savings interest and returns', iconCodePoint: 0xe5f8, color: 0xFF2E7D32, budget: 0, isBudgetActive: false, isIncome: true),
    PaisaCategoryPreset(id: 'health', name: 'Health', description: 'Medicines and consultations', iconCodePoint: 0xe3f3, color: 0xFFFB8C00, budget: 2500, isBudgetActive: true),
    PaisaCategoryPreset(id: 'entertainment', name: 'Entertainment', description: 'Movies, streaming, and events', iconCodePoint: 0xe02c, color: 0xFF1976D2, budget: 2000, isBudgetActive: true),
    PaisaCategoryPreset(id: 'education', name: 'Education', description: 'School fees, books, and courses', iconCodePoint: 0xe0c3, color: 0xFF8E24AA, budget: 4000, isBudgetActive: true),
    PaisaCategoryPreset(id: 'loan-emi', name: 'Loan EMI', description: 'Loan and credit repayments', iconCodePoint: 0xe04a, color: 0xFFC77800, budget: 0, isBudgetActive: false),
    PaisaCategoryPreset(id: 'others', name: 'Others', description: 'Uncategorized entries', iconCodePoint: 0xe5d3, color: 0xFFF57C00, budget: 1000, isBudgetActive: true),
  ];
}

@immutable
class PaisaPeriodSummary {
  const PaisaPeriodSummary({
    required this.filter,
    required this.range,
    required this.income,
    required this.expense,
    required this.transferTotal,
    required this.transactionCount,
  });

  final FilterExpense filter;
  final DateTimeRange range;
  final double income;
  final double expense;
  final double transferTotal;
  final int transactionCount;

  double get net => income - expense;
  double get volume => income + expense + transferTotal;
  String get label => PaisaProvider.filterLabel(filter);
}

@immutable
class PaisaCategoryBudgetInsight {
  const PaisaCategoryBudgetInsight({
    required this.category,
    required this.spend,
    required this.budget,
    required this.percentUsed,
    required this.remainingBudget,
    required this.dailyAllowance,
    required this.daysLeftInMonth,
  });

  final CategoryModel category;
  final double spend;
  final double budget;
  final double percentUsed;
  final double remainingBudget;
  final double dailyAllowance;
  final int daysLeftInMonth;

  bool get isActive => category.hasBudget;
  bool get isOverBudget => isActive && spend > budget;
  double get clampedPercent => percentUsed.clamp(0.0, 1.0).toDouble();
}

@immutable
class PaisaDebtInsight {
  const PaisaDebtInsight({
    required this.debt,
    required this.paidAmount,
    required this.remainingAmount,
    required this.progressPercentage,
  });

  final DebtModel debt;
  final double paidAmount;
  final double remainingAmount;
  final double progressPercentage;

  bool get isSettled => remainingAmount <= 0;
  bool get isLent => debt.isLent;
  bool get isCredit => debt.isCredit;
}

@immutable
class PaisaDebtPaymentResult {
  const PaisaDebtPaymentResult({
    required this.payment,
    required this.linkedTransaction,
  });

  final DebtTransactionModel payment;
  final TransactionModel linkedTransaction;
}

/// Deterministic starter records derived from the existing live-data catalog.
/// These are ordinary editable user records persisted like any other entry.
@immutable
class _SeedTransaction {
  const _SeedTransaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.dayOffset,
    required this.hour,
    required this.accountIndex,
    this.categoryName,
    this.toAccountIndex,
    this.note,
  });

  final String title;
  final double amount;
  final TransactionType type;
  final int dayOffset;
  final int hour;
  final int accountIndex;
  final String? categoryName;
  final int? toAccountIndex;
  final String? note;
}

@immutable
class _SeedDebtPayment {
  const _SeedDebtPayment({
    required this.debtIndex,
    required this.amount,
    required this.dayOffset,
    required this.accountIndex,
    required this.note,
  });

  final int debtIndex;
  final double amount;
  final int dayOffset;
  final int accountIndex;
  final String note;
}

abstract final class PaisaStarterData {
  static List<TransactionModel> buildTransactions({
    required List<AccountModel> accounts,
    required List<CategoryModel> categories,
    required DateTime now,
    required String Function() newId,
  }) {
    if (accounts.isEmpty || categories.isEmpty) {
      return <TransactionModel>[];
    }
    final List<String> accountIds =
        accounts.map((AccountModel account) => account.id).toList(growable: false);
    final Map<String, String> categoryIds = <String, String>{
      for (final CategoryModel category in categories) category.name: category.id,
    };
    final DateTime thisMonth = DateTime(now.year, now.month, 1);
    final DateTime previousMonth = DateTime(now.year, now.month - 1, 1);

    const List<_SeedTransaction> seeds = <_SeedTransaction>[
      _SeedTransaction(title: 'Monthly salary', amount: 5200, type: TransactionType.income, dayOffset: 2, hour: 9, accountIndex: 1, categoryName: 'Salary', note: 'Payroll · Raj'),
      _SeedTransaction(title: 'Freelance payout', amount: 1200, type: TransactionType.income, dayOffset: 8, hour: 16, accountIndex: 1, categoryName: 'Investments', note: 'Client · Acme Studio'),
      _SeedTransaction(title: 'Savings interest', amount: 714, type: TransactionType.income, dayOffset: 15, hour: 10, accountIndex: 1, categoryName: 'Investments', note: 'Quarterly interest'),
      _SeedTransaction(title: 'Lunch with Alice', amount: 187, type: TransactionType.expense, dayOffset: 18, hour: 13, accountIndex: 0, categoryName: 'Food & Dining', note: 'Cafe · Work'),
      _SeedTransaction(title: 'Weekly groceries', amount: 438, type: TransactionType.expense, dayOffset: 19, hour: 18, accountIndex: 0, categoryName: 'Groceries', note: 'Kirana · Home'),
      _SeedTransaction(title: 'Metro card recharge', amount: 260, type: TransactionType.expense, dayOffset: 20, hour: 8, accountIndex: 2, categoryName: 'Transport & Fuel', note: 'Commute'),
      _SeedTransaction(title: 'Mobile & broadband', amount: 320, type: TransactionType.expense, dayOffset: 21, hour: 11, accountIndex: 1, categoryName: 'Bills & Utilities', note: 'Monthly plan'),
      _SeedTransaction(title: 'Streaming subscription', amount: 299, type: TransactionType.expense, dayOffset: 22, hour: 20, accountIndex: 2, categoryName: 'Entertainment', note: 'Family plan'),
      _SeedTransaction(title: 'Medical pharmacy', amount: 221, type: TransactionType.expense, dayOffset: 23, hour: 17, accountIndex: 0, categoryName: 'Health', note: 'Chemist · Home'),
      _SeedTransaction(title: 'Weekend shopping', amount: 200, type: TransactionType.expense, dayOffset: 24, hour: 19, accountIndex: 2, categoryName: 'Shopping', note: 'Mall · Personal'),
      _SeedTransaction(title: 'Wallet to bank', amount: 2500, type: TransactionType.transfer, dayOffset: 25, hour: 12, accountIndex: 0, toAccountIndex: 1, note: 'Cash deposit'),
      _SeedTransaction(title: 'Last-month consulting', amount: 295, type: TransactionType.income, dayOffset: 6, hour: 14, accountIndex: 1, categoryName: 'Salary', note: 'Previous month'),
      _SeedTransaction(title: 'Last-month utilities', amount: 408, type: TransactionType.expense, dayOffset: 11, hour: 9, accountIndex: 1, categoryName: 'Bills & Utilities', note: 'Previous month'),
      _SeedTransaction(title: 'Last-month groceries', amount: 300, type: TransactionType.expense, dayOffset: 17, hour: 18, accountIndex: 0, categoryName: 'Groceries', note: 'Previous month'),
    ];

    return seeds.map((_SeedTransaction seed) {
      final bool previous = seed.title.startsWith('Last-month');
      final DateTime anchor = previous ? previousMonth : thisMonth;
      final DateTime time = _dateInMonth(anchor, seed.dayOffset, seed.hour, seed.note == null ? 0 : 7);
      final String accountId = accountIds[seed.accountIndex % accountIds.length];
      final String? toAccountId = seed.toAccountIndex == null
          ? null
          : accountIds[seed.toAccountIndex! % accountIds.length];
      final String? categoryId = seed.categoryName == null
          ? null
          : categoryIds[seed.categoryName] ?? categories.first.id;

      return TransactionModel(
        id: newId(),
        name: seed.title,
        amount: seed.amount,
        time: time,
        type: seed.type,
        accountId: accountId,
        toAccountId: toAccountId,
        categoryId: seed.type == TransactionType.transfer ? null : categoryId,
        description: seed.note,
      );
    }).toList(growable: false);
  }

  static List<DebtModel> buildDebts({
    required DateTime now,
    required String Function() newId,
  }) {
    return <DebtModel>[
      DebtModel(
        id: newId(),
        name: 'Home Loan',
        description: 'HDFC Bank home loan EMI',
        amount: 325000,
        dateTime: DateTime(now.year - 3, now.month, 7, 10),
        expiryDateTime: DateTime(now.year + 10, 7, 27, 18),
        debtType: DebtType.credit,
      ),
      DebtModel(
        id: newId(),
        name: 'Car Loan',
        description: 'Kotak Mahindra Bank vehicle loan',
        amount: 160000,
        dateTime: DateTime(now.year - 1, now.month, 12, 11),
        expiryDateTime: DateTime(now.year + 4, 3, 12, 18),
        debtType: DebtType.credit,
      ),
      DebtModel(
        id: newId(),
        name: 'Lent to Alice',
        description: 'Personal loan lent to a friend',
        amount: 25000,
        dateTime: DateTime(now.year, now.month - 1, 20, 15),
        expiryDateTime: DateTime(now.year, now.month + 3, 20, 18),
        debtType: DebtType.debt,
      ),
    ];
  }

  static List<_SeedDebtPayment> debtPayments(DateTime now) {
    return <_SeedDebtPayment>[
      _SeedDebtPayment(debtIndex: 0, amount: 32000, dayOffset: 5, accountIndex: 1, note: 'Home loan EMI · HDFC Bank'),
      _SeedDebtPayment(debtIndex: 0, amount: 17815, dayOffset: 16, accountIndex: 1, note: 'Home loan prepayment'),
      _SeedDebtPayment(debtIndex: 1, amount: 15600, dayOffset: 9, accountIndex: 1, note: 'Car loan EMI'),
      _SeedDebtPayment(debtIndex: 2, amount: 5000, dayOffset: 13, accountIndex: 0, note: 'Alice repayment received'),
    ];
  }

  static DateTime paymentDate(DateTime now, int dayOffset) {
    return _dateInMonth(DateTime(now.year, now.month, 1), dayOffset, 14, 30);
  }

  static DateTime _dateInMonth(
    DateTime monthAnchor,
    int day,
    int hour,
    int minute,
  ) {
    final int daysInMonth =
        DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    final int clampedDay = math.min(math.max(day, 1), daysInMonth);
    return DateTime(
      monthAnchor.year,
      monthAnchor.month,
      clampedDay,
      hour,
      minute,
    );
  }
}

/// Master reactive state and financial calculation engine.
class PaisaProvider extends ChangeNotifier {
  PaisaProvider({
    HiveStorage? storage,
    PaisaThemeEngine? themeEngine,
  })  : storage = storage ?? HiveStorage.instance,
        themeEngine = themeEngine ?? PaisaThemeEngine();

  final HiveStorage storage;
  final PaisaThemeEngine themeEngine;

  bool _initialized = false;
  bool _disposed = false;

  String _userName = '';
  int _userAvatarIndex = 0;
  String? _customImagePath;
  String _currencyCode = 'INR';
  String _localeTag = 'en_IN';
  FilterExpense _selectedTimeFilter = FilterExpense.monthly;
  bool _biometricEnabled = false;

  List<AccountModel> _accounts = const <AccountModel>[];
  List<CategoryModel> _categories = const <CategoryModel>[];
  List<TransactionModel> _transactions = const <TransactionModel>[];
  List<DebtModel> _debts = const <DebtModel>[];
  List<DebtTransactionModel> _debtTransactions =
      const <DebtTransactionModel>[];

  late final VoidCallback _storageListener = _onStorageChanged;
  late final VoidCallback _themeListener = _onThemeEngineChanged;
  final List<ValueListenable<Box<dynamic>>> _storageListeners =
      <ValueListenable<Box<dynamic>>>[];

  bool get isInitialized => _initialized;
  bool get isOnboardingComplete => storage.isOnboardingComplete;

  String get userName => _userName;
  int get userAvatarIndex => _userAvatarIndex;
  String? get customImagePath => _customImagePath;
  String get currencyCode => _currencyCode;
  CurrencyMeta get currencyMeta => CurrencyFormatter.meta(_currencyCode);
  String get currencySymbol => CurrencyFormatter.symbol(_currencyCode);
  String get localeTag => _localeTag;
  Locale get materialLocale => language.locale;
  PaisaLanguage get language => PaisaLanguages.byCode(
        storage.getSetting<String>(PaisaProviderKeys.languageCode),
      );
  PaisaThemeMode get themeMode => themeEngine.themeMode;
  bool get isAmoled => themeEngine.isAmoled;
  bool get useDynamicColor => themeEngine.useDynamicColor;
  Color get seedColor => themeEngine.seedColor;
  bool get biometricEnabled => _biometricEnabled;
  FilterExpense get selectedTimeFilter => _selectedTimeFilter;

  List<AccountModel> get accounts => _accounts;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<DebtModel> get debts => _debts;
  List<DebtTransactionModel> get debtTransactions => _debtTransactions;

  static String filterLabel(FilterExpense filter) {
    switch (filter) {
      case FilterExpense.daily:
        return 'Today';
      case FilterExpense.weekly:
        return 'This Week';
      case FilterExpense.monthly:
        return 'This Month';
      case FilterExpense.yearly:
        return 'This Year';
      case FilterExpense.all:
        return 'All Time';
    }
  }

  String get selectedTimeFilterLabel => filterLabel(_selectedTimeFilter);

  Future<void> initialize() async {
    if (_initialized) return;
    await storage.init();
    await themeEngine.load();
    _loadSettingsFromStorage();
    _refreshData();
    _attachListeners();
    _initialized = true;
    _safeNotify();
  }

  void _loadSettingsFromStorage() {
    _userName = storage.getSetting<String>(PaisaProviderKeys.userName) ?? '';
    _userAvatarIndex =
        storage.getSetting<int>(PaisaProviderKeys.userAvatarIndex) ?? 0;
    _customImagePath =
        storage.getSetting<String>(PaisaProviderKeys.customImagePath);
    _currencyCode =
        storage.getSetting<String>(PaisaSettingsKeys.baseCurrency) ?? 'INR';
    _localeTag =
        storage.getSetting<String>(PaisaProviderKeys.localeTag) ?? 'en_IN';
    _selectedTimeFilter = _filterFromName(
      storage.getSetting<String>(PaisaProviderKeys.selectedTimeFilter),
    );
    _biometricEnabled =
        storage.boolSetting(PaisaSettingsKeys.biometricLock);
  }

  FilterExpense _filterFromName(String? name) {
    if (name == null) return FilterExpense.monthly;
    for (final FilterExpense filter in FilterExpense.values) {
      if (filter.name == name) return filter;
    }
    return FilterExpense.monthly;
  }

  void _attachListeners() {
    _storageListeners
      ..add(storage.accountsListenable())
      ..add(storage.categoriesListenable())
      ..add(storage.transactionsListenable())
      ..add(storage.debtsListenable())
      ..add(storage.debtTransactionsListenable())
      ..add(storage.settingsListenable());
    for (final ValueListenable<Box<dynamic>> listenable in _storageListeners) {
      listenable.addListener(_storageListener);
    }
    themeEngine.addListener(_themeListener);
  }

  void _onStorageChanged() {
    if (!_initialized || _disposed) return;
    _refreshData();
  }

  void _onThemeEngineChanged() {
    if (_disposed) return;
    _safeNotify();
  }

  void _refreshData() {
    if (_disposed) return;
    _accounts = storage.getAccounts();
    _categories = storage.getCategories();
    _transactions = storage.getTransactions();
    _debts = storage.getDebts();
    _debtTransactions = storage.getDebtTransactions();
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final ValueListenable<Box<dynamic>> listenable in _storageListeners) {
      listenable.removeListener(_storageListener);
    }
    themeEngine.removeListener(_themeListener);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  String format(double amount, {bool showPlusSign = false}) {
    return CurrencyFormatter.format(
      amount,
      code: _currencyCode,
      showPlusSign: showPlusSign,
    );
  }

  String formatCompact(double amount) {
    return CurrencyFormatter.compact(amount, code: _currencyCode);
  }

  Future<void> setUserName(String value) async {
    _userName = value.trim();
    await storage.setSetting(PaisaProviderKeys.userName, _userName);
    _safeNotify();
  }

  Future<void> setAvatarIndex(int value) async {
    _userAvatarIndex = value.clamp(0, 11).toInt();
    _customImagePath = null;
    await storage.setSetting(
      PaisaProviderKeys.userAvatarIndex,
      _userAvatarIndex,
    );
    await storage.setSetting(PaisaProviderKeys.customImagePath, null);
    _safeNotify();
  }

  Future<void> setCustomImagePath(String? value) async {
    _customImagePath = value;
    await storage.setSetting(PaisaProviderKeys.customImagePath, value);
    _safeNotify();
  }

  Future<void> setCurrency(String code) async {
    final CurrencyMeta item = CurrencyFormatter.meta(code);
    _currencyCode = item.code;
    await storage.setSetting(PaisaSettingsKeys.baseCurrency, item.code);
    _safeNotify();
  }

  Future<void> setLanguage(PaisaLanguage language) async {
    _localeTag = language.localeTag;
    await storage.setSetting(PaisaProviderKeys.languageCode, language.code);
    await storage.setSetting(PaisaProviderKeys.localeTag, language.localeTag);
    _safeNotify();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    await storage.setSetting(PaisaSettingsKeys.biometricLock, value);
    _safeNotify();
  }

  Future<void> setSelectedTimeFilter(FilterExpense filter) async {
    _selectedTimeFilter = filter;
    await storage.setSetting(
      PaisaProviderKeys.selectedTimeFilter,
      filter.name,
    );
    _safeNotify();
  }

  Future<void> setThemeMode(PaisaThemeMode mode) async {
    await themeEngine.setThemeMode(mode);
    _safeNotify();
  }

  Future<void> setAmoled(bool value) async {
    await themeEngine.setThemeMode(
      value ? PaisaThemeMode.amoled : PaisaThemeMode.dark,
    );
    _safeNotify();
  }

  Future<void> setUseDynamicColor(bool value) async {
    await themeEngine.setUseDynamicColor(value);
    _safeNotify();
  }

  Future<void> setSeedColor(Color color) async {
    await themeEngine.setSeedColor(color);
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Period calculations
  // ---------------------------------------------------------------------------

  DateTimeRange periodRange(
    FilterExpense filter, {
    DateTime? anchor,
  }) {
    final DateTime now = anchor ?? DateTime.now();
    switch (filter) {
      case FilterExpense.daily:
        final DateTime start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(
          start: start,
          end: start
              .add(const Duration(days: 1))
              .subtract(const Duration(microseconds: 1)),
        );
      case FilterExpense.weekly:
        final DateTime date = DateTime(now.year, now.month, now.day);
        final DateTime start =
            date.subtract(Duration(days: date.weekday - 1));
        return DateTimeRange(
          start: start,
          end: start
              .add(const Duration(days: 7))
              .subtract(const Duration(microseconds: 1)),
        );
      case FilterExpense.monthly:
        final DateTime start = DateTime(now.year, now.month);
        final DateTime end = DateTime(now.year, now.month + 1);
        return DateTimeRange(
          start: start,
          end: end.subtract(const Duration(microseconds: 1)),
        );
      case FilterExpense.yearly:
        final DateTime start = DateTime(now.year);
        final DateTime end = DateTime(now.year + 1);
        return DateTimeRange(
          start: start,
          end: end.subtract(const Duration(microseconds: 1)),
        );
      case FilterExpense.all:
        return DateTimeRange(
          start: DateTime(1970),
          end: DateTime(2100, 12, 31, 23, 59, 59, 999),
        );
    }
  }

  DateTimeRange previousPeriodRange(
    FilterExpense filter, {
    DateTime? anchor,
  }) {
    final DateTimeRange current = periodRange(filter, anchor: anchor);
    if (filter == FilterExpense.all) {
      return DateTimeRange(start: DateTime(1960), end: DateTime(1969, 12, 31));
    }
    final Duration length =
        current.end.difference(current.start) + const Duration(microseconds: 1);
    return DateTimeRange(
      start: current.start.subtract(length),
      end: current.start.subtract(const Duration(microseconds: 1)),
    );
  }

  List<TransactionModel> _transactionsInRange(DateTimeRange range) {
    return _transactions
        .where(
          (TransactionModel tx) =>
              !tx.time.isBefore(range.start) && !tx.time.isAfter(range.end),
        )
        .toList(growable: false);
  }

  PaisaPeriodSummary _summaryForRange(
    FilterExpense filter,
    DateTimeRange range,
  ) {
    double income = 0;
    double expense = 0;
    double transferTotal = 0;
    int count = 0;

    for (final TransactionModel tx in _transactionsInRange(range)) {
      count++;
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expense += tx.amount;
          break;
        case TransactionType.transfer:
          // Transfers are intentionally excluded from income and expense.
          transferTotal += tx.amount;
          break;
      }
    }

    return PaisaPeriodSummary(
      filter: filter,
      range: range,
      income: income,
      expense: expense,
      transferTotal: transferTotal,
      transactionCount: count,
    );
  }

  PaisaPeriodSummary periodSummary([FilterExpense? filter]) {
    final FilterExpense effective = filter ?? _selectedTimeFilter;
    return _summaryForRange(effective, periodRange(effective));
  }

  PaisaPeriodSummary previousPeriodSummary([FilterExpense? filter]) {
    final FilterExpense effective = filter ?? _selectedTimeFilter;
    return _summaryForRange(
      effective,
      previousPeriodRange(effective),
    );
  }

  double get periodIncome => periodSummary().income;
  double get periodExpense => periodSummary().expense;
  double get periodNet => periodSummary().net;
  double get periodTransferTotal => periodSummary().transferTotal;
  String get periodIncomeFormatted => format(periodIncome);
  String get periodExpenseFormatted => format(periodExpense);
  String get periodNetFormatted => format(periodNet, showPlusSign: true);

  // ---------------------------------------------------------------------------
  // Account balances
  // ---------------------------------------------------------------------------

  AccountModel? accountById(String id) {
    for (final AccountModel account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  List<TransactionModel> transactionsForAccount(String accountId) {
    return _transactions
        .where(
          (TransactionModel tx) =>
              tx.accountId == accountId || tx.toAccountId == accountId,
        )
        .toList(growable: false);
  }

  /// Exact live balance:
  /// initial + income - expense - outgoing transfers + incoming transfers.
  ///
  /// Debt installments are already represented as linked income/expense
  /// transactions, so they are not double-counted here.
  double accountBalance(String accountId) {
    final AccountModel? account = accountById(accountId);
    if (account == null) return 0;

    double balance = account.initialAmount;
    for (final TransactionModel tx in _transactions) {
      if (tx.accountId == accountId) {
        switch (tx.type) {
          case TransactionType.income:
            balance += tx.amount;
            break;
          case TransactionType.expense:
            balance -= tx.amount;
            break;
          case TransactionType.transfer:
            balance -= tx.amount;
            break;
        }
      }
      if (tx.isTransfer && tx.toAccountId == accountId) {
        balance += tx.amount;
      }
    }
    return balance;
  }

  double get totalNetBalance {
    return _accounts.fold<double>(
      0,
      (double total, AccountModel account) =>
          total + accountBalance(account.id),
    );
  }

  String accountBalanceFormatted(String accountId) =>
      format(accountBalance(accountId));

  String get totalNetBalanceFormatted => format(totalNetBalance);
  String get totalNetBalanceCompact => formatCompact(totalNetBalance);

  List<TransactionModel> recentTransactions({int limit = 8}) {
    final List<TransactionModel> sorted =
        List<TransactionModel>.from(_transactions)
          ..sort((TransactionModel a, TransactionModel b) =>
              b.time.compareTo(a.time));
    if (sorted.length <= limit) return sorted;
    return sorted.take(limit).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Category spend and budgets
  // ---------------------------------------------------------------------------

  DateTimeRange monthRange([DateTime? anchor]) {
    final DateTime now = anchor ?? DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1)
          .subtract(const Duration(microseconds: 1)),
    );
  }

  int daysLeftInMonth([DateTime? anchor]) {
    final DateTime now = anchor ?? DateTime.now();
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day + 1;
  }

  CategoryModel? categoryById(String id) {
    for (final CategoryModel category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  double currentMonthCategorySpend(String categoryId) {
    final DateTimeRange range = monthRange();
    return _transactions
        .where(
          (TransactionModel tx) =>
              tx.isExpense &&
              tx.categoryId == categoryId &&
              !tx.time.isBefore(range.start) &&
              !tx.time.isAfter(range.end),
        )
        .fold<double>(0, (double total, TransactionModel tx) => total + tx.amount);
  }

  PaisaCategoryBudgetInsight? budgetInsight(String categoryId) {
    final CategoryModel? category = categoryById(categoryId);
    if (category == null) return null;
    final double spend = currentMonthCategorySpend(categoryId);
    final double budget = category.budget;
    final double percentUsed = budget > 0 ? spend / budget : 0;
    final double remainingBudget = budget - spend;
    final int daysLeft = daysLeftInMonth();
    final double dailyAllowance = daysLeft > 0 && remainingBudget > 0
        ? remainingBudget / daysLeft
        : 0;
    return PaisaCategoryBudgetInsight(
      category: category,
      spend: spend,
      budget: budget,
      percentUsed: percentUsed,
      remainingBudget: remainingBudget,
      dailyAllowance: dailyAllowance,
      daysLeftInMonth: daysLeft,
    );
  }

  List<PaisaCategoryBudgetInsight> get budgetInsights {
    return _categories
        .map((CategoryModel category) => budgetInsight(category.id))
        .whereType<PaisaCategoryBudgetInsight>()
        .where((PaisaCategoryBudgetInsight insight) => insight.isActive)
        .toList(growable: false);
  }

  double get totalMonthlyBudget => _categories.fold<double>(
        0,
        (double total, CategoryModel category) =>
            total + (category.hasBudget ? category.budget : 0),
      );

  double get totalMonthlyBudgetSpend => budgetInsights.fold<double>(
        0,
        (double total, PaisaCategoryBudgetInsight insight) =>
            total + insight.spend,
      );

  double get totalRemainingBudget =>
      totalMonthlyBudget - totalMonthlyBudgetSpend;

  double get overallBudgetPercentUsed {
    if (totalMonthlyBudget <= 0) return 0;
    return totalMonthlyBudgetSpend / totalMonthlyBudget;
  }

  double get totalDailyAllowance {
    final int daysLeft = daysLeftInMonth();
    if (daysLeft <= 0 || totalRemainingBudget <= 0) return 0;
    return totalRemainingBudget / daysLeft;
  }

  // ---------------------------------------------------------------------------
  // Debt and installment math
  // ---------------------------------------------------------------------------

  DebtModel? debtById(String id) {
    for (final DebtModel debt in _debts) {
      if (debt.id == id) return debt;
    }
    return null;
  }

  DebtTransactionModel? debtTransactionById(String id) {
    for (final DebtTransactionModel payment in _debtTransactions) {
      if (payment.id == id) return payment;
    }
    return null;
  }

  List<DebtTransactionModel> debtPaymentsFor(String debtId) {
    return _debtTransactions
        .where((DebtTransactionModel payment) => payment.parentId == debtId)
        .toList(growable: false);
  }

  double debtPaidAmount(String debtId) {
    return debtPaymentsFor(debtId).fold<double>(
      0,
      (double total, DebtTransactionModel payment) => total + payment.amount,
    );
  }

  double debtRemainingAmount(String debtId) {
    final DebtModel? debt = debtById(debtId);
    if (debt == null) return 0;
    return debt.amount - debtPaidAmount(debtId);
  }

  double debtProgressPercentage(String debtId) {
    final DebtModel? debt = debtById(debtId);
    if (debt == null || debt.amount <= 0) return 0;
    return (debtPaidAmount(debtId) / debt.amount).clamp(0.0, 1.0).toDouble();
  }

  PaisaDebtInsight? debtInsight(String debtId) {
    final DebtModel? debt = debtById(debtId);
    if (debt == null) return null;
    final double paid = debtPaidAmount(debtId);
    return PaisaDebtInsight(
      debt: debt,
      paidAmount: paid,
      remainingAmount: debt.amount - paid,
      progressPercentage: debt.amount > 0
          ? (paid / debt.amount).clamp(0.0, 1.0).toDouble()
          : 0,
    );
  }

  List<PaisaDebtInsight> get debtInsights {
    return _debts
        .map((DebtModel debt) => debtInsight(debt.id))
        .whereType<PaisaDebtInsight>()
        .toList(growable: false);
  }

  double get totalLent => _debts.fold<double>(
        0,
        (double total, DebtModel debt) => total + (debt.isLent ? debt.amount : 0),
      );

  double get totalBorrowed => _debts.fold<double>(
        0,
        (double total, DebtModel debt) => total + (debt.isCredit ? debt.amount : 0),
      );

  double get totalOutstandingLent => debtInsights.fold<double>(
        0,
        (double total, PaisaDebtInsight insight) =>
            total + (insight.isLent ? math.max(0, insight.remainingAmount) : 0),
      );

  double get totalOutstandingBorrowed => debtInsights.fold<double>(
        0,
        (double total, PaisaDebtInsight insight) =>
            total + (insight.isCredit ? math.max(0, insight.remainingAmount) : 0),
      );

  String _linkedTransactionId(String paymentId) => 'debt-payment-tx-$paymentId';

  String _linkedDescription(
    DebtModel debt,
    String paymentId,
    String? note,
  ) {
    final String suffix = note == null || note.trim().isEmpty
        ? ''
        : ' · ${note.trim()}';
    return 'Linked debt payment $paymentId · ${debt.name}$suffix';
  }

  String? _findCategoryIdByName(String name) {
    final String needle = name.toLowerCase();
    for (final CategoryModel category in _categories) {
      if (category.name.toLowerCase() == needle) return category.id;
    }
    for (final CategoryModel category in _categories) {
      if (category.name.toLowerCase().contains(needle)) return category.id;
    }
    return null;
  }

  String? _categoryIdForDebtPayment(DebtModel debt) {
    return debt.isCredit
        ? _findCategoryIdByName('Loan EMI')
        : _findCategoryIdByName('Salary');
  }

  void _validateDebtPaymentInputs({
    required String parentId,
    required double amount,
    required String accountId,
  }) {
    if (storage.getDebt(parentId) == null) {
      throw ArgumentError('Parent debt does not exist: $parentId');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Debt payment amount must be greater than zero.');
    }
    if (storage.getAccount(accountId) == null) {
      throw ArgumentError('Linked account does not exist: $accountId');
    }
  }

  Future<PaisaDebtPaymentResult> addDebtPayment({
    required String parentId,
    required double amount,
    required DateTime dateTime,
    required String accountId,
    String? note,
    String? id,
  }) async {
    _requireInitialized();
    _validateDebtPaymentInputs(
      parentId: parentId,
      amount: amount,
      accountId: accountId,
    );
    final DebtModel debt = storage.getDebt(parentId)!;
    final String paymentId = id ?? storage.newId();
    final bool isRepaymentReceived = debt.isLent;
    final TransactionType linkedType =
        isRepaymentReceived ? TransactionType.income : TransactionType.expense;
    final String linkedName = isRepaymentReceived
        ? 'Repayment received · ${debt.name}'
        : 'Installment paid · ${debt.name}';

    final DebtTransactionModel payment = DebtTransactionModel(
      id: paymentId,
      parentId: parentId,
      amount: amount.abs(),
      dateTime: dateTime,
      accountId: accountId,
      note: note,
    );
    final TransactionModel linkedTransaction = TransactionModel(
      id: _linkedTransactionId(paymentId),
      name: linkedName,
      amount: amount.abs(),
      time: dateTime,
      type: linkedType,
      accountId: accountId,
      toAccountId: null,
      categoryId: _categoryIdForDebtPayment(debt),
      description: _linkedDescription(debt, paymentId, note),
    );

    await storage.putDebtTransaction(payment);
    await storage.putTransaction(linkedTransaction);
    _refreshData();
    return PaisaDebtPaymentResult(
      payment: payment,
      linkedTransaction: linkedTransaction,
    );
  }

  Future<PaisaDebtPaymentResult> updateDebtPayment({
    required String paymentId,
    double? amount,
    DateTime? dateTime,
    String? accountId,
    String? note,
  }) async {
    _requireInitialized();
    final DebtTransactionModel? existing =
        storage.getDebtTransaction(paymentId);
    if (existing == null) {
      throw ArgumentError('Debt payment does not exist: $paymentId');
    }
    final DebtModel? debt = storage.getDebt(existing.parentId);
    if (debt == null) {
      throw ArgumentError('Parent debt no longer exists.');
    }
    final double effectiveAmount = amount ?? existing.amount;
    final String effectiveAccountId = accountId ?? existing.accountId;
    _validateDebtPaymentInputs(
      parentId: existing.parentId,
      amount: effectiveAmount,
      accountId: effectiveAccountId,
    );

    final DebtTransactionModel updatedPayment = existing.copyWith(
      amount: effectiveAmount,
      dateTime: dateTime ?? existing.dateTime,
      accountId: effectiveAccountId,
      note: note,
    );
    final bool isRepaymentReceived = debt.isLent;
    final TransactionType linkedType =
        isRepaymentReceived ? TransactionType.income : TransactionType.expense;
    final String linkedName = isRepaymentReceived
        ? 'Repayment received · ${debt.name}'
        : 'Installment paid · ${debt.name}';
    final TransactionModel? existingLinked =
        storage.getTransaction(_linkedTransactionId(paymentId));
    final TransactionModel baseLinked = existingLinked ??
        TransactionModel(
          id: _linkedTransactionId(paymentId),
          name: linkedName,
          amount: effectiveAmount,
          time: updatedPayment.dateTime,
          type: linkedType,
          accountId: effectiveAccountId,
          categoryId: _categoryIdForDebtPayment(debt),
          description:
              _linkedDescription(debt, paymentId, updatedPayment.note),
        );
    final TransactionModel updatedLinked = baseLinked.copyWith(
      name: linkedName,
      amount: effectiveAmount,
      time: updatedPayment.dateTime,
      type: linkedType,
      accountId: effectiveAccountId,
      categoryId: _categoryIdForDebtPayment(debt),
      description: _linkedDescription(debt, paymentId, updatedPayment.note),
    );

    await storage.putDebtTransaction(updatedPayment);
    await storage.putTransaction(updatedLinked);
    _refreshData();
    return PaisaDebtPaymentResult(
      payment: updatedPayment,
      linkedTransaction: updatedLinked,
    );
  }

  Future<void> deleteDebtPayment(String paymentId) async {
    _requireInitialized();
    await storage.deleteDebtTransaction(paymentId);
    await storage.deleteTransaction(_linkedTransactionId(paymentId));
    _refreshData();
  }

  // ---------------------------------------------------------------------------
  // CRUD wrappers
  // ---------------------------------------------------------------------------

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('PaisaProvider.initialize() must be awaited first.');
    }
  }

  Future<void> addAccount(AccountModel account) async {
    _requireInitialized();
    await storage.putAccount(account);
    _refreshData();
  }

  Future<void> updateAccount(AccountModel account) => addAccount(account);

  Future<void> deleteAccount(String id) async {
    _requireInitialized();
    await storage.deleteAccount(id);
    _refreshData();
  }

  Future<void> setDefaultAccount(String id) async {
    _requireInitialized();
    await storage.setDefaultAccount(id);
    _refreshData();
  }

  Future<void> addCategory(CategoryModel category) async {
    _requireInitialized();
    await storage.putCategory(category);
    _refreshData();
  }

  Future<void> updateCategory(CategoryModel category) => addCategory(category);

  Future<void> deleteCategory(String id) async {
    _requireInitialized();
    await storage.deleteCategory(id);
    _refreshData();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    _requireInitialized();
    await storage.putTransaction(transaction);
    _refreshData();
  }

  Future<void> updateTransaction(TransactionModel transaction) =>
      addTransaction(transaction);

  Future<void> deleteTransaction(String id) async {
    _requireInitialized();
    await storage.deleteTransaction(id);
    _refreshData();
  }

  Future<TransactionModel> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime time,
    String name = 'Account transfer',
    String? description,
    String? id,
  }) async {
    _requireInitialized();
    final TransactionModel transaction = TransactionModel(
      id: id ?? storage.newId(),
      name: name,
      amount: amount.abs(),
      time: time,
      type: TransactionType.transfer,
      accountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: null,
      description: description,
    );
    await addTransaction(transaction);
    return transaction;
  }

  Future<void> addDebt(DebtModel debt) async {
    _requireInitialized();
    await storage.putDebt(debt);
    _refreshData();
  }

  Future<void> updateDebt(DebtModel debt) => addDebt(debt);

  Future<void> deleteDebt(String id) async {
    _requireInitialized();
    await storage.deleteDebt(id);
    _refreshData();
  }

  Future<void> clearAllData() async {
    _requireInitialized();
    await storage.clearAllData();
    _loadSettingsFromStorage();
    _refreshData();
  }

  Map<String, dynamic> exportSnapshot() {
    _requireInitialized();
    return storage.exportSnapshot();
  }

  Future<void> restoreSnapshot(Map<String, dynamic> snapshot) async {
    _requireInitialized();
    await storage.restoreSnapshot(snapshot);
    _loadSettingsFromStorage();
    _refreshData();
  }

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  List<AccountModel> _accountModelsFromPresets(
    List<PaisaAccountPreset> presets,
  ) {
    return presets.map((PaisaAccountPreset preset) {
      return AccountModel(
        id: storage.newId(),
        name: preset.name,
        bankName: preset.bankName,
        number: preset.number,
        cardType: preset.cardType,
        initialAmount: preset.initialAmount,
        color: preset.color,
        isDefault: preset.isDefault,
      );
    }).toList(growable: false);
  }

  List<CategoryModel> _categoryModelsFromPresets(
    List<PaisaCategoryPreset> presets,
  ) {
    return presets.map((PaisaCategoryPreset preset) {
      return CategoryModel(
        id: storage.newId(),
        name: preset.name,
        description: preset.description,
        icon: preset.iconCodePoint,
        color: preset.color,
        budget: preset.budget,
        isBudgetActive: preset.isBudgetActive,
        isDefault: true,
      );
    }).toList(growable: false);
  }

  Future<void> _clearUserRecords() async {
    await Future.wait<int>(<Future<int>>[
      storage.clearAccounts(),
      storage.clearCategories(),
      storage.clearTransactions(),
      storage.clearDebts(),
      storage.clearDebtTransactions(),
    ]);
  }

  Future<void> _seedStarterData({
    required List<AccountModel> accounts,
    required List<CategoryModel> categories,
    required DateTime now,
  }) async {
    final List<TransactionModel> starterTransactions =
        PaisaStarterData.buildTransactions(
      accounts: accounts,
      categories: categories,
      now: now,
      newId: storage.newId,
    );
    await storage.putTransactions(starterTransactions);

    final List<DebtModel> starterDebts = PaisaStarterData.buildDebts(
      now: now,
      newId: storage.newId,
    );
    await storage.putDebts(starterDebts);

    final List<String> accountIds =
        accounts.map((AccountModel account) => account.id).toList(growable: false);
    for (final _SeedDebtPayment seed
        in PaisaStarterData.debtPayments(now)) {
      if (seed.debtIndex >= starterDebts.length) continue;
      await addDebtPayment(
        parentId: starterDebts[seed.debtIndex].id,
        amount: seed.amount,
        dateTime: PaisaStarterData.paymentDate(now, seed.dayOffset),
        accountId: accountIds[seed.accountIndex % accountIds.length],
        note: seed.note,
      );
    }
  }

  Future<void> completeOnboarding({
    required String userName,
    required int avatarIndex,
    String? customImagePath,
    required PaisaLanguage language,
    required String currencyCode,
    required List<PaisaAccountPreset> accounts,
    required List<PaisaCategoryPreset> categories,
    bool seedStarterData = true,
  }) async {
    if (!_initialized) await initialize();
    if (userName.trim().isEmpty) {
      throw ArgumentError('User name is required.');
    }
    if (accounts.isEmpty) {
      throw ArgumentError('Select at least one account.');
    }
    if (categories.isEmpty) {
      throw ArgumentError('Select at least one category.');
    }
    if (!accounts.any((PaisaAccountPreset account) => account.isDefault)) {
      accounts = <PaisaAccountPreset>[
        accounts.first.copyWith(isDefault: true),
        ...accounts.skip(1),
      ];
    }

    await _clearUserRecords();
    final List<AccountModel> accountModels =
        _accountModelsFromPresets(accounts);
    final List<CategoryModel> categoryModels =
        _categoryModelsFromPresets(categories);
    await storage.putAccounts(accountModels);
    await storage.putCategories(categoryModels);

    await setUserName(userName);
    await setAvatarIndex(avatarIndex);
    await setCustomImagePath(customImagePath);
    await setLanguage(language);
    await setCurrency(currencyCode);
    await storage.setSetting(PaisaSettingsKeys.countryCode, 'IN');
    await storage.setSetting(PaisaSettingsKeys.defaultsSeeded, true);
    await storage.setSetting(
      PaisaProviderKeys.selectedTimeFilter,
      FilterExpense.monthly.name,
    );
    _selectedTimeFilter = FilterExpense.monthly;

    if (seedStarterData) {
      await _seedStarterData(
        accounts: accountModels,
        categories: categoryModels,
        now: DateTime.now(),
      );
    }

    await storage.completeOnboarding(withDefaults: false);
    _refreshData();
  }

  Future<void> resetOnboarding() async {
    _requireInitialized();
    await storage.setOnboardingComplete(false);
    _safeNotify();
  }
}
