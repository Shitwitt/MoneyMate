import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/enum/filter_enums.dart';
import 'package:moneymate/core/l10n/app_strings.dart';
import 'package:moneymate/core/theme/paisa_theme.dart';
import 'package:moneymate/data/local/hive_storage.dart';
import 'package:moneymate/providers/paisa_provider.dart';
import 'package:moneymate/screens/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';

/// Walks the five onboarding pages the way a first-time user would and asserts
/// that nothing is written to Hive until the final tap.
void main() {
  final HiveStorage storage = HiveStorage.instance;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('moneymate_onboarding_');
    await storage.init(directoryOverride: tempDir.path);
  });

  tearDownAll(() async {
    await storage.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await storage.clearAll();
  });

  /// Advances a bounded number of frames.
  ///
  /// `pumpAndSettle` cannot be used anywhere in this flow: the welcome page's
  /// lava lamp repeats forever, so "settled" never happens and the call would
  /// hang until the test times out.
  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<PaisaProvider> pumpFlow(WidgetTester tester) async {
    final PaisaProvider provider = PaisaProvider(storage: storage);
    await tester.pumpWidget(
      ChangeNotifierProvider<PaisaProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: PaisaTheme.light(),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await settle(tester);
    return provider;
  }

  testWidgets(
      'page 1 shows the welcome copy and the five languages',
      (WidgetTester tester) async {
    await pumpFlow(tester);

    expect(find.text('Know where every rupee goes'), findsOneWidget);
    for (final AppLanguage language in AppLanguage.all) {
      expect(find.text(language.nativeName), findsOneWidget);
    }
    expect(find.text('English'), findsWidgets);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
  });

  testWidgets(
      'switching language translates the welcome page',
      (WidgetTester tester) async {
    await pumpFlow(tester);

    await tester.tap(find.text('हिन्दी'));
    await settle(tester);

    expect(find.text('हर रुपये का हिसाब'), findsOneWidget);
    expect(find.text('Know where every rupee goes'), findsNothing);
  });

  testWidgets(
      'page 2 requires a name before continuing',
      (WidgetTester tester) async {
    await pumpFlow(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);

    // Continue with an empty field stays on page 2 and shows the error.
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Add your accounts'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Hemanth');
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('Add your accounts'), findsOneWidget);
  });

  testWidgets(
      'full flow persists the profile, account, categories and currency',
      (WidgetTester tester) async {
    final PaisaProvider provider = await pumpFlow(tester);

    // ---- Page 1 → 2
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // ---- Page 2: name + avatar
    await tester.enterText(find.byType(TextFormField), 'Hemanth');
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // ---- Page 3: pick the bank preset
    expect(find.text('Bank Account'), findsOneWidget);
    await tester.tap(find.text('Bank Account'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // ---- Page 4: categories are preselected
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.textContaining('selected'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // ---- Page 5: currency, INR pinned, switch to USD then back
    expect(find.text('Choose your currency'), findsOneWidget);
    expect(find.text('Indian Rupee (₹ - INR)'), findsOneWidget);
    await tester.tap(find.text('US Dollar (\$ - USD)'));
    await settle(tester);
    await tester.tap(find.text('Indian Rupee (₹ - INR)'));
    await settle(tester);

    // Nothing persisted until the final tap.
    expect(provider.isOnboardingComplete, isFalse);
    expect(storage.getAccounts(), isEmpty);

    await tester.tap(find.text('Open MoneyMate'));
    await settle(tester);

    expect(provider.isOnboardingComplete, isTrue);
    expect(provider.userName, 'Hemanth');
    expect(provider.accounts.length, 1);
    expect(provider.accounts.first.cardType, AccountType.bank);
    expect(provider.currencyCode, 'INR');
    expect(provider.categories, isNotEmpty);
    // Persisted, not just in memory.
    expect(storage.loadSettings().onboardingComplete, isTrue);
  });

  testWidgets(
      'search filters the currency list',
      (WidgetTester tester) async {
    await pumpFlow(tester);

    // Page 1 → 2
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Page 2 → 3
    await tester.enterText(find.byType(TextFormField), 'Hemanth');
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Page 3 → 4
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Page 4 → 5
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('Choose your currency'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'yen');
    await settle(tester);
    expect(find.text('Japanese Yen (¥ - JPY)'), findsOneWidget);
    expect(find.text('Indian Rupee (₹ - INR)'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await settle(tester);
    expect(find.textContaining('No currency matches'), findsOneWidget);
  });

  test('every language defines every English key', () {
    for (final String code in AppStrings.languageCodes) {
      for (final String key in AppStrings.keys) {
        expect(
          AppStrings.has(code, key),
          isTrue,
          reason: 'Language "$code" is missing the "$key" key',
        );
      }
    }
  });
}
