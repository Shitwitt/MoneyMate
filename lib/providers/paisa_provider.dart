import 'package:flutter/foundation.dart';

import '../core/constants/avatars.dart';
import '../core/constants/currencies.dart';
import '../core/enum/filter_enums.dart';
import '../core/theme/seed_color.dart';
import '../core/theme/theme_preference.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/id_generator.dart';
import '../data/local/hive_storage.dart';
import '../data/models/account_model.dart';
import '../data/models/category_budget_stat.dart';
import '../data/models/category_model.dart';
import '../data/models/debt_model.dart';
import '../data/models/debt_summary.dart';
import '../data/models/debt_transaction_model.dart';
import '../data/models/settings_model.dart';
import '../data/models/transaction_model.dart';
import '../domain/default_data.dart';

/// The single reactive bridge between `HiveStorage` and the UI.
///
/// Responsibilities:
///  * hold a cached, immutable snapshot of every box (so `build()` never reads
///    from disk twice for the same data),
///  * run the money maths — account balances, period summaries, budget health
///    and debt/installment progress — exactly once per mutation,
///  * write through to Hive and `notifyListeners()`.
///
/// Money rules enforced here (and covered by tests):
///  * `TransactionType.transfer` never counts as income or expense.
///  * A transfer debits its source account and credits its destination, so it
///    can never change the total net balance.
///  * Repaying a borrowed loan (`DebtType.credit`) writes an **expense** from
///    the paying account; being repaid on money lent (`DebtType.debt`) writes an
///    **income** into the receiving account. Balances therefore always reflect
///    real life without double counting.
class PaisaProvider extends ChangeNotifier {
  PaisaProvider({HiveStorage? storage, SettingsModel? initialSettings})
      : _storage = storage ?? HiveStorage.instance {
    _settings = initialSettings ?? _storage.loadSettings();
    _reloadCache();
  }

  final HiveStorage _storage;

  // ---------------------------------------------------------------------
  // Cached state
  // ---------------------------------------------------------------------

  late SettingsModel _settings;

  List<AccountModel> _accounts = const <AccountModel>[];
  List<CategoryModel> _categories = const <CategoryModel>[];
  List<TransactionModel> _transactions = const <TransactionModel>[];
  List<DebtModel> _debts = const <DebtModel>[];
  List<DebtTransactionModel> _debtTransactions =
      const <DebtTransactionModel>[];

  /// Snapshot of every account balance, recomputed on each mutation.
  Map<String, double> _balances = const <String, double>{};

  /// True while a write is in flight; the UI uses it to disable double taps.
  bool _busy = false;

  bool get isBusy => _busy;

  /// Localized-free error channel for the last failed write.
  String? _lastError;
  String? get lastError => _lastError;

  /// Re-reads every box and recomputes derived values.
  void _reloadCache() {
    _accounts = _storage.getAccounts();
    _categories = _storage.getCategories();
    _transactions = _storage.getTransactions();
    _debts = _storage.getDebts();
    _debtTransactions = _storage.getDebtTransactions();
    _balances = _computeBalances();
  }

  /// Public refresh hook — call after a backup restore or an external write.
  void refresh() {
    _settings = _storage.loadSettings();
    _reloadCache();
    notifyListeners();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      final T result = await action();
      _reloadCache();
      return result;
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Cached getters
  // ---------------------------------------------------------------------

  SettingsModel get settings => _settings;

  List<AccountModel> get accounts => _accounts;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<DebtModel> get debts => _debts;
  List<DebtTransactionModel> get debtTransactions => _debtTransactions;
  Map<String, double> get accountBalances => _balances;

  bool get isOnboardingComplete => _settings.onboardingComplete;

  // ---------------------------------------------------------------------
  // Settings state
  // ---------------------------------------------------------------------

  String get userName => _settings.userName;

  /// First name, or `there` when the profile is empty.
  String get greetingName => _settings.greetingName;

  int get userAvatarIndex => _settings.userAvatarIndex;

  PaisaAvatar get avatar => Avatars.byIndex(_settings.userAvatarIndex);

  String? get customImagePath => _settings.customImagePath;

  bool get hasCustomAvatar => _settings.hasCustomAvatar;

  String get languageCode => _settings.languageCode;

  String get currencyCode => _settings.currencyCode;

  String get currencySymbol => _settings.currencySymbol;

  String get locale => _settings.localeCode;

  CurrencyDefinition get currency => CurrencyTable.byCode(_settings.currencyCode);

  ThemePreference get themeMode => _settings.themePreference;

  bool get isAmoled => _settings.themePreference.isAmoled;

  bool get useDynamicColor => _settings.useDynamicColor;

  SeedColor get seedColor => _settings.seed;

  bool get biometricEnabled => _settings.biometricLockEnabled;

  bool get hideAmounts => _settings.hideAmounts;

  bool get incomeTrackingEnabled => _settings.incomeTrackingEnabled;

  bool get budgetAlertsEnabled => _settings.budgetAlertsEnabled;

  bool get weeklyStartMonday => _settings.weeklyStartMonday;

  ThemeSettings get themeSettings => _settings.themeSettings;

  /// The currently selected home-screen period filter.
  ///
  /// Persisted through the settings box so the dashboard reopens on the period
  /// the user last looked at.
  FilterExpense get selectedTimeFilter {
    final String? stored = _storage.readFlag<String>(_selectedFilterKey);
    return FilterExpenseX.fromKey(stored);
  }

  static const String _selectedFilterKey = 'selected_time_filter';

  /// The active formatter, rebuilt whenever the currency or privacy mode
  /// changes. Cheap: the underlying `NumberFormat`s are cached statically.
  CurrencyFormatter get formatter => CurrencyFormatter(
        currency: currency,
        hideAmounts: _settings.hideAmounts,
      );

  Future<void> updateSettings(
    SettingsModel next, {
    bool notify = true,
  }) async {
    _settings = next;
    if (notify) notifyListeners();
    await _storage.saveSettings(next);
  }

  Future<void> setUserName(String name) async {
    await updateSettings(_settings.copyWith(userName: name.trim()));
  }

  Future<void> setAvatarIndex(int index) async {
    await updateSettings(
      _settings.copyWith(
        userAvatarIndex: index,
        clearCustomImagePath: true,
      ),
    );
  }

  Future<void> setCustomAvatar(String? path) async {
    await updateSettings(
      path == null
          ? _settings.copyWith(clearCustomImagePath: true)
          : _settings.copyWith(customImagePath: path),
    );
  }

  Future<void> setLanguage(String code) async {
    await updateSettings(_settings.copyWith(languageCode: code));
  }

  /// Switches the app currency. The symbol and formatting locale travel with
  /// the definition, so `INR` regains Indian lakh/crore grouping immediately.
  Future<void> setCurrency(String code) async {
    final CurrencyDefinition definition = CurrencyTable.byCode(code);
    await updateSettings(
      _settings.copyWith(
        currencyCode: definition.code,
        currencySymbol: definition.symbol,
        localeCode: definition.locale,
      ),
    );
  }

  Future<void> setThemeMode(ThemePreference preference) async {
    await updateSettings(_settings.copyWith(themePreference: preference));
  }

  /// Toggles AMOLED while keeping the rest of the theme mode.
  ///
  /// AMOLED is a dark-mode variant, so enabling it from Light/Dark lands on
  /// [ThemePreference.amoled]; disabling it lands on [ThemePreference.dark].
  Future<void> setAmoled(bool enabled) async {
    final ThemePreference next;
    if (enabled) {
      next = ThemePreference.amoled;
    } else {
      next = _settings.themePreference == ThemePreference.amoled
          ? ThemePreference.dark
          : _settings.themePreference;
    }
    await setThemeMode(next);
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    await updateSettings(_settings.copyWith(useDynamicColor: enabled));
  }

  Future<void> setSeedColor(SeedColor seed) async {
    await updateSettings(_settings.copyWith(seed: seed));
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(biometricLockEnabled: enabled));
  }

  Future<void> setHideAmounts(bool hide) async {
    await updateSettings(_settings.copyWith(hideAmounts: hide));
  }

  Future<void> setIncomeTrackingEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(incomeTrackingEnabled: enabled));
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(budgetAlertsEnabled: enabled));
  }

  Future<void> setWeeklyStartMonday(bool monday) async {
    await updateSettings(_settings.copyWith(weeklyStartMonday: monday));
  }

  Future<void> setSelectedTimeFilter(FilterExpense filter) async {
    await _storage.writeFlag(_selectedFilterKey, filter.key);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // ACCOUNT BALANCE MATH
  //
  //   balance(id) = initialAmount
  //               + Σ income   where accountId    == id
  //               - Σ expense  where accountId    == id
  //               - Σ transfer where accountId    == id
  //               + Σ transfer where toAccountId  == id
  //
  // Debt installments need no extra term here: every installment that moved
  // money is mirrored into a linked income/expense transaction by
  // [addDebtInstallment], so it is already inside the sums above — counted
  // exactly once, never twice.
  // ---------------------------------------------------------------------

  Map<String, double> _computeBalances() {
    final Map<String, double> balances = <String, double>{
      for (final AccountModel account in _accounts)
        account.id: account.initialAmount,
    };

    for (final TransactionModel transaction in _transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          _applyDelta(balances, transaction.accountId, transaction.amount);
        case TransactionType.expense:
          _applyDelta(balances, transaction.accountId, -transaction.amount);
        case TransactionType.transfer:
          _applyDelta(balances, transaction.accountId, -transaction.amount);
          _applyDelta(
            balances,
            transaction.toAccountId ?? '',
            transaction.amount,
          );
      }
    }

    return balances;
  }

  static void _applyDelta(
    Map<String, double> balances,
    String accountId,
    double delta,
  ) {
    if (accountId.isEmpty) return;
    final double? current = balances[accountId];
    if (current == null) return; // orphaned row — the account is gone
    balances[accountId] = current + delta;
  }

  /// Checked arithmetic used by the public balance helpers: the cached map is
  /// authoritative, but callers may pass a different transaction list (e.g. a
  /// "what if" preview in the entry sheet).
  double accountBalance(String accountId) => _balances[accountId] ?? 0;

  /// `Σ account balances` — the app's headline number.
  double get totalNetBalance =>
      _balances.values.fold<double>(0, (double sum, double value) => sum + value);

  /// Sum of the positive account balances only (assets).
  double get totalAssets => _balances.values
      .where((double value) => value > 0)
      .fold<double>(0, (double sum, double value) => sum + value);

  /// Sum of the negative account balances only (credit-card debt), as a
  /// positive number.
  double get totalLiabilities => _balances.values
      .where((double value) => value < 0)
      .fold<double>(0, (double sum, double value) => sum + value.abs());

  AccountModel? get defaultAccount {
    for (final AccountModel account in _accounts) {
      if (account.isDefault) return account;
    }
    return _accounts.isEmpty ? null : _accounts.first;
  }

  AccountModel? accountById(String? id) {
    if (id == null) return null;
    for (final AccountModel account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  CategoryModel? categoryById(String? id) {
    if (id == null) return null;
    for (final CategoryModel category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Category name for display, resolving orphans gracefully.
  String categoryName(String? id) => categoryById(id)?.name ?? 'Uncategorised';

  /// Account title for display, resolving orphans gracefully.
  String accountName(String? id) => accountById(id)?.title ?? 'Deleted account';

  // ---------------------------------------------------------------------
  // PERIOD SUMMARY MATH
  //
  // Transfers are excluded from both income and expense — a transfer moves
  // money between the user's own accounts, so counting it as a spend (or as
  // income) would double count the user's money.
  // ---------------------------------------------------------------------

  /// The inclusive `(start, end)` window for [filter].
  (DateTime, DateTime) periodRange([
    FilterExpense? filter,
    DateTime? now,
  ]) {
    final FilterExpense active = filter ?? selectedTimeFilter;
    final DateTime reference = now ?? DateTime.now();
    final DateTime today =
        DateTime(reference.year, reference.month, reference.day);

    switch (active) {
      case FilterExpense.daily:
        return (today, today);
      case FilterExpense.weekly:
        // Monday-start weeks (Indian convention) unless the user turned it off.
        final int weekday = today.weekday; // Mon=1 … Sun=7
        final int offset = _settings.weeklyStartMonday ? weekday - 1 : weekday % 7;
        final DateTime start = today.subtract(Duration(days: offset));
        return (start, start.add(const Duration(days: 6)));
      case FilterExpense.monthly:
        return (
          DateTime(today.year, today.month),
          DateTime(today.year, today.month + 1, 0),
        );
      case FilterExpense.yearly:
        return (DateTime(today.year), DateTime(today.year, 12, 31));
      case FilterExpense.all:
        final DateTime? oldest = _oldestTransactionDate;
        return (
          oldest == null ? DateTime(2000) : DateTime(oldest.year, oldest.month, 1),
          today,
        );
    }
  }

  DateTime? get _oldestTransactionDate {
    if (_transactions.isEmpty) return null;
    DateTime oldest = _transactions.first.time;
    for (final TransactionModel transaction in _transactions) {
      if (transaction.time.isBefore(oldest)) oldest = transaction.time;
    }
    return oldest;
  }

  /// Transactions inside the active (or given) period, newest first.
  List<TransactionModel> transactionsInPeriod([
    FilterExpense? filter,
    DateTime? now,
  ]) {
    final (DateTime, DateTime) range = periodRange(filter, now);
    final DateTime start = DateTime(range.$1.year, range.$1.month, range.$1.day);
    final DateTime end = DateTime(
      range.$2.year,
      range.$2.month,
      range.$2.day,
      23,
      59,
      59,
      999,
    );
    return _transactions
        .where((TransactionModel transaction) =>
            !transaction.time.isBefore(start) && !transaction.time.isAfter(end))
        .toList(growable: false);
  }

  /// True when [transaction] is the auto-generated mirror of a debt
  /// installment rather than a row the user typed.
  static bool isLinkedDebtTransaction(TransactionModel transaction) =>
      (transaction.description ?? '')
          .startsWith(linkedDebtDescriptionPrefix);

  /// The transactions the user should see in lists and summaries.
  ///
  /// Linked debt-installment rows are filtered out because the installment is
  /// already shown on the Loans screen; showing it twice (once as an expense,
  /// once as an installment) is how trackers double count.
  List<TransactionModel> get ledgerTransactions => _transactions
      .where((TransactionModel t) => !isLinkedDebtTransaction(t))
      .toList(growable: false);

  /// Income in the period — transfers excluded by construction, linked debt
  /// rows excluded so a loan repayment is reported once.
  double get periodIncome => _sumByType(
        transactionsInPeriod(),
        TransactionType.income,
        includeLinked: false,
      );

  /// Expense in the period — transfers excluded by construction, linked debt
  /// rows excluded so a loan repayment is reported once.
  double get periodExpense => _sumByType(
        transactionsInPeriod(),
        TransactionType.expense,
        includeLinked: false,
      );

  /// Income minus expense for the period (transfers are net-zero money).
  double get periodNet => periodIncome - periodExpense;

  /// Total money moved between own accounts in the period. Shown separately so
  /// users understand why it is not part of income/expense.
  double get periodTransferVolume => _sumByType(
        transactionsInPeriod(),
        TransactionType.transfer,
        includeLinked: false,
      );

  /// Number of user-entered transactions in the period.
  int get periodTransactionCount => transactionsInPeriod()
      .where((TransactionModel t) => !isLinkedDebtTransaction(t))
      .length;

  static double _sumByType(
    Iterable<TransactionModel> items,
    TransactionType type, {
    bool includeLinked = true,
  }) {
    double total = 0;
    for (final TransactionModel transaction in items) {
      if (transaction.type != type) continue;
      if (!includeLinked && isLinkedDebtTransaction(transaction)) continue;
      total += transaction.amount;
    }
    return total;
  }

  /// Per-day income/expense totals for the period — fuels the bar chart.
  ///
  /// Transfers never appear.
  List<DailyTotal> dailyTotals([FilterExpense? filter, DateTime? now]) {
    final (DateTime, DateTime) range = periodRange(filter, now);
    final FilterExpense active = filter ?? selectedTimeFilter;
    final DateTime start =
        DateTime(range.$1.year, range.$1.month, range.$1.day);
    final DateTime end = DateTime(range.$2.year, range.$2.month, range.$2.day);
    final int dayCount = end.difference(start).inDays + 1;
    final int capped = dayCount.clamp(1, 366);

    final List<DailyTotal> totals = <DailyTotal>[
      for (int i = 0; i < capped; i++)
        DailyTotal(date: start.add(Duration(days: i))),
    ];

    final Map<int, int> indexByDay = <int, int>{
      for (int i = 0; i < totals.length; i++)
        _dayKey(totals[i].date): i,
    };

    for (final TransactionModel transaction in transactionsInPeriod(active, now)) {
      // Installments already surface on the Loans screen; counting their mirror
      // rows here would show a loan repayment as fresh spending.
      if (isLinkedDebtTransaction(transaction)) continue;
      final int? index = indexByDay[_dayKey(transaction.time)];
      if (index == null) continue;
      final DailyTotal current = totals[index];
      switch (transaction.type) {
        case TransactionType.income:
          totals[index] = current.copyWith(
            income: current.income + transaction.amount,
          );
        case TransactionType.expense:
          totals[index] = current.copyWith(
            expense: current.expense + transaction.amount,
          );
        case TransactionType.transfer:
          break; // never counted
      }
    }
    return totals;
  }

  static int _dayKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  /// How many days the current period still has left (including today).
  int daysLeftInPeriod([FilterExpense? filter, DateTime? now]) {
    final FilterExpense active = filter ?? selectedTimeFilter;
    final (DateTime, DateTime) range = periodRange(active, now);
    final DateTime reference = now ?? DateTime.now();
    final DateTime today =
        DateTime(reference.year, reference.month, reference.day);
    if (active == FilterExpense.all) return 1;
    final int remaining = range.$2.difference(today).inDays + 1;
    return remaining < 1 ? 1 : remaining;
  }

  /// Whole days elapsed in the current period (including today).
  int daysElapsedInPeriod([FilterExpense? filter, DateTime? now]) {
    final (DateTime, DateTime) range = periodRange(filter, now);
    final DateTime reference = now ?? DateTime.now();
    final DateTime today =
        DateTime(reference.year, reference.month, reference.day);
    final int elapsed = today.difference(range.$1).inDays + 1;
    return elapsed < 1 ? 1 : elapsed;
  }

  /// Average daily spend so far this period.
  double get averageDailySpend {
    final int elapsed = daysElapsedInPeriod();
    if (elapsed <= 0) return 0;
    return periodExpense / elapsed;
  }

  /// Projection of period-end spend at the current pace: the average daily
  /// spend multiplied by the whole length of the period.
  double get projectedPeriodExpense {
    final int totalDays =
        daysElapsedInPeriod() + daysLeftInPeriod() - 1; // today counts once
    return averageDailySpend * (totalDays < 1 ? 1 : totalDays);
  }

  // ---------------------------------------------------------------------
  // CATEGORY SPEND & BUDGET MATH
  // ---------------------------------------------------------------------

  /// Spend per category for the **current calendar month**, keyed by id.
  ///
  /// Month — not [selectedTimeFilter] — because budgets are monthly.
  Map<String, double> get monthlySpendByCategory {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month);
    final DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    final Map<String, double> totals = <String, double>{};
    for (final TransactionModel transaction in _transactions) {
      if (transaction.type != TransactionType.expense) continue;
      if (isLinkedDebtTransaction(transaction)) continue;
      if (transaction.time.isBefore(start) || transaction.time.isAfter(end)) {
        continue;
      }
      final String key = transaction.categoryId ?? 'uncategorised';
      totals[key] = (totals[key] ?? 0) + transaction.amount;
    }
    return totals;
  }

  /// Spend per category for an arbitrary window (used by analytics).
  Map<String, double> spendByCategoryForPeriod([
    FilterExpense? filter,
    DateTime? now,
  ]) {
    final Map<String, double> totals = <String, double>{};
    for (final TransactionModel transaction in transactionsInPeriod(filter, now)) {
      if (transaction.type != TransactionType.expense) continue;
      if (isLinkedDebtTransaction(transaction)) continue;
      final String key = transaction.categoryId ?? 'uncategorised';
      totals[key] = (totals[key] ?? 0) + transaction.amount;
    }
    return totals;
  }

  /// Whole days left in the current month, including today. Never below 1 so
  /// the daily allowance can never divide by zero on the 31st.
  int get daysLeftInMonth {
    final DateTime now = DateTime.now();
    final DateTime lastDay = DateTime(now.year, now.month + 1, 0);
    final int remaining = lastDay.day - now.day + 1;
    return remaining < 1 ? 1 : remaining;
  }

  /// Budget health for every category that has spending *or* a budget.
  ///
  /// Sorted by usage descending so the categories at risk surface first.
  List<CategoryBudgetStat> get categoryBudgetStats {
    final Map<String, double> spend = monthlySpendByCategory;
    final int daysLeft = daysLeftInMonth;
    final List<CategoryBudgetStat> stats = <CategoryBudgetStat>[];
    for (final CategoryModel category in _categories) {
      final double spent = spend[category.id] ?? 0;
      if (spent <= 0 && !(category.isBudgetActive && category.budget > 0)) {
        continue;
      }
      stats.add(
        CategoryBudgetStat(
          category: category,
          spent: spent,
          daysLeftInPeriod: daysLeft,
        ),
      );
    }
    stats.sort((CategoryBudgetStat a, CategoryBudgetStat b) {
      final int byUsage = b.usedFraction.compareTo(a.usedFraction);
      if (byUsage != 0) return byUsage;
      return b.spent.compareTo(a.spent);
    });
    return stats;
  }

  /// Only the categories that actually carry a budget.
  List<CategoryBudgetStat> get activeBudgets => categoryBudgetStats
      .where((CategoryBudgetStat stat) => stat.hasBudget)
      .toList(growable: false);

  /// Budget health for one category, or `null` when it has neither spend nor
  /// budget. `null` (not a zeroed object) lets the UI show an empty state.
  CategoryBudgetStat? budgetStatFor(String categoryId) {
    for (final CategoryBudgetStat stat in categoryBudgetStats) {
      if (stat.categoryId == categoryId) return stat;
    }
    return null;
  }

  /// `Σ category budgets` for the current month.
  double get totalMonthlyBudget => _categories
      .where((CategoryModel category) => category.isBudgetActive && category.budget > 0)
      .fold<double>(0, (double sum, CategoryModel category) => sum + category.budget);

  /// `Σ monthly expense` across every category — the budget denominator.
  double get totalMonthlySpend => monthlySpendByCategory.values
      .fold<double>(0, (double sum, double value) => sum + value);

  /// Budget left across all categories for the month (may go negative).
  double get totalBudgetRemaining => totalMonthlyBudget - totalMonthlySpend;

  /// Whole-month budget progress, clamped to `0..1` for rings.
  double get totalBudgetProgress {
    if (totalMonthlyBudget <= 0) return 0;
    return (totalMonthlySpend / totalMonthlyBudget).clamp(0.0, 1.0);
  }

  /// How much the user can spend per remaining day of the month while staying
  /// inside the overall budget.
  double get safeDailySpend {
    if (totalMonthlyBudget <= 0) return 0;
    final double left = totalBudgetRemaining;
    if (left <= 0) return 0;
    return left / daysLeftInMonth;
  }

  /// Categories that are over budget right now.
  List<CategoryBudgetStat> get overBudgetCategories =>
      activeBudgets.where((CategoryBudgetStat stat) => stat.isOverBudget).toList(
            growable: false,
          );

  // ---------------------------------------------------------------------
  // DEBTS & INSTALLMENTS
  // ---------------------------------------------------------------------

  /// Every debt joined with its installments, soonest due first.
  List<DebtSummary> get debtSummaries {
    final Map<String, List<DebtTransactionModel>> grouped =
        <String, List<DebtTransactionModel>>{};
    for (final DebtTransactionModel item in _debtTransactions) {
      grouped.putIfAbsent(item.parentId, () => <DebtTransactionModel>[]).add(item);
    }
    return _debts
        .map(
          (DebtModel debt) => DebtSummary(
            debt: debt,
            installments: grouped[debt.id] ?? const <DebtTransactionModel>[],
          ),
        )
        .toList(growable: false);
  }

  List<DebtSummary> debtsOfType(DebtType type) => debtSummaries
      .where((DebtSummary summary) => summary.debtType == type)
      .toList(growable: false);

  DebtSummary? debtSummaryById(String debtId) {
    for (final DebtSummary summary in debtSummaries) {
      if (summary.id == debtId) return summary;
    }
    return null;
  }

  /// `Σ installments` recorded against [debtId].
  double paidAmountFor(String debtId) {
    double total = 0;
    for (final DebtTransactionModel item in _debtTransactions) {
      if (item.parentId == debtId) total += item.amount;
    }
    return total;
  }

  /// `debt.amount - paidAmount`, never negative.
  double remainingAmountFor(String debtId) {
    final DebtModel? debt = _debtById(debtId);
    if (debt == null) return 0;
    final double remaining = debt.amount - paidAmountFor(debtId);
    return remaining < 0 ? 0 : remaining;
  }

  /// `(paidAmount / debt.amount).clamp(0, 1)` — `0` when the total is zero.
  double progressFor(String debtId) {
    final DebtModel? debt = _debtById(debtId);
    if (debt == null || debt.amount <= 0) return 0;
    return (paidAmountFor(debtId) / debt.amount).clamp(0.0, 1.0);
  }

  DebtModel? _debtById(String id) {
    for (final DebtModel debt in _debts) {
      if (debt.id == id) return debt;
    }
    return null;
  }

  /// Outstanding money the user lent to others.
  double get totalLent => debtsOfType(DebtType.debt)
      .fold<double>(0, (double sum, DebtSummary s) => sum + s.outstandingAmount);

  /// Outstanding money the user owes.
  double get totalBorrowed => debtsOfType(DebtType.credit)
      .fold<double>(0, (double sum, DebtSummary s) => sum + s.outstandingAmount);

  /// Debts whose due date has passed and that are not settled yet.
  List<DebtSummary> get overdueDebts =>
      debtSummaries.where((DebtSummary s) => s.isOverdue()).toList(growable: false);

  /// Debts due within the next seven days.
  List<DebtSummary> get dueSoonDebts => debtSummaries
      .where((DebtSummary s) => s.isDueSoon(withinDays: 7))
      .toList(growable: false);

  // ---------------------------------------------------------------------
  // MUTATIONS — ACCOUNTS
  // ---------------------------------------------------------------------

  Future<AccountModel> addAccount(AccountModel account) async {
    return _guard<AccountModel>(() async {
      final AccountModel saved = await _storage.addAccount(account);
      return saved;
    });
  }

  Future<void> updateAccount(AccountModel account) async {
    await _guard<void>(() => _storage.saveAccount(account));
  }

  Future<void> deleteAccount(String accountId) async {
    await _guard<void>(() => _storage.deleteAccount(accountId));
  }

  Future<void> setDefaultAccount(String accountId) async {
    await _guard<void>(() => _storage.setDefaultAccount(accountId));
  }

  // ---------------------------------------------------------------------
  // MUTATIONS — CATEGORIES
  // ---------------------------------------------------------------------

  Future<void> addCategory(CategoryModel category) async {
    await _guard<void>(() => _storage.saveCategory(category));
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _guard<void>(() => _storage.saveCategory(category));
  }

  Future<void> deleteCategory(String categoryId) async {
    await _guard<void>(() => _storage.deleteCategory(categoryId));
  }

  /// Sets (or clears) a monthly budget for a category.
  Future<void> setCategoryBudget(
    String categoryId, {
    required double budget,
    bool active = true,
  }) async {
    final CategoryModel? category = categoryById(categoryId);
    if (category == null) return;
    await updateCategory(
      category.copyWith(
        budget: budget < 0 ? 0 : budget,
        isBudgetActive: active && budget > 0,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MUTATIONS — TRANSACTIONS
  // ---------------------------------------------------------------------

  /// Validates and saves a transaction.
  ///
  /// Returns the persisted model, or throws a [TransactionException] the UI can
  /// surface. Transfers require two distinct, existing accounts and no
  /// category; expenses/income require one existing account.
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    return _guard<TransactionModel>(() async {
      final TransactionModel validated = _validateTransaction(transaction);
      await _storage.saveTransaction(validated);
      return validated;
    });
  }

  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    return _guard<TransactionModel>(() async {
      final TransactionModel validated = _validateTransaction(transaction);
      await _storage.saveTransaction(validated);
      return validated;
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _guard<void>(() => _storage.deleteTransaction(id));
  }

  TransactionModel _validateTransaction(TransactionModel transaction) {
    if (!transaction.amount.isFinite || transaction.amount <= 0) {
      throw const TransactionException('Amount must be greater than zero.');
    }
    if (transaction.name.trim().isEmpty) {
      throw const TransactionException('Please add a title.');
    }
    if (accountById(transaction.accountId) == null) {
      throw const TransactionException('Choose an account.');
    }
    if (transaction.type == TransactionType.transfer) {
      final String? destination = transaction.toAccountId;
      if (destination == null || destination.isEmpty) {
        throw const TransactionException('Choose a destination account.');
      }
      if (destination == transaction.accountId) {
        throw const TransactionException(
          'Source and destination accounts must differ.',
        );
      }
      if (accountById(destination) == null) {
        throw const TransactionException('Destination account is missing.');
      }
      // A transfer has no category and no notes-driven category link.
      return transaction.copyWith(clearCategory: true);
    }
    if (transaction.categoryId != null &&
        categoryById(transaction.categoryId) == null) {
      // A deleted category should never block entry — drop it instead.
      return transaction.copyWith(clearCategory: true, clearToAccount: true);
    }
    return transaction.copyWith(clearToAccount: true);
  }

  /// Builds a ready-to-save transaction with a fresh id.
  TransactionModel draftTransaction({
    required String name,
    required double amount,
    required TransactionType type,
    required String accountId,
    DateTime? time,
    String? toAccountId,
    String? categoryId,
    String? description,
  }) {
    return TransactionModel(
      id: IdGenerator.newId(),
      name: name.trim(),
      amount: amount < 0 ? amount.abs() : amount,
      time: time ?? DateTime.now(),
      type: type,
      accountId: accountId,
      toAccountId: type == TransactionType.transfer ? toAccountId : null,
      categoryId: type == TransactionType.transfer ? null : categoryId,
      description: description,
    );
  }

  // ---------------------------------------------------------------------
  // MUTATIONS — DEBTS
  // ---------------------------------------------------------------------

  Future<DebtModel> addDebt(DebtModel debt) async {
    return _guard<DebtModel>(() async {
      if (debt.amount <= 0) {
        throw const TransactionException('Loan amount must be greater than zero.');
      }
      if (debt.name.trim().isEmpty) {
        throw const TransactionException('Please add a name.');
      }
      if (debt.expiryDateTime.isBefore(debt.dateTime)) {
        throw const TransactionException('Due date cannot be before the start date.');
      }
      await _storage.saveDebt(debt);
      return debt;
    });
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _guard<void>(() => _storage.saveDebt(debt));
  }

  Future<void> deleteDebt(String debtId) async {
    await _guard<void>(() => _storage.deleteDebt(debtId));
  }

  /// Records an installment / repayment and keeps the ledger truthful.
  ///
  /// The installment itself is the source of truth for debt progress. When an
  /// [accountId] is supplied the money provably moved, so a linked transaction
  /// is written with the same amount and timestamp:
  ///
  ///  * parent `DebtType.debt` (money lent, now being repaid to you) → **income**
  ///  * parent `DebtType.credit` (loan/EMI you are paying back)      → **expense**
  ///
  /// The linked transaction is tagged with [linkedDebtDescriptionPrefix] so a
  /// repeated tap or a repair pass can find and reuse it instead of creating a
  /// duplicate.
  Future<DebtTransactionModel> addDebtInstallment({
    required String parentId,
    required double amount,
    required DateTime dateTime,
    String? accountId,
    String note = '',
    bool createLinkedTransaction = true,
  }) async {
    return _guard<DebtTransactionModel>(() async {
      final DebtModel? debt = _debtById(parentId);
      if (debt == null) {
        throw const TransactionException('This loan no longer exists.');
      }
      if (amount <= 0) {
        throw const TransactionException('Installment must be greater than zero.');
      }
      final double remaining = remainingAmountFor(parentId);
      if (amount > remaining + 0.005) {
        throw TransactionException(
          'Installment is more than the remaining amount.',
        );
      }
      final String? resolvedAccount = accountId ?? defaultAccount?.id;
      if (createLinkedTransaction) {
        if (resolvedAccount == null || accountById(resolvedAccount) == null) {
          throw const TransactionException('Choose the account used.');
        }
      }

      final DebtTransactionModel installment = DebtTransactionModel(
        id: IdGenerator.newId(),
        parentId: parentId,
        amount: amount,
        dateTime: dateTime,
        accountId: resolvedAccount ?? '',
        note: note.trim(),
      );
      await _storage.saveDebtTransaction(installment);

      if (createLinkedTransaction && resolvedAccount != null) {
        await _storage.saveTransaction(
          _linkedTransactionFromInstallment(
            installment: installment,
            debt: debt,
          ),
        );
      }
      return installment;
    });
  }

  /// Marker used in the linked transaction's `description`.
  static const String linkedDebtDescriptionPrefix = 'Debt installment';

  /// The income/expense row that mirrors an installment in the ledger.
  TransactionModel _linkedTransactionFromInstallment({
    required DebtTransactionModel installment,
    required DebtModel debt,
  }) {
    final TransactionType type = debt.debtType == DebtType.debt
        ? TransactionType.income // someone repaid money you lent
        : TransactionType.expense; // you paid back a loan / EMI
    final String suffix = installment.note.trim().isEmpty
        ? ''
        : ' · ${installment.note.trim()}';
    return TransactionModel(
      id: linkedTransactionId(installment.id),
      // Deliberately identical for both directions: the *type* (income vs
      // expense) already carries the meaning, and the linked row is excluded
      // from the user's income/expense summaries (see [ledgerTransactions]).
      name: '${debt.name} · EMI',
      description: '$linkedDebtDescriptionPrefix · ${debt.name}$suffix',
      amount: installment.amount,
      time: installment.dateTime,
      type: type,
      accountId: installment.accountId,
      categoryId: null,
    );
  }

  /// Deterministic id so an installment can never produce two ledger rows.
  static String linkedTransactionId(String installmentId) =>
      'debt-linked-$installmentId';

  Future<void> deleteDebtInstallment(String installmentId) async {
    await _guard<void>(() async {
      await _storage.deleteDebtTransaction(installmentId);
      // The mirror row must go too, otherwise the balance stays wrong.
      await _storage.deleteTransaction(linkedTransactionId(installmentId));
    });
  }

  /// Repairs installments recorded without a linked transaction (e.g. saved by
  /// an older build) so balances and the ledger agree.
  Future<int> repairDebtLedger() async {
    return _guard<int>(() async {
      int repaired = 0;
      final Set<String> existingIds = <String>{
        for (final TransactionModel transaction in _transactions) transaction.id,
      };
      for (final DebtTransactionModel installment in _debtTransactions) {
        if (installment.accountId.isEmpty) continue;
        final String expectedId = linkedTransactionId(installment.id);
        final DebtModel? debt = _debtById(installment.parentId);
        if (debt == null) continue;
        // Any row with the same amount/date/account already covers it.
        final bool alreadyCovered = existingIds.contains(expectedId) ||
            _transactions.any((TransactionModel transaction) =>
                transaction.accountId == installment.accountId &&
                transaction.amount == installment.amount &&
                transaction.time == installment.dateTime &&
                (transaction.description ?? '')
                    .startsWith(linkedDebtDescriptionPrefix));
        if (alreadyCovered) continue;
        await _storage.saveTransaction(
          _linkedTransactionFromInstallment(
            installment: installment,
            debt: debt,
          ),
        );
        existingIds.add(expectedId);
        repaired++;
      }
      return repaired;
    });
  }

  // ---------------------------------------------------------------------
  // ONBOARDING
  // ---------------------------------------------------------------------

  /// Seeds the full default catalogue (accounts + categories) and marks
  /// onboarding complete.
  Future<void> completeOnboarding({
    required String name,
    required int avatarIndex,
    String? customImagePath,
    required String languageCode,
    required String currencyCode,
    required List<AccountModel> selectedAccounts,
    required List<CategoryModel> selectedCategories,
    bool incomeTracking = true,
  }) async {
    await _guard<void>(() async {
      // 1. Accounts — the first selected account becomes the default.
      final List<AccountModel> ordered = List<AccountModel>.of(selectedAccounts);
      for (int i = 0; i < ordered.length; i++) {
        final AccountModel account = ordered[i];
        await _storage.addAccount(
          account.copyWith(isDefault: i == 0),
        );
      }
      if (ordered.isEmpty) {
        await _storage.addAccount(DefaultData.cashAccount.toModel());
      }

      // 2. Categories — only the user's picks (plus the income ones they need).
      if (selectedCategories.isNotEmpty) {
        await _storage.saveCategories(
          selectedCategories.map(
            (CategoryModel category) => category.copyWith(isDefault: true),
          ),
        );
      } else {
        for (final CategoryModel category in DefaultData.categories) {
          await _storage.saveCategory(category);
        }
      }
      if (incomeTracking) {
        final Set<String> existing = <String>{
          for (final CategoryModel category in _storage.getCategories())
            category.id,
        };
        for (final CategoryModel category in DefaultData.incomeCategories) {
          if (existing.contains(category.id)) continue;
          await _storage.saveCategory(category);
        }
      }

      // 3. Currency + profile + flags.
      final CurrencyDefinition definition = CurrencyTable.byCode(currencyCode);
      _settings = _settings.copyWith(
        onboardingComplete: true,
        userName: name.trim(),
        userAvatarIndex: avatarIndex,
        customImagePath: customImagePath,
        languageCode: languageCode,
        currencyCode: definition.code,
        currencySymbol: definition.symbol,
        localeCode: definition.locale,
        incomeTrackingEnabled: incomeTracking,
        installedAt: _settings.installedAt ?? DateTime.now(),
      );
      await _storage.saveSettings(_settings);
    });
  }

  /// Marks onboarding complete without seeding anything (the "Skip" path).
  Future<void> skipOnboarding() async {
    await updateSettings(
      _settings.copyWith(
        onboardingComplete: true,
        installedAt: _settings.installedAt ?? DateTime.now(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BACKUP
  // ---------------------------------------------------------------------

  String exportBackupJson() => _storage.exportBackupAsJson();

  Future<int> restoreBackupJson(String json) async {
    return _guard<int>(() async {
      final int count = await _storage.restoreBackupFromJson(json);
      _settings = _storage.loadSettings();
      return count;
    });
  }

  /// Full app reset used by Settings › Danger zone.
  Future<void> resetEverything() async {
    await _guard<void>(() async {
      await _storage.clearAll();
      _settings = SettingsModel(installedAt: DateTime.now());
      await _storage.saveSettings(_settings);
    });
  }
}

/// A user-correctable validation failure from the provider layer.
class TransactionException implements Exception {
  const TransactionException(this.message);

  /// Human readable reason, safe to show in a snack bar.
  final String message;

  @override
  String toString() => message;
}

/// Income / expense totals for one day, used by the period bar chart.
@immutable
class DailyTotal {
  const DailyTotal({
    required this.date,
    this.income = 0,
    this.expense = 0,
  });

  final DateTime date;
  final double income;
  final double expense;

  /// Net movement for the day (transfers excluded).
  double get net => income - expense;

  DailyTotal copyWith({double? income, double? expense}) => DailyTotal(
        date: date,
        income: income ?? this.income,
        expense: expense ?? this.expense,
      );

  @override
  bool operator ==(Object other) =>
      other is DailyTotal &&
      other.date == date &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(date, income, expense);

  @override
  String toString() => 'DailyTotal($date, in: $income, out: $expense)';
}
