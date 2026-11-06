import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/financial_pulse.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/core/utils/money.dart';
import 'package:paisaclone/features/catalog/catalog_screen.dart';
import 'package:paisaclone/features/catalog/category_detail_screen.dart';
import 'package:paisaclone/features/reports/spending_health_screen.dart';
import 'package:paisaclone/features/transactions/transaction_form.dart';
import 'package:paisaclone/features/recurring/recurring_editor.dart';
import 'package:paisaclone/l10n/generated/app_localizations.dart';
import 'package:paisaclone/shared/analytics_chart.dart';
import 'package:paisaclone/shared/reference_charts.dart';
import 'package:paisaclone/shared/wavy_ring.dart';
import 'package:paisaclone/core/data/reporting.dart';

import 'reference_batch_03_widgets_test.dart' show batchThreeData;
import 'support.dart';

ProfileData batchFourData() {
  final base = batchThreeData();
  final root = base.categories.firstWhere((c) => c.type == 'expense');
  return base.copyWith(
    accounts: [
      ...base.accounts,
      base.accounts.first.copyWith(
        id: 'second',
        name: 'Euro account',
        currency: 'EUR',
      ),
    ],
    categories: [
      ...base.categories,
      Category(
        id: 'leaf',
        name: 'Coffee outings',
        type: 'expense',
        parentId: root.id,
      ),
    ],
    entities: [
      ...base.entities,
      const NamedEntity(id: 'shop', name: 'Local shop', kind: 'place'),
    ],
    transactions: [
      ...base.transactions,
      expense(base, id: 'leaf-record', date: DateTime.now()).copyWith(
        categoryId: 'leaf',
        personIds: ['person'],
        placeId: 'shop',
        labelIds: ['personal'],
      ),
    ],
  );
}

Future<MemoryRepository> pumpFour(
  WidgetTester tester,
  Widget screen, {
  ProfileData? data,
  AppSettings settings = const AppSettings(),
  double scale = 1.6,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = MemoryRepository(
    appFor(data ?? batchFourData(), settings: settings),
  );
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(repo),
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: tinkTheme(settings, Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
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

Future<void> scrollFour(WidgetTester tester) async {
  final scroll = find
      .byWidgetPredicate(
        (w) =>
            w is Scrollable &&
            (w.axisDirection == AxisDirection.down ||
                w.axisDirection == AxisDirection.up),
      )
      .first;
  if (scroll.evaluate().isEmpty) return;
  final position = tester.state<ScrollableState>(scroll).position;
  for (var i = 0; i < 60; i++) {
    expect(tester.takeException(), isNull, reason: 'Real section $i');
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
    for (final item in <(String, Widget)>[
      ('Categories', const CatalogScreen('category')),
      (
        'Category detail',
        CategoryDetailScreen(
          batchFourData().categories.firstWhere((c) => c.type == 'expense').id,
        ),
      ),
      ('Places', const CatalogScreen('place')),
      ('People', const CatalogScreen('person')),
      ('Spending review', const SpendingHealthScreen()),
      (
        'Connected transaction editor',
        const TransactionForm(
          initialCategoryId: 'leaf',
          initialPlaceId: 'shop',
          initialPersonIds: ['person'],
        ),
      ),
    ]) {
      testWidgets('${item.$1} is finite and readable at 320px 160% $direction', (
        tester,
      ) async {
        // Category IDs are fixture-generated; derive the actual route in this
        // same snapshot instead of accidentally testing an empty removed page.
        final data = batchFourData();
        final screen = item.$1 == 'Category detail'
            ? CategoryDetailScreen(
                data.categories.firstWhere((c) => c.type == 'expense').id,
              )
            : item.$2;
        final repo = await pumpFour(
          tester,
          screen,
          data: data,
          direction: direction,
        );
        await scrollFour(tester);
        expect(repo.writes, 0);
      });
    }
  }
  testWidgets('Signed chart holds and moves to the correct rounded-bar bin', (
    tester,
  ) async {
    final data = batchFourData(),
        ledger = Ledger(batchFourData(), const AppSettings());
    await pumpFour(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AnalyticsChart(
            values: const [-1000, 0, 2000],
            labels: const ['Loss', 'Zero', 'Gain'],
            ledger: ledger,
            bars: true,
          ),
        ),
      ),
      data: data,
      scale: 1,
    );
    final plot = find
        .descendant(
          of: find.byType(AnalyticsChart),
          matching: find.byType(CustomPaint),
        )
        .first;
    final rect = tester.getRect(plot);
    final touch = await tester.startGesture(
      Offset(rect.left + 42 + (rect.width - 48) / 6, rect.top + 80),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Loss'), findsOneWidget);
    expect(
      find.text(money(-1000, 'USD', locale: ledger.settings.locale)),
      findsOneWidget,
    );
    await touch.moveTo(
      Offset(rect.left + 42 + (rect.width - 48) * 5 / 6, rect.top + 80),
    );
    await tester.pump();
    await touch.up();
    await tester.pumpAndSettle();
    expect(find.text('Gain'), findsOneWidget);
    expect(
      find.text(money(2000, 'USD', locale: ledger.settings.locale)),
      findsOneWidget,
    );
    expect(find.textContaining('zero or negative baseline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Donut exposes real segments and complete adjustment semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      final data = batchFourData(),
          ledger = Ledger(batchFourData(), const AppSettings());
      await pumpFour(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ReferenceDonut(const [
              ReportGroup(
                id: 'one',
                name: 'One',
                icon: 'food',
                color: 0xfff6bb96,
                amount: 100,
                entries: [],
              ),
              ReportGroup(
                id: 'two',
                name: 'Two',
                icon: 'food',
                color: 0xff93c995,
                amount: 300,
                entries: [],
              ),
            ], ledger),
          ),
        ),
        data: data,
        scale: 1,
      );
      await tester.tap(find.byTooltip('Next allocation segment'));
      await tester.pumpAndSettle();
      expect(find.text('Two · 75.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      handle.dispose();
    }
  });
  testWidgets(
    'Pinned transaction save retains collapsed links, dates and native amount',
    (tester) async {
      var data = batchFourData();
      final original =
          expense(
            data,
            id: 'edit-me',
            amount: 12345,
            date: DateTime(2026, 11, 1, 14, 35),
          ).copyWith(
            name: 'A detailed local record',
            notes: 'Keep this note',
            categoryId: 'leaf',
            personIds: ['person'],
            placeId: 'shop',
            labelIds: ['personal', 'work'],
            loanId: 'loan',
          );
      data = data.copyWith(transactions: [...data.transactions, original]);
      final repo = await pumpFour(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionForm(initial: original),
                  ),
                ),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
        data: data,
        scale: 1,
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Collapse extra fields'));
      await tester.pumpAndSettle();
      expect(find.text('Save transaction'), findsOneWidget);
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();
      final saved = repo.persisted!.profiles.first.transactions.singleWhere(
        (e) => e.id == 'edit-me',
      );
      expect(saved.amountMinor, 12345);
      expect(saved.name, original.name);
      expect(saved.notes, original.notes);
      expect(saved.categoryId, 'leaf');
      expect(saved.personIds, ['person']);
      expect(saved.placeId, 'shop');
      expect(saved.labelIds, original.labelIds);
      expect(saved.loanId, 'loan');
      expect(saved.date.isAtSameMomentAs(original.date), isTrue);
      expect(find.byType(TransactionForm), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Spending review privacy hides values, percentages and inspector data',
    (tester) async {
      await pumpFour(
        tester,
        const SpendingHealthScreen(),
        settings: const AppSettings(hideAmounts: true),
      );
      await scrollFour(tester);
      expect(find.textContaining(r'$'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Possible-repeat review stays unsaved, posting starts off, and cancel retains records',
    (tester) async {
      final data = batchFourData();
      final category = data.categories.firstWhere((c) => c.type == 'expense');
      final draft = Recurring(
        id: 'unsaved-candidate',
        name: 'A reading suggestion',
        amountMinor: 949,
        accountId: data.accounts.first.id,
        categoryId: category.id,
        start: DateTime(2026, 5, 8),
        nextDue: DateTime(2026, 11, 8),
        autoPost: false,
      );
      final repo = await pumpFour(
        tester,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => reviewRecurringDraft(context, ref, draft),
                child: const Text('Review candidate'),
              ),
            ),
          ),
        ),
        data: data,
        scale: 1,
      );
      await tester.tap(find.text('Review candidate'));
      await tester.pumpAndSettle();
      expect(find.text('Review recurring draft'), findsOneWidget);
      expect(repo.writes, 0);
      final automatic = find.byWidgetPredicate(
        (w) =>
            w is SwitchListTile &&
            w.title is Text &&
            (w.title as Text).data == 'Auto-create due entries',
      );
      expect(tester.widget<SwitchListTile>(automatic).value, isFalse);
      await tester.tap(find.byTooltip('Cancel editor'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(find.text('Review recurring draft'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Holding the index reveals its actual calculation and honors privacy',
    (tester) async {
      for (final hidden in [false, true]) {
        final data = batchFourData(),
            settings = AppSettings(hideAmounts: hidden);
        final score = FinancialPulse.fromLedger(
          Ledger(data, settings),
          DateTime.now(),
        ).score;
        await pumpFour(
          tester,
          const SpendingHealthScreen(),
          data: data,
          settings: settings,
        );
        await tester.longPress(find.byType(WavyRing).first);
        await tester.pumpAndSettle();
        expect(find.text('How Spending Review Works'), findsOneWidget);
        expect(
          find.textContaining(
            hidden ? 'Index hidden.' : 'Recorded planning index $score / 100.',
          ),
          findsOneWidget,
        );
        if (hidden) {
          expect(
            find.textContaining('Recorded planning index $score / 100.'),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'Hidden category can be restored without modifying its linked records',
    (tester) async {
      var data = batchFourData();
      final category = data.categories
          .firstWhere((c) => c.type == 'expense')
          .copyWith(hidden: true);
      data = data.copyWith(
        categories: [
          for (final c in data.categories) c.id == category.id ? category : c,
        ],
      );
      final repo = await pumpFour(
        tester,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => editCatalogCategory(context, ref, category),
                child: const Text('Restore category'),
              ),
            ),
          ),
        ),
        data: data,
        scale: 1,
      );
      await tester.tap(find.text('Restore category'));
      await tester.pumpAndSettle();
      final toggle = find.byWidgetPredicate(
        (w) =>
            w is SwitchListTile &&
            w.title is Text &&
            (w.title as Text).data == 'Hide from new entries',
      );
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = repo.persisted!.profiles.first;
      expect(
        saved.categories.singleWhere((c) => c.id == category.id).hidden,
        isFalse,
      );
      expect(
        saved.transactions.map((e) => e.toJson()),
        data.transactions.map((e) => e.toJson()),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Saving a reviewed monthly candidate preserves its next due without historical replay',
    (tester) async {
      final data = batchFourData(), now = DateTime.now();
      final category = data.categories.firstWhere((c) => c.type == 'expense');
      final start = DateTime(now.year, now.month - 5, 8),
          last = DateTime(now.year, now.month - 1, 8);
      final next = DateTime(now.year, now.month, 8);
      final draft = Recurring(
        id: 'unsaved-candidate',
        name: 'Reading circle',
        amountMinor: 750,
        accountId: data.accounts.first.id,
        categoryId: category.id,
        start: start,
        nextDue: next,
        frequency: 'monthly',
        autoPost: false,
        notes: 'Candidate history ends $last',
      );
      final repo = await pumpFour(
        tester,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => reviewRecurringDraft(context, ref, draft),
                child: const Text('Save candidate'),
              ),
            ),
          ),
        ),
        data: data,
        scale: 1,
      );
      await tester.tap(find.text('Save candidate'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(find.text('Next due'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Save'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = repo.persisted!.profiles.first;
      final rule = saved.recurrings.single;
      expect(rule.id, isNot(draft.id));
      expect(rule.name, draft.name);
      expect(rule.start, start);
      expect(rule.nextDue, next);
      expect(rule.autoPost, isFalse);
      expect(
        saved.transactions.map((e) => e.toJson()),
        data.transactions.map((e) => e.toJson()),
      );
      expect(find.text('Review recurring draft'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Habits retain the selected card after vertical list recycling', (
    tester,
  ) async {
    await pumpFour(tester, const SpendingHealthScreen(), scale: 1);
    final vertical = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    final pager = find.byType(PageView);
    await tester.scrollUntilVisible(pager, 350, scrollable: vertical);
    await tester.ensureVisible(pager);
    await tester.pumpAndSettle();
    await tester.drag(pager, const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('End-of-month pattern').hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Possible Monthly Repeats'),
      350,
      scrollable: vertical,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(pager, -350, scrollable: vertical);
    await tester.ensureVisible(pager);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('End-of-month pattern').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
