import 'dart:typed_data';

import '../data/ledger.dart';
import '../models/models.dart';
import 'csv_service.dart';
import 'pdf_service.dart';

enum TransactionExportKind { csv, pdf }

class TransactionExportFile {
  final Uint8List bytes;
  final String name, mime;
  const TransactionExportFile(this.bytes, this.name, this.mime);
}

/// Exports the complete selected set, never the UI's paginated first page.
/// Callers capture the ledger and records before opening the format chooser.
class TransactionExportService {
  static Future<TransactionExportFile> create(
    Ledger ledger,
    List<MoneyTransaction> entries,
    TransactionExportKind kind, {
    String title = 'Filtered transactions',
  }) async {
    final snapshot = List<MoneyTransaction>.unmodifiable(entries);
    if (snapshot.isEmpty) {
      throw const FormatException('Select at least one transaction to export');
    }
    if (kind == TransactionExportKind.csv) {
      return TransactionExportFile(
        CsvService.export(ledger, snapshot),
        'Tink-transactions.csv',
        'text/csv',
      );
    }
    return TransactionExportFile(
      await PdfService.report(
        ledger,
        snapshot,
        title,
        scopeNote:
            'This export contains exactly ${snapshot.length} selected saved records, not only the visible page. Future-dated records are included if selected. Totals describe this selection, not the entire account history. This file is not a backup.',
      ),
      'Tink-transactions.pdf',
      'application/pdf',
    );
  }
}
