import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/features/recurring/recurring_screen.dart';
import 'package:paisaclone/main.dart';

import 'support.dart';

void main() {
  testWidgets('Demo exit awaits deep route disposal', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository(const AppData());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const PaisaApp(enablePlatformServices: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try Demo Mode'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push<void>(
      MaterialPageRoute(builder: (_) => const RecurringScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit Demo'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Start fresh'), findsOneWidget);
    expect(find.byType(RecurringScreen), findsNothing);
    expect(repo.writes, 0);
    expect(tester.takeException(), isNull);
  });
}
