import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/paisa_theme.dart';
import 'core/theme/theme_preference.dart';
import 'core/utils/app_lock.dart';
import 'data/local/hive_storage.dart';
import 'data/models/settings_model.dart';
import 'providers/paisa_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/app_lock_gate.dart';

/// Boots Hive, loads the persisted settings, then hands over to [MoneyMateApp].
///
/// `PaisaProvider` is created *after* the boxes are open, so the very first
/// frame already carries real data and the correct theme — there is no splash
/// spinner and no flash of the wrong palette on a cold start.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only: every screen is designed for one hand and a narrow column of
  // money, and the charts re-bucket rather than rotate.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final HiveStorage storage = HiveStorage.instance;
  await storage.init();

  final SettingsModel settings = storage.loadSettings();

  runApp(MoneyMateApp(storage: storage, initialSettings: settings));
}

/// Root widget: owns the provider graph and the theme.
class MoneyMateApp extends StatelessWidget {
  const MoneyMateApp({
    super.key,
    required this.storage,
    required this.initialSettings,
    this.gateAuthenticator,
  });

  final HiveStorage storage;
  final SettingsModel initialSettings;

  /// Test seam: replaces the `local_auth` prompt inside the app lock.
  /// Production leaves this `null` and the real device prompt is used.
  final DeviceAuthenticator? gateAuthenticator;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HiveStorage>.value(value: storage),
        ChangeNotifierProvider<PaisaProvider>(
          create: (_) => PaisaProvider(
            storage: storage,
            initialSettings: initialSettings,
          ),
        ),
      ],
      child: _AppRoot(gateAuthenticator: gateAuthenticator),
    );
  }
}

/// Rebuilds the whole tree when the theme, language, currency or onboarding
/// state changes.
class _AppRoot extends StatelessWidget {
  const _AppRoot({this.gateAuthenticator});

  final DeviceAuthenticator? gateAuthenticator;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final AppLanguage language = AppLanguage.byCode(provider.languageCode);
    final ThemeSettings themeSettings = provider.themeSettings;

    // [PaisaThemeBuilder] owns the dynamic-colour plumbing: it only subscribes
    // to the platform channel where Material You can actually answer (Android
    // 12+), and otherwise resolves the seeded palette straight away. Duplicating
    // that here would mean two places to keep in sync.
    return PaisaThemeBuilder(
      settings: themeSettings,
      builder: (BuildContext context, ThemeData light, ThemeData dark) {
        return MaterialApp(
          title: 'MoneyMate',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: themeSettings.preference.materialThemeMode,
          locale: language.locale,
          supportedLocales: <Locale>[
            for (final AppLanguage item in AppLanguage.all) item.locale,
          ],
          // Without these three the app would *claim* five locales while
          // Material's own strings (date pickers, tooltips, "Cancel"/"OK")
          // stayed English — and any non-English locale would be missing its
          // MaterialLocalizations entirely. `context.tr` handles the app's own
          // copy; these delegates handle Flutter's.
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (BuildContext context, Widget? child) {
            return TranslationScope(
              languageCode: provider.languageCode,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: BiometricGate(
            authenticator: gateAuthenticator,
            child: const _EntryPoint(),
          ),
        );
      },
    );
  }
}

/// Decides between onboarding and the app shell.
///
/// A [KeyedSubtree] keyed on `onboardingComplete` guarantees the shell is built
/// fresh the moment onboarding finishes, so `MainShell` seeds its state from the
/// freshly written boxes instead of the pre-onboarding empty ones.
class _EntryPoint extends StatelessWidget {
  const _EntryPoint();

  @override
  Widget build(BuildContext context) {
    final bool onboarded =
        context.select<PaisaProvider, bool>((p) => p.isOnboardingComplete);

    return KeyedSubtree(
      key: ValueKey<bool>(onboarded),
      child: onboarded ? const MainShell() : const OnboardingScreen(),
    );
  }
}

/// The app-launch biometric guard.
///
/// * Reads `PaisaProvider.biometricEnabled`; when it is off the child is shown
///   immediately and nothing is prompted.
/// * When it is on, `LocalAuthentication().authenticate()` runs before the
///   ledger is rendered, and the app re-locks every time it returns from the
///   background.
/// * The lock screen always offers a real "Unlock" button, so a device with no
///   enrolled biometric can still get in with its PIN / pattern / password —
///   and if the platform has no screen lock at all, the app opens and explains
///   why rather than holding the owner hostage.
///
/// The implementation lives in [AppLockGate] (which also owns the lock screen
/// UI); this named wrapper keeps the entry point readable.
class BiometricGate extends StatelessWidget {
  const BiometricGate({super.key, required this.child, this.authenticator});

  /// The unlocked application: onboarding or the main shell.
  final Widget child;

  /// Device-auth stand-in, used only by widget tests.
  final DeviceAuthenticator? authenticator;

  @override
  Widget build(BuildContext context) {
    return AppLockGate(authenticator: authenticator, child: child);
  }
}

/// Exposed for tests and for the settings screen's "test the prompt" affordance:
/// a single, honest device-credential prompt with the same options the gate uses.
Future<bool> promptForUnlock() => requestDeviceUnlock(
      reason: 'Unlock MoneyMate to view your money',
    );
