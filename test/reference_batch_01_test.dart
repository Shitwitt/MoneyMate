import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/data/recurring_schedule.dart';
import 'package:paisaclone/core/data/validation.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/theme/theme.dart';
import 'package:paisaclone/core/utils/constants.dart';
import 'package:paisaclone/core/utils/dates.dart';
import 'package:paisaclone/features/recurring/recurring_calendar.dart';
import 'package:paisaclone/features/recurring/recurring_detail_screen.dart';
import 'package:paisaclone/features/recurring/recurring_screen.dart';
import 'package:paisaclone/l10n/generated/app_localizations.dart';
import 'package:paisaclone/main.dart';
import 'package:paisaclone/shared/widgets.dart';

import 'support.dart';

Recurring schedule(
  ProfileData profile, {
  DateTime? date,
  String frequency = 'monthly',
}) {
  final due = date ?? DateTime(2026, 1, 31, 9);
  return Recurring(
    id: 'schedule',
    name: 'Monthly test',
    amountMinor: 1250,
    accountId: profile.accounts.first.id,
    categoryId: profile.categories.firstWhere((c) => c.type == 'expense').id,
    start: due,
    nextDue: due,
    frequency: frequency,
    autoPost: false,
  );
}

void main() {
  test('Demo isolates edits, settings, restore and exits without any durable write', () async {
    final original = appFor(fixture());
    final repo = MemoryRepository(original);
    final app = AppController(repo);
    await app.startDemo(clock: DateTime(2026, 11, 6));
    expect(app.snapshot.isDemo, true);
    validateData(app.snapshot);
    expect(app.snapshot.profiles.single.recurrings.length, 2);
    expect(app.snapshot.profiles.single.bills.length, 2);
    expect(repo.writes, 0);
    await app.renameProfile('Edited demo');
    await app.settings((s) => s.copyWith(locale: 'fa'));
    await app.restore(
      original,
    ); // May replace the demo, never the real repository.
    expect(app.snapshot.isDemo, true);
    expect(repo.writes, 0);
    await app.exitDemo();
    expect(app.snapshot.isDemo, false);
    expect(app.snapshot.toJson(), original.toJson());
    expect(repo.writes, 0);
    app.dispose();
  });
  test('Demo is never restored from a serialized flag; the real queue continues after exit', () async {
    final original = appFor(fixture());
    expect(
      AppData.fromJson({...original.toJson(), 'isDemo': true}).isDemo,
      false,
    );
    final repo = MemoryRepository(original);
    final controller = AppController(repo);
    await controller.renameProfile('Real change');
    await controller.startDemo(clock: DateTime(2026, 11, 6));
    await controller.renameProfile('Not real');
    await controller.exitDemo();
    expect(controller.snapshot.profiles.single.profile.name, 'Real change');
    expect(repo.persisted!.profiles.single.profile.name, 'Real change');
    expect(repo.writes, 1);
    await controller.renameProfile('Real again');
    expect(repo.writes, 2);
    controller.dispose();
  });
  test('Process records one exact due occurrence; stale concurrent taps cannot double debit', () async {
    final profile = fixture();
    final rule = schedule(profile);
    final repo = MemoryRepository(appFor(profile.copyWith(recurrings: [rule])));
    final controller = AppController(repo);
    final first = controller.processRecurringOccurrence(
      rule.id,
      expectedDue: rule.nextDue,
      clock: DateTime(2026, 4, 1),
    );
    final stale = controller.processRecurringOccurrence(
      rule.id,
      expectedDue: rule.nextDue,
      clock: DateTime(2026, 4, 1),
    );
    final rejected = expectLater(stale, throwsFormatException);
    await first;
    await rejected;
    final next = controller.snapshot.profiles.single;
    expect(next.transactions.length, 1);
    expect(
      next.transactions.single.id,
      '${rule.id}@${rule.nextDue.toIso8601String()}',
    );
    expect(next.recurrings.single.nextDue, DateTime(2026, 2, 28, 9));
    expect(repo.writes, 1);
    controller.dispose();
  });
  test(
    'Skip is atomic, never touches money and honors an inclusive end',
    () async {
      final profile = fixture();
      final rule = schedule(profile)
          .copyWith(end: DateTime(2026, 1, 31, 23, 59));
      final repo = MemoryRepository(
        appFor(profile.copyWith(recurrings: [rule])),
      );
      final controller = AppController(repo);
      repo.failNext = true;
      await expectLater(
        controller.skipRecurringOccurrence(rule.id, expectedDue: rule.nextDue),
        throwsStateError,
      );
      expect(
        controller.snapshot.profiles.single.recurrings.single.nextDue,
        rule.nextDue,
      );
      await controller.skipRecurringOccurrence(
        rule.id,
        expectedDue: rule.nextDue,
      );
      final next = controller.snapshot.profiles.single;
      expect(next.transactions, isEmpty);
      expect(next.recurrings.single.enabled, false);
      expect(
        next.accounts.first.openingMinor,
        profile.accounts.first.openingMinor,
      );
      controller.dispose();
    },
  );
  test('Future processing fails safely; archived auto rules cannot catch up or affect projections', () async {
    final profile = fixture();
    final rule = schedule(profile, date: DateTime(2027, 1, 31));
    final repo = MemoryRepository(appFor(profile.copyWith(recurrings: [rule])));
    final controller = AppController(repo);
    await expectLater(
      controller.processRecurringOccurrence(
        rule.id,
        expectedDue: rule.nextDue,
        clock: DateTime(2026, 1, 1),
      ),
      throwsFormatException,
    );
    await controller.upsertRecurring(
      rule.copyWith(archived: true, autoPost: true),
    );
    await controller.processRecurring(clock: DateTime(2028, 1, 1));
    final next = controller.snapshot.profiles.single;
    expect(next.transactions, isEmpty);
    expect(Ledger(next, const AppSettings()).monthlyBurn, 0);
    controller.dispose();
  });
  test('Linked metadata is recorded and included in its budget; deleting links preserves history', () async {
    var profile = fixture();
    final rule = schedule(profile).copyWith(
      budgetId: 'budget',
      labelIds: ['label'],
      personIds: ['person'],
      placeId: 'place',
      reminderDays: 7,
    );
    profile = profile.copyWith(
      recurrings: [rule],
      budgets: [
        Budget(
          id: 'budget',
          name: 'Linked plan',
          limitMinor: 5000,
          start: DateTime(2026, 1, 1),
          categoryIds: [
            profile.categories.lastWhere((c) => c.type == 'expense').id,
          ],
        ),
      ],
      entities: const [
        NamedEntity(id: 'label', name: 'Home', kind: 'label'),
        NamedEntity(id: 'person', name: 'Friend', kind: 'person'),
        NamedEntity(id: 'place', name: 'Nearby', kind: 'place'),
      ],
    );
    final controller = AppController(MemoryRepository(appFor(profile)));
    await controller.processRecurringOccurrence(
      rule.id,
      expectedDue: rule.nextDue,
      clock: DateTime(2026, 1, 31, 10),
    );
    var next = controller.snapshot.profiles.single;
    final entry = next.transactions.single;
    expect(entry.labelIds, ['label']);
    expect(entry.personIds, ['person']);
    expect(entry.placeId, 'place');
    expect(entry.budgetId, 'budget');
    expect(
      Ledger(
        next,
        const AppSettings(),
      ).budgetStatus(next.budgets.single, DateTime(2026, 1, 31)).spent,
      1250,
    );
    await controller.deleteBudget('budget');
    await controller.deleteEntity('label');
    next = controller.snapshot.profiles.single;
    expect(next.transactions.single.amountMinor, 1250);
    expect(next.transactions.single.budgetId, '');
    expect(next.recurrings.single.budgetId, '');
    expect(next.transactions.single.labelIds, isEmpty);
    expect(next.recurrings.single.labelIds, isEmpty);
    await controller.deleteRecurring(rule.id);
    expect(controller.snapshot.profiles.single.transactions.length, 1);
    controller.dispose();
  });
  test(
    'Old rule JSON defaults remain compatible and all new fields round trip',
    () {
      final rule = schedule(fixture()).copyWith(
        archived: true,
        reminderDays: 3,
        budgetId: 'budget',
        placeId: 'place',
        labelIds: ['one'],
        personIds: ['two'],
      );
      expect(Recurring.fromJson(rule.toJson()).toJson(), rule.toJson());
      final legacy = rule.toJson()
        ..remove('archived')
        ..remove('reminderDays')
        ..remove('budgetId')
        ..remove('placeId')
        ..remove('labelIds')
        ..remove('personIds');
      final restored = Recurring.fromJson(legacy);
      expect(restored.archived, false);
      expect(restored.reminderDays, 0);
      expect(restored.labelIds, isEmpty);
      expect(
        rule.copyWith(end: DateTime(2027)).copyWith(clearEnd: true).end,
        isNull,
      );
    },
  );
  test('Calendar projections retain month-end anchors, end limits and future/handled separation', () {
    final rule = schedule(fixture());
    final dates = projectedOccurrences(
      rule,
      DateWindow(DateTime(2026, 1, 1), DateTime(2026, 4, 1)),
    );
    expect(dates, [
      DateTime(2026, 1, 31, 9),
      DateTime(2026, 2, 28, 9),
      DateTime(2026, 3, 31, 9),
    ]);
    expect(
      projectedOccurrences(
        rule.copyWith(nextDue: DateTime(2026, 3, 31, 9)),
        DateWindow(DateTime(2026, 2), DateTime(2026, 3)),
      ),
      isEmpty,
    );
    expect(
      projectedOccurrences(
        rule.copyWith(end: DateTime(2026, 2, 28, 23, 59)),
        DateWindow(DateTime(2026), DateTime(2027)),
      ).length,
      2,
    );
  });
  test('Old daily rules jump to a distant month without unbounded loops; every frequency advances', () {
    final profile = fixture();
    final rule = schedule(
      profile,
      date: DateTime(1970, 1, 1, 9),
      frequency: 'daily',
    );
    final dates = projectedOccurrences(
      rule,
      DateWindow(DateTime(2199, 3), DateTime(2199, 4)),
    );
    expect(dates.length, 31);
    expect(dates.first, DateTime(2199, 3, 1, 9));
    for (final frequency in frequencies) {
      final item = rule.copyWith(frequency: frequency);
      expect(
        nextOccurrence(item, item.nextDue).isAfter(item.nextDue),
        true,
        reason: frequency,
      );
      expect(recurrenceLabel(item), isNotEmpty);
    }
  });
  test('36 starter locales are real, complete key sets and generated; no fake count', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    expect(languageNames.length, 36);
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      languageNames.keys.toSet(),
    );
    for (final locale in languageNames.keys) {
      final messages = jsonDecode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map;
      expect(messages.keys.toSet(), en.keys.toSet(), reason: locale);
      expect(
        messages.values.every(
          (value) => value is String && value.trim().isNotEmpty,
        ),
        true,
        reason: locale,
      );
    }
  });
  testWidgets(
    'Calendar navigates months and detail processing publishes real history',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = fixture(), now = DateTime.now();
      final rule = schedule(
        profile,
        date: DateTime(now.year, now.month, now.day - 1, 9),
      );
      final repo = MemoryRepository(
        appFor(profile.copyWith(recurrings: [rule])),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: tinkTheme(const AppSettings(), Brightness.dark),
            home: RecurringDetailScreen(rule.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Process'));
      await tester.pumpAndSettle();
      expect(
        repo.persisted!.profiles.single.transactions.single.recurringId,
        rule.id,
      );
      await tester.scrollUntilVisible(
        find.text('History'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('1 transactions'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: tinkTheme(const AppSettings(), Brightness.dark),
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecurringCalendar(
                  rules: [rule],
                  ledger: Ledger(
                    profile.copyWith(recurrings: [rule]),
                    const AppSettings(),
                  ),
                  onOpen: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Recurring overview/list/calendar/help tolerate narrow large text and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = fixture(), now = DateTime.now();
      final rule = schedule(
        profile,
        date: DateTime(now.year, now.month, now.day - 1, 9),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              MemoryRepository(appFor(profile.copyWith(recurrings: [rule]))),
            ),
          ],
          child: MaterialApp(
            theme: tinkTheme(const AppSettings(), Brightness.dark),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(1.6),
                disableAnimations: true,
              ),
              child: const RecurringScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('How recurring works'));
      await tester.pumpAndSettle();
      expect(find.text('Got it'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Persian and Urdu route direction is RTL with usable primary navigation',
    (tester) async {
      for (final locale in ['fa', 'ur']) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(locale),
            overrides: [
              repositoryProvider.overrideWithValue(
                MemoryRepository(
                  appFor(fixture(), settings: AppSettings(locale: locale)),
                ),
              ),
            ],
            child: const PaisaApp(enablePlatformServices: false),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          Directionality.of(
            tester.element(find.byType(ReferenceNavigationDock)),
          ),
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
