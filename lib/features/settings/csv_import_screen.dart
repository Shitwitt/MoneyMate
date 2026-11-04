import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/services/csv_service.dart';
import '../../core/services/file_service.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});
  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  CsvDocument? document;
  CsvPreview? preview;
  final mapping = <String, int>{};
  String filename = '';
  bool busy = false;
  static const columns = [
    'date',
    'type',
    'name',
    'amount',
    'account',
    'currency',
    'category',
    'notes',
    'id',
  ];
  Future<void> _pick() async {
    await runSafe(context, () async {
      final file = await FileService.pick(['csv']);
      if (file == null) return;
      final doc = CsvDocument.parse(file.bytes);
      if (!mounted) return;
      setState(() {
        document = doc;
        filename = file.name;
        preview = null;
        mapping.clear();
        for (final key in columns) {
          final index = doc.headers.indexWhere(
            (header) => header.toLowerCase().trim() == key,
          );
          if (index >= 0) mapping[key] = index;
        }
      });
    });
  }

  void _validate() {
    if (!['date', 'type', 'name', 'amount'].every(mapping.containsKey)) {
      toast(context, 'Map date, type, name, and amount first.');
      return;
    }
    setState(
      () => preview = document!.preview(ref.read(profileProvider)!, mapping),
    );
  }

  Future<void> _import() async {
    if (preview == null || preview!.valid.isEmpty) return;
    if (preview!.errors.isNotEmpty &&
        !await confirm(
          context,
          'Import only valid rows?',
          '${preview!.valid.length} rows will be imported; ${preview!.errors.length} invalid rows will be skipped. No existing data is overwritten.',
          confirmLabel: 'Import valid rows',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    final saved = await runSafe(
      context,
      () => ref.read(appProvider.notifier).importTransactions(preview!.valid),
      success: '${preview!.valid.length} transactions imported on your device',
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (saved) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => FeaturePage(
    title: 'Bring your history along',
    subtitle:
        'CSV import · profile: ${ref.watch(profileProvider)!.profile.name}',
    child: ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        const Text(
          'Import income and expenses. Dates use ISO format; amounts are positive decimal numbers in the account’s currency. Existing account/category names must match. Missing optional account/category columns use the first matching record. Transfers and receipt images are restored only through JSON/ZIP.',
          style: TextStyle(height: 1.6),
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: _pick,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(
            document == null ? 'Choose CSV file' : 'Change $filename',
          ),
        ),
        if (document != null) ...[
          const SizedBox(height: 20),
          SectionHeader(
            '1 · Match your columns (${document!.rows.length} rows)',
          ),
          for (final key in columns)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: formSelect(
                '$key${['date', 'type', 'name', 'amount'].contains(key) ? ' *' : ' (optional)'}',
                '${mapping[key] ?? -1}',
                ['-1', for (var i = 0; i < document!.headers.length; i++) '$i'],
                (value) => setState(() {
                  final index = int.parse(value);
                  if (index == -1) {
                    mapping.remove(key);
                  } else {
                    mapping[key] = index;
                  }
                  preview = null;
                }),
                display: (value) => value == '-1'
                    ? 'Not mapped'
                    : '${int.parse(value) + 1}: ${document!.headers[int.parse(value)]}',
              ),
            ),
          FilledButton(
            onPressed: _validate,
            child: const Text('Validate & preview'),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 24),
          const SectionHeader('2 · A quick check before importing'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${preview!.valid.length} valid\n${preview!.duplicates} duplicate IDs / identical CSV fingerprints skipped\n${preview!.errors.length} invalid\n\nAll valid rows are committed together; a failed import never partially changes balances.',
                style: const TextStyle(height: 1.7),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final error in preview!.errors.take(100))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          if (preview!.errors.length > 100)
            const Text(
              'Showing the first 100 errors. Fix the file and choose it again.',
            ),
          for (final entry in preview!.valid.take(8))
            ListTile(
              title: Text(entry.name),
              subtitle: Text(
                '${entry.date.toIso8601String().substring(0, 10)} · ${entry.type}',
              ),
              trailing: AmountText(
                entry.amountMinor,
                currency: ref
                    .read(profileProvider)!
                    .accounts
                    .firstWhere((account) => account.id == entry.accountId)
                    .currency,
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy || preview!.valid.isEmpty ? null : _import,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              busy
                  ? 'Importing…'
                  : 'Import ${preview!.valid.length} valid rows',
            ),
          ),
        ],
      ],
    ),
  );
}
