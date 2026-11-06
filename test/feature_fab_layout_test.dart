import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/shared/widgets.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'Floating actions never cover the scroll viewport $direction $scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: tinkTheme(const AppSettings(), Brightness.dark),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: Directionality(textDirection: direction, child: child!),
              ),
              home: FeaturePage(
                title: 'Goal details',
                fab: FloatingActionButton.extended(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                bottomBar: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.all(16),
                  child: PillTabs(
                    labels: const ['Daily', 'Weekly', 'Monthly', 'Yearly'],
                    selected: 0,
                    onSelected: (_) {},
                  ),
                ),
                child: ListView(
                  children: [
                    for (var i = 0; i < 40; i++)
                      ListTile(title: Text('Record $i')),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final viewport = tester.getRect(find.byType(ListView));
          final action = tester.getRect(find.byType(FloatingActionButton));
          expect(viewport.bottom, lessThanOrEqualTo(action.top));
          await tester.drag(find.byType(ListView), const Offset(0, -4000));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byType(ListView)).bottom,
            lessThanOrEqualTo(action.top),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
