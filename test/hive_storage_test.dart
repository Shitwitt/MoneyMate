import 'dart:io';

import 'package:flutter/material.dart' show Brightness, ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/core/theme/seed_color.dart';
import 'package:moneymate/core/theme/theme_preference.dart';
import 'package:moneymate/data/local/hive_storage.dart';
import 'package:moneymate/data/models/account_model.dart';
import 'package:moneymate/data/models/category_model.dart';
import 'package:moneymate/data/models/debt_model.dart';
import 'package:moneymate/data/models/debt_summary.dart';
import 'package:moneymate/data/models/debt_transaction_model.dart';
import 'package:moneymate/data/models/settings_model.dart';
import 'package:moneymate/data/models/transaction_model.dart';
import 'package:moneymate/domain/default_data.dart';

/// End-to-end coverage of the offline data layer: seeding, CRUD, derived
/// balances, filtering, debt maths and backup/restore.
///
/// Run with `flutter test`.
void main() {
  final HiveStorage storage = HiveStorage.instance;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('moneymate_test_');
    await storage.init(directoryOverride: tempDir.path);
  });

  tearDownAll(() async {
    await storage.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await storage.clearAll();
  });

  group('seeding', () {
    test('seeds default accounts and categories exactly once', () async {
      final SeedResult first = await storage.seedDefaults();
      expect(first.accountsSeeded, DefaultData.accounts.length);
      expect(first.categoriesSeeded, DefaultData.categories.length);
      expect(first.incomeCategoriesSeeded, DefaultData.incomeCategories.length);

      final SeedResult second = await storage.seedDefaults();
      expect(second.didChange, isFalse);
      expect(storage.getAccounts().length, DefaultData.accounts.length);
      expect(
        storage.getCategories().length,
        DefaultData.categories.length + DefaultData.incomeCategories.length,
      );
    });

    test('exactly one account is the default', () async {
      await storage.seedDefaults();
      final List<AccountModel> accounts = storage.getAccounts();
      expect(accounts.where((AccountModel a) => a.isDefault).length, 1);
      expect(storage.getDefaultAccount()!.id, DefaultData.cashAccountId);
    });

    test('income categories can be excluded from the expense picker', () async {
      await storage.seedDefaults();
      final List<CategoryModel> expenseOnly =
          storage.getCategories(excludeIncome: true);
      expect(
        expenseOnly.any((CategoryModel c) => c.id == DefaultData.salaryCategoryId),
        isFalse,
      );
      expect(expenseOnly.length, DefaultData.categories.length);
    });

    test('every seeded category icon resolves in the registry', () async {
      await storage.seedDefaults();
      for (final CategoryModel category in storage.getCategories()) {
        expect(
          category.icon,
          isNot(0),
          reason: '${category.name} has no persisted icon code point',
        );
      }
    });
  });

  group('accounts', () {
    test('save keeps exactly one default', () async {
      await storage.seedDefaults();
      const AccountModel second = AccountModel(
        id: 'second',
        name: 'Hemanth',
        bankName: 'HDFC Savings',
        number: '1234',
        cardType: AccountType.bank,
        initialAmount: 1000,
        color: 0xFF1E88E5,
        isDefault: true,
      );
      await storage.saveAccount(second);
      final List<AccountModel> accounts = storage.getAccounts();
      expect(accounts.where((AccountModel a) => a.isDefault).length, 1);
      expect(storage.getDefaultAccount()!.id, 'second');
    });

    test('delete removes orphan transactions', () async {
      await storage.seedDefaults();
      await storage.saveTransaction(
        TransactionModel(
          id: 't1',
          name: 'Chai',
          amount: 20,
          time: DateTime(2024, 5, 1, 10),
          type: TransactionType.expense,
          accountId: DefaultData.cashAccountId,
          categoryId: 'seed-category-food',
        ),
      );
      final int removed = await storage.deleteAccount(DefaultData.cashAccountId);
      expect(removed, 1);
      expect(storage.getTransactions(), isEmpty);
      expect(storage.getAccounts().any((AccountModel a) => a.isDefault), isTrue);
    });
  });

  group('balances', () {
    test('expense, income and transfer maths', () async {
      const AccountModel bank = AccountModel(
        id: 'bank',
        name: 'Me',
        bankName: 'Bank',
        number: '0001',
        cardType: AccountType.bank,
        initialAmount: 1000,
        color: 0xFF1E88E5,
      );
      await storage.saveAccount(DefaultData.cashAccount.toModel());
      await storage.saveAccount(bank);

      await storage.saveTransactions(<TransactionModel>[
        TransactionModel(
          id: 'income',
          name: 'Salary',
          amount: 5000,
          time: DateTime(2024, 5, 1),
          type: TransactionType.income,
          accountId: 'bank',
        ),
        TransactionModel(
          id: 'expense',
          name: 'Groceries',
          amount: 500,
          time: DateTime(2024, 5, 2),
          type: TransactionType.expense,
          accountId: 'bank',
          categoryId: 'seed-category-groceries',
        ),
        TransactionModel(
          id: 'transfer',
          name: 'ATM withdrawal',
          amount: 2000,
          time: DateTime(2024, 5, 3),
          type: TransactionType.transfer,
          accountId: 'bank',
          toAccountId: DefaultData.cashAccountId,
        ),
      ]);

      final Map<String, double> balances = storage.getAccountBalances();
      expect(balances['bank'], 1000 + 5000 - 500 - 2000);
      expect(balances[DefaultData.cashAccountId], 2000);

      // A transfer must never change the grand total.
      expect(storage.getTotalBalance(), 1000 + 5000 - 500);
    });

    test('debt installments move real money in the right direction', () async {
      await storage.saveAccount(DefaultData.cashAccount.toModel());
      await storage.saveAccount(
        const AccountModel(
          id: 'bank',
          name: 'Me',
          bankName: 'Bank',
          number: '',
          cardType: AccountType.bank,
          initialAmount: 10000,
          color: 0xFF1E88E5,
        ),
      );

      // Borrowed money: repaying debits the account.
      await storage.saveDebt(
        DebtModel(
          id: 'loan',
          name: 'HDFC Car Loan',
          amount: 100000,
          dateTime: DateTime(2024, 1, 1),
          expiryDateTime: DateTime(2025, 1, 1),
          debtType: DebtType.credit,
        ),
      );
      // Lent money: the collection credits the account.
      await storage.saveDebt(
        DebtModel(
          id: 'lent',
          name: 'Ravi',
          amount: 5000,
          dateTime: DateTime(2024, 1, 1),
          expiryDateTime: DateTime(2024, 12, 1),
          debtType: DebtType.debt,
        ),
      );

      await storage.saveDebtTransaction(
        DebtTransactionModel(
          id: 'emi-1',
          parentId: 'loan',
          amount: 8500,
          dateTime: DateTime(2024, 2, 1),
          accountId: 'bank',
        ),
      );
      await storage.saveDebtTransaction(
        DebtTransactionModel(
          id: 'return-1',
          parentId: 'lent',
          amount: 2000,
          dateTime: DateTime(2024, 2, 2),
          accountId: DefaultData.cashAccountId,
        ),
      );

      expect(storage.getAccountBalance('bank'), 10000 - 8500);
      expect(storage.getAccountBalance(DefaultData.cashAccountId), 2000);
    });
  });

  group('filtering', () {
    test('date ranges follow the Indian Monday-start week', () async {
      final DateTime now = DateTime(2024, 5, 15); // a Wednesday
      final (DateTime, DateTime) daily =
          storage.dateRangeForFilter(FilterExpense.daily, now: now);
      expect(daily.$1, DateTime(2024, 5, 15));
      expect(daily.$2, DateTime(2024, 5, 15));

      final (DateTime, DateTime) weekly =
          storage.dateRangeForFilter(FilterExpense.weekly, now: now);
      expect(weekly.$1, DateTime(2024, 5, 13)); // Monday
      expect(weekly.$2, DateTime(2024, 5, 19)); // Sunday

      final (DateTime, DateTime) monthly =
          storage.dateRangeForFilter(FilterExpense.monthly, now: now);
      expect(monthly.$1, DateTime(2024, 5, 1));
      expect(monthly.$2, DateTime(2024, 5, 31));

      final (DateTime, DateTime) yearly =
          storage.dateRangeForFilter(FilterExpense.yearly, now: now);
      expect(yearly.$1, DateTime(2024, 1, 1));
      expect(yearly.$2, DateTime(2024, 12, 31));
    });

    test('getTransactionsBetween is inclusive and newest-first', () async {
      await storage.saveAccount(DefaultData.cashAccount.toModel());
      await storage.saveTransactions(<TransactionModel>[
        TransactionModel(
          id: 'a',
          name: 'First',
          amount: 10,
          time: DateTime(2024, 5, 1, 0, 0),
          type: TransactionType.expense,
          accountId: DefaultData.cashAccountId,
        ),
        TransactionModel(
          id: 'b',
          name: 'Last',
          amount: 20,
          time: DateTime(2024, 5, 31, 23, 59),
          type: TransactionType.expense,
          accountId: DefaultData.cashAccountId,
        ),
        TransactionModel(
          id: 'c',
          name: 'Outside',
          amount: 30,
          time: DateTime(2024, 6, 1),
          type: TransactionType.expense,
          accountId: DefaultData.cashAccountId,
        ),
      ]);

      final List<TransactionModel> may = storage.getTransactionsBetween(
        DateTime(2024, 5, 1),
        DateTime(2024, 5, 31),
      );
      expect(may.map((TransactionModel t) => t.id), <String>['b', 'a']);
    });

    test('spendingByCategory aggregates expenses only', () async {
      await storage.saveAccount(DefaultData.cashAccount.toModel());
      await storage.saveTransactions(<TransactionModel>[
        TransactionModel(
          id: '1',
          name: 'Lunch',
          amount: 300,
          time: DateTime(2024, 5, 2),
          type: TransactionType.expense,
          accountId: DefaultData.cashAccountId,
          categoryId: 'seed-category-food',
        ),
        TransactionModel(
          id: '2',
          name: 'Dinner',
          amount: 200,
          time: DateTime(2024, 5, 3),
          type: TransactionType.expense,
          accountId: DefaultData.cashAccountId,
          categoryId: 'seed-category-food',
        ),
        TransactionModel(
          id: '3',
          name: 'Salary',
          amount: 5000,
          time: DateTime(2024, 5, 4),
          type: TransactionType.income,
          accountId: DefaultData.cashAccountId,
        ),
      ]);
      expect(storage.spendingByCategory()['seed-category-food'], 500);
    });
  });

  group('categories', () {
    test('deleting a category detaches its transactions', () async {
      await storage.seedDefaults();
      await storage.saveTransaction(
        TransactionModel(
          id: 't1',
          name: 'Movie',
          amount: 400,
          time: DateTime(2024, 5, 5),
          type: TransactionType.expense,
          accountId: DefaultData.cashAccountId,
          categoryId: 'seed-category-entertainment',
        ),
      );
      final int detached = await storage.deleteCategory('seed-category-entertainment');
      expect(detached, 1);
      expect(storage.getCategory('seed-category-entertainment'), isNull);
      expect(storage.getTransaction('t1')!.categoryId, isNull);
    });
  });

  group('debts', () {
    test('summaries track outstanding and progress', () async {
      await storage.saveAccount(DefaultData.cashAccount.toModel());
      await storage.saveDebt(
        DebtModel(
          id: 'borrowed',
          name: 'SBI Personal Loan',
          amount: 10000,
          dateTime: DateTime(2024, 1, 1),
          expiryDateTime: DateTime(2024, 6, 1),
          debtType: DebtType.credit,
        ),
      );
      await storage.saveDebtTransaction(
        DebtTransactionModel(
          id: 'p1',
          parentId: 'borrowed',
          amount: 4000,
          dateTime: DateTime(2024, 2, 1),
          accountId: DefaultData.cashAccountId,
        ),
      );

      final DebtSummary summary = storage.getDebtSummary('borrowed')!;
      expect(summary.paidAmount, 4000);
      expect(summary.outstandingAmount, 6000);
      expect(summary.progress, closeTo(0.4, 0.0001));
      expect(summary.isSettled, isFalse);
      expect(storage.getTotalBorrowed(), 6000);
      expect(storage.getTotalLent(), 0);

      // Deleting the parent removes its installments.
      expect(await storage.deleteDebt('borrowed'), 1);
      expect(storage.getDebtTransactions(), isEmpty);
    });
  });

  group('serialization robustness', () {
    test('models survive missing and mistyped map values', () {
      final AccountModel account = AccountModel.fromMap(<dynamic, dynamic>{
        'id': 'x',
        'initialAmount': '1500',
        'isDefault': 1,
        'cardType': 'not-a-type',
      });
      expect(account.initialAmount, 1500);
      expect(account.isDefault, isTrue);
      expect(account.cardType, AccountType.cash);

      final TransactionModel transaction =
          TransactionModel.fromMap(<dynamic, dynamic>{'id': 't'});
      expect(transaction.amount, 0);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.time, isA<DateTime>());

      final DebtModel debt = DebtModel.fromMap(<dynamic, dynamic>{'id': 'd'});
      expect(debt.debtType, DebtType.debt);
      expect(debt.expiryDateTime.isAfter(debt.dateTime), isTrue);
    });

    test('model round-trips preserve every field', () {
      final TransactionModel original = TransactionModel(
        id: 'tx',
        name: 'Coffee',
        amount: 120.5,
        time: DateTime(2024, 3, 4, 9, 30),
        type: TransactionType.transfer,
        accountId: 'a',
        toAccountId: 'b',
        categoryId: 'c',
        description: 'Morning',
      );
      expect(TransactionModel.fromMap(original.toMap()), original);
    });
  });

  group('settings', () {
    test('defaults, save and reload', () async {
      final SettingsModel defaults = storage.loadSettings();
      expect(defaults.onboardingComplete, isFalse);
      expect(defaults.seed, SeedColor.defaultSeed);

      final SettingsModel updated = defaults.copyWith(
        onboardingComplete: true,
        userName: 'Hemanth',
        themePreference: ThemePreference.amoled,
        seed: SeedColor.palette[4],
        useDynamicColor: false,
      );
      await storage.saveSettings(updated);

      final SettingsModel reloaded = storage.loadSettings();
      expect(reloaded, updated);
      expect(reloaded.greetingName, 'Hemanth');
      expect(reloaded.themeSettings.preference, ThemePreference.amoled);
      expect(reloaded.seed.name, 'Orange');
    });

    test('amoled maps to the dark MaterialApp theme mode', () {
      expect(ThemePreference.amoled.materialThemeMode, ThemeMode.dark);
      expect(ThemePreference.amoled.isAmoled, isTrue);
      expect(ThemePreference.system.resolve(Brightness.dark), ThemePreference.dark);
    });
  });

  group('backup', () {
    test('export and restore round-trips every record', () async {
      await storage.seedDefaults();
      await storage.saveAccount(
        const AccountModel(
          id: 'bank',
          name: 'Me',
          bankName: 'HDFC',
          number: '4242',
          cardType: AccountType.bank,
          initialAmount: 2500,
          color: 0xFF1E88E5,
          isDefault: true,
        ),
      );
      await storage.saveTransaction(
        TransactionModel(
          id: 'tx',
          name: 'Rent',
          amount: 15000,
          time: DateTime(2024, 4, 1),
          type: TransactionType.expense,
          accountId: 'bank',
          categoryId: 'seed-category-rent',
        ),
      );
      await storage.saveDebt(
        DebtModel(
          id: 'debt',
          name: 'Ravi',
          amount: 2000,
          dateTime: DateTime(2024, 4, 1),
          expiryDateTime: DateTime(2024, 5, 1),
          debtType: DebtType.debt,
        ),
      );
      await storage.saveDebtTransaction(
        DebtTransactionModel(
          id: 'inst',
          parentId: 'debt',
          amount: 500,
          dateTime: DateTime(2024, 4, 10),
          accountId: 'bank',
        ),
      );

      final String json = storage.exportBackupAsJson();
      final int restored = await storage.restoreBackupFromJson(json);

      expect(restored, greaterThan(0));
      expect(storage.getAccount('bank')!.initialAmount, 2500);
      expect(storage.getTransaction('tx')!.amount, 15000);
      expect(storage.getDebtSummary('debt')!.paidAmount, 500);
      expect(
        storage.getCategories().length,
        DefaultData.categories.length + DefaultData.incomeCategories.length,
      );
    });

    test('restore rejects a foreign file', () async {
      expect(
        () => storage.restoreBackupFromJson('{"app":"something-else"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
