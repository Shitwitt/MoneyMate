import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
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
}
