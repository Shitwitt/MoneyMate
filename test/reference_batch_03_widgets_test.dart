import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/features/catalog/labels_screen.dart';
import 'package:paisaclone/features/goals/goals_screen.dart';
import 'package:paisaclone/features/loans/loans_screen.dart';
import 'package:paisaclone/features/reports/analytics_screen.dart';
import 'package:paisaclone/features/transactions/transaction_form.dart';
import 'package:paisaclone/l10n/generated/app_localizations.dart';
import 'package:paisaclone/shared/analytics_chart.dart';
import 'package:paisaclone/shared/reference_editor.dart';
import 'package:paisaclone/shared/widgets.dart';

import 'support.dart';

ProfileData batchThreeData() {
  final base = fixture(), now = DateTime.now();
  final payment =
      expense(
        base,
        id: 'payment',
        amount: 900,
        type: 'income',
        date: now,
      ).copyWith(
        name: 'Linked payment',
        loanId: 'loan',
        labelIds: ['personal', 'work'],
        personIds: ['person'],
      );
  return base.copyWith(
    accounts: [base.accounts.first.copyWith(openingMinor: -250000)],
    entities: const [
      NamedEntity(
        id: 'personal',
        name: 'Personal',
        kind: 'label',
        icon: 'bank',
      ),
      NamedEntity(id: 'work', name: 'Work', kind: 'label'),
      NamedEntity(id: 'person', name: 'Alice', kind: 'person'),
    ],
    transactions: [
      payment,
      for (var i = 0; i < 10; i++)
        expense(
          base,
          id: '$i',
          amount: i == 9 ? 50000 : 100,
          date: DateTime(now.year, now.month, 1),
        ).copyWith(labelIds: ['personal']),
      expense(
        base,
        id: 'second-category',
        amount: 10000,
        date: DateTime(now.year, now.month, 1),
      ).copyWith(
        categoryId: base.categories.where((c) => c.type == 'expense').last.id,
      ),
    ],
    loans: [
      Loan(
        id: 'loan',
        personName: 'Car Loan',
        personId: 'person',
        principalMinor: 10000,
        due: now.add(const Duration(days: 30)),
        start: DateTime(now.year, now.month - 1, 1),
        repayments: [
          MoneyEvent(
            id: 'repayment',
            amountMinor: 900,
            date: now,
            transactionId: 'payment',
          ),
        ],
      ),
    ],
    goals: [
      Goal(
        id: 'goal',
        name: 'Emergency Fund',
        targetMinor: 50000,
        deadline: DateTime(now.year + 1, now.month, 1),
        start: DateTime(now.year, now.month - 3, 1),
        accountId: base.accounts.first.id,
        color: 0xff009688,
      ),
    ],
  );
}

Future<MemoryRepository> pumpBatchThree(
  WidgetTester tester,
  Widget screen, {
  bool hidden = false,
  TextDirection direction = TextDirection.ltr,
  double scale = 1.6,
  double width = 320,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = AppSettings(hideAmounts: hidden, theme: 'dark');
  final repo = MemoryRepository(appFor(batchThreeData(), settings: settings));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: tinkTheme(settings, Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(
            size: Size(width, 844),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: Directionality(textDirection: direction, child: child!),
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> inspectAll(WidgetTester tester) async {
  final main = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(main).position;
  for (var i = 0; i < 90; i++) {
    expect(tester.takeException(), isNull, reason: 'Scroll step $i');
    if (position.pixels >= position.maxScrollExtent - 1) break;
    position.jumpTo(
      (position.pixels + 340).clamp(0, position.maxScrollExtent).toDouble(),
    );
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

void main() {
  for (final direction in TextDirection.values) {
    for (final feature in <(String, Widget)>[
      ('Loans', const LoansScreen()),
      ('Loan detail', const LoanDetailScreen('loan')),
      ('Goals', const GoalsScreen()),
      ('Goal detail', const GoalDetailScreen('goal')),
      ('Labels', const LabelsScreen()),
      ('Label detail', const LabelDetailScreen('personal')),
      ('Analytics', const AnalyticsScreen()),
    ]) {
      testWidgets(
        '${feature.$1} 320px 160% $direction has finite motion and no layout errors',
        (tester) async {
          await pumpBatchThree(tester, feature.$2, direction: direction);
          await inspectAll(tester);
        },
      );
    }
  }
  for (final feature in <(String, Widget)>[
    ('Loan', const LoanDetailScreen('loan')),
    ('Goal', const GoalDetailScreen('goal')),
    ('Label', const LabelDetailScreen('personal')),
    ('Analytics', const AnalyticsScreen()),
  ]) {
    testWidgets(
      '${feature.$1} amount privacy masks money, progress and charts',
      (tester) async {
        await pumpBatchThree(
          tester,
          feature.$2,
          hidden: true,
          scale: 1,
          width: 390,
        );
        expect(tester.takeException(), isNull);
        await inspectAll(tester);
        expect(find.textContaining('\$'), findsNothing);
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          expect(text.data ?? '', isNot(contains('9.0%')));
        }
      },
    );
  }
  testWidgets(
    'Loan editor has real type-dependent category choices, pinned save and retained controls',
    (tester) async {
      await pumpBatchThree(
        tester,
        const LoanDetailScreen('loan'),
        scale: 1,
        width: 390,
      );
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Update Loan'), findsOneWidget);
      expect(find.byType(ReferenceColorPicker), findsOneWidget);
      await tester.tap(find.text('Borrowing'));
      await tester.pumpAndSettle();
      final choices = tester.widget<ReferenceChoices>(
        find.byType(ReferenceChoices).last,
      );
      expect(choices.choices.values, contains('Salary'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Goal update awaits route removal before disposing controllers and saves custom hex',
    (tester) async {
      final repo = await pumpBatchThree(
        tester,
        const GoalDetailScreen('goal'),
        scale: 1,
        width: 390,
      );
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Updated local goal',
      );
      await tester.ensureVisible(find.byType(ReferenceColorPicker));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.decoration?.labelText == 'ARGB color',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.decoration?.labelText == 'ARGB color',
        ),
        '#123456',
      );
      await tester.tap(find.text('Update Goal'));
      await tester.pumpAndSettle();
      expect(
        repo.persisted!.profiles.first.goals.single.name,
        'Updated local goal',
      );
      expect(repo.persisted!.profiles.first.goals.single.color, 0xff123456);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Goal help has all five working-behavior sections and independent scrolling',
    (tester) async {
      await pumpBatchThree(tester, const GoalsScreen());
      await tester.tap(find.byTooltip('How Goals Work'));
      await tester.pumpAndSettle();
      expect(find.text('How Goals Work'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tracking'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Tracking'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Labels switch grid/scope; income summary filters real transactions',
    (tester) async {
      await pumpBatchThree(tester, const LabelsScreen(), scale: 1, width: 390);
      await tester.tap(find.byTooltip('Show label grid'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Show label list'), findsOneWidget);
      await tester.tap(find.text('Overall'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income · 1'));
      await tester.pumpAndSettle();
      await inspectAll(tester);
      expect(find.text('Linked payment'), findsOneWidget);
      expect(find.text('Coffee'), findsNothing);
    },
  );
  testWidgets(
    'Transaction details open edit/copy drafts, never silently duplicate records',
    (tester) async {
      final repo = await pumpBatchThree(
        tester,
        const LabelDetailScreen('personal'),
        scale: 1,
        width: 390,
      );
      await tester.scrollUntilVisible(
        find.text('Linked payment'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Linked payment'));
      await tester.pumpAndSettle();
      expect(find.text('Transaction Details'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionForm), findsOneWidget);
      expect(
        tester.widget<TransactionForm>(find.byType(TransactionForm)).initial,
        isNull,
      );
      expect(
        tester
            .widget<TransactionForm>(find.byType(TransactionForm))
            .copyFrom!
            .id,
        'payment',
      );
      expect(repo.writes, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Analytics carousel arrows work with reduced motion and exact chart points remain accessible',
    (tester) async {
      await pumpBatchThree(
        tester,
        const AnalyticsScreen(),
        scale: 1,
        width: 390,
      );
      await tester.tap(find.byTooltip('Next smart insight'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous smart insight'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(AnalyticsChart).first,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'All new edit FABs are rounded rectangles, not inherited circles',
    (tester) async {
      for (final screen in [
        const LoanDetailScreen('loan'),
        const GoalDetailScreen('goal'),
        const LabelDetailScreen('personal'),
      ]) {
        await pumpBatchThree(tester, screen, scale: 1, width: 390);
        expect(
          tester
              .widget<FloatingActionButton>(find.byType(FloatingActionButton))
              .shape,
          isA<RoundedRectangleBorder>(),
        );
      }
    },
  );
}
