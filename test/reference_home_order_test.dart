import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/main.dart';

import 'support.dart';

Future<void> pumpHome(WidgetTester tester, List<String> cards) async {
  tester.view.physicalSize = const Size(390, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = AppSettings(homeCards: cards);
  final repo = MemoryRepository(appFor(fixture(), settings: settings));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: const PaisaApp(enablePlatformServices: false),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Templates retain their place before balance', (tester) async {
    await pumpHome(tester, ['templates', 'balance', 'cashflow', 'accounts']);
    final templateY = tester.getTopLeft(find.text('Templates').first).dy;
    final balanceY = tester.getTopLeft(find.text('Total balance').first).dy;
    expect(templateY, lessThan(balanceY));
    expect(find.text('Income'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Separated summary cards retain saved order', (tester) async {
    await pumpHome(tester, ['cashflow', 'templates', 'balance', 'accounts']);
    final templateY = tester.getTopLeft(find.text('Templates').first).dy;
    expect(
      tester.getTopLeft(find.text('Income').first).dy,
      lessThan(templateY),
    );
    expect(
      tester.getTopLeft(find.text('Total balance').first).dy,
      greaterThan(templateY),
    );
    expect(tester.takeException(), isNull);
  });
}
