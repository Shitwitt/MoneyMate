import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/services/csv_service.dart';
import 'package:paisaclone/core/services/transaction_export_service.dart';
import 'package:paisaclone/features/transactions/transaction_tile.dart';
import 'package:paisaclone/features/transactions/transactions_screen.dart';
import 'package:paisaclone/shared/transaction_export_sheet.dart';

import 'reference_batch_04_widgets_test.dart' show pumpFour;
import 'support.dart';

ProfileData exportFixture() {
  final data = fixture();
  return data.copyWith(
    transactions: [
      for (var i = 0; i < 150; i++)
        expense(
          data,
          id: 'selected-$i',
          amount: 125 + i,
        ).copyWith(name: 'Selected coffee $i', notes: 'Private note $i'),
      expense(data, id: 'not-selected').copyWith(name: 'Not in this export'),
    ],
  );
}

void main() {
  test(
    'CSV exports all matching rows beyond the first UI page and no other rows',
    () async {
      final ledger = Ledger(
        exportFixture(),
        const AppSettings(hideAmounts: true),
      );
      final records = const TransactionFilter(query: 'Selected coffee')
          .apply(ledger);
      final result = await TransactionExportService.create(
        ledger,
        records,
        TransactionExportKind.csv,
      );
      final csv = CsvDocument.parse(result.bytes);
      expect(result.name, 'Tink-transactions.csv');
      expect(result.mime, 'text/csv');
      expect(csv.rows.length, 150);
      final text = utf8.decode(result.bytes);
      expect(text, contains('Selected coffee 149'));
      expect(text, contains('Private note 149'));
      expect(text, isNot(contains('Not in this export')));
    },
  );

  test('PDF produces a real local report from the captured selection', () async {
    final ledger = Ledger(exportFixture(), const AppSettings());
    final records = const TransactionFilter(query: 'Selected coffee')
        .apply(ledger);
    final pending = TransactionExportService.create(
      ledger,
      records,
      TransactionExportKind.pdf,
    );
    records
        .clear(); // A later UI filter change must not alter an in-flight file.
    final file = await pending;
    expect(file.name, 'Tink-transactions.pdf');
    expect(file.mime, 'application/pdf');
    expect(String.fromCharCodes(file.bytes.take(5)), '%PDF-');
    expect(file.bytes.length, greaterThan(1000));
  });

  test('Empty selections do not produce a misleading report', () async {
    final ledger = Ledger(fixture(), const AppSettings());
    for (final kind in TransactionExportKind.values) {
      await expectLater(
        TransactionExportService.create(ledger, [], kind),
        throwsFormatException,
      );
    }
  });

  testWidgets(
    'Search exports its full filter or explicit selection, not only rendered rows',
    (tester) async {
      final repo = await pumpFour(
        tester,
        const TransactionsScreen(
          initialFilter: TransactionFilter(query: 'Selected coffee'),
        ),
        data: exportFixture(),
        scale: 1,
      );
      await tester.tap(find.byTooltip('Export filtered records'));
      await tester.pumpAndSettle();
      expect(find.text('Export 150 transactions'), findsOneWidget);
      expect(find.text('CSV spreadsheet'), findsOneWidget);
      expect(find.text('PDF report'), findsOneWidget);
      expect(find.textContaining('Files are unencrypted.'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel export'));
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(TransactionTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Export selected records'));
      await tester.pumpAndSettle();
      expect(find.text('Export 1 transaction'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel export'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Export formats remain scrollable at narrow 160 percent LTR and RTL',
    (tester) async {
      for (final direction in TextDirection.values) {
        TransactionExportKind? choice;
        await pumpFour(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async =>
                      choice = await showTransactionExportSheet(context, 150),
                  child: const Text('Choose export'),
                ),
              ),
            ),
          ),
          direction: direction,
        );
        await tester.tap(find.text('Choose export'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('PDF report'),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('PDF report'));
        await tester.pumpAndSettle();
        expect(choice, TransactionExportKind.pdf);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
