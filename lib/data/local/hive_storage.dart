import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/enum/filter_enums.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/debt_model.dart';
import '../models/debt_transaction_model.dart';
import '../models/model_codec.dart';
import '../models/transaction_model.dart';

/// Exact Hive box names used by the app.
abstract final class PaisaBoxes {
  static const String accounts = 'accounts_box';
  static const String categories = 'categories_box';
  static const String transactions = 'transactions_box';
  static const String debts = 'debts_box';
  static const String debtTransactions = 'debt_transactions_box';
  static const String settings = 'settings_box';

  static const List<String> all = <String>[
    accounts,
    categories,
    transactions,
    debts,
    debtTransactions,
    settings,
  ];
}

/// Keys persisted in [PaisaBoxes.settings].
abstract final class PaisaSettingsKeys {
  static const String onboardingComplete = 'paisa.onboarding.complete';
  static const String defaultsSeeded = 'paisa.defaults.seeded.v1';
  static const String baseCurrency = 'paisa.currency.base';
  static const String countryCode = 'paisa.country';
  static const String userName = 'paisa.user.name';
  static const String biometricLock = 'paisa.security.biometric';
}

/// Singleton storage facade over six Hive boxes.
///
/// All model values are stored as `Map<dynamic, dynamic>` instances containing
/// only Hive primitives. Reads are synchronous because Hive boxes are
/// in-memory after `init()`; writes use the asynchronous box API.
class HiveStorage {
  HiveStorage._();

  static final HiveStorage instance = HiveStorage._();

  factory HiveStorage() => instance;

  static const Uuid _uuid = Uuid();

  bool _initialized = false;
  late Box<dynamic> _accountsBox;
  late Box<dynamic> _categoriesBox;
  late Box<dynamic> _transactionsBox;
  late Box<dynamic> _debtsBox;
  late Box<dynamic> _debtTransactionsBox;
  late Box<dynamic> _settingsBox;

  bool get isInitialized => _initialized;

  String newId() => _uuid.v4();

  /// Initializes Hive and opens every named box. Safe to call more than once.
  ///
  /// `Hive.initFlutter()` resolves the application documents directory through
  /// `path_provider`, so no Android INTERNET permission is required.
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    final List<Box<dynamic>> boxes = await Future.wait<Box<dynamic>>(
      PaisaBoxes.all.map<Future<Box<dynamic>>>(_openBox).toList(),
    );
    _accountsBox = boxes[0];
    _categoriesBox = boxes[1];
    _transactionsBox = boxes[2];
    _debtsBox = boxes[3];
    _debtTransactionsBox = boxes[4];
    _settingsBox = boxes[5];
    _initialized = true;

    if (getSetting<String>(PaisaSettingsKeys.baseCurrency) == null) {
      await setSetting(PaisaSettingsKeys.baseCurrency, 'INR');
    }
    if (getSetting<String>(PaisaSettingsKeys.countryCode) == null) {
      await setSetting(PaisaSettingsKeys.countryCode, 'IN');
    }
  }

  Future<Box<dynamic>> _openBox(String name) {
    if (Hive.isBoxOpen(name)) {
      return Future<Box<dynamic>>.value(Hive.box<dynamic>(name));
    }
    return Hive.openBox<dynamic>(name);
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError(
        'HiveStorage.init() must be awaited before accessing storage.',
      );
    }
  }

  Map<dynamic, dynamic> _primitiveMap(Map<String, dynamic> map) {
    return Map<dynamic, dynamic>.from(map);
  }

  List<T> _readModels<T>(
    Box<dynamic> box,
    T Function(dynamic raw) decoder,
  ) {
    return box.values
        .where((dynamic value) => value is Map)
        .map<T>(decoder)
        .toList(growable: false);
  }

  Box<dynamic> get accountsBox {
    _requireInitialized();
    return _accountsBox;
  }

  Box<dynamic> get categoriesBox {
    _requireInitialized();
    return _categoriesBox;
  }

  Box<dynamic> get transactionsBox {
    _requireInitialized();
    return _transactionsBox;
  }

  Box<dynamic> get debtsBox {
    _requireInitialized();
    return _debtsBox;
  }

  Box<dynamic> get debtTransactionsBox {
    _requireInitialized();
    return _debtTransactionsBox;
  }

  Box<dynamic> get settingsBox {
    _requireInitialized();
    return _settingsBox;
  }

  ValueListenable<Box<dynamic>> accountsListenable() => accountsBox.listenable();
  ValueListenable<Box<dynamic>> categoriesListenable() => categoriesBox.listenable();
  ValueListenable<Box<dynamic>> transactionsListenable() =>
      transactionsBox.listenable();
  ValueListenable<Box<dynamic>> debtsListenable() => debtsBox.listenable();
  ValueListenable<Box<dynamic>> debtTransactionsListenable() =>
      debtTransactionsBox.listenable();
  ValueListenable<Box<dynamic>> settingsListenable() => settingsBox.listenable();

  Stream<BoxEvent> watchAccounts({String? key}) => accountsBox.watch(key: key);
  Stream<BoxEvent> watchCategories({String? key}) =>
      categoriesBox.watch(key: key);
  Stream<BoxEvent> watchTransactions({String? key}) =>
      transactionsBox.watch(key: key);
  Stream<BoxEvent> watchDebts({String? key}) => debtsBox.watch(key: key);
  Stream<BoxEvent> watchDebtTransactions({String? key}) =>
      debtTransactionsBox.watch(key: key);
  Stream<BoxEvent> watchSettings({String? key}) =>
      settingsBox.watch(key: key);

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  List<AccountModel> getAccounts() {
    _requireInitialized();
    final List<AccountModel> accounts =
        _readModels<AccountModel>(_accountsBox, AccountModel.fromMap);
    accounts.sort((AccountModel a, AccountModel b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return accounts;
  }

  AccountModel? getAccount(String id) {
    _requireInitialized();
    final dynamic raw = _accountsBox.get(id);
    return raw is Map ? AccountModel.fromMap(raw) : null;
  }

  AccountModel? get defaultAccount {
    final List<AccountModel> accounts = getAccounts();
    for (final AccountModel account in accounts) {
      if (account.isDefault) return account;
    }
    return accounts.isEmpty ? null : accounts.first;
  }

  Future<void> putAccount(AccountModel account) async {
    _requireInitialized();
    await _accountsBox.put(account.id, _primitiveMap(account.toMap()));
  }

  Future<void> putAccounts(Iterable<AccountModel> accounts) async {
    for (final AccountModel account in accounts) {
      await putAccount(account);
    }
  }

  Future<AccountModel> createAccount({
    required String name,
    required String bankName,
    required String number,
    required AccountType cardType,
    double initialAmount = 0,
    int color = 0xFFFBB69D,
    bool isDefault = false,
    String? id,
  }) async {
    final AccountModel account = AccountModel(
      id: id ?? newId(),
      name: name,
      bankName: bankName,
      number: number,
      cardType: cardType,
      initialAmount: initialAmount,
      color: color,
      isDefault: isDefault,
    );
    await putAccount(account);
    return account;
  }

  Future<void> setDefaultAccount(String id) async {
    for (final AccountModel account in getAccounts()) {
      await putAccount(account.copyWith(isDefault: account.id == id));
    }
  }

  Future<void> deleteAccount(String id) async {
    _requireInitialized();
    await _accountsBox.delete(id);
    final List<TransactionModel> linked = getTransactions()
        .where(
          (TransactionModel tx) =>
              tx.accountId == id || tx.toAccountId == id,
        )
        .toList(growable: false);
    for (final TransactionModel tx in linked) {
      await deleteTransaction(tx.id);
    }
    final List<DebtTransactionModel> payments = getDebtTransactions()
        .where((DebtTransactionModel payment) => payment.accountId == id)
        .toList(growable: false);
    for (final DebtTransactionModel payment in payments) {
      await deleteDebtTransaction(payment.id);
    }
  }

  Future<void> clearAccounts() async {
    _requireInitialized();
    await _accountsBox.clear();
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  List<CategoryModel> getCategories() {
    _requireInitialized();
    final List<CategoryModel> categories =
        _readModels<CategoryModel>(_categoriesBox, CategoryModel.fromMap);
    categories.sort((CategoryModel a, CategoryModel b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  CategoryModel? getCategory(String id) {
    _requireInitialized();
    final dynamic raw = _categoriesBox.get(id);
    return raw is Map ? CategoryModel.fromMap(raw) : null;
  }

  Future<void> putCategory(CategoryModel category) async {
    _requireInitialized();
    await _categoriesBox.put(category.id, _primitiveMap(category.toMap()));
  }

  Future<void> putCategories(Iterable<CategoryModel> categories) async {
    for (final CategoryModel category in categories) {
      await putCategory(category);
    }
  }

  Future<CategoryModel> createCategory({
    required String name,
    String description = '',
    required int icon,
    int color = 0xFFFBB69D,
    double budget = 0,
    bool isBudgetActive = false,
    bool isDefault = false,
    String? id,
  }) async {
    final CategoryModel category = CategoryModel(
      id: id ?? newId(),
      name: name,
      description: description,
      icon: icon,
      color: color,
      budget: budget,
      isBudgetActive: isBudgetActive,
      isDefault: isDefault,
    );
    await putCategory(category);
    return category;
  }

  Future<void> deleteCategory(String id) async {
    _requireInitialized();
    await _categoriesBox.delete(id);
    final List<TransactionModel> linked = getTransactions()
        .where((TransactionModel tx) => tx.categoryId == id)
        .toList(growable: false);
    for (final TransactionModel tx in linked) {
      await putTransaction(tx.copyWith(categoryId: null));
    }
  }

  Future<void> clearCategories() async {
    _requireInitialized();
    await _categoriesBox.clear();
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  List<TransactionModel> getTransactions() {
    _requireInitialized();
    final List<TransactionModel> transactions =
        _readModels<TransactionModel>(_transactionsBox, TransactionModel.fromMap);
    transactions.sort(
      (TransactionModel a, TransactionModel b) => b.time.compareTo(a.time),
    );
    return transactions;
  }

  TransactionModel? getTransaction(String id) {
    _requireInitialized();
    final dynamic raw = _transactionsBox.get(id);
    return raw is Map ? TransactionModel.fromMap(raw) : null;
  }

  Future<void> putTransaction(TransactionModel transaction) async {
    _requireInitialized();
    await _transactionsBox.put(
      transaction.id,
      _primitiveMap(transaction.toMap()),
    );
  }

  Future<void> putTransactions(Iterable<TransactionModel> transactions) async {
    for (final TransactionModel transaction in transactions) {
      await putTransaction(transaction);
    }
  }

  Future<TransactionModel> createTransaction({
    required String name,
    required double amount,
    required DateTime time,
    required TransactionType type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    String? description,
    String? id,
  }) async {
    final TransactionModel transaction = TransactionModel(
      id: id ?? newId(),
      name: name,
      amount: amount.abs(),
      time: time,
      type: type,
      accountId: accountId,
      toAccountId: type == TransactionType.transfer ? toAccountId : null,
      categoryId: type == TransactionType.transfer ? null : categoryId,
      description: description,
    );
    await putTransaction(transaction);
    return transaction;
  }

  Future<void> deleteTransaction(String id) async {
    _requireInitialized();
    await _transactionsBox.delete(id);
  }

  Future<void> clearTransactions() async {
    _requireInitialized();
    await _transactionsBox.clear();
  }

  List<TransactionModel> transactionsForAccount(String accountId) {
    return getTransactions()
        .where(
          (TransactionModel tx) =>
              tx.accountId == accountId || tx.toAccountId == accountId,
        )
        .toList(growable: false);
  }

  List<TransactionModel> transactionsForCategory(String categoryId) {
    return getTransactions()
        .where((TransactionModel tx) => tx.categoryId == categoryId)
        .toList(growable: false);
  }

  List<TransactionModel> transactionsBetween(
    DateTime start,
    DateTime end,
  ) {
    final DateTime normalizedStart =
        start.isBefore(end) ? start : end;
    final DateTime normalizedEnd = start.isBefore(end) ? end : start;
    return getTransactions()
        .where(
          (TransactionModel tx) =>
              !tx.time.isBefore(normalizedStart) &&
              !tx.time.isAfter(normalizedEnd),
        )
        .toList(growable: false);
  }

  DateTimeRange rangeForFilter(
    FilterExpense filter, {
    DateTime? anchor,
  }) {
    final DateTime now = anchor ?? DateTime.now();
    switch (filter) {
      case FilterExpense.daily:
        final DateTime start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 1)).subtract(
                const Duration(microseconds: 1),
              ),
        );
      case FilterExpense.weekly:
        final DateTime date = DateTime(now.year, now.month, now.day);
        final DateTime start = date.subtract(Duration(days: date.weekday - 1));
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 7)).subtract(
                const Duration(microseconds: 1),
              ),
        );
      case FilterExpense.monthly:
        final DateTime start = DateTime(now.year, now.month);
        final DateTime nextMonth = DateTime(now.year, now.month + 1);
        return DateTimeRange(
          start: start,
          end: nextMonth.subtract(const Duration(microseconds: 1)),
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

  List<TransactionModel> transactionsForFilter(
    FilterExpense filter, {
    DateTime? anchor,
  }) {
    if (filter == FilterExpense.all) return getTransactions();
    final DateTimeRange range = rangeForFilter(filter, anchor: anchor);
    return transactionsBetween(range.start, range.end);
  }

  double totalIncome({DateTime? start, DateTime? end}) {
    final Iterable<TransactionModel> transactions = start == null || end == null
        ? getTransactions()
        : transactionsBetween(start, end);
    return transactions.fold<double>(
      0,
      (double total, TransactionModel tx) =>
          total + (tx.isIncome ? tx.amount : 0),
    );
  }

  double totalExpense({DateTime? start, DateTime? end}) {
    final Iterable<TransactionModel> transactions = start == null || end == null
        ? getTransactions()
        : transactionsBetween(start, end);
    return transactions.fold<double>(
      0,
      (double total, TransactionModel tx) =>
          total + (tx.isExpense ? tx.amount : 0),
    );
  }

  double netFlow({DateTime? start, DateTime? end}) {
    return totalIncome(start: start, end: end) -
        totalExpense(start: start, end: end);
  }

  double categorySpend(
    String categoryId, {
    DateTime? start,
    DateTime? end,
  }) {
    final Iterable<TransactionModel> transactions = start == null || end == null
        ? transactionsForCategory(categoryId)
        : transactionsForCategory(categoryId)
            .where(
              (TransactionModel tx) =>
                  !tx.time.isBefore(start) && !tx.time.isAfter(end),
            );
    return transactions.fold<double>(
      0,
      (double total, TransactionModel tx) =>
          total + (tx.isExpense ? tx.amount : 0),
    );
  }

  // ---------------------------------------------------------------------------
  // Debts
  // ---------------------------------------------------------------------------

  List<DebtModel> getDebts() {
    _requireInitialized();
    final List<DebtModel> debts =
        _readModels<DebtModel>(_debtsBox, DebtModel.fromMap);
    debts.sort(
      (DebtModel a, DebtModel b) =>
          a.expiryDateTime.compareTo(b.expiryDateTime),
    );
    return debts;
  }

  DebtModel? getDebt(String id) {
    _requireInitialized();
    final dynamic raw = _debtsBox.get(id);
    return raw is Map ? DebtModel.fromMap(raw) : null;
  }

  Future<void> putDebt(DebtModel debt) async {
    _requireInitialized();
    await _debtsBox.put(debt.id, _primitiveMap(debt.toMap()));
  }

  Future<void> putDebts(Iterable<DebtModel> debts) async {
    for (final DebtModel debt in debts) {
      await putDebt(debt);
    }
  }

  Future<DebtModel> createDebt({
    required String name,
    String description = '',
    required double amount,
    required DateTime dateTime,
    required DateTime expiryDateTime,
    required DebtType debtType,
    String? id,
  }) async {
    final DebtModel debt = DebtModel(
      id: id ?? newId(),
      name: name,
      description: description,
      amount: amount.abs(),
      dateTime: dateTime,
      expiryDateTime: expiryDateTime,
      debtType: debtType,
    );
    await putDebt(debt);
    return debt;
  }

  Future<void> deleteDebt(String id) async {
    _requireInitialized();
    await _debtsBox.delete(id);
    final List<DebtTransactionModel> payments = getDebtTransactions()
        .where((DebtTransactionModel payment) => payment.parentId == id)
        .toList(growable: false);
    for (final DebtTransactionModel payment in payments) {
      await deleteDebtTransaction(payment.id);
    }
  }

  Future<void> clearDebts() async {
    _requireInitialized();
    await _debtsBox.clear();
  }

  // ---------------------------------------------------------------------------
  // Debt transactions
  // ---------------------------------------------------------------------------

  List<DebtTransactionModel> getDebtTransactions() {
    _requireInitialized();
    final List<DebtTransactionModel> payments =
        _readModels<DebtTransactionModel>(
      _debtTransactionsBox,
      DebtTransactionModel.fromMap,
    );
    payments.sort(
      (DebtTransactionModel a, DebtTransactionModel b) =>
          b.dateTime.compareTo(a.dateTime),
    );
    return payments;
  }

  DebtTransactionModel? getDebtTransaction(String id) {
    _requireInitialized();
    final dynamic raw = _debtTransactionsBox.get(id);
    return raw is Map ? DebtTransactionModel.fromMap(raw) : null;
  }

  Future<void> putDebtTransaction(DebtTransactionModel payment) async {
    _requireInitialized();
    await _debtTransactionsBox.put(
      payment.id,
      _primitiveMap(payment.toMap()),
    );
  }

  Future<void> putDebtTransactions(
    Iterable<DebtTransactionModel> payments,
  ) async {
    for (final DebtTransactionModel payment in payments) {
      await putDebtTransaction(payment);
    }
  }

  Future<DebtTransactionModel> createDebtTransaction({
    required String parentId,
    required double amount,
    required DateTime dateTime,
    required String accountId,
    String? note,
    String? id,
  }) async {
    final DebtTransactionModel payment = DebtTransactionModel(
      id: id ?? newId(),
      parentId: parentId,
      amount: amount.abs(),
      dateTime: dateTime,
      accountId: accountId,
      note: note,
    );
    await putDebtTransaction(payment);
    return payment;
  }

  Future<void> deleteDebtTransaction(String id) async {
    _requireInitialized();
    await _debtTransactionsBox.delete(id);
  }

  Future<void> clearDebtTransactions() async {
    _requireInitialized();
    await _debtTransactionsBox.clear();
  }

  List<DebtTransactionModel> debtTransactionsForDebt(String parentId) {
    return getDebtTransactions()
        .where(
          (DebtTransactionModel payment) => payment.parentId == parentId,
        )
        .toList(growable: false);
  }

  double debtPaidOrCollected(String debtId) {
    return debtTransactionsForDebt(debtId).fold<double>(
      0,
      (double total, DebtTransactionModel payment) => total + payment.amount,
    );
  }

  double debtRemaining(String debtId) {
    final DebtModel? debt = getDebt(debtId);
    if (debt == null) return 0;
    return debt.remainingAmount(debtPaidOrCollected(debtId));
  }

  // ---------------------------------------------------------------------------
  // Balances
  // ---------------------------------------------------------------------------

  double accountBalance(String accountId) {
    final AccountModel? account = getAccount(accountId);
    if (account == null) return 0;
    double balance = account.initialAmount;

    for (final TransactionModel tx in getTransactions()) {
      if (tx.accountId == accountId) {
        if (tx.isIncome) {
          balance += tx.amount;
        } else if (tx.isExpense || tx.isTransfer) {
          balance -= tx.amount;
        }
      }
      if (tx.isTransfer && tx.toAccountId == accountId) {
        balance += tx.amount;
      }
    }

    for (final DebtTransactionModel payment in getDebtTransactions()) {
      if (payment.accountId != accountId) continue;
      final DebtModel? debt = getDebt(payment.parentId);
      if (debt == null) continue;
      if (debt.isCredit) {
        balance -= payment.amount;
      } else {
        balance += payment.amount;
      }
    }

    return balance;
  }

  double totalBalance() {
    return getAccounts().fold<double>(
      0,
      (double total, AccountModel account) =>
          total + accountBalance(account.id),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings and onboarding
  // ---------------------------------------------------------------------------

  T? getSetting<T>(String key) {
    _requireInitialized();
    final dynamic value = _settingsBox.get(key);
    return value is T ? value : null;
  }

  bool boolSetting(String key, {bool fallback = false}) {
    _requireInitialized();
    final dynamic value = _settingsBox.get(key);
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return fallback;
  }

  Future<void> setSetting(String key, Object? value) async {
    _requireInitialized();
    assert(
      value == null ||
          value is String ||
          value is num ||
          value is bool ||
          value is DateTime ||
          value is List ||
          value is Map,
      'Hive settings must contain only Hive-primitive values.',
    );
    if (value == null) {
      await _settingsBox.delete(key);
      return;
    }
    final Object? primitive = value is Map
        ? Map<dynamic, dynamic>.from(value)
        : value is List
            ? List<dynamic>.from(value)
            : value;
    await _settingsBox.put(key, primitive);
  }

  Future<void> removeSetting(String key) async {
    _requireInitialized();
    await _settingsBox.delete(key);
  }

  bool get isOnboardingComplete => boolSetting(
        PaisaSettingsKeys.onboardingComplete,
      );

  Future<void> setOnboardingComplete(bool value) {
    return setSetting(PaisaSettingsKeys.onboardingComplete, value);
  }

  /// Seeds Indian-first defaults exactly once, typically from onboarding.
  Future<void> seedDefaultsIfNeeded() async {
    _requireInitialized();
    final bool alreadySeeded = boolSetting(PaisaSettingsKeys.defaultsSeeded);
    if (alreadySeeded &&
        _accountsBox.keys.isNotEmpty &&
        _categoriesBox.keys.isNotEmpty) {
      return;
    }
    await seedDefaults();
  }

  /// Writes the default account and category sets. Existing user data is never
  /// overwritten; with [force] set to true the defaults are re-inserted.
  Future<void> seedDefaults({bool force = false}) async {
    _requireInitialized();
    final bool hasAccounts = _accountsBox.keys.isNotEmpty;
    final bool hasCategories = _categoriesBox.keys.isNotEmpty;
    if (!force && hasAccounts && hasCategories) {
      await setSetting(PaisaSettingsKeys.defaultsSeeded, true);
      return;
    }

    if (!hasAccounts || force) {
      await putAccounts(_defaultAccounts());
    }
    if (!hasCategories || force) {
      await putCategories(_defaultCategories());
    }

    await setSetting(PaisaSettingsKeys.baseCurrency, 'INR');
    await setSetting(PaisaSettingsKeys.countryCode, 'IN');
    await setSetting(PaisaSettingsKeys.defaultsSeeded, true);
  }

  Future<void> completeOnboarding({bool withDefaults = true}) async {
    if (withDefaults) await seedDefaultsIfNeeded();
    await setOnboardingComplete(true);
  }

  List<AccountModel> _defaultAccounts() {
    return <AccountModel>[
      AccountModel(
        id: newId(),
        name: 'Cash Wallet',
        bankName: 'Cash in hand',
        number: '0000',
        cardType: AccountType.cash,
        initialAmount: 0,
        color: 0xFFFBB69D,
        isDefault: true,
      ),
      AccountModel(
        id: newId(),
        name: 'HDFC Savings',
        bankName: 'HDFC Bank',
        number: '1234',
        cardType: AccountType.bank,
        initialAmount: 0,
        color: 0xFF6C8CD5,
        isDefault: false,
      ),
      AccountModel(
        id: newId(),
        name: 'SBI Card',
        bankName: 'State Bank of India',
        number: '4321',
        cardType: AccountType.card,
        initialAmount: 0,
        color: 0xFF8D6E63,
        isDefault: false,
      ),
    ];
  }

  List<CategoryModel> _defaultCategories() {
    return <CategoryModel>[
      CategoryModel(
        id: newId(),
        name: 'Food & Dining',
        description: 'Restaurants, cafés, and food delivery',
        icon: Icons.restaurant.codePoint,
        color: 0xFFFBB69D,
        budget: 6000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Groceries',
        description: 'Kirana, supermarkets, and household supplies',
        icon: Icons.local_grocery_store.codePoint,
        color: 0xFF9FD8B2,
        budget: 5000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Transport',
        description: 'Auto, cab, bus, metro, and commuting',
        icon: Icons.directions_car.codePoint,
        color: 0xFF9FC3F5,
        budget: 3000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Fuel',
        description: 'Petrol, diesel, and EV charging',
        icon: Icons.local_gas_station.codePoint,
        color: 0xFFFFD39B,
        budget: 2500,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Mobile & Internet',
        description: 'Recharges, broadband, and data plans',
        icon: Icons.wifi.codePoint,
        color: 0xFFC9B6F2,
        budget: 1500,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Rent',
        description: 'Monthly house rent',
        icon: Icons.home.codePoint,
        color: 0xFFFFB8B1,
        budget: 15000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Bills & Utilities',
        description: 'Electricity, water, gas, and maintenance',
        icon: Icons.bolt.codePoint,
        color: 0xFFFFE08A,
        budget: 3000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Health & Medical',
        description: 'Medicines, consultations, and insurance',
        icon: Icons.local_hospital.codePoint,
        color: 0xFFF3AFC4,
        budget: 2500,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Education',
        description: 'School fees, books, and courses',
        icon: Icons.school.codePoint,
        color: 0xFFA9DCE8,
        budget: 4000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Shopping',
        description: 'Clothing, electronics, and household purchases',
        icon: Icons.shopping_bag.codePoint,
        color: 0xFFE0C09B,
        budget: 4000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Entertainment',
        description: 'Movies, streaming, events, and hobbies',
        icon: Icons.movie.codePoint,
        color: 0xFFBEB4F2,
        budget: 2000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Travel',
        description: 'Flights, trains, hotels, and holidays',
        icon: Icons.flight.codePoint,
        color: 0xFFA8D6C0,
        budget: 5000,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Festivals & Gifts',
        description: 'Celebrations, donations, and presents',
        icon: Icons.card_giftcard.codePoint,
        color: 0xFFFFAFC5,
        budget: 2500,
        isBudgetActive: true,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'EMI & Loans',
        description: 'Loan repayments and credit obligations',
        icon: Icons.account_balance.codePoint,
        color: 0xFFB8C2CC,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Salary',
        description: 'Monthly salary and employer credits',
        icon: Icons.payments.codePoint,
        color: 0xFF8FD6A8,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Freelance & Business',
        description: 'Consulting, side projects, and business income',
        icon: Icons.work.codePoint,
        color: 0xFFA5D8C8,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Interest & Investments',
        description: 'Savings interest, dividends, and returns',
        icon: Icons.savings.codePoint,
        color: 0xFFC3E39B,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
      CategoryModel(
        id: newId(),
        name: 'Other',
        description: 'Uncategorized entries',
        icon: Icons.more_horiz.codePoint,
        color: 0xFFBDBDBD,
        budget: 0,
        isBudgetActive: false,
        isDefault: true,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Backup, reset, and lifecycle
  // ---------------------------------------------------------------------------

  Object? _jsonSafe(Object? value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map<dynamic, dynamic>(
        (dynamic key, dynamic nested) =>
            MapEntry<dynamic, dynamic>(key.toString(), _jsonSafe(nested)),
      );
    }
    if (value is Iterable) {
      return value.map<Object?>(_jsonSafe).toList(growable: false);
    }
    return value.toString();
  }

  Map<String, dynamic> exportSnapshot() {
    _requireInitialized();
    final Map<dynamic, dynamic> rawSettings =
        Map<dynamic, dynamic>.from(_settingsBox.toMap());
    final Map<String, dynamic> snapshot = <String, dynamic>{
      'version': 1,
      'exportedAt': ModelCodec.encodeDateTime(DateTime.now()),
      'accounts': getAccounts()
          .map((AccountModel model) => model.toMap())
          .toList(growable: false),
      'categories': getCategories()
          .map((CategoryModel model) => model.toMap())
          .toList(growable: false),
      'transactions': getTransactions()
          .map((TransactionModel model) => model.toMap())
          .toList(growable: false),
      'debts': getDebts()
          .map((DebtModel model) => model.toMap())
          .toList(growable: false),
      'debtTransactions': getDebtTransactions()
          .map((DebtTransactionModel model) => model.toMap())
          .toList(growable: false),
      'settings': rawSettings.map<String, dynamic>(
        (dynamic key, dynamic value) => MapEntry<String, dynamic>(
          key.toString(),
          _jsonSafe(value) as dynamic,
        ),
      ),
    };
    return jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
  }

  Future<void> restoreSnapshot(Map<String, dynamic> snapshot) async {
    _requireInitialized();
    await clearAllData();

    Future<void> restoreList(
      String key,
      Future<void> Function(Map<dynamic, dynamic> map) writer,
    ) async {
      final dynamic raw = snapshot[key];
      if (raw is! Iterable) return;
      for (final dynamic item in raw) {
        if (item is Map) {
          await writer(Map<dynamic, dynamic>.from(item));
        }
      }
    }

    await restoreList('accounts', (Map<dynamic, dynamic> map) async {
      final AccountModel model = AccountModel.fromMap(map);
      await putAccount(model);
    });
    await restoreList('categories', (Map<dynamic, dynamic> map) async {
      final CategoryModel model = CategoryModel.fromMap(map);
      await putCategory(model);
    });
    await restoreList('transactions', (Map<dynamic, dynamic> map) async {
      final TransactionModel model = TransactionModel.fromMap(map);
      await putTransaction(model);
    });
    await restoreList('debts', (Map<dynamic, dynamic> map) async {
      final DebtModel model = DebtModel.fromMap(map);
      await putDebt(model);
    });
    await restoreList('debtTransactions', (Map<dynamic, dynamic> map) async {
      final DebtTransactionModel model = DebtTransactionModel.fromMap(map);
      await putDebtTransaction(model);
    });

    final dynamic rawSettings = snapshot['settings'];
    if (rawSettings is Map) {
      for (final MapEntry<dynamic, dynamic> entry
          in rawSettings.entries) {
        await setSetting(entry.key.toString(), _jsonSafe(entry.value));
      }
    }
  }

  Future<void> clearAllData() async {
    _requireInitialized();
    await Future.wait<int>(<Future<int>>[
      _accountsBox.clear(),
      _categoriesBox.clear(),
      _transactionsBox.clear(),
      _debtsBox.clear(),
      _debtTransactionsBox.clear(),
      _settingsBox.clear(),
    ]);
  }

  Future<void> compact() async {
    _requireInitialized();
    await Future.wait<void>(<Future<void>>[
      _accountsBox.compact(),
      _categoriesBox.compact(),
      _transactionsBox.compact(),
      _debtsBox.compact(),
      _debtTransactionsBox.compact(),
      _settingsBox.compact(),
    ]);
  }

  Future<void> close() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
  }
}
