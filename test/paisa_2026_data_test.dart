import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/home_layout.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/reporting.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/services/deep_link_service.dart';
import 'package:paisaclone/core/utils/dates.dart';
import 'package:paisaclone/features/home/page_destinations.dart';

import 'support.dart';

void main() {
  test('Visible Home moves keep hidden cards anchored, ordered and hidden', () {
    final current = ['balance', 'hidden', 'accounts', 'reports'];
    final visible = ['balance', 'accounts', 'reports'];
    expect(reorderVisibleHomeCards(current, visible, 0, 3), [
      'accounts',
      'hidden',
      'reports',
      'balance',
    ]);
    expect(reorderVisibleHomeCards(current, visible, 2, 0), [
      'reports',
      'hidden',
      'balance',
      'accounts',
    ]);
    expect(reorderVisibleHomeCards(current, visible, 1, 2), current);
    expect(current, ['balance', 'hidden', 'accounts', 'reports']);
    expect(visible, ['balance', 'accounts', 'reports']);
  });
  test(
    'Stale, duplicated or out-of-range Home drags do not invent layout IDs',
    () {
      for (final move in [
        () => reorderVisibleHomeCards(['a', 'b'], ['a', 'c'], 0, 2),
        () => reorderVisibleHomeCards(['a', 'b'], ['a', 'a'], 0, 2),
        () => reorderVisibleHomeCards(['a', 'a'], ['a'], 0, 1),
        () => reorderVisibleHomeCards(['a', 'b'], ['a', 'b'], -1, 2),
        () => reorderVisibleHomeCards(['a', 'b'], ['a', 'b'], 0, 3),
      ]) {
        expect(move, throwsFormatException);
      }
    },
  );

  test(
    'Every page shortcut resolves to an allowlisted screen and cannot post money',
    () {
      final data = fixture();
      for (final destination in DeepLinkService.pages.keys) {
        expect(pageDestination(destination), isNotNull);
        expect(DeepLinkService.pageUri(destination).scheme, 'tink');
        for (final scheme in ['tink', 'paisa']) {
          for (final uri in [
            Uri(
              scheme: scheme,
              host: 'open',
              queryParameters: {
                'page': destination,
                'amount': '999',
                'type': 'income',
              },
            ),
            Uri(scheme: scheme, host: destination),
            Uri(scheme: scheme, host: 'page', path: '/$destination'),
          ]) {
            final request = DeepLinkService.parse(uri, data);
            expect(request.destination, destination);
            expect(request.transaction, isNull);
            expect(request.silent, isFalse);
          }
        }
      }
    },
  );
  test(
    'External URLs, arbitrary pages and route traversal are never opened',
    () {
      for (final text in [
        'tink://open',
        'tink://open?page=https%3A%2F%2Fexample.com',
        'tink://open?page=..%2Fsettings',
        'tink://page/reports/other',
        'tink://not-a-page',
        'https://paisa-tracker.app/reports',
        'javascript://reports',
      ]) {
        expect(
          () => DeepLinkService.parse(Uri.parse(text), fixture()),
          throwsFormatException,
        );
      }
      expect(() => DeepLinkService.pageUri('arbitrary'), throwsFormatException);
      expect(() => pageDestination('arbitrary'), throwsFormatException);
      final quick = DeepLinkService.parse(
        Uri.parse('tink://quick_add'),
        fixture(),
      );
      expect(quick.destination, isNull);
      expect(quick.transaction, isNull);
      final add = DeepLinkService.parse(
        Uri.parse('tink://add?amount=2'),
        fixture(),
      );
      expect(add.destination, isNull);
      expect(add.transaction!.amountMinor, 200);
    },
  );

  test(
    'Excluded categories include descendants and survive date-window changes',
    () {
      final source = fixture();
      final root = source.categories.firstWhere((v) => v.type == 'expense');
      final other = source.categories.firstWhere(
        (v) => v.type == 'expense' && v.id != root.id,
      );
      final child = Category(id: 'child', name: 'Child', parentId: root.id);
      final data = source.copyWith(
        categories: [...source.categories, child],
        transactions: [
          expense(source, id: 'root', amount: 100),
          expense(
            source,
            id: 'child',
            amount: 200,
          ).copyWith(categoryId: child.id),
          expense(
            source,
            id: 'other',
            amount: 300,
          ).copyWith(categoryId: other.id),
          expense(source, id: 'income', amount: 500, type: 'income'),
        ],
      );
      final ledger = Ledger(data, const AppSettings());
      final filter = TransactionFilter(excludedCategories: {root.id});
      expect(filter.active, isTrue);
      expect(filter.apply(ledger).map((v) => v.id).toSet(), {
        'other',
        'income',
      });
      final window = DateWindow(DateTime(2026, 1), DateTime(2026, 2));
      expect(filter.withDates(window).excludedCategories, {root.id});
      final snapshot = ReportSnapshot(
        ledger,
        window,
        now: DateTime(2026, 2),
        selection: filter.withDates(window).apply(ledger),
      );
      expect(snapshot.expense, 300);
      expect(snapshot.income, 500);
      expect(snapshot.net, 200);
      expect(
        TransactionFilter(
          categories: {child.id},
          excludedCategories: {root.id},
        ).apply(ledger),
        isEmpty,
      );
      expect(
        const TransactionFilter().apply(ledger).length,
        4,
      ); // No global category deletion.
    },
  );
  test(
    'Exclusion traversal is bounded even for an invalid cyclic read-only input',
    () {
      final data = fixture();
      final category = data.categories.firstWhere((v) => v.type == 'expense');
      final ledger = Ledger(
        data.copyWith(
          categories: [
            for (final c in data.categories)
              if (c.id == category.id) c.copyWith(parentId: c.id) else c,
          ],
          transactions: [expense(data)],
        ),
        const AppSettings(),
      );
      expect(
        const TransactionFilter(
          excludedCategories: {'unrelated'},
        ).apply(ledger).length,
        1,
      );
    },
  );
}
