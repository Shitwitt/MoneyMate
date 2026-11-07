import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/default_data.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/debt_model.dart';
import '../models/debt_summary.dart';
import '../models/debt_transaction_model.dart';
import '../models/settings_model.dart';
import '../models/transaction_model.dart';

/// Result of [HiveStorage.seedDefaults].
@immutable
class SeedResult {
  const SeedResult({
    required this.accountsSeeded,
    required this.categoriesSeeded,
    required this.incomeCategoriesSeeded,
  });

  final int accountsSeeded;
  final int categoriesSeeded;
  final int incomeCategoriesSeeded;

  bool get didChange =>
      accountsSeeded > 0 ||
      categoriesSeeded > 0 ||
      incomeCategoriesSeeded > 0;

  @override
  String toString() =>
      'SeedResult(accounts: $accountsSeeded, categories: $categoriesSeeded, income: $incomeCategoriesSeeded)';
}

/// One box's worth of records, used by backup / restore.
@immutable
class BackupPayload {
  const BackupPayload({
    required this.createdAt,
    required this.schemaVersion,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.debts,
    required this.debtTransactions,
    required this.settings,
  });

  final DateTime createdAt;
  final int schemaVersion;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> debts;
  final List<Map<String, dynamic>> debtTransactions;
  final Map<String, dynamic> settings;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'app': 'moneymate',
      'package': 'dev.hemanths.paisa',
      'createdAt': createdAt.toIso8601String(),
      'schemaVersion': schemaVersion,
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'debts': debts,
      'debtTransactions': debtTransactions,
      'settings': settings,
    };
  }

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> readList(Object? raw) {
      if (raw is! List) return <Map<String, dynamic>>[];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> entry) =>
              Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }

    return BackupPayload(
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      schemaVersion: json['schemaVersion'] is num
          ? (json['schemaVersion'] as num).toInt()
          : SettingsModel.currentSchemaVersion,
      accounts: readList(json['accounts']),
      categories: readList(json['categories']),
      transactions: readList(json['transactions']),
      debts: readList(json['debts']),
      debtTransactions: readList(json['debtTransactions']),
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'] as Map<dynamic, dynamic>)
          : <String, dynamic>{},
    );
  }

  int get totalRecords =>
      accounts.length +
      categories.length +
      transactions.length +
      debts.length +
      debtTransactions.length;
}

/// The single gateway to every local Hive box.
///
/// Design notes:
///  * **No code generation.** Records are stored as `Map<String, dynamic>`
///    value objects, so the app compiles without `build_runner`. The model
///    classes own the schema through their `toMap` / `fromMap` pair.
///  * **Lazy open.** Boxes are opened once in [init]; every accessor asserts
///    they are open so a mis-ordered `main()` fails loudly instead of silently
///    writing to a stale box.
///  * **Totals are pure.** Balance maths never mutates storage; it derives from
///    the records plus each account's `initialAmount`.
class HiveStorage {
  HiveStorage._();

  /// Global instance — the app is single-user and fully offline.
  static final HiveStorage instance = HiveStorage._();

  // ---------------------------------------------------------------------
  // Box names
  // ---------------------------------------------------------------------

  static const String accountsBoxName = 'accounts_box';
  static const String categoriesBoxName = 'categories_box';
  static const String transactionsBoxName = 'transactions_box';
  static const String debtsBoxName = 'debts_box';
  static const String debtTransactionsBoxName = 'debt_transactions_box';
  static const String settingsBoxName = 'settings_box';

  /// Every box the app owns, in backup order.
  static const List<String> boxNames = <String>[
    accountsBoxName,
    categoriesBoxName,
    transactionsBoxName,
    debtsBoxName,
    debtTransactionsBoxName,
    settingsBoxName,
  ];

  Box<Map>? _accountsBox;
  Box<Map>? _categoriesBox;
  Box<Map>? _transactionsBox;
  Box<Map>? _debtsBox;
  Box<Map>? _debtTransactionsBox;
  Box<dynamic>? _settingsBox;

  bool _initialized = false;

  /// True once [init] has completed.
  bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------

  /// Initialises Hive and opens every box.
  ///
  /// [subdirectory] isolates the data of desktop builds and secondary
  /// instances. [directoryOverride] points Hive at an explicit absolute
  /// directory instead of the platform app-documents folder — that is what
  /// widget/unit tests use, since `path_provider` has no plugin in a test
  /// binding.
  ///
  /// Safe to call more than once — a second call is a no-op.
  Future<void> init({String? subdirectory, String? directoryOverride}) async {
    if (_initialized) return;

    if (directoryOverride != null && directoryOverride.isNotEmpty) {
      Hive.init(directoryOverride);
    } else if (subdirectory == null || subdirectory.isEmpty) {
      await Hive.initFlutter();
    } else {
      await Hive.initFlutter(subdirectory);
    }

    _accountsBox = await Hive.openBox<Map>(accountsBoxName);
    _categoriesBox = await Hive.openBox<Map>(categoriesBoxName);
    _transactionsBox = await Hive.openBox<Map>(transactionsBoxName);
    _debtsBox = await Hive.openBox<Map>(debtsBoxName);
    _debtTransactionsBox = await Hive.openBox<Map>(debtTransactionsBoxName);
    // The settings box is untyped: it holds the settings record *and*
    // small primitive flags (last opened date, biometric prompt state, …).
    _settingsBox = await Hive.openBox(settingsBoxName);

    _initialized = true;
  }

  /// Closes every box (used before restoring a backup and in tests).
  Future<void> close() async {
    await Hive.close();
    _accountsBox = null;
    _categoriesBox = null;
    _transactionsBox = null;
    _debtsBox = null;
    _debtTransactionsBox = null;
    _settingsBox = null;
    _initialized = false;
  }

  /// Wipes every record but keeps the boxes open. Used by "Reset app" and
  /// before restoring a backup.
  Future<void> clearAll() async {
    await Future.wait(<Future<void>>[
      accounts.clear(),
      categories.clear(),
      transactions.clear(),
      debts.clear(),
      debtTransactions.clear(),
      settingsBox.clear(),
    ]);
  }

  // ---------------------------------------------------------------------
  // Box accessors
  // ---------------------------------------------------------------------

  Box<Map> get accounts => _require(_accountsBox, accountsBoxName);
  Box<Map> get categories => _require(_categoriesBox, categoriesBoxName);
  Box<Map> get transactions =>
      _require(_transactionsBox, transactionsBoxName);
  Box<Map> get debts => _require(_debtsBox, debtsBoxName);
  Box<Map> get debtTransactions =>
      _require(_debtTransactionsBox, debtTransactionsBoxName);
  Box<dynamic> get settingsBox => _require(_settingsBox, settingsBoxName);

  Box<T> _require<T>(Box<T>? box, String name) {
    if (box == null || !box.isOpen) {
      throw StateError(
        'Hive box "$name" is not open. Call HiveStorage.instance.init() '
        'before using the repository.',
      );
    }
    return box;
  }

  /// Every raw record, used by backup.
  Map<String, List<Map<String, dynamic>>> exportRaw() {
    List<Map<String, dynamic>> read(Box<Map> box) {
      return box.values
          .map((Map record) => Map<String, dynamic>.from(record))
          .toList(growable: false);
    }

    return <String, List<Map<String, dynamic>>>{
      accountsBoxName: read(accounts),
      categoriesBoxName: read(categories),
      transactionsBoxName: read(transactions),
      debtsBoxName: read(debts),
      debtTransactionsBoxName: read(debtTransactions),
    };
  }

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  /// The single settings record; returns defaults when nothing is stored yet.
  SettingsModel loadSettings() {
    final Object? raw = settingsBox.get(SettingsModel.storageKey);
    if (raw is! Map) {
      return SettingsModel(installedAt: DateTime.now());
    }
    return SettingsModel.fromMap(raw);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await settingsBox.put(SettingsModel.storageKey, settings.toMap());
  }

  /// Reads a free-form flag from the settings box.
  T? readFlag<T>(String key) {
    final Object? value = settingsBox.get(key);
    return value is T ? value : null;
  }

  /// Writes a free-form flag into the settings box.
  Future<void> writeFlag(String key, Object? value) async {
    await settingsBox.put(key, value);
  }

  Future<void> deleteFlag(String key) async {
    await settingsBox.delete(key);
  }

  // ---------------------------------------------------------------------
  // ACCOUNTS
  // ---------------------------------------------------------------------

  /// All accounts, default account first, then alphabetical by title.
  List<AccountModel> getAccounts() {
    final List<AccountModel> result = accounts.values
        .map((Map raw) => AccountModel.fromMap(raw))
        .toList(growable: true);
    result.sort((AccountModel a, AccountModel b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return result;
  }

  AccountModel? getAccount(String id) {
    final Map? raw = accounts.get(id);
    return raw == null ? null : AccountModel.fromMap(raw);
  }

  /// The account flagged as default, falling back to the first account.
  AccountModel? getDefaultAccount() {
    final List<AccountModel> all = getAccounts();
    if (all.isEmpty) return null;
    for (final AccountModel account in all) {
      if (account.isDefault) return account;
    }
    return all.first;
  }

  /// Inserts or updates an account. If [account] is flagged default every other
  /// account is un-flagged so exactly one default always exists.
  Future<void> saveAccount(AccountModel account) async {
    if (account.isDefault) {
      await _clearDefaultAccountFlag(exceptId: account.id);
    }
    await accounts.put(account.id, account.toMap());
  }

  /// Adds a new account, promoting it to default when it is the first one.
  Future<AccountModel> addAccount(AccountModel account) async {
    final AccountModel prepared = accounts.isEmpty
        ? account.copyWith(isDefault: true)
        : account;
    await saveAccount(prepared);
    return prepared;
  }

  /// Marks [id] as the default account.
  Future<void> setDefaultAccount(String id) async {
    final AccountModel? target = getAccount(id);
    if (target == null) return;
    await _clearDefaultAccountFlag(exceptId: id);
    await accounts.put(id, target.copyWith(isDefault: true).toMap());
  }

  Future<void> _clearDefaultAccountFlag({required String exceptId}) async {
    final Map<String, Map> updates = <String, Map>{};
    for (final MapEntry<dynamic, Map> entry in accounts.toMap().entries) {
      final String key = entry.key.toString();
      if (key == exceptId) continue;
      final AccountModel model = AccountModel.fromMap(entry.value);
      if (!model.isDefault) continue;
      updates[key] = model.copyWith(isDefault: false).toMap();
    }
    if (updates.isEmpty) return;
    await accounts.putAll(updates);
  }

  /// Deletes an account. Transactions and installments that reference it are
  /// deleted too, so no orphan rows can inflate balances later.
  Future<int> deleteAccount(String id) async {
    final List<dynamic> orphanTransactions = <dynamic>[
      for (final MapEntry<dynamic, Map> entry in transactions.toMap().entries)
        if (_transactionTouchesAccount(
          TransactionModel.fromMap(entry.value),
          id,
        ))
          entry.key,
    ];
    final List<dynamic> orphanInstallments = <dynamic>[
      for (final MapEntry<dynamic, Map> entry
          in debtTransactions.toMap().entries)
        if (DebtTransactionModel.fromMap(entry.value).accountId == id)
          entry.key,
    ];

    if (orphanTransactions.isNotEmpty) {
      await transactions.deleteAll(orphanTransactions);
    }
    if (orphanInstallments.isNotEmpty) {
      await debtTransactions.deleteAll(orphanInstallments);
    }
    await accounts.delete(id);

    // Never leave the app without a default account.
    final List<AccountModel> remaining = getAccounts();
    if (remaining.isNotEmpty && !remaining.any((AccountModel a) => a.isDefault)) {
      await setDefaultAccount(remaining.first.id);
    }
    return orphanTransactions.length + orphanInstallments.length;
  }

  static bool _transactionTouchesAccount(
    TransactionModel transaction,
    String accountId,
  ) {
    return transaction.accountId == accountId ||
        transaction.toAccountId == accountId;
  }

  /// Live balance per account: opening balance plus every transaction and debt
  /// installment that touched it.
  Map<String, double> getAccountBalances() {
    final Map<String, double> balances = <String, double>{
      for (final AccountModel account in getAccounts())
        account.id: account.initialAmount,
    };

    for (final Map raw in transactions.values) {
      final TransactionModel transaction = TransactionModel.fromMap(raw);
      void apply(String accountId, double delta) {
        if (!balances.containsKey(accountId)) return;
        balances[accountId] = balances[accountId]! + delta;
      }

      switch (transaction.type) {
        case TransactionType.expense:
          apply(transaction.accountId, -transaction.amount);
        case TransactionType.income:
          apply(transaction.accountId, transaction.amount);
        case TransactionType.transfer:
          // Money leaves one account and lands in another; whichever side is
          // missing from the balance map is simply skipped, never created.
          apply(transaction.accountId, -transaction.amount);
          final String? destination = transaction.toAccountId;
          apply(destination ?? '', transaction.amount);
      }
    }

    // Debt installments move real money: borrowed money is repaid from an
    // account, lent money comes back into one.
    final Map<String, DebtModel> debtById = <String, DebtModel>{
      for (final DebtModel debt in getDebts()) debt.id: debt,
    };
    for (final Map raw in debtTransactions.values) {
      final DebtTransactionModel installment =
          DebtTransactionModel.fromMap(raw);
      final DebtModel? debt = debtById[installment.parentId];
      if (debt == null) continue;
      final double delta = debt.debtType == DebtType.credit
          ? -installment.amount
          : installment.amount;
      if (!balances.containsKey(installment.accountId)) continue;
      balances[installment.accountId] =
          balances[installment.accountId]! + delta;
    }

    return balances;
  }

  /// Current balance for a single account.
  double getAccountBalance(String accountId) =>
      getAccountBalances()[accountId] ?? 0;

  /// Total across every account (transfers net to zero, so they never inflate
  /// the total).
  double getTotalBalance() {
    final Map<String, double> balances = getAccountBalances();
    return balances.values.fold<double>(0, (double sum, double value) => sum + value);
  }

  // ---------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------

  /// All categories, ordered by name.
  ///
  /// Pass `excludeIncome: true` for the expense category picker so `Salary` and
  /// `Refunds` never show up while logging a spend.
  List<CategoryModel> getCategories({bool excludeIncome = false}) {
    final List<CategoryModel> result = categories.values
        .map((Map raw) => CategoryModel.fromMap(raw))
        .toList(growable: true);
    result.sort(
      (CategoryModel a, CategoryModel b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    if (!excludeIncome) return result;
    final Set<String> incomeIds = DefaultData.incomeCategories
        .map((CategoryModel category) => category.id)
        .toSet();
    return result
        .where((CategoryModel category) => !incomeIds.contains(category.id))
        .toList(growable: false);
  }

  CategoryModel? getCategory(String id) {
    final Map? raw = categories.get(id);
    return raw == null ? null : CategoryModel.fromMap(raw);
  }

  /// First category whose name matches [name] (case-insensitive), used when
  /// importing spreadsheets that carry names instead of ids.
  CategoryModel? findCategoryByName(String name) {
    final String needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final CategoryModel category in getCategories()) {
      if (category.name.toLowerCase() == needle) return category;
    }
    return null;
  }

  Future<void> saveCategory(CategoryModel category) async {
    await categories.put(category.id, category.toMap());
  }

  /// Persists several categories at once (bulk import / seeding).
  Future<void> saveCategories(Iterable<CategoryModel> items) async {
    final Map<String, Map<String, dynamic>> batch = <String, Map<String, dynamic>>{
      for (final CategoryModel item in items) item.id: item.toMap(),
    };
    if (batch.isEmpty) return;
    await categories.putAll(batch);
  }

  /// Deletes a category.
  ///
  /// Transactions that used it are kept but detached (`categoryId` cleared) so
  /// no spending history is ever lost.
  Future<int> deleteCategory(String id) async {
    final Map<String, Map<String, dynamic>> updates =
        <String, Map<String, dynamic>>{};
    for (final MapEntry<dynamic, Map> entry in transactions.toMap().entries) {
      final TransactionModel transaction = TransactionModel.fromMap(entry.value);
      if (transaction.categoryId != id) continue;
      updates[entry.key.toString()] =
          transaction.copyWith(clearCategory: true).toMap();
    }
    if (updates.isNotEmpty) {
      await transactions.putAll(updates);
    }
    await categories.delete(id);
    return updates.length;
  }

  // ---------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------

  /// Every transaction, newest first.
  List<TransactionModel> getTransactions() {
    final List<TransactionModel> result = transactions.values
        .map((Map raw) => TransactionModel.fromMap(raw))
        .toList(growable: true);
    _sortTransactions(result);
    return result;
  }

  TransactionModel? getTransaction(String id) {
    final Map? raw = transactions.get(id);
    return raw == null ? null : TransactionModel.fromMap(raw);
  }

  /// Newest first, ties broken by title for a stable order.
  static void _sortTransactions(List<TransactionModel> items) {
    items.sort((TransactionModel a, TransactionModel b) {
      final int byTime = b.time.compareTo(a.time);
      if (byTime != 0) return byTime;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  /// Transactions inside an inclusive date range, newest first.
  List<TransactionModel> getTransactionsBetween(
    DateTime start,
    DateTime end, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
  }) {
    final DateTime from = DateTime(start.year, start.month, start.day);
    final DateTime to = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
    );
    final List<TransactionModel> result = <TransactionModel>[];
    for (final Map raw in transactions.values) {
      final TransactionModel transaction = TransactionModel.fromMap(raw);
      if (transaction.time.isBefore(from) || transaction.time.isAfter(to)) {
        continue;
      }
      if (type != null && transaction.type != type) continue;
      if (accountId != null &&
          !_transactionTouchesAccount(transaction, accountId)) {
        continue;
      }
      if (categoryId != null && transaction.categoryId != categoryId) continue;
      result.add(transaction);
    }
    _sortTransactions(result);
    return result;
  }

  /// Transactions in the window described by [filter], relative to [now].
  List<TransactionModel> getTransactionsForFilter(
    FilterExpense filter, {
    DateTime? now,
  }) {
    final (DateTime, DateTime) range = dateRangeForFilter(filter, now: now);
    return getTransactionsBetween(range.$1, range.$2);
  }

  /// Computes the inclusive `(start, end)` window for a [FilterExpense].
  ///
  /// Weeks honour the Monday-start convention used across India.
  (DateTime, DateTime) dateRangeForFilter(
    FilterExpense filter, {
    DateTime? now,
  }) {
    final DateTime reference = now ?? DateTime.now();
    final DateTime today =
        DateTime(reference.year, reference.month, reference.day);
    switch (filter) {
      case FilterExpense.daily:
        return (today, today);
      case FilterExpense.weekly:
        final int weekday = today.weekday; // Mon = 1 … Sun = 7
        final DateTime start = today.subtract(Duration(days: weekday - 1));
        return (start, start.add(const Duration(days: 6)));
      case FilterExpense.monthly:
        final DateTime start = DateTime(today.year, today.month);
        final DateTime end = DateTime(today.year, today.month + 1, 0);
        return (start, end);
      case FilterExpense.yearly:
        return (DateTime(today.year), DateTime(today.year, 12, 31));
      case FilterExpense.all:
        return (DateTime(1970), DateTime(9999, 12, 31));
    }
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    await transactions.put(transaction.id, transaction.toMap());
  }

  Future<void> saveTransactions(Iterable<TransactionModel> items) async {
    final Map<String, Map<String, dynamic>> batch = <String, Map<String, dynamic>>{
      for (final TransactionModel item in items) item.id: item.toMap(),
    };
    if (batch.isEmpty) return;
    await transactions.putAll(batch);
  }

  Future<void> deleteTransaction(String id) async {
    await transactions.delete(id);
  }

  /// Sum of amounts matching an optional type / category / account.
  double sumTransactions({
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateTime? start,
    DateTime? end,
  }) {
    double total = 0;
    for (final Map raw in transactions.values) {
      final TransactionModel transaction = TransactionModel.fromMap(raw);
      if (type != null && transaction.type != type) continue;
      if (categoryId != null && transaction.categoryId != categoryId) continue;
      if (accountId != null &&
          !_transactionTouchesAccount(transaction, accountId)) {
        continue;
      }
      if (start != null && transaction.time.isBefore(start)) continue;
      if (end != null && transaction.time.isAfter(end)) continue;
      total += transaction.amount;
    }
    return total;
  }

  /// Spend per category in a window — powers the pie chart.
  Map<String, double> spendingByCategory({
    DateTime? start,
    DateTime? end,
    TransactionType type = TransactionType.expense,
  }) {
    final Map<String, double> totals = <String, double>{};
    for (final Map raw in transactions.values) {
      final TransactionModel transaction = TransactionModel.fromMap(raw);
      if (transaction.type != type) continue;
      if (start != null && transaction.time.isBefore(start)) continue;
      if (end != null && transaction.time.isAfter(end)) continue;
      final String key = transaction.categoryId ?? 'uncategorised';
      totals[key] = (totals[key] ?? 0) + transaction.amount;
    }
    return totals;
  }

  // ---------------------------------------------------------------------
  // DEBTS
  // ---------------------------------------------------------------------

  /// Every debt, soonest due first.
  List<DebtModel> getDebts() {
    final List<DebtModel> result = debts.values
        .map((Map raw) => DebtModel.fromMap(raw))
        .toList(growable: true);
    result.sort(
      (DebtModel a, DebtModel b) =>
          a.expiryDateTime.compareTo(b.expiryDateTime),
    );
    return result;
  }

  /// Debts of one type (lent or borrowed).
  List<DebtModel> getDebtsByType(DebtType type) => getDebts()
      .where((DebtModel debt) => debt.debtType == type)
      .toList(growable: false);

  DebtModel? getDebt(String id) {
    final Map? raw = debts.get(id);
    return raw == null ? null : DebtModel.fromMap(raw);
  }

  Future<void> saveDebt(DebtModel debt) async {
    await debts.put(debt.id, debt.toMap());
  }

  /// Deletes a debt and every installment recorded against it.
  Future<int> deleteDebt(String id) async {
    final List<dynamic> installments = <dynamic>[
      for (final MapEntry<dynamic, Map> entry in debtTransactions.toMap().entries)
        if (DebtTransactionModel.fromMap(entry.value).parentId == id) entry.key,
    ];
    if (installments.isNotEmpty) {
      await debtTransactions.deleteAll(installments);
    }
    await debts.delete(id);
    return installments.length;
  }

  // ---------------------------------------------------------------------
  // DEBT INSTALLMENTS
  // ---------------------------------------------------------------------

  /// Every installment, newest first.
  List<DebtTransactionModel> getDebtTransactions() {
    final List<DebtTransactionModel> result = debtTransactions.values
        .map((Map raw) => DebtTransactionModel.fromMap(raw))
        .toList(growable: true);
    result.sort(
      (DebtTransactionModel a, DebtTransactionModel b) =>
          b.dateTime.compareTo(a.dateTime),
    );
    return result;
  }

  /// Installments of a single debt, newest first.
  List<DebtTransactionModel> getDebtTransactionsFor(String debtId) {
    return getDebtTransactions()
        .where((DebtTransactionModel item) => item.parentId == debtId)
        .toList(growable: false);
  }

  DebtTransactionModel? getDebtTransaction(String id) {
    final Map? raw = debtTransactions.get(id);
    return raw == null ? null : DebtTransactionModel.fromMap(raw);
  }

  Future<void> saveDebtTransaction(DebtTransactionModel item) async {
    await debtTransactions.put(item.id, item.toMap());
  }

  Future<void> deleteDebtTransaction(String id) async {
    await debtTransactions.delete(id);
  }

  /// Total repaid / collected per debt id.
  Map<String, double> getDebtPaidTotals() {
    final Map<String, double> totals = <String, double>{};
    for (final Map raw in debtTransactions.values) {
      final DebtTransactionModel item = DebtTransactionModel.fromMap(raw);
      totals[item.parentId] = (totals[item.parentId] ?? 0) + item.amount;
    }
    return totals;
  }

  /// A debt joined with its installments.
  DebtSummary? getDebtSummary(String id) {
    final DebtModel? debt = getDebt(id);
    if (debt == null) return null;
    return DebtSummary(
      debt: debt,
      installments: getDebtTransactionsFor(id),
    );
  }

  /// Every debt joined with its installments, soonest due first.
  List<DebtSummary> getDebtSummaries({DebtType? type}) {
    final Map<String, List<DebtTransactionModel>> grouped =
        <String, List<DebtTransactionModel>>{};
    for (final DebtTransactionModel item in getDebtTransactions()) {
      grouped.putIfAbsent(item.parentId, () => <DebtTransactionModel>[])
          .add(item);
    }
    return getDebts()
        .where((DebtModel debt) => type == null || debt.debtType == type)
        .map(
          (DebtModel debt) => DebtSummary(
            debt: debt,
            installments:
                grouped[debt.id] ?? const <DebtTransactionModel>[],
          ),
        )
        .toList(growable: false);
  }

  /// Outstanding money lent to others.
  double getTotalLent() => getDebtSummaries(type: DebtType.debt).fold<double>(
        0,
        (double sum, DebtSummary summary) => sum + summary.outstandingAmount,
      );

  /// Outstanding money borrowed.
  double getTotalBorrowed() =>
      getDebtSummaries(type: DebtType.credit).fold<double>(
        0,
        (double sum, DebtSummary summary) => sum + summary.outstandingAmount,
      );

  // ---------------------------------------------------------------------
  // SEEDING
  // ---------------------------------------------------------------------

  /// Seeds the default Indian categories and accounts.
  ///
  /// Idempotent: records whose id already exists are left untouched, so it is
  /// safe to call on every launch and safe to re-run after a partial failure.
  /// Pass `includeIncomeCategories: false` for pure expense users.
  Future<SeedResult> seedDefaults({
    bool includeIncomeCategories = true,
    bool seedAccounts = true,
  }) async {
    int accountsSeeded = 0;
    int categoriesSeeded = 0;
    int incomeSeeded = 0;

    if (seedAccounts) {
      for (final AccountModel account in DefaultData.accountModels) {
        if (accounts.containsKey(account.id)) continue;
        // The seeded cash account is the default only when nothing else is.
        final bool promoteToDefault = account.isDefault && accounts.isEmpty;
        await accounts.put(
          account.id,
          account.copyWith(isDefault: promoteToDefault).toMap(),
        );
        accountsSeeded++;
      }
    }

    for (final CategoryModel category in DefaultData.categories) {
      if (categories.containsKey(category.id)) continue;
      // A brand-new user benefits from budgets on by default; if every seeded
      // budget is active the home screen has something to show immediately.
      await categories.put(category.id, category.toMap());
      categoriesSeeded++;
    }

    if (includeIncomeCategories) {
      for (final CategoryModel category in DefaultData.incomeCategories) {
        if (categories.containsKey(category.id)) continue;
        await categories.put(category.id, category.toMap());
        incomeSeeded++;
      }
    }

    // Guarantee exactly one default account exists after seeding.
    if (accounts.isNotEmpty) {
      final bool hasDefault =
          getAccounts().any((AccountModel account) => account.isDefault);
      if (!hasDefault) {
        await setDefaultAccount(getAccounts().first.id);
      }
    }

    return SeedResult(
      accountsSeeded: accountsSeeded,
      categoriesSeeded: categoriesSeeded,
      incomeCategoriesSeeded: incomeSeeded,
    );
  }

  /// Creates a ready-to-use demo-free first account, used by onboarding when
  /// the user wants to add their bank instead of the seeded defaults.
  Future<AccountModel> createPrimaryAccount({
    required String holderName,
    required String bankName,
    required AccountType type,
    required double initialAmount,
    String number = '',
    int color = 0xFF1E88E5,
  }) async {
    final AccountModel account = AccountModel(
      id: IdGenerator.newId(),
      name: holderName.trim().isEmpty ? 'Me' : holderName.trim(),
      bankName: bankName.trim().isEmpty ? type.label : bankName.trim(),
      number: number.trim(),
      cardType: type,
      initialAmount: initialAmount,
      color: color,
      isDefault: true,
    );
    return addAccount(account);
  }

  // ---------------------------------------------------------------------
  // Backup / restore
  // ---------------------------------------------------------------------

  /// Serialises every box into a JSON-encodable payload.
  BackupPayload exportBackup() {
    final Map<String, List<Map<String, dynamic>>> raw = exportRaw();
    return BackupPayload(
      createdAt: DateTime.now(),
      schemaVersion: SettingsModel.currentSchemaVersion,
      accounts: raw[accountsBoxName]!,
      categories: raw[categoriesBoxName]!,
      transactions: raw[transactionsBoxName]!,
      debts: raw[debtsBoxName]!,
      debtTransactions: raw[debtTransactionsBoxName]!,
      settings: loadSettings().toMap(),
    );
  }

  /// Pretty-printed backup document, ready to be written to a `.json` file.
  String exportBackupAsJson() =>
      const JsonEncoder.withIndent('  ').convert(exportBackup().toJson());

  /// Replaces every box with the contents of [payload].
  ///
  /// Records are re-validated through the models on the way in, so a damaged or
  /// hand-edited file cannot corrupt the app. Returns the number of records
  /// imported.
  Future<int> restoreBackup(BackupPayload payload) async {
    await clearAll();

    final Map<String, Map<String, dynamic>> accountBatch =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> raw in payload.accounts) {
      final AccountModel model = AccountModel.fromMap(raw);
      if (model.id.isEmpty) continue;
      accountBatch[model.id] = model.toMap();
    }

    final Map<String, Map<String, dynamic>> categoryBatch =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> raw in payload.categories) {
      final CategoryModel model = CategoryModel.fromMap(raw);
      if (model.id.isEmpty) continue;
      categoryBatch[model.id] = model.toMap();
    }

    final Map<String, Map<String, dynamic>> transactionBatch =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> raw in payload.transactions) {
      final TransactionModel model = TransactionModel.fromMap(raw);
      if (model.id.isEmpty) continue;
      // Drop mirrors of rows that no longer exist in the file.
      if (!accountBatch.containsKey(model.accountId)) continue;
      if (model.toAccountId != null &&
          !accountBatch.containsKey(model.toAccountId)) {
        continue;
      }
      transactionBatch[model.id] = model.toMap();
    }

    final Map<String, Map<String, dynamic>> debtBatch =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> raw in payload.debts) {
      final DebtModel model = DebtModel.fromMap(raw);
      if (model.id.isEmpty) continue;
      debtBatch[model.id] = model.toMap();
    }

    final Map<String, Map<String, dynamic>> installmentBatch =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> raw in payload.debtTransactions) {
      final DebtTransactionModel model = DebtTransactionModel.fromMap(raw);
      if (model.id.isEmpty) continue;
      // An installment without its debt (or its account) is meaningless.
      if (!debtBatch.containsKey(model.parentId)) continue;
      if (!accountBatch.containsKey(model.accountId)) continue;
      installmentBatch[model.id] = model.toMap();
    }

    if (accountBatch.isNotEmpty) await accounts.putAll(accountBatch);
    if (categoryBatch.isNotEmpty) await categories.putAll(categoryBatch);
    if (transactionBatch.isNotEmpty) {
      await transactions.putAll(transactionBatch);
    }
    if (debtBatch.isNotEmpty) await debts.putAll(debtBatch);
    if (installmentBatch.isNotEmpty) {
      await debtTransactions.putAll(installmentBatch);
    }

    final SettingsModel settings = payload.settings.isEmpty
        ? SettingsModel(installedAt: DateTime.now())
        : SettingsModel.fromMap(payload.settings);
    await saveSettings(settings);

    return accountBatch.length +
        categoryBatch.length +
        transactionBatch.length +
        debtBatch.length +
        installmentBatch.length;
  }

  /// Parses a backup JSON string and restores it.
  Future<int> restoreBackupFromJson(String jsonText) async {
    final Object? decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      throw const FormatException('Backup file is not a MoneyMate backup.');
    }
    final Map<String, dynamic> json =
        Map<String, dynamic>.from(decoded);
    if (json['app'] != null && json['app'] != 'moneymate') {
      throw const FormatException('Backup file belongs to another app.');
    }
    return restoreBackup(BackupPayload.fromJson(json));
  }

  // ---------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------

  /// Record counts per box, shown in Settings › About.
  Map<String, int> getBoxCounts() {
    return <String, int>{
      accountsBoxName: accounts.length,
      categoriesBoxName: categories.length,
      transactionsBoxName: transactions.length,
      debtsBoxName: debts.length,
      debtTransactionsBoxName: debtTransactions.length,
      settingsBoxName: settingsBox.length,
    };
  }

  /// Total number of user data records across the five data boxes.
  int get totalRecordCount {
    final Map<String, int> counts = getBoxCounts();
    return counts[accountsBoxName]! +
        counts[categoriesBoxName]! +
        counts[transactionsBoxName]! +
        counts[debtsBoxName]! +
        counts[debtTransactionsBoxName]!;
  }
}
