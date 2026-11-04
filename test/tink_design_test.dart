import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/features/onboarding/introduction_screen.dart';
import 'package:paisaclone/features/onboarding/tink_illustration.dart';
import 'package:paisaclone/main.dart';
import 'package:paisaclone/shared/widgets.dart';

import 'support.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

void main() {
  testWidgets(
    'All six original introduction pages lead to real account setup',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              MemoryRepository(const AppData()),
            ),
          ],
          child: const PaisaApp(enablePlatformServices: false),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        expect(find.text(introductionPages[i].$1), findsOneWidget);
        expect(find.byType(TinkIllustration), findsWidgets);
        await tester.tap(find.text(i == 5 ? 'Get started' : 'Continue'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Let’s make it yours.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    },
  );
  testWidgets('Tour supports horizontal swipes and Skip at large text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: tinkTheme(const AppSettings(), Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.6),
          ),
          child: IntroductionScreen(onFinish: () => finished = true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-380, 0));
    await tester.pumpAndSettle();
    expect(find.text(introductionPages[1].$1), findsOneWidget);
    await tester.tap(find.text('Skip'));
    expect(finished, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Light and dark palettes, tabular data and offline fonts', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final theme = tinkTheme(const AppSettings(), brightness);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: TinkBrand()),
        ),
      );
      await tester.pumpAndSettle();
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(
        theme.scaffoldBackgroundColor,
        brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.background,
      );
      expect(
        contrast(theme.colorScheme.onSurface, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(theme.colorScheme.onSurfaceVariant, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      final label = theme.filledButtonTheme.style!.textStyle!.resolve({})!;
      expect(label.fontSize, 20);
      expect(label.fontWeight, FontWeight.w700);
      expect(
        contrast(theme.colorScheme.primary, theme.colorScheme.onPrimary),
        greaterThanOrEqualTo(3),
      );
      expect(
        theme.textTheme.bodyMedium!.fontFeatures,
        containsAll(AppTextStyles.tabular),
      );
      expect(GoogleFonts.config.allowRuntimeFetching, false);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Reduced motion finishes finite progress immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tinkTheme(const AppSettings(), Brightness.dark),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Column(
              children: [
                ProgressBar(.75),
                ProgressRing(.75),
                Entrance(child: Text('Ready')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('New add-entry sheet retains calculator and saves an expense', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository(appFor(fixture()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const PaisaApp(enablePlatformServices: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '120+30');
    await tester.enterText(find.byType(TextFormField).at(1), 'Evening chai');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(
      repo.persisted!.profiles.first.transactions.single.amountMinor,
      15000,
    );
    expect(tester.takeException(), isNull);
  });
}
