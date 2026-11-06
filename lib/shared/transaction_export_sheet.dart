import 'package:flutter/material.dart';

import '../core/services/transaction_export_service.dart';

/// Deliberate, local export: the user chooses the format after seeing scope
/// and privacy warnings. Dismissing this sheet creates no file or data write.
Future<TransactionExportKind?> showTransactionExportSheet(
  BuildContext context,
  int count, {
  bool selectedOnly = false,
}) => showModalBottomSheet<TransactionExportKind>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheet) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(sheet).height * .9,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Export $count ${count == 1 ? 'transaction' : 'transactions'}',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cancel export',
                onPressed: () => Navigator.pop(sheet),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            selectedOnly
                ? 'Only your explicitly selected records, including selections hidden by the current search. Other records and profiles are not included.'
                : 'The complete matching selection, not just the visible page. No other profiles or non-matching records are included.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Both formats include full amounts, even when hidden in Tink. CSV also includes private notes and linked names. Files are unencrypted. Share and store them carefully.',
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('CSV spreadsheet'),
            subtitle: const Text(
              'Selected records, native account amounts and linked names',
            ),
            onTap: () => Navigator.pop(sheet, TransactionExportKind.csv),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF report'),
            subtitle: const Text(
              'Selection totals, category breakdown and full transaction table',
            ),
            onTap: () => Navigator.pop(sheet, TransactionExportKind.pdf),
          ),
        ],
      ),
    ),
  ),
);
