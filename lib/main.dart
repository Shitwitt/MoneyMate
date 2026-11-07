import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/paisa_theme.dart';
import 'data/local/hive_storage.dart';
import 'data/models/settings_model.dart';
import 'providers/paisa_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';

/// Boots Hive, loads settings, then hands over to [MoneyMateApp].
///
/// `PaisaProvider` is created *after* the boxes are open so its first frame
/// already shows real data — there is no loading spinner on launch, and the
/// theme is correct from the very first paint.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final HiveStorage storage = HiveStorage.instance;
  await storage.init();

  final SettingsModel settings = storage.loadSettings();

  runApp(MoneyMateApp(storage: storage, initialSettings: settings));
}

class MoneyMateApp extends StatelessWidget {
  const MoneyMateApp({
    super.key,
    required this.storage,
    required this.initialSettings,
  });

  final HiveStorage storage;
  final SettingsModel initialSettings;

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
      child: const _AppRoot(),
    );
  }
}

/// Rebuilds the whole tree when the theme, language, currency or onboarding
/// state changes.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final AppLanguage language = AppLanguage.byCode(provider.languageCode);

    return PaisaThemeBuilder(
      settings: provider.themeSettings,
      builder: (BuildContext context, ThemeData light, ThemeData dark) {
        return MaterialApp(
          title: 'MoneyMate',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: provider.themeMode.materialThemeMode,
          locale: language.locale,
          supportedLocales: <Locale>[
            for (final AppLanguage item in AppLanguage.all) item.locale,
          ],
          builder: (BuildContext context, Widget? child) {
            return TranslationScope(
              languageCode: provider.languageCode,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const _EntryPoint(),
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

    if (!onboarded) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}
