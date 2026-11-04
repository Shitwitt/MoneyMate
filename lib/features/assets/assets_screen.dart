import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    return FeaturePage(title: 'The things you’re building', actions: [IconButton(tooltip: 'Add asset', onPressed: () => editAsset(context, ref), icon: const Icon(Icons.add_rounded))], child: ListView(padding: const EdgeInsets.only(bottom: 110), children: [StatCard(title: 'Total assets', value: AmountText(ledger.assetsTotal), icon: Icons.landscape_rounded, caption: 'Included in net worth · values you update manually'), const SizedBox(height: 22), if (ledger.data.assets.isEmpty) EmptyState(title: 'There’s more to wealth than a balance', message: 'Track investments, gold, your home, or anything with value.', icon: Icons.landscape_outlined, action: 'Add an asset', onAction: () => editAsset(context, ref)), for (final asset in ledger.data.assets) Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(child: ListTile(contentPadding: const EdgeInsets.all(18), leading: ColorIcon(asset.icon, asset.color), title: Text(asset.name), subtitle: Text(titleCase(asset.type)), trailing: AmountText(asset.valueMinor, style: Theme.of(context).textTheme.titleMedium), onTap: () => openPage(context, AssetDetailScreen(asset.id)))))]));
  }
}
int parseAssetValue(String text, String currency) {
  final value = num.tryParse(text.replaceAll(',', ''));
  if (value == null || !value.isFinite || value < 0) throw const FormatException('Enter a nonnegative value');
  return toMinor(value, currency);
}
Future<void> editAsset(BuildContext context, WidgetRef ref, [Asset? initial]) async {
  final currency = ref.read(profileProvider)!.profile.currency;
  final name = TextEditingController(text: initial?.name ?? ''), value = TextEditingController(text: initial == null ? '' : fromMinor(initial.valueMinor, currency).toString()), purchase = TextEditingController(text: fromMinor(initial?.purchaseMinor ?? 0, currency).toString()), notes = TextEditingController(text: initial?.notes ?? '');
  var type = initial?.type ?? 'other', icon = initial?.icon ?? 'asset'; var color = initial?.color ?? palette[5]; var date = initial?.purchaseDate ?? DateTime.now();
  await showEditor(context, title: initial == null ? 'Add something valuable' : 'Edit asset', description: 'Values are manual, not live quotes. Avoid double-counting assets already tracked in an investment account; exclude that account from net worth.', fields: (context, setLocal) => [formText(name, 'Name', required: true), formSelect('Asset type', type, assetTypes, (value) => setLocal(() => type = value)), formText(value, 'Current value ($currency)', required: true, numeric: true), formText(purchase, 'Purchase cost (optional)', numeric: true), formDate(context, 'Purchase date', date, (value) => setLocal(() => date = value)), formText(notes, 'Notes', lines: 3), formColors(color, (value) => setLocal(() => color = value)), ExpansionTile(title: const Text('Choose an icon'), children: [formIcons(icon, (value) => setLocal(() => icon = value))])], onSave: () async {
    final amount = parseAssetValue(value.text, currency);
    await ref.read(appProvider.notifier).upsertAsset(Asset(id: initial?.id ?? uuid.v4(), name: name.text.trim(), valueMinor: amount, type: type, purchaseMinor: parseAssetValue(purchase.text.isEmpty ? '0' : purchase.text, currency), purchaseDate: date, notes: notes.text.trim(), icon: icon, color: color, history: [...?initial?.history, if (initial == null || initial.valueMinor != amount) MoneyEvent(id: uuid.v4(), amountMinor: amount, date: DateTime.now(), note: initial == null ? 'Initial value' : 'Edited value')]));
  });
  for (final controller in [name, value, purchase, notes]) { controller.dispose(); }
}
class AssetDetailScreen extends ConsumerWidget {
  final String id;
  const AssetDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final asset = ledger.data.assets.where((item) => item.id == id).firstOrNull;
    if (asset == null) return const Scaffold(body: EmptyState(title: 'Asset removed', message: 'Your account balances are unchanged.'));
    return FeaturePage(title: asset.name, actions: [IconButton(tooltip: 'Edit asset', onPressed: () => editAsset(context, ref, asset), icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: 'Delete asset', onPressed: () async { if (await confirm(context, 'Delete asset?', 'The asset and its value history will be removed.') && context.mounted) { final done = await runSafe(context, () => ref.read(appProvider.notifier).deleteAsset(id)); if (done && context.mounted) Navigator.pop(context); } }, icon: const Icon(Icons.delete_outline_rounded))], child: ListView(children: [StatCard(title: 'Current value', value: AmountText(asset.valueMinor), icon: iconFor(asset.icon), caption: titleCase(asset.type)), const SizedBox(height: 14), if (asset.purchaseMinor > 0) StatCard(title: 'Change since purchase', value: AmountText(asset.valueMinor - asset.purchaseMinor), icon: Icons.trending_up_rounded, caption: '${((asset.valueMinor - asset.purchaseMinor) / asset.purchaseMinor * 100).toStringAsFixed(1)}% · unrealized'), if (asset.notes.isNotEmpty) Padding(padding: const EdgeInsets.all(18), child: Text(asset.notes)), const SizedBox(height: 18), FilledButton.icon(onPressed: () async { final amount = TextEditingController(text: fromMinor(asset.valueMinor, ledger.currency).toString()), note = TextEditingController(); await showEditor(context, title: 'Update its value', fields: (_, __) => [formText(amount, 'New value (${ledger.currency})', required: true, numeric: true), formText(note, 'What changed?')], onSave: () => ref.read(appProvider.notifier).valueAsset(id, parseAssetValue(amount.text, ledger.currency), note.text.trim())); amount.dispose(); note.dispose(); }, icon: const Icon(Icons.refresh_rounded), label: const Text('Update value')), const SizedBox(height: 18), const SectionHeader('Value history'), for (final event in asset.history.reversed) ListTile(leading: const Icon(Icons.show_chart_rounded), title: AmountText(event.amountMinor), subtitle: Text('${DateFormat.yMMMd().format(event.date)}${event.note.isEmpty ? '' : ' · ${event.note}'}')), const SizedBox(height: 100)]));
  }
}
