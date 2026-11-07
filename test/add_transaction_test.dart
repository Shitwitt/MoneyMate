import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/core/theme/paisa_theme.dart';
import 'package:moneymate/data/local/hive_storage.dart';
import 'package:moneymate/data/models/transaction_model.dart';
import 'package:moneymate/providers/paisa_provider.dart';
import 'package:moneymate/screens/transactions/add_transaction_screen.dart';
import 'package:provider/provider.dart';

/// Drives the add/edit form: validation, save, and the transfer rules that stop
/// a user from moving money into the same account.
void main() {
  final HiveStorage storage = HiveStorage.instance;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('moneymate_add_');
    await storage.init(directoryOverride: tempDir.path);
  });

  tearDownAll(() async {
    await storage.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await storage.clearAll();
    await storage.seedDefaults();
  });

  Future<PaisaProvider> pumpForm(WidgetTester tester) async {
    final PaisaProvider provider = PaisaProvider(storage: storage);
    await tester.pumpWidget(
      ChangeNotifierProvider<PaisaProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: PaisaTheme.light(),
          home: const AddTransactionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return provider;
  }

  testWidgets('saving without data surfaces inline errors and writes nothing',
      (WidgetTester tester) async {
    final PaisaProvider provider = await pumpForm(tester);
    final int before = provider.transactions.length;

    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Add a title'), findsOneWidget);
    expect(provider.transactions.length, before);
  });

  testWidgets('a complete expense is persisted with the entered values',
      (WidgetTester tester) async {
    final PaisaProvider provider = await pumpForm(tester);
    final int before = provider.transactions.length;

    await tester.enterText(
      find.widgetWithText(TextField, '0'),
      '450',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Groceries'),
      'Filter coffee',
    );
    await tester.pumpAndSettle();

    // Pick the first category chip so the form is valid.
    final Finder chip = find.text('Food & Dining').first;
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    expect(provider.transactions.length, before + 1);
    final TransactionModel saved = provider.transactions
        .firstWhere((TransactionModel t) => t.name == 'Filter coffee');
    expect(saved.amount, 450);
    expect(saved.type, TransactionType.expense);
  });

  testWidgets('switching to transfer hides the category grid',
      (WidgetTester tester) async {
    await pumpForm(tester);
    expect(find.text('Food & Dining'), findsWidgets);

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    expect(find.text('Food & Dining'), findsNothing);
    expect(find.text('Transfer from account'), findsOneWidget);
    expect(find.text('Transfer to account'), findsOneWidget);
  });

  testWidgets('edit mode preloads the record and exposes delete',
      (WidgetTester tester) async {
    final PaisaProvider provider = PaisaProvider(storage: storage);
    final TransactionModel existing = TransactionModel(
      id: 'tx-edit',
      name: 'Metro card',
      amount: 450,
      time: DateTime(2026, 11, 6, 18, 30),
      type: TransactionType.expense,
      accountId: provider.defaultAccount!.id,
      categoryId: 'seed-category-food',
    );
    await provider.addTransaction(existing);

    await tester.pumpWidget(
      ChangeNotifierProvider<PaisaProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: PaisaTheme.light(),
          home: AddTransactionScreen(existing: existing),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('Metro card'), findsWidgets);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });
}
