import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/theme/paisa_colors.dart';
import 'package:moneymate/core/theme/paisa_theme.dart';
import 'package:moneymate/core/theme/seed_color.dart';
import 'package:moneymate/core/theme/theme_preference.dart';

/// Verifies the Material You contract: 24dp tonal cards, zero elevation, four
/// theme modes (including pitch black AMOLED) and the twelve seed colours.
void main() {
  group('seed palette', () {
    test('ships exactly twelve unique vibrant seeds', () {
      expect(SeedColor.palette.length, 12);
      final Set<int> values =
          SeedColor.palette.map((SeedColor seed) => seed.value).toSet();
      expect(values.length, 12);
    });

    test('default seed is the first palette entry', () {
      expect(SeedColor.defaultSeed.value, SeedColor.palette.first.value);
      expect(SeedColor.fromValue(SeedColor.palette[5].value).name,
          SeedColor.palette[5].name);
      expect(SeedColor.fromValue(null), SeedColor.defaultSeed);
      // Unknown legacy values are still honoured rather than dropped.
      expect(SeedColor.fromValue(0xFF123456).name, 'Custom');
    });
  });

  group('light theme', () {
    final ThemeData theme = PaisaTheme.light();

    test('uses Material 3 with a 24dp zero-elevation card', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.shadowColor, Colors.transparent);
      final ShapeBorder? shape = theme.cardTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      expect(
        (shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(PaisaTheme.cardRadius),
      );
      expect(PaisaTheme.cardRadius, 24);
    });

    test('dialogs are 24dp rounded with no shadow', () {
      expect(theme.dialogTheme.elevation, 0);
      expect(theme.dialogTheme.shadowColor, Colors.transparent);
      final RoundedRectangleBorder shape =
          theme.dialogTheme.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
    });

    test('cards sit on a tonal container, not the scaffold colour', () {
      expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerLow);
      expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    });

    test('exposes the money-semantic colour tokens', () {
      final PaisaColors colors = theme.extension<PaisaColors>()!;
      expect(colors.expense, isNot(colors.income));
      expect(colors.chartPalette.length, 12);
      expect(colors.chartAt(12), colors.chartPalette.first);
    });

    test('typography is applied to every role', () {
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.textTheme.displayLarge?.letterSpacing, isNotNull);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
    });
  });

  group('dark theme', () {
    test('dark is not black', () {
      final ThemeData theme = PaisaTheme.dark();
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, isNot(const Color(0xFF000000)));
    });

    test('amoled collapses surfaces to pitch black', () {
      final ThemeData theme = PaisaTheme.dark(amoled: true);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(theme.colorScheme.surface, const Color(0xFF000000));
      expect(theme.colorScheme.surfaceContainerLowest, const Color(0xFF000000));
      expect(theme.colorScheme.surfaceTint, const Color(0xFF000000));
      // Containers keep a whisper of the seed so cards remain visible.
      expect(theme.colorScheme.surfaceContainerLow, isNot(const Color(0xFF000000)));
      // Dark accents survive so income/expense stay readable.
      expect(theme.colorScheme.primary, isNotNull);
    });
  });

  group('resolution', () {
    test('every seed colour produces a valid light and dark pair', () {
      for (final SeedColor seed in SeedColor.palette) {
        final (ThemeData light, ThemeData dark) = PaisaTheme.resolve(
          settings: ThemeSettings(
            seed: seed,
            useDynamicColor: false,
          ),
        );
        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
        expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
      }
    });

    test('dynamic colour wins when supplied and chromatic', () {
      const ColorScheme dynamicLight = ColorScheme.light(
        primary: Color(0xFF00A0FF),
      );
      final (ThemeData light, _) = PaisaTheme.resolve(
        settings: const ThemeSettings(),
        dynamicLight: dynamicLight,
      );
      expect(light.colorScheme.primary, dynamicLight.primary);
    });

    test('a monochrome dynamic scheme is rejected in favour of the seed', () {
      const ColorScheme grey = ColorScheme.light(primary: Color(0xFF777777));
      final (ThemeData light, _) = PaisaTheme.resolve(
        settings: const ThemeSettings(),
        dynamicLight: grey,
      );
      expect(light.colorScheme.primary, isNot(grey.primary));
    });

    test('theme preference toggles AMOLED only for its own mode', () {
      final (_, ThemeData darkSystem) = PaisaTheme.resolve(
        settings: const ThemeSettings(preference: ThemePreference.dark),
      );
      final (_, ThemeData darkAmoled) = PaisaTheme.resolve(
        settings: const ThemeSettings(preference: ThemePreference.amoled),
      );
      expect(darkSystem.scaffoldBackgroundColor, isNot(const Color(0xFF000000)));
      expect(darkAmoled.scaffoldBackgroundColor, const Color(0xFF000000));
    });
  });

  group('widget smoke test', () {
    testWidgets(
      'renders a themed card and exposes tokens via context',
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PaisaTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              final PaisaColors colors = PaisaColors.of(context);
              return Scaffold(
                body: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'MoneyMate',
                      style: TextStyle(color: colors.income),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('MoneyMate'), findsOneWidget);
      final Card card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, isNull); // inherits the zero-elevation theme
      final ThemeData theme = Theme.of(tester.element(find.byType(Card)));
      expect(theme.cardTheme.elevation, 0);
  });
  });
}
