import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/financial_pulse.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/core/utils/constants.dart';
import 'package:paisaclone/features/settings/layout_screen.dart';
import 'package:paisaclone/shared/widgets.dart';
import 'package:paisaclone/shared/pulse_charts.dart';

import 'support.dart';

void main() {
  test(
    'Old account JSON defaults to automatic art; finishes roundtrip losslessly',
    () {
      final old = fixture().accounts.first.toJson()..remove('cardStyle');
      final account = Account.fromJson(old);
      expect(account.cardStyle, 'auto');
      for (final finish in accountFinishes.keys) {
        final edited = account.copyWith(
          cardStyle: finish,
          name: 'My personal account',
        );
        expect(Account.fromJson(edited.toJson()).cardStyle, finish);
        expect(edited.openingMinor, account.openingMinor);
        expect(edited.currency, account.currency);
      }
    },
  );
  test('Pulse does not invent missing income, goals or a score from an empty ledger', () {
    final data = fixture().copyWith(accounts: []);
    final pulse = FinancialPulse.fromLedger(
      Ledger(data, const AppSettings()),
      DateTime(2026, 1, 20),
    );
    expect(pulse.score, isNull);
    expect(pulse.metrics.every((m) => m.value == null), true);
  });
  test(
    'Pulse ignores future transactions and explains record-derived values',
    () {
      final data = fixture();
      final records = [
        expense(data, id: 'salary', type: 'income', amount: 50000),
        expense(data, amount: 10000),
        expense(
          data,
          id: 'future',
          amount: 90000000,
          date: DateTime(2026, 2, 1),
        ),
      ];
      final pulse = FinancialPulse.fromLedger(
        Ledger(data.copyWith(transactions: records), const AppSettings()),
        DateTime(2026, 1, 20),
      );
      expect(pulse.metrics.firstWhere((m) => m.label == 'Spending').value, 80);
      expect(pulse.metrics.firstWhere((m) => m.label == 'Goals').value, isNull);
      expect(pulse.metrics.firstWhere((m) => m.label == 'Debt').value, 100);
      expect(
        pulse.metrics
            .where((m) => m.value != null)
            .every((m) => m.value! >= 0 && m.value! <= 100),
        true,
      );
      expect(pulse.score, isNotNull);
    },
  );
  testWidgets(
    'All seven account kinds and six finishes render at large text without remote art',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final type in accountTypes) {
        for (final finish in accountFinishes.keys) {
          await tester.pumpWidget(
            MaterialApp(
              theme: tinkTheme(const AppSettings(), Brightness.light),
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(390, 844),
                  textScaler: TextScaler.linear(1.6),
                  disableAnimations: true,
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: AccountArtwork(
                      account: Account(
                        id: 'a',
                        name: 'A beautifully personal everyday account',
                        currency: 'INR',
                        type: type,
                        cardStyle: finish,
                      ),
                      balance: 12456789,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('A beautifully personal everyday account'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: '$type / $finish');
        }
      }
    },
  );
  testWidgets(
    'Glass dock preserves reordered custom destinations and RTL semantics',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              bottomNavigationBar: GlassNavigationDock(
                tabs: const ['home', 'reports', 'accounts', 'plans', 'more'],
                selected: 'reports',
                labels: const {
                  'home': 'Home',
                  'reports': 'Reports',
                  'accounts': 'Accounts',
                  'plans': 'Plans',
                  'more': 'More',
                },
                icons: tabIcons,
                onSelect: (id) => selected = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();
      expect(selected, 'accounts');
      expect(
        Directionality.of(tester.element(find.byType(GlassNavigationDock))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Radar, gauge and calendar honor reduced motion and expose actual records',
    (tester) async {
      final data = fixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: tinkTheme(const AppSettings(), Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    FinancialPulsePanel(
                      Ledger(data, const AppSettings()),
                      expanded: true,
                    ),
                    ActivityHeatmap([
                      expense(data),
                    ], anchor: DateTime(2026, 1, 20)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your financial pulse'), findsOneWidget);
      expect(find.text('Your story is unfolding'), findsOneWidget);
      expect(find.textContaining('Planning estimate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
