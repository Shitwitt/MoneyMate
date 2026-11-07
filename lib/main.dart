import 'package:flutter/material.dart';

import 'core/theme/paisa_theme.dart';
import 'providers/paisa_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PaisaThemeEngine themeEngine = PaisaThemeEngine();
  final PaisaProvider provider = PaisaProvider(themeEngine: themeEngine);
  await provider.initialize();

  runApp(
    PaisaAppRoot(
      provider: provider,
      themeEngine: themeEngine,
    ),
  );
}
