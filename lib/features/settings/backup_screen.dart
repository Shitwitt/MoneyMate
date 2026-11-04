import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/data/providers.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/file_service.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import 'csv_import_screen.dart';

Future<bool> restoreBackup(
  BuildContext context,
  Future<void> Function(BackupPreview) restore,
) async {
  var restored = false;
  await runSafe(context, () async {
    final file = await FileService.pick(['json', 'zip']);
    if (file == null) return;
    final preview = BackupService.inspect(file.bytes, file.name);
    if (!context.mounted) return;
    final approved = await confirm(
      context,
      'Restore this backup?',
      'Created ${DateFormat.yMMMd().add_jm().format(preview.createdAt.toLocal())}\n\n${preview.data.profiles.length} profiles\n${preview.transactions} transactions\n${preview.receipts} receipt photos\n\nThis REPLACES ALL current profiles, not just the active one. Export a backup of current data first. Your current app lock is retained; automation and notifications are turned off for review.',
      confirmLabel: 'Replace & restore',
    );
    if (!approved) return;
    await restore(preview);
    restored = true;
    if (context.mounted) {
      toast(
        context,
        'Backup restored. Review your currency rates and notification preferences.',
      );
    }
  });
  return restored;
}

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});
  Future<void> _export(BuildContext context, WidgetRef ref, bool zip) async {
    await runSafe(
      context,
      () async {
        final bytes = BackupService.export(ref.read(appProvider), zip: zip);
        await FileService.save(
          bytes,
          'PaisaClone-${DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now())}.${zip ? 'zip' : 'json'}',
          mime: zip ? 'application/zip' : 'application/json',
        );
        await ref
            .read(appProvider.notifier)
            .settings((s) => s.copyWith(lastBackup: DateTime.now()));
      },
      success:
          'Export opened. Keep the saved file somewhere private and verify it before resetting this app.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    return FeaturePage(
      title: 'Your data, in your hands',
      child: ListView(
        children: [
          Card(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: .65),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.backup_outlined, size: 32),
                  SizedBox(height: 16),
                  Text(
                    'A backup is a little peace of mind.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Export every profile, setting, and receipt. No account or server needed. Files contain full amounts even when “Hide amounts” is enabled. They are not encrypted; share them carefully.',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Keep a copy'),
          FilledButton.icon(
            onPressed: () => _export(context, ref, true),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Export full ZIP backup'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _export(context, ref, false),
            icon: const Icon(Icons.data_object_rounded),
            label: const Text('Export readable JSON'),
          ),
          const SizedBox(height: 14),
          Text(
            settings.lastBackup == null
                ? 'No export yet. A good day to start.'
                : 'Last export opened: ${DateFormat.yMMMd().add_jm().format(settings.lastBackup!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          const SectionHeader('Bring your data home'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore_rounded),
              title: const Text('Restore JSON / ZIP'),
              subtitle: const Text('Validate & preview before replacing data'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => restoreBackup(
                context,
                (preview) =>
                    ref.read(appProvider.notifier).restore(preview.data),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Import transactions from CSV'),
              subtitle: const Text(
                'Map columns, validate rows, preview, then import',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => openPage(context, const CsvImportScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download CSV template'),
              subtitle: const Text('Edit account names to match your own'),
              onTap: () => runSafe(context, () async {
                final template = await rootBundle.load(
                  'assets/templates/transactions.csv',
                );
                await FileService.save(
                  template.buffer.asUint8List(),
                  'PaisaClone-import-template.csv',
                  mime: 'text/csv',
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('A gentle reminder'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Weekly backup reminder'),
            subtitle: const Text(
              'Uses local notifications; enable their master switch too',
            ),
            value: settings.backupReminders,
            onChanged: (value) => runSafe(
              context,
              () => ref
                  .read(appProvider.notifier)
                  .settings((s) => s.copyWith(backupReminders: value)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Optional cloud storage: use your device’s share/save sheet to put an export in Google Drive, iCloud Drive, or another provider you choose. PaisaClone has no cloud SDK and never uploads anything automatically.\n\nWeb: data belongs to this browser and origin. Private browsing, clearing site data, or changing hosts can erase it. Download backups regularly.',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
