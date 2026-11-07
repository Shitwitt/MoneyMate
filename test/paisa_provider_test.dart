import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/core/theme/theme_preference.dart';
import 'package:moneymate/core/utils/currency_formatter.dart';
import 'package:moneymate/data/local/hive_storage.dart';
import 'package:moneymate/data/models/account_model.dart';
import 'package:moneymate/data/models/category_budget_stat.dart';
import 'package:moneymate/data/models/category_model.dart';
import 'package:moneymate/data/models/debt_model.dart';
import 'package:moneymate/data/models/debt_transaction_model.dart';
import 'package:moneymate/data/models/transaction_model.dart';
import 'package:moneymate/providers/paisa_provider.dart';

/// Exercises the financial engine end-to-end against a real (temporary) Hive
/// database: balances, period summaries, budgets, installments and onboarding.
void main() {
  final HiveStorage storage = HiveStorage.instance;
  late Directory tempDir;
  late PaisaProvider provider;

  const String bankId = 'bank';
  const String cashId = 'cash';
  const String cardId = 'card';

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('moneymate_provider_');
    await storage.init(directoryOverride: tempDir.path);
  });

  tearDownAll(() async {
    await storage.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await storage.clearAll();
    await storage.saveAccount(
      const AccountModel(
        id: bankId,
        name: 'Me',
        bankName: 'HDFC Savings',
        number: '4242',
        cardType: AccountType.bank,
        initialAmount: 10000,
        color: 0xFF1E88E5,
        isDefault: true,
      ),
    );
    await storage.saveAccount(
      const AccountModel(
        id: cashId,
        name: 'Me',
        bankName: 'Cash',
        number: '',
        cardType: AccountType.cash,
        initialAmount: 500,
        color: 0xFF43A047,
      ),
    );
    await storage.saveAccount(
      const AccountModel(
        id: cardId,
        name: 'Me',
        bankName: 'HDFC Credit Card',
        number: '1111',
        cardType: AccountType.card,
        initialAmount: 0,
        color: 0xFF8E24AA,
      ),
    );
    await storage.saveCategory(
      const CategoryModel(
        id: 'food',
        name: 'Food & Dining',
        icon: 0xe56c,
        color: 0xFFF4511E,
        budget: 6000,
        isBudgetActive: true,
      ),
    );
    await storage.saveCategory(
      const CategoryModel(
        id: 'travel',
        name: 'Travel',
        icon: 0xe1d7,
        color: 0xFF1E88E5,
        budget: 2000,
        isBudgetActive: true,
      ),
    );

    provider = PaisaProvider(storage: storage);
  });

  Future<TransactionModel> put({
    required String id,
    required double amount,
    required TransactionType type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    DateTime? time,
    String? description,
  }) {
    final TransactionModel model = TransactionModel(
      id: id,
      name: id,
      amount: amount,
      time: time ?? DateTime.now(),
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      description: description,
    );
    return provider.addTransaction(model);
  }

  group('account balances', () {
    test('implements the exact formula from the spec', () async {
      await put(
        id: 'inc',
        amount: 5000,
        type: TransactionType.income,
        accountId: bankId,
      );
      await put(
        id: 'exp',
        amount: 1200,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
      );
      await put(
        id: 'trf',
        amount: 3000,
        type: TransactionType.transfer,
        accountId: bankId,
        toAccountId: cashId,
      );

      // balance = initial + income - expense - transferOut + transferIn
      expect(
        provider.accountBalance(bankId),
        10000 + 5000 - 1200 - 3000,
      );
      expect(provider.accountBalance(cashId), 500 + 3000);
      expect(provider.accountBalance(cardId), 0);
    });

    test('totalNetBalance is the sum of live balances', () async {
      await put(
        id: 'exp',
        amount: 2000,
        type: TransactionType.expense,
        accountId: cardId,
        categoryId: 'food',
      );
      const double expected = 10000 + 500 + 0 - 2000;
      expect(provider.totalNetBalance, expected);
      expect(
        provider.totalNetBalance,
        closeTo(
          provider.accounts
              .map((AccountModel a) => provider.accountBalance(a.id))
              .fold<double>(0, (double s, double v) => s + v),
          0.001,
        ),
      );
      expect(provider.totalLiabilities, 2000);
      expect(provider.totalAssets, 10500);
    });

    test('a transfer never changes the total net balance', () async {
      final double before = provider.totalNetBalance;
      await put(
        id: 'trf',
        amount: 4000,
        type: TransactionType.transfer,
        accountId: bankId,
        toAccountId: cardId,
      );
      expect(provider.totalNetBalance, before);
      expect(provider.accountBalance(bankId), 6000);
      expect(provider.accountBalance(cardId), 4000);
    });

    test('unknown accounts cannot corrupt the map', () async {
      // Saving straight to storage bypasses provider validation, simulating an
      // orphaned row from an older build.
      await storage.saveTransaction(
        TransactionModel(
          id: 'orphan',
          name: 'orphan',
          amount: 999,
          time: DateTime.now(),
          type: TransactionType.expense,
          accountId: 'ghost-account',
        ),
      );
      provider.refresh();
      expect(provider.accountBalance('ghost-account'), 0);
      expect(provider.totalNetBalance, 10500);
    });
  });

  group('period summary', () {
    test('transfers are never counted as income or expense', () async {
      final DateTime now = DateTime.now();
      await put(
        id: 'inc',
        amount: 5000,
        type: TransactionType.income,
        accountId: bankId,
        time: now,
      );
      await put(
        id: 'exp',
        amount: 1500,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );
      await put(
        id: 'trf',
        amount: 9000,
        type: TransactionType.transfer,
        accountId: bankId,
        toAccountId: cashId,
        time: now,
      );

      await provider.setSelectedTimeFilter(FilterExpense.daily);
      expect(provider.periodIncome, 5000);
      expect(provider.periodExpense, 1500);
      expect(provider.periodTransferVolume, 9000);
      expect(provider.periodNet, 3500);
      expect(provider.periodTransactionCount, 3);
    });

    test('period windows match the calendar', () async {
      final DateTime now = DateTime.now();
      final (DateTime, DateTime) daily = provider.periodRange(FilterExpense.daily, now);
      expect(daily.$1, DateTime(now.year, now.month, now.day));
      expect(daily.$2, daily.$1);

      final (DateTime, DateTime) monthly =
          provider.periodRange(FilterExpense.monthly, now);
      expect(monthly.$1, DateTime(now.year, now.month, 1));
      expect(monthly.$2.day, DateTime(now.year, now.month + 1, 0).day);

      final (DateTime, DateTime) yearly =
          provider.periodRange(FilterExpense.yearly, now);
      expect(yearly.$1, DateTime(now.year));
      expect(yearly.$2, DateTime(now.year, 12, 31));
    });

    test('only this period counts', () async {
      final DateTime now = DateTime.now();
      final DateTime lastMonth = DateTime(now.year, now.month - 1, 15);
      await put(
        id: 'old',
        amount: 9999,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: lastMonth,
      );
      await put(
        id: 'now',
        amount: 100,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );

      await provider.setSelectedTimeFilter(FilterExpense.monthly);
      expect(provider.periodExpense, 100);
      await provider.setSelectedTimeFilter(FilterExpense.all);
      expect(provider.periodExpense, greaterThanOrEqualTo(10099 - 0.01));
    });

    test('dailyTotals skips transfers and fills every day', () async {
      final DateTime now = DateTime.now();
      await put(
        id: 'inc',
        amount: 1000,
        type: TransactionType.income,
        accountId: bankId,
        time: now,
      );
      await put(
        id: 'exp',
        amount: 400,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );
      await put(
        id: 'trf',
        amount: 700,
        type: TransactionType.transfer,
        accountId: bankId,
        toAccountId: cashId,
        time: now,
      );

      final List<DailyTotal> totals =
          provider.dailyTotals(FilterExpense.monthly, now);
      final DateTime lastDay = DateTime(now.year, now.month + 1, 0);
      expect(totals.length, lastDay.day);
      expect(totals[now.day - 1].income, 1000);
      expect(totals[now.day - 1].expense, 400);
      expect(
        totals.fold<double>(0, (double s, DailyTotal t) => s + t.income),
        1000,
      );
      expect(
        totals.fold<double>(0, (double s, DailyTotal t) => s + t.expense),
        400,
      );
    });
  });

  group('budget math', () {
    test('spend, usage, remaining and daily allowance', () async {
      final DateTime now = DateTime.now();
      await put(
        id: 'food1',
        amount: 1500,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );
      await put(
        id: 'food2',
        amount: 500,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );
      // Income in the same category must not offset spending.
      await put(
        id: 'refund',
        amount: 200,
        type: TransactionType.income,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );

      final CategoryBudgetStat stat = provider.budgetStatFor('food')!;
      expect(stat.spent, 2000);
      expect(stat.usedFraction, closeTo(2000 / 6000, 0.0001));
      expect(stat.remaining, 4000);
      expect(provider.daysLeftInMonth, greaterThanOrEqualTo(1));
      expect(
        stat.dailyAllowance,
        closeTo(4000 / provider.daysLeftInMonth, 0.0001),
      );
      expect(stat.isOverBudget, isFalse);
    });

    test('over-budget categories are flagged and remaining goes negative', () async {
      final DateTime now = DateTime.now();
      await put(
        id: 'big',
        amount: 8000,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );
      final CategoryBudgetStat stat = provider.budgetStatFor('food')!;
      expect(stat.isOverBudget, isTrue);
      expect(stat.remaining, -2000);
      expect(stat.progress, 1.0); // clamped for the ring
      expect(stat.usedFraction, greaterThan(1));
      expect(stat.dailyAllowance, 0);
      expect(provider.overBudgetCategories.map((s) => s.categoryId), contains('food'));
    });

    test('total budget aggregates only active budgets', () async {
      final DateTime now = DateTime.now();
      await put(
        id: 'food',
        amount: 1000,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'food',
        time: now,
      );
      expect(provider.totalMonthlyBudget, 8000);
      expect(provider.totalMonthlySpend, 1000);
      expect(provider.totalBudgetRemaining, 7000);
      expect(provider.totalBudgetProgress, closeTo(1000 / 8000, 0.0001));
      expect(
        provider.safeDailySpend,
        closeTo(7000 / provider.daysLeftInMonth, 0.0001),
      );
    });

    test('setting a budget updates the stat', () async {
      await provider.setCategoryBudget('travel', budget: 5000);
      final CategoryModel travel = provider.categoryById('travel')!;
      expect(travel.budget, 5000);
      expect(travel.isBudgetActive, isTrue);
      await provider.setCategoryBudget('travel', budget: 0);
      expect(provider.categoryById('travel')!.isBudgetActive, isFalse);
    });
  });

  group('debts and installments', () {
    test('lent money repaid writes income and raises the balance', () async {
      await provider.addDebt(
        DebtModel(
          id: 'lent',
          name: 'Ravi',
          amount: 5000,
          dateTime: DateTime.now().subtract(const Duration(days: 10)),
          expiryDateTime: DateTime.now().add(const Duration(days: 20)),
          debtType: DebtType.debt,
        ),
      );
      final double before = provider.accountBalance(bankId);

      await provider.addDebtInstallment(
        parentId: 'lent',
        amount: 2000,
        dateTime: DateTime.now(),
        accountId: bankId,
      );

      expect(provider.accountBalance(bankId), before + 2000);
      expect(provider.paidAmountFor('lent'), 2000);
      expect(provider.remainingAmountFor('lent'), 3000);
      expect(provider.progressFor('lent'), closeTo(0.4, 0.0001));

      // A linked income row exists but is excluded from period summaries.
      expect(
        provider.transactions.any(
          (TransactionModel t) =>
              t.type == TransactionType.income &&
              PaisaProvider.isLinkedDebtTransaction(t),
        ),
        isTrue,
      );
      expect(provider.periodIncome, 0);
      expect(provider.ledgerTransactions.length, 0);
    });

    test('borrowed money repayment writes an expense and lowers the balance',
        () async {
      await provider.addDebt(
        DebtModel(
          id: 'loan',
          name: 'SBI Car Loan',
          amount: 100000,
          dateTime: DateTime.now().subtract(const Duration(days: 30)),
          expiryDateTime: DateTime.now().add(const Duration(days: 300)),
          debtType: DebtType.credit,
        ),
      );
      final double before = provider.accountBalance(bankId);

      await provider.addDebtInstallment(
        parentId: 'loan',
        amount: 8500,
        dateTime: DateTime.now(),
        accountId: bankId,
        note: 'EMI 1',
      );

      expect(provider.accountBalance(bankId), before - 8500);
      expect(provider.paidAmountFor('loan'), 8500);
      expect(provider.progressFor('loan'), closeTo(0.085, 0.0001));
      expect(provider.totalBorrowed, 91500);
      expect(provider.periodExpense, 0);
    });

    test('progress is clamped and never divides by zero', () async {
      await provider.addDebt(
        DebtModel(
          id: 'zero',
          name: 'Zero',
          amount: 0,
          dateTime: DateTime.now(),
          expiryDateTime: DateTime.now().add(const Duration(days: 1)),
          debtType: DebtType.debt,
        ),
      );
      expect(provider.progressFor('zero'), 0);
      expect(provider.remainingAmountFor('zero'), 0);
    });

    test('over-payment is rejected', () async {
      await provider.addDebt(
        DebtModel(
          id: 'small',
          name: 'Small',
          amount: 100,
          dateTime: DateTime.now(),
          expiryDateTime: DateTime.now().add(const Duration(days: 5)),
          debtType: DebtType.credit,
        ),
      );
      expect(
        () => provider.addDebtInstallment(
          parentId: 'small',
          amount: 500,
          dateTime: DateTime.now(),
          accountId: bankId,
        ),
        throwsA(isA<TransactionException>()),
      );
    });

    test('deleting an installment removes its linked ledger row', () async {
      await provider.addDebt(
        DebtModel(
          id: 'lent',
          name: 'Asha',
          amount: 1000,
          dateTime: DateTime.now(),
          expiryDateTime: DateTime.now().add(const Duration(days: 5)),
          debtType: DebtType.debt,
        ),
      );
      final DebtTransactionModel installment = await provider.addDebtInstallment(
        parentId: 'lent',
        amount: 400,
        dateTime: DateTime.now(),
        accountId: bankId,
      );
      final double afterPayment = provider.accountBalance(bankId);
      expect(
        provider.transactions.any((TransactionModel t) => t.id ==
            PaisaProvider.linkedTransactionId(installment.id)),
        isTrue,
      );

      await provider.deleteDebtInstallment(installment.id);
      expect(provider.accountBalance(bankId), afterPayment - 400);
      expect(provider.paidAmountFor('lent'), 0);
    });

    test('repairDebtLedger heals installments saved without a mirror row',
        () async {
      await storage.saveDebt(
        DebtModel(
          id: 'orphan',
          name: 'Orphan',
          amount: 1000,
          dateTime: DateTime.now(),
          expiryDateTime: DateTime.now().add(const Duration(days: 5)),
          debtType: DebtType.credit,
        ),
      );
      await storage.saveDebtTransaction(
        DebtTransactionModel(
          id: 'inst',
          parentId: 'orphan',
          amount: 250,
          dateTime: DateTime.now(),
          accountId: bankId,
        ),
      );
      provider.refresh();
      expect(provider.periodExpense, 0);

      final int repaired = await provider.repairDebtLedger();
      expect(repaired, 1);
      expect(
        provider.transactions.any((TransactionModel t) =>
            t.id == PaisaProvider.linkedTransactionId('inst')),
        isTrue,
      );
      // Running it again is a no-op.
      expect(await provider.repairDebtLedger(), 0);
    });
  });

  group('transaction validation', () {
    test('rejects zero amounts, empty titles and unknown accounts', () async {
      await expectLater(
        put(id: 'a', amount: 0, type: TransactionType.expense, accountId: bankId),
        throwsA(isA<TransactionException>()),
      );
      await expectLater(
        put(id: 'b', amount: 10, type: TransactionType.expense, accountId: 'nope'),
        throwsA(isA<TransactionException>()),
      );
      await expectLater(
        provider.addTransaction(
          TransactionModel(
            id: 'c',
            name: '   ',
            amount: 10,
            time: DateTime.now(),
            type: TransactionType.expense,
            accountId: bankId,
          ),
        ),
        throwsA(isA<TransactionException>()),
      );
    });

    test('transfers need two distinct existing accounts', () async {
      await expectLater(
        put(
          id: 'trf1',
          amount: 100,
          type: TransactionType.transfer,
          accountId: bankId,
        ),
        throwsA(isA<TransactionException>()),
      );
      await expectLater(
        put(
          id: 'trf2',
          amount: 100,
          type: TransactionType.transfer,
          accountId: bankId,
          toAccountId: bankId,
        ),
        throwsA(isA<TransactionException>()),
      );
    });

    test('an orphaned category is dropped instead of blocking entry', () async {
      final TransactionModel saved = await put(
        id: 'x',
        amount: 100,
        type: TransactionType.expense,
        accountId: bankId,
        categoryId: 'deleted-category',
      );
      expect(saved.categoryId, isNull);
    });

    test('transfers never carry a category', () async {
      final TransactionModel saved = await put(
        id: 'trf',
        amount: 100,
        type: TransactionType.transfer,
        accountId: bankId,
        toAccountId: cashId,
        categoryId: 'food',
      );
      expect(saved.categoryId, isNull);
      expect(saved.toAccountId, cashId);
    });
  });

  group('settings', () {
    test('currency switch updates symbol, locale and formatting', () async {
      await provider.setCurrency('USD');
      expect(provider.currencyCode, 'USD');
      expect(provider.currencySymbol, r'$');
      expect(provider.locale, 'en_US');
      expect(provider.formatter.format(125450), contains('125,450'));

      await provider.setCurrency('INR');
      expect(provider.formatter.format(125450), contains('1,25,450'));
    });

    test('amoled toggle moves between dark and amoled', () async {
      await provider.setAmoled(true);
      expect(provider.isAmoled, isTrue);
      expect(provider.themeMode.materialThemeMode, ThemeMode.dark);
      await provider.setAmoled(false);
      expect(provider.isAmoled, isFalse);
      expect(provider.themeMode, ThemePreference.dark);
    });

    test('hide amounts masks the formatter', () async {
      await provider.setHideAmounts(true);
      expect(
        provider.formatter.format(500),
        CurrencyFormatter.maskedAmount,
      );
    });

    test('profile fields persist', () async {
      await provider.setUserName('  Hemanth  ');
      await provider.setAvatarIndex(3);
      expect(provider.userName, 'Hemanth');
      expect(provider.userAvatarIndex, 3);
      expect(provider.avatar.label, 'Investor');
      expect(PaisaProvider(storage: storage).userName, 'Hemanth');
    });
  });

  group('onboarding', () {
    test('completeOnboarding seeds accounts, categories and settings', () async {
      await storage.clearAll();
      final PaisaProvider fresh = PaisaProvider(storage: storage);
      expect(fresh.isOnboardingComplete, isFalse);

      await fresh.completeOnboarding(
        name: 'Hemanth',
        avatarIndex: 2,
        languageCode: 'hi',
        currencyCode: 'INR',
        selectedAccounts: <AccountModel>[
          const AccountModel(
            id: 'onboarding-account-bank',
            name: 'Hemanth',
            bankName: 'Bank Account',
            number: '',
            cardType: AccountType.bank,
            initialAmount: 25000,
            color: 0xFF1E88E5,
            isDefault: true,
          ),
        ],
        selectedCategories: <CategoryModel>[
          const CategoryModel(
            id: 'seed-category-food',
            name: 'Food & Dining',
            icon: 0xe56c,
            color: 0xFFF4511E,
            budget: 6000,
            isBudgetActive: true,
            isDefault: true,
          ),
        ],
      );

      expect(fresh.isOnboardingComplete, isTrue);
      expect(fresh.userName, 'Hemanth');
      expect(fresh.languageCode, 'hi');
      expect(fresh.accounts.length, 1);
      expect(fresh.accounts.first.initialAmount, 25000);
      expect(fresh.accounts.first.isDefault, isTrue);
      expect(fresh.accountBalance('onboarding-account-bank'), 25000);
      expect(fresh.totalNetBalance, 25000);
      expect(
        fresh.categories.any((CategoryModel c) => c.id == 'seed-category-food'),
        isTrue,
      );
      // Income categories are added because incomeTracking defaults to true.
      expect(
        fresh.categories.any((CategoryModel c) => c.id == 'seed-category-salary'),
        isTrue,
      );
    });
  });
}
