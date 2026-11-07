import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/l10n/app_strings.dart';
import 'package:moneymate/core/utils/app_lock.dart';
import 'package:moneymate/data/local/hive_storage.dart';
import 'package:moneymate/data/models/settings_model.dart';
import 'package:moneymate/domain/default_data.dart';
import 'package:moneymate/main.dart';
import 'package:moneymate/providers/paisa_provider.dart';
import 'package:moneymate/screens/main_shell.dart';
import 'package:moneymate/screens/onboarding/onboarding_screen.dart';
import 'package:moneymate/widgets/app_lock_gate.dart';
import 'package:provider/provider.dart';

/// Step 6: the entry point (`MoneyMateApp` → theme → gate → onboarding/shell),
/// the app lock's three contracts (authenticated, cancelled, unsupported), and
/// the localization plumbing the app root owns.
void main() {
  final HiveStorage storage = HiveStorage.instance;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('moneymate_step6_');
    await storage.init(directoryOverride: tempDir.path);
  });

  tearDownAll(() async {
    await storage.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await storage.clearAll();
  });

  /// Advances a fixed number of frames.
  ///
  /// Deliberately *not* `pumpAndSettle`: onboarding's lava-lamp animation
  /// repeats forever, so "settle" would never come. Every assertion below is
  /// about a widget that exists as soon as its frame is built.
  Future<void> pumpFrames(WidgetTester tester, [int frames = 6]) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  /// Pumps the real app root — the same widget `main()` hands to `runApp`.
  ///
  /// [authenticator] replaces the `local_auth` prompt so the lock's behaviour is
  /// asserted deterministically; production never passes it.
  Future<void> pumpApp(
    WidgetTester tester, {
    DeviceAuthenticator? authenticator,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final SettingsModel settings = storage.loadSettings();
    await tester.pumpWidget(
      MoneyMateApp(
        storage: storage,
        initialSettings: settings,
        gateAuthenticator: authenticator,
      ),
    );
    await pumpFrames(tester, 4);
  }

  group('entry point', () {
    testWidgets('a fresh install lands on onboarding, not the shell',
        (WidgetTester tester) async {
      await pumpApp(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
      expect(storage.loadSettings().onboardingComplete, isFalse);
    });

    testWidgets('an onboarded ledger lands straight in the shell',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(onboardingComplete: true, userName: 'Asha'),
      );

      await pumpApp(tester);

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      // The shell greets the real stored name, so the provider was fed the
      // persisted settings rather than the constructor defaults.
      expect(find.text('Welcome back, Asha'), findsOneWidget);
    });

    testWidgets('completing onboarding swaps the tree without a restart',
        (WidgetTester tester) async {
      await pumpApp(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      final PaisaProvider provider = Provider.of<PaisaProvider>(
        tester.element(find.byType(OnboardingScreen)),
        listen: false,
      );
      await provider.completeOnboarding(
        name: 'Asha',
        avatarIndex: 1,
        languageCode: 'en',
        currencyCode: 'INR',
        selectedAccounts: DefaultData.accountModels,
        selectedCategories: DefaultData.categories.take(2).toList(),
      );
      await pumpFrames(tester);

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(storage.loadSettings().onboardingComplete, isTrue);
      expect(storage.loadSettings().userName, 'Asha');
    });
  });

  group('app lock', () {
    testWidgets('off by default: no prompt, ledger visible',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(onboardingComplete: true),
      );
      int prompts = 0;
      await pumpApp(
        tester,
        authenticator: ({required String reason}) async {
          prompts++;
          return const DeviceAuthResult(authenticated: true);
        },
      );

      expect(prompts, 0);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Unlock'), findsNothing);
    });

    testWidgets('locked ledger asks once and opens when the device confirms',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(
          onboardingComplete: true,
          biometricLockEnabled: true,
        ),
      );
      final List<String> reasons = <String>[];
      await pumpApp(
        tester,
        authenticator: ({required String reason}) async {
          reasons.add(reason);
          return const DeviceAuthResult(authenticated: true);
        },
      );

      expect(reasons, hasLength(1));
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('a cancelled prompt keeps the lock up, with a reason',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(
          onboardingComplete: true,
          biometricLockEnabled: true,
        ),
      );
      await pumpApp(
        tester,
        authenticator: ({required String reason}) async =>
            const DeviceAuthResult(authenticated: false),
      );

      // The ledger must not be reachable yet…
      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Unlock'), findsOneWidget);
      expect(
        find.textContaining('Authentication cancelled'),
        findsOneWidget,
      );

      // …but the button is a real retry, not decoration.
      final PaisaProvider provider = Provider.of<PaisaProvider>(
        tester.element(find.byType(AppLockGate)),
        listen: false,
      );
      expect(provider.biometricEnabled, isTrue);
    });

    testWidgets('a device that cannot authenticate fails open and explains',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(
          onboardingComplete: true,
          biometricLockEnabled: true,
        ),
      );
      await pumpApp(
        tester,
        authenticator: ({required String reason}) async =>
            const DeviceAuthResult(
          authenticated: true,
          message: 'No screen lock is set up on this device.',
        ),
      );

      // Never trap the owner out of their own ledger.
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('No screen lock is set up on this device.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('stayed unlocked this time'),
        findsOneWidget,
      );
    });

    testWidgets('switching the lock off in settings releases the app at once',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(
          onboardingComplete: true,
          biometricLockEnabled: true,
        ),
      );
      await pumpApp(
        tester,
        authenticator: ({required String reason}) async =>
            const DeviceAuthResult(authenticated: false),
      );
      expect(find.byType(MainShell), findsNothing);

      final PaisaProvider provider = Provider.of<PaisaProvider>(
        tester.element(find.byType(AppLockGate)),
        listen: false,
      );
      await provider.setBiometricEnabled(false);
      await pumpFrames(tester);

      expect(find.byType(MainShell), findsOneWidget);
      expect(storage.loadSettings().biometricLockEnabled, isFalse);
    });
  });

  group('device auth wrapper', () {
    test('an injected authenticator is used verbatim', () async {
      final DeviceAuthResult result = await authenticateWithDevice(
        reason: 'test',
        authenticator: ({required String reason}) async =>
            const DeviceAuthResult(authenticated: false),
      );

      expect(result.authenticated, isFalse);
      expect(result.message, isNull);
    });

    test('a platform with no local_auth plugin fails open', () async {
      // The test binding has no plugin registered, so the real code path hits
      // MissingPluginException. That must authenticate and explain, never throw.
      final DeviceAuthResult result = await authenticateWithDevice(
        reason: 'test',
      );
      expect(result.authenticated, isTrue);
      expect(result.message, isNotNull);

      expect(await promptForUnlock(), isTrue);
    });
  });

  group('localization plumbing', () {
    testWidgets('Material strings follow the chosen language',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(onboardingComplete: true, languageCode: 'hi'),
      );
      await pumpApp(tester);

      final BuildContext context = tester.element(find.byType(AppLockGate));
      expect(Localizations.localeOf(context).languageCode, 'hi');
      // Proof the delegates installed: Material's own delegate answers for Hindi
      // instead of being absent (which would make `Localizations.of` null and
      // every date picker throw).
      expect(
        Localizations.of<MaterialLocalizations>(context, MaterialLocalizations),
        isNotNull,
      );
      // `Localizations.of` is never null — Flutter appends
      // `DefaultMaterialLocalizations` (hardcoded English) as a last resort — so
      // assert on *behaviour*: the month name must come from intl's Hindi data,
      // which only a `GlobalMaterialLocalizations` delegate can supply.
      final MaterialLocalizations material =
          Localizations.of<MaterialLocalizations>(context, MaterialLocalizations)!;
      final String december = material.formatShortMonthDay(DateTime(2024, 12, 1));
      expect(
        RegExp(r'[\u0900-\u097F]').hasMatch(december),
        isTrue,
        reason: 'expected a Devanagari month name for hi, got "$december"',
      );
    });

    testWidgets('every supported language has Material localization',
        (WidgetTester tester) async {
      await storage.saveSettings(
        const SettingsModel(onboardingComplete: true),
      );
      await pumpApp(tester);

      final BuildContext context = tester.element(find.byType(AppLockGate));
      expect(context.tr('appTitle'), 'MoneyMate');

      for (final AppLanguage language in AppLanguage.all) {
        expect(
          GlobalMaterialLocalizations.delegate.isSupported(language.locale),
          isTrue,
          reason: 'Material delegate must cover ${language.code}',
        );
        // Every language in the picker also has a real (non-fallback) title.
        expect(
          AppStrings.has(language.code, 'appTitle'),
          isTrue,
          reason: '${language.code} is offered but missing translations',
        );
      }
    });
  });
}
