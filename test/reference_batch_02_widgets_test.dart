import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/features/accounts/accounts_screen.dart';
import 'package:paisaclone/features/budgets/budgets_screen.dart';
import 'package:paisaclone/features/home/home_reference_sections.dart';
import 'package:paisaclone/features/reports/reports_screen.dart';
import 'package:paisaclone/features/transactions/transaction_form.dart';
import 'package:paisaclone/l10n/generated/app_localizations.dart';
import 'package:paisaclone/shared/reference_charts.dart';

import 'support.dart';

ProfileData populated() {
  final data = fixture(), now = DateTime.now();
  return data.copyWith(
    accounts: [
      data.accounts.first.copyWith(
        name: 'My everyday account with a longer label',
        holderName: 'A local holder label',
        lastDigits: '1234',
      ),
      const Account(
        id: 'linked',
        name: 'Linked cash wallet',
        currency: 'USD',
        type: 'cash',
        parentId: '',
      ),
    ],
    budgets: [
      Budget(
        id: 'manual',
        name: 'Manual allowance',
        limitMinor: 100000,
        period: 'monthly',
        start: DateTime(now.year, now.month, 1),
        mode: 'manual',
      ),
      Budget(
        id: 'target',
        name: 'Income target',
        limitMinor: 200000,
        period: 'monthly',
        start: DateTime(now.year, now.month, 1),
        transactionType: 'income',
      ),
    ],
    transactions: [
      expense(
        data,
        id: 'one',
        amount: 6400,
        date: DateTime(now.year, now.month, 1),
      ).copyWith(budgetId: 'manual'),
      expense(
        data,
        id: 'income',
        type: 'income',
        amount: 200000,
        date: DateTime(now.year, now.month, 1),
      ),
    ],
  );
}

Future<MemoryRepository> pumpFeature(
  WidgetTester tester,
  Widget feature, {
  ProfileData? data,
  AppSettings settings = const AppSettings(),
  TextDirection direction = TextDirection.ltr,
  double scale = 1.6,
}) async {
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = MemoryRepository(
    appFor(data ?? populated(), settings: settings),
  );
  final handler = FlutterError.onError;
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
    handler?.call(details);
  };
  addTearDown(() => FlutterError.onError = handler);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: tinkTheme(settings, Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 844),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: Directionality(textDirection: direction, child: feature),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> inspectScroll(WidgetTester tester) async {
  final scroll = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scroll).position;
  for (var i = 0; i < 45; i++) {
    expect(tester.takeException(), isNull, reason: 'Section $i');
    if (position.pixels >= position.maxScrollExtent - 1) break;
    position.jumpTo(
      (position.pixels + 350).clamp(0, position.maxScrollExtent).toDouble(),
    );
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

void main() {
  for (final direction in TextDirection.values) {
    for (final page in <String, Widget>{
      'accounts': const AccountsScreen(),
      'reports': const ReportsScreen(),
      'budgets': const BudgetsScreen(),
      'budget details': const BudgetDetailScreen('manual'),
    }.entries) {
      testWidgets('Calendar date targets retain 48 pixels on a narrow screen', (
        tester,
      ) async {
        final data = populated();
        await pumpFeature(
          tester,
          HomeCalendarHeatmap(Ledger(data, const AppSettings())),
          data: data,
        );
        final targets = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label?.contains('recorded transactions') ?? false),
        );
        final now = DateTime.now();
        expect(
          targets,
          findsNWidgets(DateTime(now.year, now.month + 1, 0).day),
        );
        for (final element in targets.evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      });
      testWidgets('${page.key} reflows at 320 px / 1.6× in $direction', (
        tester,
      ) async {
        final repo = await pumpFeature(
          tester,
          page.value,
          direction: direction,
        );
        await inspectScroll(tester);
        expect(repo.writes, 0);
      });
    }
  }
  testWidgets(
    'Manual budget is available without labels, and resets on type change',
    (tester) async {
      final repo = await pumpFeature(
        tester,
        const TransactionForm(),
        data: populated().copyWith(entities: []),
        scale: 1,
      );
      final budget = find.byKey(const ValueKey('transaction-budget-expense'));
      await tester.scrollUntilVisible(
        budget,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(budget);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manual allowance · manual').last);
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income').first);
      await tester.pumpAndSettle();
      final income = find.byKey(const ValueKey('transaction-budget-income'));
      await tester.scrollUntilVisible(
        income,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<DropdownButtonFormField<String>>(income).initialValue,
        '',
      );
      expect(tester.takeException(), isNull);
      expect(repo.writes, 0);
    },
  );
  testWidgets('Show Budget is persisted only after a successful save', (
    tester,
  ) async {
    final repo = await pumpFeature(
      tester,
      const BudgetDetailScreen('manual'),
      scale: 1,
    );
    final toggle = find.byType(SwitchListTile).first;
    await tester.scrollUntilVisible(
      toggle,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(repo.persisted!.profiles.first.budgets.first.showOnHome, isFalse);
    final writes = repo.writes;
    repo.failNext = true;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(repo.writes, writes);
    expect(repo.persisted!.profiles.first.budgets.first.showOnHome, isFalse);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Charts inspect actual points and suppress financial values in privacy mode',
    (tester) async {
      final data = populated();
      final chart = ReferenceLineChart(
        ledger: Ledger(data, const AppSettings()),
        start: DateTime(2026, 1, 1),
        series: const [
          ReferenceSeries('Recorded', [100.0, 200.0, null], Colors.teal),
        ],
      );
      await pumpFeature(tester, Scaffold(body: chart), data: data, scale: 1);
      await tester.tapAt(
        tester.getTopLeft(find.byType(ReferenceLineChart)) +
            const Offset(100, 100),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Recorded:'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await pumpFeature(
        tester,
        Scaffold(
          body: ReferenceLineChart(
            ledger: Ledger(data, const AppSettings(hideAmounts: true)),
            start: DateTime(2026, 1, 1),
            series: chart.series,
          ),
        ),
        data: data,
        settings: const AppSettings(hideAmounts: true),
        scale: 1,
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.textContaining('Recorded:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
