import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/main.dart';

import 'support.dart';

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets('Full populated Home feed at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final handler = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        handler?.call(details);
      };
      addTearDown(() => FlutterError.onError = handler);
      final repo = MemoryRepository(
        AppData(settings: AppSettings(fontScale: scale)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const PaisaApp(enablePlatformServices: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Try Demo Mode'));
      await tester.tap(find.text('Try Demo Mode'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Initial Home at $scale');
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      for (var index = 0; index < 40; index++) {
        final next = (position.pixels + 500)
            .clamp(0.0, position.maxScrollExtent)
            .toDouble();
        position.jumpTo(next);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Home section $index');
        if (position.pixels >= position.maxScrollExtent - 1) break;
      }
      expect(find.text('Templates'), findsOneWidget);
      expect(repo.writes, 0);
    });
  }
}
