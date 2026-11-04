import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/data/seed.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/main.dart';

import 'support.dart';

void main() {
  testWidgets('First launch shows a usable private onboarding wizard', (
    tester,
  ) async {
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
    expect(find.text('PaisaClone'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Let’s make it yours.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Dashboard and navigation work with a real persisted-model fixture',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              MemoryRepository(appFor(fixture())),
            ),
          ],
          child: const PaisaApp(enablePlatformServices: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Total net worth'), findsOneWidget);
      await tester.tap(find.text('Activity').last);
      await tester.pumpAndSettle();
      expect(find.text('Every little entry counts'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Account editor saves without retaining disposed controllers', (
    tester,
  ) async {
    final repo = MemoryRepository(appFor(fixture()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const PaisaApp(enablePlatformServices: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cash envelope');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      repo.persisted!.profiles.first.accounts.any(
        (account) => account.name == 'Cash envelope',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Profile picker scrolls safely with many isolated profiles', (
    tester,
  ) async {
    final first = fixture();
    final app = appFor(first).copyWith(
      profiles: [
        first,
        for (var i = 0; i < 39; i++)
          seedProfile(
            name: 'Extra $i',
            currency: 'USD',
            accountName: 'Everyday',
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(MemoryRepository(app)),
        ],
        child: const PaisaApp(enablePlatformServices: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Manage your private spaces'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
