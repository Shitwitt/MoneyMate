import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

class ExchangeRatesScreen extends ConsumerWidget {
  const ExchangeRatesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider)!;
    return FeaturePage(title: 'Rates, on your terms', subtitle: 'Offline reference rates · units per 1 USD', actions: [IconButton(tooltip: 'About refreshing rates', onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('No background rate requests'), content: const Text('These are illustrative offline rates, not live market quotes. To refresh, look up a rate in a source you trust, then tap a currency to enter it manually. The timestamp updates only when you save. Existing transfers keep their recorded receiving amounts.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))])), icon: const Icon(Icons.info_outline_rounded))], child: ListView.builder(padding: const EdgeInsets.only(bottom: 100), itemCount: profile.rates.length, itemBuilder: (context, index) { final rate = profile.rates[index]; return Card(child: ListTile(leading: CircleAvatar(child: Text(currencySymbols[rate.code] ?? rate.code, style: const TextStyle(fontSize: 16))), title: Text(rate.code), subtitle: Text('${rate.perUsd} per USD · ${DateFormat.yMMMd().format(rate.updatedAt)}'), trailing: rate.code == 'USD' ? const Icon(Icons.lock_outline_rounded, size: 18) : const Icon(Icons.edit_outlined, size: 18), onTap: rate.code == 'USD' ? null : () async { final value = await askText(context, 'Update ${rate.code}', label: '1 USD = ? ${rate.code}', initial: rate.perUsd.toString(), numeric: true); if (value == null || !context.mounted) return; await runSafe(context, () async { final number = double.tryParse(value); if (number == null || !number.isFinite || number <= 0 || number > 1000000000) throw const FormatException('Enter a positive exchange rate'); await ref.read(appProvider.notifier).setRate(ExchangeRate(code: rate.code, perUsd: number, updatedAt: DateTime.now())); }, success: 'Reference rate updated. Reports use this rate; transfers remain unchanged.'); })); }));
  }
}
