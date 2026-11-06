import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/shared/demo_frame.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.6]) {
      for (final direction in TextDirection.values) {
        testWidgets('Demo reserves header at $width / $scale / $direction', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var exited = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: tinkTheme(const AppSettings(), Brightness.dark),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                ),
                child: Directionality(
                  textDirection: direction,
                  child: DemoFrame(
                    enabled: true,
                    onExit: () => exited = true,
                    child: child!,
                  ),
                ),
              ),
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('Emergency fund verified'),
                  actions: [
                    IconButton(
                      tooltip: 'Archive goal',
                      onPressed: () {},
                      icon: const Icon(Icons.archive_outlined),
                    ),
                  ],
                ),
                body: const Center(child: Text('Your saved data is separate')),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final exit = find.widgetWithText(FilledButton, 'Exit Demo');
          final exitRect = tester.getRect(exit);
          final barRect = tester.getRect(find.byType(AppBar));
          expect(exitRect.bottom, lessThanOrEqualTo(barRect.top));
          expect(exitRect.width, greaterThanOrEqualTo(48));
          expect(exitRect.height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          await tester.tap(exit);
          expect(exited, isTrue);
        });
      }
    }
  }
}
