import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/shared/widgets.dart';

import 'support.dart';

void main() {
  testWidgets(
    'Narrow statistic cards fit the complete monetary value at large text',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              MemoryRepository(appFor(fixture())),
            ),
          ],
          child: MaterialApp(
            theme: tinkTheme(const AppSettings(), Brightness.light),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 170,
                    child: StatCard(
                      title: 'Expenses',
                      value: AmountText(5882600, currency: 'INR'),
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final text = find.descendant(
        of: find.byType(AmountText),
        matching: find.byType(RichText),
      );
      expect(
        tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
