import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/core/utils/constants.dart';
import 'package:paisaclone/features/accounts/accounts_screen.dart';
import 'package:paisaclone/features/home/home_screen.dart';
import 'package:paisaclone/features/settings/page_shortcuts_screen.dart';
import 'package:paisaclone/features/settings/paisa_import_screen.dart';
import 'package:paisaclone/features/transactions/transaction_form.dart';
import 'package:paisaclone/l10n/generated/app_localizations.dart';
import 'package:paisaclone/shared/private_amount.dart';
import 'package:paisaclone/shared/widgets.dart';

import 'fixtures/paisa_636.dart';
import 'support.dart';

Future<MemoryRepository> pump2026(
  WidgetTester tester,
  Widget screen, {
  AppSettings settings = const AppSettings(),
  double width = 390,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = MemoryRepository(appFor(fixture(), settings: settings));
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

Future<void> scrollAll2026(WidgetTester tester) async {
  final scroll = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;
  final position = tester.state<ScrollableState>(scroll).position;
  for (var i = 0; i < 80; i++) {
    expect(tester.takeException(), isNull, reason: '2026 scroll section $i');
    if (position.pixels >= position.maxScrollExtent - 1) break;
    position.jumpTo(
      (position.pixels + 350).clamp(0, position.maxScrollExtent).toDouble(),
    );
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

Future<void> previewLegacy2026(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(r'USD · $').last);
  await tester.pumpAndSettle();
  final mapping = find.byType(DropdownButtonFormField<String>).last;
  await tester.ensureVisible(mapping);
  await tester.tap(mapping);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Debt = I borrowed · Credit = I lent').last);
  await tester.pumpAndSettle();
  final validate = find.text('Validate & preview import');
  await tester.ensureVisible(validate);
  await tester.tap(validate);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Private amounts paint fixed shapes and reveal no number or sign in semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      await pump2026(
        tester,
        const Scaffold(
          body: Column(
            children: [
              AmountText(1, prefix: '+'),
              AmountText(-987654321),
            ],
          ),
        ),
        settings: const AppSettings(hideAmounts: true),
      );
      expect(find.byType(PrivateAmount), findsNWidgets(2));
      expect(
        tester.getSize(find.byType(PrivateAmount).first),
        tester.getSize(find.byType(PrivateAmount).last),
      );
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.textContaining('987'), findsNothing);
      expect(find.textContaining('••••'), findsNothing);
      final label = tester
          .getSemantics(find.byType(PrivateAmount).first)
          .toStringDeep();
      expect(label, contains('Amount hidden'));
      expect(label, isNot(contains('987654321')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Name Next focuses amount, amount Next focuses notes, never saves implicitly',
    (tester) async {
      final repo = await pump2026(tester, const TransactionForm());
      final name = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'What was it for?',
      );
      final amount = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.labelText?.startsWith('Amount (') ?? false),
      );
      final notes = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'A little note (optional)',
      );
      await tester.tap(name);
      await tester.enterText(name, 'A new 2026 entry');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(amount).focusNode!.hasFocus, isTrue);
      await tester.enterText(amount, '2+0.50');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(notes).focusNode!.hasFocus, isTrue);
      await tester.enterText(notes, 'First line\nSecond line');
      expect(repo.writes, 0);
      expect(repo.initial.profiles.single.transactions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home move buttons save inline and retain hidden cards without editing money',
    (tester) async {
      final repo = await pump2026(
        tester,
        const HomeScreen(),
        settings: const AppSettings(
          homeCards: ['accounts', 'premium', 'reports'],
          hiddenCards: ['premium'],
        ),
      );
      await tester.tap(find.byTooltip('Reorder Home cards'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-inline-reorder')), findsOneWidget);
      expect(find.byType(ReorderableDragStartListener), findsNWidgets(2));
      final up = find.byTooltip('Move ${homeCardNames['reports']} up');
      await tester.ensureVisible(up);
      await tester.tap(up);
      await tester.pumpAndSettle();
      expect(repo.persisted!.settings.homeCards, [
        'reports',
        'premium',
        'accounts',
      ]);
      expect(repo.persisted!.settings.hiddenCards, ['premium']);
      expect(repo.persisted!.profiles.single.transactions, isEmpty);
      expect(repo.writes, 1);
      await tester.tap(find.byTooltip('Finish reordering'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-inline-reorder')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home handles accept a real drag and a failed save never exposes a new order',
    (tester) async {
      final repo = await pump2026(
        tester,
        const HomeScreen(),
        settings: const AppSettings(homeCards: ['accounts', 'reports']),
      );
      await tester.tap(find.byTooltip('Reorder Home cards'));
      await tester.pumpAndSettle();
      final handle = find.byType(ReorderableDragStartListener).first;
      await tester.ensureVisible(handle);
      final start = tester.getCenter(handle);
      final target = tester.getCenter(
        find.byType(ReorderableDragStartListener).last,
      );
      final drag = await tester.startGesture(start);
      await drag.moveTo(target + const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 400));
      await drag.up();
      await tester.pumpAndSettle();
      expect(repo.persisted!.settings.homeCards, ['reports', 'accounts']);
      final writes = repo.writes;
      repo.failNext = true;
      final up = find.byTooltip('Move ${homeCardNames['accounts']} up');
      await tester.ensureVisible(up);
      await tester.tap(up);
      await tester.pumpAndSettle();
      expect(repo.persisted!.settings.homeCards, ['reports', 'accounts']);
      expect(repo.writes, writes);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Legacy preview and cancelled confirmation write nothing; save creates one separate profile',
    (tester) async {
      final repo = await pump2026(
        tester,
        PaisaImportScreen(initialBytes: legacyBytes()),
      );
      await previewLegacy2026(tester);
      expect(repo.writes, 0);
      expect(find.text('Validated preview'), findsOneWidget);
      await tester.ensureVisible(find.text('Create imported profile'));
      await tester.tap(find.text('Create imported profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(repo.initial.profiles.length, 1);
      await tester.tap(find.text('Create imported profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create new profile'));
      await tester.pumpAndSettle();
      expect(repo.writes, 1);
      expect(repo.persisted!.profiles.length, 2);
      expect(
        repo.persisted!.profiles.first.toJson(),
        repo.initial.profiles.first.toJson(),
      );
      expect(repo.persisted!.profiles.last.transactions.length, 3);
      expect(find.text('Your new profile is saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final direction in TextDirection.values) {
    for (final screen in ['shortcuts', 'import', 'home-edit']) {
      testWidgets('2026 $screen fully scrolls at 320px / 160% / $direction', (
        tester,
      ) async {
        final page = switch (screen) {
          'shortcuts' => const PageShortcutsScreen(),
          'import' => PaisaImportScreen(initialBytes: legacyBytes()),
          _ => const HomeScreen(),
        };
        await pump2026(
          tester,
          page,
          width: 320,
          scale: 1.6,
          direction: direction,
        );
        if (screen == 'import') await previewLegacy2026(tester);
        if (screen == 'home-edit') {
          await tester.tap(find.byTooltip('Reorder Home cards'));
          await tester.pumpAndSettle();
        }
        await scrollAll2026(tester);
      });
    }
  }

  for (final width in [800.0, 1280.0]) {
    testWidgets(
      'Accounts use a working portrait/landscape two-pane layout at $width',
      (tester) async {
        await pump2026(tester, const AccountsScreen(), width: width);
        expect(find.byType(AccountsListScreen), findsOneWidget);
        expect(find.text('Pick an account'), findsOneWidget);
        await tester.tap(find.byType(AccountOverviewCard).first);
        await tester.pumpAndSettle();
        expect(find.byType(AccountDetailScreen), findsOneWidget);
        expect(find.byTooltip('Close account panel'), findsOneWidget);
        await tester.tap(find.byTooltip('Close account panel'));
        await tester.pumpAndSettle();
        expect(find.text('Pick an account'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
