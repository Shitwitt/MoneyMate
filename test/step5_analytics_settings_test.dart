import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/constants/currencies.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/core/theme/paisa_theme.dart';
import 'package:moneymate/core/theme/seed_color.dart';
import 'package:moneymate/core/theme/theme_preference.dart';
import 'package:moneymate/core/utils/backup_service.dart';
import 'package:moneymate/core/utils/currency_formatter.dart';
import 'package:moneymate/core/utils/date_time_format.dart';
import 'package:moneymate/data/local/hive_storage.dart';
import 'package:moneymate/data/models/account_model.dart';
import 'package:moneymate/data/models/analytics_models.dart';
import 'package:moneymate/data/models/category_model.dart';
import 'package:moneymate/data/models/settings_model.dart';
import 'package:moneymate/data/models/transaction_model.dart';
import 'package:moneymate/providers/paisa_provider.dart';
import 'package:moneymate/screens/overview/overview_screen.dart';
import 'package:moneymate/screens/settings/settings_screen.dart';
import 'package:moneymate/widgets/analytics_charts.dart';
import 'package:provider/provider.dart';

/// Step 5: the analytics engine (real, filter-driven buckets) plus the settings
/// and data-management flows (backup JSON ⇄ restore, CSV, currency).
void main() {
  final HiveStorage storage = HiveStorage.instance;
  late Directory tempDir;
  late DateTime now;

  const String bankId = 'bank';
  const String cashId = 'cash';
  const String foodId = 'seed-category-food';
  const String travelId = 'seed-category-travel';
  const String salaryId = 'seed-category-salary';

  /// Midday of the day [daysAgo] days before [now] — inside the same calendar
  /// day no matter which timezone the test runner uses.
  DateTime dayAgo(int daysAgo) {
    final DateTime day = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysAgo));
    return DateTime(day.year, day.month, day.day, 12);
  }

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('moneymate_step5_');
    await storage.init(directoryOverride: tempDir.path);
  });

  tearDownAll(() async {
    await storage.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await storage.clearAll();
    // A fixed reference instant: the 7th of a 30-day month, used by every
    // expectation below so the buckets are deterministic.
    now = DateTime(2026, 11, 7, 15, 30);

    await storage.saveSettings(
      SettingsModel(installedAt: now, onboardingComplete: true),
    );
    await storage.saveAccount(
      const AccountModel(
        id: bankId,
        name: 'Me',
        bankName: 'HDFC Savings',
        number: '4821',
        cardType: AccountType.bank,
        initialAmount: 40000,
        color: 0xFF1E88E5,
        isDefault: true,
      ),
    );
    await storage.saveAccount(
      const AccountModel(
        id: cashId,
        name: 'Me',
        bankName: 'Cash in Hand',
        number: '',
        cardType: AccountType.cash,
        initialAmount: 2500,
        color: 0xFF43A047,
      ),
    );
    await storage.saveCategory(
      const CategoryModel(
        id: foodId,
        name: 'Food & Dining',
        icon: 0xe56c,
        color: 0xFFE53935,
      ),
    );
    await storage.saveCategory(
      const CategoryModel(
        id: travelId,
        name: 'Travel',
        icon: 0xe530,
        color: 0xFF1E88E5,
      ),
    );
    await storage.saveCategory(
      const CategoryModel(
        id: salaryId,
        name: 'Salary',
        icon: 0xe263,
        color: 0xFF43A047,
      ),
    );

    await storage.saveTransactions(<TransactionModel>[
      // Today: two expenses on different accounts + a salary credit.
      TransactionModel(
        id: 't1',
        name: 'Lunch',
        amount: 450,
        time: dayAgo(0),
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: foodId,
      ),
      TransactionModel(
        id: 't2',
        name: 'Auto',
        amount: 120,
        time: dayAgo(0),
        type: TransactionType.expense,
        accountId: cashId,
        categoryId: travelId,
      ),
      TransactionModel(
        id: 't3',
        name: 'November salary',
        amount: 60000,
        time: dayAgo(0),
        type: TransactionType.income,
        accountId: bankId,
        categoryId: salaryId,
      ),
      // Three days ago: the biggest single day (1 800 on food).
      TransactionModel(
        id: 't4',
        name: 'Groceries',
        amount: 1800,
        time: dayAgo(3),
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: foodId,
      ),
      // Five days ago: a transfer — must never add to income or expense.
      TransactionModel(
        id: 't5',
        name: 'ATM withdrawal',
        amount: 5000,
        time: dayAgo(5),
        type: TransactionType.transfer,
        accountId: bankId,
        toAccountId: cashId,
      ),
      // Ten days ago, outside the current week.
      TransactionModel(
        id: 't6',
        name: 'Weekend trip',
        amount: 2200,
        time: dayAgo(10),
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: travelId,
      ),
      // Two months ago, inside the 6-month bar chart but outside this month.
      TransactionModel(
        id: 't7',
        name: 'Old dinner',
        amount: 900,
        time: DateTime(now.year, now.month - 2, 12, 20),
        type: TransactionType.expense,
        accountId: cashId,
        categoryId: foodId,
      ),
      // A loan-installment mirror row: shown on the Loans tab, never counted.
      TransactionModel(
        id: 't8',
        name: 'Debt installment — Car loan',
        amount: 4000,
        time: dayAgo(1),
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: foodId,
        description:
            '${PaisaProvider.linkedDebtDescriptionPrefix} · Car loan',
      ),
    ]);
  });

  group('analytics engine', () {
    test('month window buckets days, excludes transfers and debt mirrors',
        () {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.all,
        now: now,
      );

      // Month-to-date income: the salary only.
      expect(snapshot.income, 60000);
      // Expenses: 450 + 120 + 1800 + 2200 (+900 is two months back, and the
      // 4 000 instalment mirror is excluded).
      expect(snapshot.expense, 4570);
      expect(snapshot.net, 60000 - 4570);
      expect(snapshot.transactionCount, 5);

      // One point per day from the 1st to today (the 7th).
      expect(snapshot.flowPoints.length, 7);
      expect(snapshot.flowPoints.first.label, '1');
      expect(snapshot.flowPoints.last.label, '7');
      expect(snapshot.hasFlow, isTrue);

      // No transfer volume leaked into any bucket.
      final double totalFlow = snapshot.flowPoints.fold<double>(
        0,
        (double sum, FlowPoint point) => sum + point.income + point.expense,
      );
      expect(totalFlow, 60000 + 4570);
    });

    test('type filter narrows the numbers and the chart series', () {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());

      final AnalyticsSnapshot expensesOnly = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.expense,
        now: now,
      );
      expect(expensesOnly.income, 0);
      expect(expensesOnly.expense, 4570);
      expect(expensesOnly.savingsRate, 0); // nothing to save against
      expect(expensesOnly.analysedTotal, 4570);

      final AnalyticsSnapshot incomeOnly = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.income,
        now: now,
      );
      expect(incomeOnly.income, 60000);
      expect(incomeOnly.expense, 0);
      expect(incomeOnly.net, 60000);
      expect(incomeOnly.savingsRate, 1);
      // The donut distributes income by category in income-only mode.
      expect(incomeOnly.categorySlices.length, 1);
      expect(incomeOnly.categorySlices.single.name, 'Salary');
    });

    test('savings rate, daily average and highest spending day are real', () {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.all,
        now: now,
      );

      expect(snapshot.elapsedDays, 7);
      expect(snapshot.averageDailySpend, closeTo(4570 / 7, 0.001));
      expect(
        snapshot.savingsRate,
        closeTo((60000 - 4570) / 60000, 0.0001),
      );
      // 1 800 on day 3 is the peak, not today's combined 570.
      expect(snapshot.highestSpendingDay, isNotNull);
      expect(snapshot.highestSpendingDay!.expense, 1800);
      expect(snapshot.highestSpendingDay!.date.day, now.day - 3);
    });

    test('category slices are ranked, counted and percentage-summed to 100', () {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.all,
        now: now,
      );

      expect(snapshot.categorySlices.length, 2);
      // Travel 2 200 + 120 = 2 320 beats food 450 + 1 800 = 2 250.
      expect(snapshot.categorySlices.first.name, 'Travel');
      expect(snapshot.categorySlices.first.amount, 2320);
      expect(snapshot.categorySlices.first.count, 2);
      final double shares = snapshot.categorySlices.fold<double>(
        0,
        (double sum, CategorySlice slice) => sum + slice.share,
      );
      expect(shares, closeTo(1, 0.0001));
      // Colours and icons come from the category rows, not from the widget.
      expect(snapshot.categorySlices.first.colorValue, 0xFF1E88E5);
    });

    test('week window and monthly bars respect the calendar', () {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());

      final AnalyticsSnapshot week = provider.analyticsSnapshot(
        range: AnalyticsRange.thisWeek,
        type: AnalyticsTypeFilter.all,
        now: now,
      );
      // The window is Mon → Sun, but it is clamped to today so the line chart
      // never plots empty future days: Mon 2 Nov → Sat 7 Nov = 6 points.
      expect(week.start.weekday, DateTime.monday);
      expect(week.flowPoints.length, 6);
      // The 10-days-ago trip is outside this week: 2 200 is gone, the rest stays.
      expect(week.expense, 4570 - 2200);

      final AnalyticsSnapshot bars = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.all,
        now: now,
      );
      expect(bars.monthsShown, 6);
      expect(bars.monthlyFlows.length, 6);
      // Oldest first, current month last.
      expect(bars.monthlyFlows.last.month.month, now.month);
      final MonthlyFlow current = bars.monthlyFlows.last;
      expect(current.income, 60000);
      final MonthlyFlow twoMonthsAgo =
          bars.monthlyFlows[bars.monthlyFlows.length - 3];
      expect(twoMonthsAgo.expense, 900);
      expect(bars.hasMonthlyFlow, isTrue);

      // Long windows ask for a full year of bars.
      expect(provider.monthsForRange(AnalyticsRange.thisYear), 12);
      expect(provider.monthsForRange(AnalyticsRange.allTime), 12);
    });

    test('account distribution splits the analysed money by account type', () {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.expense,
        now: now,
      );

      expect(snapshot.accountShares.length, 2);
      final AccountShare bank = snapshot.accountShares
          .firstWhere((AccountShare share) => share.accountId == bankId);
      final AccountShare cash = snapshot.accountShares
          .firstWhere((AccountShare share) => share.accountId == cashId);
      expect(bank.amount, 450 + 1800 + 2200);
      expect(cash.amount, 120);
      expect(bank.share + cash.share, closeTo(1, 0.0001));
      expect(bank.type, AccountType.bank);

      final AccountTypeShare bankType = snapshot.typeShares
          .firstWhere((AccountTypeShare share) => share.type == AccountType.bank);
      expect(bankType.amount, bank.amount);
      expect(snapshot.hasAccountSplit, isTrue);
    });

    test('filters are persisted through the settings box', () async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      expect(provider.analyticsRange, AnalyticsRange.thisMonth);
      expect(provider.analyticsType, AnalyticsTypeFilter.all);

      await provider.setAnalyticsRange(AnalyticsRange.thisYear);
      await provider.setAnalyticsType(AnalyticsTypeFilter.expense);

      final PaisaProvider reloaded =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      expect(reloaded.analyticsRange, AnalyticsRange.thisYear);
      expect(reloaded.analyticsType, AnalyticsTypeFilter.expense);
    });

    test('an empty ledger produces an empty, non-crashing snapshot', () async {
      await storage.clearAll();
      await storage.saveSettings(SettingsModel(installedAt: now));
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());

      for (final AnalyticsRange range in AnalyticsRange.values) {
        final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
          range: range,
          type: AnalyticsTypeFilter.all,
          now: now,
        );
        expect(snapshot.isEmpty, isTrue);
        expect(snapshot.hasFlow, isFalse);
        expect(snapshot.hasMonthlyFlow, isFalse);
        expect(snapshot.categorySlices, isEmpty);
        expect(snapshot.highestSpendingDay, isNull);
        expect(snapshot.averageDailySpend, 0);
      }
    });
  });

  group('data management', () {
    test('backup JSON round-trips every record through restore', () async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final String json = provider.exportBackupJson();

      final Map<String, dynamic> decoded =
          jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['app'], 'moneymate');
      expect((decoded['transactions'] as List<dynamic>).length, 8);
      expect((decoded['accounts'] as List<dynamic>).length, 2);

      final int before = provider.totalRecordCount;

      // Wipe, then restore from the exported document.
      await provider.resetEverything();
      expect(provider.transactions, isEmpty);

      final int restored = await provider.restoreBackupJson(json);
      expect(restored, before);
      expect(provider.accounts.length, 2);
      expect(provider.categories.length, 3);
      expect(provider.transactions.length, 8);

      // Balances are recomputed from the restored ledger.
      // HDFC: 40 000 opening + 60 000 salary − 450 − 1 800 − 2 200 − 5 000 ATM.
      expect(
        provider.accountBalance(bankId),
        closeTo(40000 + 60000 - 450 - 1800 - 2200 - 5000, 0.001),
      );
      // Cash: 2 500 opening + 5 000 ATM − 120.
      expect(provider.accountBalance(cashId), closeTo(2500 + 5000 - 120, 0.001));
    });

    test('a foreign or damaged file is rejected without wiping the ledger',
        () async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final int before = provider.transactions.length;

      await expectLater(
        provider.restoreBackupJson('{"app":"not-moneymate"}'),
        throwsA(isA<FormatException>()),
      );
      expect(provider.transactions.length, before);

      await expectLater(
        provider.restoreBackupJson('this is not json'),
        throwsA(isA<FormatException>()),
      );
      expect(provider.transactions.length, before);
    });

    test('CSV export writes the exact header and one quoted row per record',
        () async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final String csv = provider.exportTransactionsCsv();
      final List<String> lines = const LineSplitter()
          .convert(csv)
          .where((String line) => line.isNotEmpty)
          .toList(growable: false);

      expect(lines.first, 'Date,Title,Type,Category,Account,Amount,Notes');
      expect(lines.length, provider.transactions.length + 1);
      // Newest first: today's rows come before the two-month-old dinner.
      expect(lines[1], contains(DateTimeFormat.date(DateTime(now.year, now.month, now.day))));
      expect(lines[1], contains('Expense'));
      expect(lines.last, contains('900.00'));
      // Amounts are plain decimals with no currency symbol.
      expect(csv.contains('₹'), isFalse);
      // Every row has exactly seven fields (none of our titles need quoting).
      for (final String line in lines) {
        expect(line.split(',').length, 7, reason: line);
      }
      // A transfer names both sides of the movement.
      expect(csv, contains('HDFC Savings → Cash in Hand'));
    });

    test('currency switch reformats the whole app immediately', () async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      expect(provider.formatter.formatWhole(125450), '₹1,25,450');

      await provider.setCurrency('USD');
      expect(provider.currencyCode, 'USD');
      expect(provider.formatter.formatWhole(125450), r'$125,450');
      expect(provider.formatter.symbol, r'$');
    });

    test('settings survive a reload (theme, AMOLED, dynamic colour, seed)',
        () async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());

      await provider.setThemeMode(ThemePreference.dark);
      await provider.setAmoled(true);
      expect(provider.settings.themePreference, ThemePreference.amoled);
      await provider.setAmoled(false);
      expect(provider.settings.themePreference, ThemePreference.dark);

      await provider.setUseDynamicColor(false);
      await provider.setSeedColor(SeedColor.palette[6]);
      await provider.setBiometricEnabled(true);
      await provider.setUserName('Hemanth');

      final PaisaProvider reloaded =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      expect(reloaded.themeMode, ThemePreference.dark);
      expect(reloaded.useDynamicColor, isFalse);
      expect(reloaded.seedColor, SeedColor.palette[6]);
      expect(reloaded.seedColor.name, 'Red');
      expect(reloaded.biometricEnabled, isTrue);
      expect(reloaded.userName, 'Hemanth');
    });

    test('backup file names follow paisa_backup_YYYYMMDD.json', () {
      final DateTime stamp = DateTime(2026, 11, 7, 9, 5);
      expect(BackupService.backupFileName(stamp), 'paisa_backup_20261107.json');
      expect(
        BackupService.csvFileName(stamp),
        'paisa_transactions_20261107.csv',
      );
      expect(BackupService.formatBytes(900), '900 B');
      expect(BackupService.formatBytes(2048), '2.0 KB');
    });
  });

  group('edge cases', () {
    test('a future-dated entry never breaks the window maths', () async {
      await storage.saveTransaction(
        TransactionModel(
          id: 'future',
          name: 'Rent prepaid',
          amount: 5000,
          // Two months ahead: outside every window, and it must not drag the
          // elapsed-day count or the daily average into nonsense.
          time: DateTime(now.year, now.month + 2, 3, 9),
          type: TransactionType.expense,
          accountId: bankId,
          categoryId: foodId,
        ),
      );
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.all,
        now: now,
      );
      expect(snapshot.expense, 4570);
      expect(snapshot.elapsedDays, 7);
      expect(snapshot.averageDailySpend, closeTo(4570 / 7, 0.001));
      // The current month bucket is still the current month.
      final MonthlyFlow current = snapshot.monthlyFlows.last;
      expect(current.month.month, now.month);
    });

    test('a row whose category vanished lands in Uncategorised', () async {
      // Detach "Food & Dining" the way a damaged/older backup can: the category
      // record goes away while its transactions keep the dangling id. (The
      // provider's own delete clears the ids instead, which is the tidy path.)
      final List<Map<String, dynamic>> raw =
          storage.exportRaw()[HiveStorage.transactionsBoxName]!;
      final Map<String, Map<String, dynamic>> rewired =
          <String, Map<String, dynamic>>{};
      for (final Map<String, dynamic> row in raw) {
        if (row['categoryId'] != travelId) continue;
        rewired[row['id'] as String] =
            Map<String, dynamic>.from(row)..['categoryId'] = foodId;
      }
      await storage.transactions.putAll(rewired);
      await storage.categories.delete(foodId);
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      // The provider no longer knows the category, but the rows are still there.
      expect(provider.transactions.where(
        (TransactionModel t) => t.categoryId == foodId,
      ), isNotEmpty);
      final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
        range: AnalyticsRange.thisMonth,
        type: AnalyticsTypeFilter.expense,
        now: now,
      );
      expect(
        snapshot.categorySlices.map((CategorySlice slice) => slice.name),
        contains('Uncategorised'),
      );
      // Nothing is lost: the slices still add up to the window's expense.
      final double sliceTotal = snapshot.categorySlices.fold<double>(
        0,
        (double sum, CategorySlice slice) => sum + slice.amount,
      );
      expect(sliceTotal, closeTo(snapshot.expense, 0.001));
    });

    test('CSV escaping survives commas, quotes and newlines', () async {
      await storage.clearAll();
      await storage.saveSettings(SettingsModel(installedAt: now));
      await storage.saveAccount(
        const AccountModel(
          id: bankId,
          name: 'Me',
          bankName: 'HDFC Savings',
          number: '4821',
          cardType: AccountType.bank,
          initialAmount: 0,
          color: 0xFF1E88E5,
          isDefault: true,
        ),
      );
      await storage.saveTransaction(
        TransactionModel(
          id: 'nasty',
          name: 'Chai, "special"',
          amount: 40,
          time: DateTime(now.year, now.month, now.day, 9),
          type: TransactionType.expense,
          accountId: bankId,
          description: 'line one\nline two',
        ),
      );
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      final String csv = provider.exportTransactionsCsv();
      // The comma forces quotes, and the inner quotes are doubled.
      expect(csv, contains('"Chai, ""special"""'));
      // The newline in the note is preserved inside one quoted field.
      expect(csv, contains('"line one\nline two"'));
      // Header + one logical record, which spans three physical lines.
      expect(csv.trim().split('\n').length, 4);
    });
  });

  group('screens', () {
    Future<void> pump(
      WidgetTester tester,
      PaisaProvider provider,
      Widget child,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<PaisaProvider>.value(
          value: provider,
          child: MaterialApp(theme: PaisaTheme.light(), home: child),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('overview renders four charts from the provider data',
        (WidgetTester tester) async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      await pump(tester, provider, const OverviewScreen());

      // Sticky filter bar.
      expect(find.text('Analytics & reports'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Year'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      // "This Month" is also in scope lines, so it may appear more than once.
      expect(find.text('This Month'), findsWidgets);
      for (final AnalyticsTypeFilter type in AnalyticsTypeFilter.values) {
        expect(find.text(type.label), findsOneWidget);
      }

      // Summary card + the four chart cards.
      expect(find.text('Net cashflow'), findsOneWidget);
      expect(find.text('Savings rate'), findsOneWidget);
      expect(find.text('Avg daily spend'), findsOneWidget);
      expect(find.text('Highest spending day'), findsOneWidget);
      expect(find.byType(IncomeExpenseLineChart), findsOneWidget);
      expect(find.byType(CategoryDonut), findsOneWidget);

      // Charts 1 and 2 are visible immediately, driven by real records.
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      // The leaderboard names come from the stored categories.
      expect(find.text('Travel'), findsWidgets);

      final Finder analyticsList =
          find.byKey(const PageStorageKey<String>('analytics_scroll'));

      // Chart 3.
      await tester.dragUntilVisible(
        find.byType(BarChart),
        analyticsList,
        const Offset(0, -320),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Monthly comparison'), findsOneWidget);

      // Chart 4.
      await tester.dragUntilVisible(
        find.byType(AccountDistributionBar),
        analyticsList,
        const Offset(0, -320),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountDistributionBar), findsOneWidget);
      expect(find.text('Account distribution'), findsOneWidget);
      // The breakdown names the account the money actually left.
      expect(find.text('HDFC Savings'), findsWidgets);
    });

    testWidgets('tapping a filter chip recomputes every chart',
        (WidgetTester tester) async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      await pump(tester, provider, const OverviewScreen());

      expect(provider.analyticsRange, AnalyticsRange.thisMonth);
      await tester.tap(find.text('This Year'));
      await tester.pumpAndSettle();

      expect(provider.analyticsRange, AnalyticsRange.thisYear);
      final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(now: now);
      // The two-month-old dinner is now inside the window.
      expect(snapshot.expense, 4570 + 900);
    });

    testWidgets('settings shows every data-management action',
        (WidgetTester tester) async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      await pump(tester, provider, const SettingsScreen());

      expect(find.text('Export full backup'), findsOneWidget);
      expect(find.text('Restore from backup'), findsOneWidget);
      expect(find.text('Export transactions as CSV'), findsOneWidget);
      expect(find.text('Clear all data'), findsOneWidget);
      expect(find.text('App lock'), findsOneWidget);
      expect(find.text('AMOLED pitch black'), findsOneWidget);
      expect(find.text('Material You colours'), findsOneWidget);
      expect(find.text('Accent colour'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
    });

    testWidgets('theme cards switch the mode and the AMOLED switch follows',
        (WidgetTester tester) async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      await pump(tester, provider, const SettingsScreen());

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(provider.themeMode, ThemePreference.dark);

      await tester.tap(find.text('AMOLED pitch black'));
      await tester.pumpAndSettle();
      expect(provider.themeMode, ThemePreference.amoled);

      // Turning Material You off unlocks the accent picker under it.
      expect(find.text('Available when Material You is off'), findsOneWidget);
      await tester.tap(find.text('Material You colours'));
      await tester.pumpAndSettle();
      expect(provider.useDynamicColor, isFalse);
      expect(find.text('Available when Material You is off'), findsNothing);
      expect(find.text(SeedColor.defaultSeed.name), findsOneWidget);
    });

    testWidgets('currency picker switches the app-wide symbol',
        (WidgetTester tester) async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      await pump(tester, provider, const SettingsScreen());

      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();
      expect(find.text('Search a currency or code'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'US Dollar');
      await tester.pumpAndSettle();
      await tester.tap(find.text('US Dollar'));
      await tester.pumpAndSettle();

      expect(provider.currencyCode, 'USD');
      expect(provider.formatter.symbol, r'$');
    });

    testWidgets('clear-all asks for confirmation and wipes the ledger',
        (WidgetTester tester) async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      await pump(tester, provider, const SettingsScreen());

      await tester.dragUntilVisible(
        find.text('Clear all data'),
        find.byKey(const PageStorageKey<String>('settings_scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear all data'));
      await tester.pumpAndSettle();
      expect(find.text('Clear all data?'), findsOneWidget);

      await tester.tap(find.text('Delete everything'));
      await tester.pumpAndSettle();

      expect(provider.transactions, isEmpty);
      expect(provider.accounts, isEmpty);
    });

    testWidgets('the CSV export helper is reachable from the tile',
        (WidgetTester tester) async {
      final PaisaProvider provider =
          PaisaProvider(storage: storage, initialSettings: storage.loadSettings());
      await pump(tester, provider, const SettingsScreen());

      // The tile states the exact column order the export writes.
      expect(
        find.textContaining('Date, Title, Type, Category, Account, Amount, '
            'Notes'),
        findsOneWidget,
      );
      expect(
        CurrencyFormatter(currency: CurrencyTable.inr).formatWhole(4570),
        '₹4,570',
      );
    });
  });
}
