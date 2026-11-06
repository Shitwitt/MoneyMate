import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/features/recurring/recurring_detail_screen.dart';

import 'support.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('Recurring detail stays readable in $direction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final handler = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        handler?.call(details);
      };
      addTearDown(() => FlutterError.onError = handler);
      final profile = fixture();
      final now = DateTime.now();
      final due = DateTime(now.year, now.month, now.day - 1, 9);
      final rule = Recurring(
        id: 'accessible',
        name: 'A household plan with a longer name',
        amountMinor: 12345678901234,
        accountId: profile.accounts.first.id,
        categoryId: profile.categories
            .firstWhere((c) => c.type == 'expense')
            .id,
        start: DateTime(now.year, now.month - 2, 1),
        nextDue: due,
        autoPost: false,
      );
      final repo = MemoryRepository(
        appFor(profile.copyWith(recurrings: [rule])),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: tinkTheme(const AppSettings(), Brightness.dark),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 844),
                textScaler: TextScaler.linear(1.6),
                disableAnimations: true,
              ),
              child: Directionality(
                textDirection: direction,
                child: const RecurringDetailScreen('accessible'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('History'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.writes, 0);
    });
  }
}
