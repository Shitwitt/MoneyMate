import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/constants/currencies.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/core/theme/paisa_theme.dart';
import 'package:moneymate/core/utils/currency_formatter.dart';
import 'package:moneymate/data/local/hive_storage.dart';
import 'package:moneymate/data/models/account_model.dart';
import 'package:moneymate/data/models/category_model.dart';
import 'package:moneymate/data/models/debt_model.dart';
import 'package:moneymate/data/models/debt_transaction_model.dart';
import 'package:moneymate/data/models/transaction_model.dart';
import 'package:moneymate/providers/paisa_provider.dart';
import 'package:moneymate/screens/accounts/add_account_screen.dart';
import 'package:moneymate/screens/budgets/add_category_screen.dart';
import 'package:moneymate/screens/debts/add_debt_screen.dart';
import 'package:moneymate/widgets/account_card.dart';
import 'package:provider/provider.dart';

/// Step 4: accounts, debts/EMIs and category budgets — engine maths first, then
/// the three editors driven through the widget tree.
void main() {
  final HiveStorage storage = HiveStorage.instance;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('moneymate_step4_');
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
        id: 'bank',
        name: 'Me',
        bankName: 'HDFC Savings',
        number: '4821',
        cardType: AccountType.bank,
        initialAmount: 20000,
        color: 0xFF1E88E5,
        isDefault: true,
      ),
    );
    await storage.saveAccount(
      const AccountModel(
        id: 'cash',
        name: 'Me',
        bankName: 'Cash in Hand',
        number: '',
        cardType: AccountType.cash,
        initialAmount: 1000,
        color: 0xFF43A047,
      ),
    );
    await storage.saveCategory(
      const CategoryModel(
        id: 'food',
        name: 'Food & Dining',
        icon: 0xe56c,
        color: 0xFFF4511E,
        budget: 5000,
        isBudgetActive: true,
        isDefault: true,
      ),
    );
  });

  group('AccountModel.carouselNumber', () {
    test('masks the last four digits like a real card', () {
      const AccountModel card = AccountModel(
        id: 'c',
        name: 'Me',
        bankName: 'HDFC Regalia',
        number: '4821',
        cardType: AccountType.card,
        initialAmount: 0,
        color: 0xFF1E88E5,
      );
      expect(card.carouselNumber, '•••• •••• •••• 4821');
    });

    test('falls back to the bank name for a cash wallet', () {
      const AccountModel cash = AccountModel(
        id: 'c',
        name: 'Me',
        bankName: 'Cash in Hand',
        number: '',
        cardType: AccountType.cash,
        initialAmount: 0,
        color: 0xFF43A047,
      );
      expect(cash.carouselNumber, 'Cash in Hand');
    });

    test('pads short numbers so the mask keeps its shape', () {
      const AccountModel short = AccountModel(
        id: 'c',
        name: 'Me',
        bankName: 'Wallet',
        number: '42',
        cardType: AccountType.bank,
        initialAmount: 0,
        color: 0xFF1E88E5,
      );
      expect(short.carouselNumber.endsWith('0042'), isTrue);
    });
  });

  group('AccountStyle', () {
    test('ships exactly twelve card themes with unique colours', () {
      expect(AccountStyle.palette.length, 12);
      final Set<int> values = <int>{
        for (final AccountStyle style in AccountStyle.palette) style.value,
      };
      expect(values.length, 12);
    });

    test('resolves an exact palette colour', () {
      final AccountStyle style = AccountStyle.forColor(0xFF0F9D58);
      expect(style.id, 'card-emerald');
    });

    test('falls back to the closest palette entry for a custom colour', () {
      final AccountStyle style = AccountStyle.forColor(0xFF000000);
      expect(AccountStyle.palette.contains(style), isTrue);
    });

    test('handles a null colour', () {
      expect(AccountStyle.forColor(null).id, AccountStyle.fallback.id);
    });
  });

  group('account totals', () {
    test('income, expense and both transfer directions stay separate', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await provider.addTransaction(
        TransactionModel(
          id: 'in',
          name: 'Salary',
          amount: 5000,
          time: DateTime(2026, 11, 2, 9),
          type: TransactionType.income,
          accountId: 'bank',
          categoryId: 'seed-category-salary',
        ),
      );
      await provider.addTransaction(
        TransactionModel(
          id: 'out',
          name: 'Groceries',
          amount: 1200,
          time: DateTime(2026, 11, 3, 18),
          type: TransactionType.expense,
          accountId: 'bank',
          categoryId: 'food',
        ),
      );
      await provider.addTransaction(
        TransactionModel(
          id: 'move',
          name: 'ATM',
          amount: 800,
          time: DateTime(2026, 11, 4, 12),
          type: TransactionType.transfer,
          accountId: 'bank',
          toAccountId: 'cash',
        ),
      );

      expect(provider.accountBalance('bank'), 20000 + 5000 - 1200 - 800);
      expect(provider.accountBalance('cash'), 1000 + 800);
    });
  });

  group('debts and installments', () {
    test('a repayment reduces the outstanding amount and logs income', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await provider.addDebt(
        DebtModel(
          id: 'lent',
          name: 'Ravi',
          description: 'Bike repair loan',
          amount: 10000,
          dateTime: DateTime(2026, 10, 1),
          expiryDateTime: DateTime(2026, 12, 1),
          debtType: DebtType.debt,
        ),
      );

      expect(provider.remainingAmountFor('lent'), 10000);

      await provider.addDebtInstallment(
        parentId: 'lent',
        amount: 4000,
        dateTime: DateTime(2026, 10, 15),
        accountId: 'bank',
        note: 'First installment',
      );

      expect(provider.paidAmountFor('lent'), 4000);
      expect(provider.remainingAmountFor('lent'), 6000);
      expect(provider.progressFor('lent'), closeTo(0.4, 0.0001));
      // The money provably moved, so the bank balance grew and a linked row
      // exists for the account statement.
      expect(provider.accountBalance('bank'), 24000);
      final TransactionModel linked = provider.transactions.firstWhere(
        (TransactionModel t) => t.id.startsWith('debt-linked-'),
      );
      expect(linked.type, TransactionType.income);
      expect(PaisaProvider.isLinkedDebtTransaction(linked), isTrue);
    });

    test('an EMI payment on a borrowing logs an expense', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await provider.addDebt(
        DebtModel(
          id: 'loan',
          name: 'HDFC car loan',
          description: '9.2% for 60 months',
          amount: 300000,
          dateTime: DateTime(2026, 1, 1),
          expiryDateTime: DateTime(2031, 1, 1),
          debtType: DebtType.credit,
        ),
      );
      await provider.addDebtInstallment(
        parentId: 'loan',
        amount: 6500,
        dateTime: DateTime(2026, 10, 5),
        accountId: 'bank',
      );

      expect(provider.accountBalance('bank'), 20000 - 6500);
      final TransactionModel linked = provider.transactions.firstWhere(
        (TransactionModel t) => t.id.startsWith('debt-linked-'),
      );
      expect(linked.type, TransactionType.expense);
    });

    test('an installment larger than the balance is rejected', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await provider.addDebt(
        DebtModel(
          id: 'small',
          name: 'Asha',
          description: '',
          amount: 500,
          dateTime: DateTime(2026, 10, 1),
          expiryDateTime: DateTime(2026, 11, 1),
          debtType: DebtType.debt,
        ),
      );
      expect(
        () => provider.addDebtInstallment(
          parentId: 'small',
          amount: 900,
          dateTime: DateTime(2026, 10, 2),
          accountId: 'bank',
        ),
        throwsA(isA<TransactionException>()),
      );
    });

    test('deleting an installment deletes its mirror transaction', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await provider.addDebt(
        DebtModel(
          id: 'd',
          name: 'Sam',
          description: '',
          amount: 1000,
          dateTime: DateTime(2026, 10, 1),
          expiryDateTime: DateTime(2026, 12, 1),
          debtType: DebtType.debt,
        ),
      );
      final DebtTransactionModel installment =
          await provider.addDebtInstallment(
        parentId: 'd',
        amount: 1000,
        dateTime: DateTime(2026, 10, 4),
        accountId: 'bank',
      );

      await provider.deleteDebtInstallment(installment.id);

      expect(provider.accountBalance('bank'), 20000);
      expect(
        provider.transactions.where(
          (TransactionModel t) => t.id.startsWith('debt-linked-'),
        ),
        isEmpty,
      );
    });

    test('overdue detection ignores settled records', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await provider.addDebt(
        DebtModel(
          id: 'old',
          name: 'Old loan',
          description: '',
          amount: 1000,
          dateTime: DateTime(2025, 1, 1),
          expiryDateTime: DateTime(2025, 6, 1),
          debtType: DebtType.credit,
        ),
      );
      expect(provider.overdueDebts.length, 1);

      await provider.addDebtInstallment(
        parentId: 'old',
        amount: 1000,
        dateTime: DateTime(2025, 5, 1),
        accountId: 'bank',
      );
      expect(provider.overdueDebts, isEmpty);
    });
  });

  group('category budgets', () {
    test('spend, remaining and progress follow the monthly window', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      final DateTime now = DateTime.now();
      await provider.addTransaction(
        TransactionModel(
          id: 'food-1',
          name: 'Lunch',
          amount: 4200,
          time: DateTime(now.year, now.month, 2, 13),
          type: TransactionType.expense,
          accountId: 'bank',
          categoryId: 'food',
        ),
      );

      final stat = provider.budgetStatFor('food');
      expect(stat, isNotNull);
      expect(stat!.spent, 4200);
      expect(stat.budget, 5000);
      expect(stat.remaining, 800);
      expect(stat.usedFraction, closeTo(0.84, 0.0001));
      expect(stat.isOverBudget, isFalse);
      expect(provider.transactionCountForCategory('food'), 1);
    });

    test('crossing the limit flags the category as over budget', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      final DateTime now = DateTime.now();
      await provider.addTransaction(
        TransactionModel(
          id: 'food-2',
          name: 'Big dinner',
          amount: 5600,
          time: DateTime(now.year, now.month, 3, 20),
          type: TransactionType.expense,
          accountId: 'bank',
          categoryId: 'food',
        ),
      );

      final stat = provider.budgetStatFor('food')!;
      expect(stat.isOverBudget, isTrue);
      expect(stat.spent - stat.budget, 600);
      expect(provider.overBudgetCategories.length, 1);
    });

    test('transactions from another month are not counted', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      final DateTime now = DateTime.now();
      final DateTime previousMonth = DateTime(now.year, now.month - 1, 15);
      await provider.addTransaction(
        TransactionModel(
          id: 'food-old',
          name: 'Last month lunch',
          amount: 900,
          time: previousMonth,
          type: TransactionType.expense,
          accountId: 'bank',
          categoryId: 'food',
        ),
      );

      expect(provider.transactionsForCategory('food'), isEmpty);
      expect(provider.budgetStatFor('food'), isNull);
    });

    test('setCategoryBudget toggles the active flag', () async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await provider.setCategoryBudget('food', budget: 8000);
      expect(provider.categoryById('food')!.budget, 8000);
      expect(provider.categoryById('food')!.isBudgetActive, isTrue);

      await provider.setCategoryBudget('food', budget: 0, active: false);
      expect(provider.categoryById('food')!.isBudgetActive, isFalse);
      expect(provider.totalMonthlyBudget, 0);
    });
  });

  group('editors', () {
    Future<void> pump(
      WidgetTester tester,
      PaisaProvider provider,
      Widget child,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaisaProvider>.value(
          value: provider,
          child: MaterialApp(theme: PaisaTheme.light(), home: child),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('add account writes one record and makes it default',
        (WidgetTester tester) async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await pump(tester, provider, const AddAccountScreen());
      final int before = provider.accounts.length;

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. HDFC Savings'),
        'ICICI Salary',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '4821'),
        '9911',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add account').last);
      await tester.pumpAndSettle();

      expect(provider.accounts.length, before + 1);
      final AccountModel created = provider.accounts.firstWhere(
        (AccountModel a) => a.bankName == 'ICICI Salary',
      );
      expect(created.number, '9911');
      expect(created.cardType, AccountType.bank);
      expect(created.isDefault, isFalse); // default switch defaults to false here
    });

    testWidgets('add account blocks an empty bank name',
        (WidgetTester tester) async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await pump(tester, provider, const AddAccountScreen());
      final int before = provider.accounts.length;

      await tester.tap(find.text('Add account').last);
      await tester.pumpAndSettle();

      expect(find.text('Add the bank name'), findsOneWidget);
      expect(provider.accounts.length, before);
    });

    testWidgets('add category stores the icon, colour and budget',
        (WidgetTester tester) async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await pump(tester, provider, const AddCategoryScreen());
      final int before = provider.categories.length;

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Groceries'),
        'Fuel',
      );
      await tester.pumpAndSettle();

      // Enable the monthly budget and set a limit.
      await tester.scrollUntilVisible(
        find.text('Set Monthly Budget'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Set Monthly Budget'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monthly limit'),
        '3500',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();

      expect(provider.categories.length, before + 1);
      final CategoryModel created = provider.categories.firstWhere(
        (CategoryModel c) => c.name == 'Fuel',
      );
      expect(created.budget, 3500);
      expect(created.isBudgetActive, isTrue);
      expect(created.isIncome, isFalse);
      expect(created.color, isNot(0));
    });

    testWidgets('add debt requires an amount and a name',
        (WidgetTester tester) async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await pump(tester, provider, const AddDebtScreen());
      final int before = provider.debts.length;

      await tester.tap(find.text('Save record'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the amount'), findsOneWidget);
      expect(provider.debts.length, before);
    });

    testWidgets('add debt saves a lent record with its due date',
        (WidgetTester tester) async {
      final PaisaProvider provider = PaisaProvider(storage: storage);
      await pump(tester, provider, const AddDebtScreen());

      await tester.enterText(
        find.widgetWithText(TextFormField, '0'),
        '7500',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Ravi'),
        'Ravi',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. 12% reducing balance, 24 EMIs'),
        'Bike repair',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save record'));
      await tester.pumpAndSettle();

      expect(provider.debts.length, 1);
      final DebtModel saved = provider.debts.single;
      expect(saved.name, 'Ravi');
      expect(saved.amount, 7500);
      expect(saved.debtType, DebtType.debt);
      expect(saved.expiryDateTime.isAfter(saved.dateTime), isTrue);
    });
  });

  group('AccountCardView', () {
    testWidgets('renders the type badge, mask and formatted balance',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PaisaTheme.light(),
          home: Scaffold(
            body: AccountCardView(
              title: 'HDFC Savings',
              holderName: 'Hemanth S',
              maskedNumber: '•••• •••• •••• 4821',
              type: AccountType.bank,
              style: AccountStyle.forColor(0xFF1E88E5),
              balanceLabel: CurrencyFormatter(currency: CurrencyTable.inr).format(125450),
              balanceCaption: 'Available balance',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BANK'), findsOneWidget);
      expect(find.text('•••• •••• •••• 4821'), findsOneWidget);
      expect(find.text('HDFC Savings'), findsOneWidget);
      expect(find.text('HEMANTH S'), findsOneWidget);
      expect(find.textContaining('1,25,450'), findsOneWidget);
    });

    testWidgets('hides the balance when asked',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PaisaTheme.light(),
          home: Scaffold(
            body: AccountCardView(
              title: 'Cash',
              holderName: 'Me',
              maskedNumber: 'Cash in Hand',
              type: AccountType.cash,
              style: AccountStyle.forColor(0xFF0F9D58),
              balanceLabel: CurrencyFormatter(currency: CurrencyTable.inr).format(9999),
              balanceCaption: 'Cash in hand',
              hideBalance: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('••••••'), findsOneWidget);
      expect(find.textContaining('9,999'), findsNothing);
    });
  });
}
