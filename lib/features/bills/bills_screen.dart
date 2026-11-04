import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(profileProvider)!.bills;
    final positions = <String, int>{}; final names = <String, String>{'me': 'You'};
    for (final bill in bills) {
      names[bill.paidById] = bill.paidByName;
      for (final share in bill.shares.where((share) => !share.settled && share.personId != bill.paidById)) {
        names[share.personId] = share.name;
        positions[share.personId] = (positions[share.personId] ?? 0) - share.amountMinor;
        positions[bill.paidById] = (positions[bill.paidById] ?? 0) + share.amountMinor;
      }
    }
    final creditors = positions.entries.where((entry) => entry.value > 0).map((entry) => MapEntry(entry.key, entry.value)).toList();
    final debtors = positions.entries.where((entry) => entry.value < 0).map((entry) => MapEntry(entry.key, -entry.value)).toList();
    final suggestions = <(String, String, int)>[]; var i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final amount = math.min(debtors[i].value, creditors[j].value);
      suggestions.add((names[debtors[i].key] ?? '', names[creditors[j].key] ?? '', amount));
      debtors[i] = MapEntry(debtors[i].key, debtors[i].value - amount); creditors[j] = MapEntry(creditors[j].key, creditors[j].value - amount);
      if (debtors[i].value == 0) i++; if (creditors[j].value == 0) j++;
    }
    return FeaturePage(title: 'Good times, fair shares', subtitle: 'Bill splitter', actions: [IconButton(tooltip: 'Split a bill', onPressed: () => editBill(context, ref), icon: const Icon(Icons.add_rounded))], child: ListView(padding: const EdgeInsets.only(bottom: 110), children: [if (suggestions.isNotEmpty) ...[const SectionHeader('A simpler way to settle'), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [for (final suggestion in suggestions) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.arrow_forward_rounded), title: Text('${suggestion.$1} → ${suggestion.$2}'), trailing: AmountText(suggestion.$3)), const Text('Suggested net settlements across outstanding bills. Mark individual shares settled after payment.', style: TextStyle(fontSize: 11))]))), const SizedBox(height: 20)], if (bills.isEmpty) EmptyState(title: 'Share the moment. Split the bill.', message: 'Equal, exact, percentages or shares. Fair to the very last cent.', icon: Icons.groups_rounded, action: 'Split a bill', onAction: () => editBill(context, ref)), for (final bill in bills.reversed) Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(child: ListTile(contentPadding: const EdgeInsets.all(18), leading: const ColorIcon('food', 0xffb6a5e8), title: Text(bill.title), subtitle: Text('${bill.shares.length} people · ${bill.shares.where((share) => !share.settled && share.personId != bill.paidById).length} outstanding\n${DateFormat.yMMMd().format(bill.date)}'), isThreeLine: true, trailing: AmountText(bill.totalMinor, style: Theme.of(context).textTheme.titleMedium), onTap: () => openPage(context, BillDetailScreen(bill.id)))))]));
  }
}
Future<void> editBill(BuildContext context, WidgetRef ref, [Bill? initial]) async {
  final profile = ref.read(profileProvider)!;
  final title = TextEditingController(text: initial?.title ?? ''), amount = TextEditingController(text: initial == null ? '' : fromMinor(initial.totalMinor, profile.profile.currency).toString());
  var method = initial?.method ?? 'equally', payer = initial?.paidById ?? 'me'; var date = initial?.date ?? DateTime.now();
  final participants = <String, String>{'me': 'You', for (final person in profile.entities.where((item) => item.kind == 'person')) person.id: person.name, for (final share in initial?.shares ?? <BillShare>[]) share.personId: share.name};
  var selected = initial == null ? <String>{'me'} : initial.shares.map((share) => share.personId).toSet();
  final fields = <String, TextEditingController>{};
  for (final id in participants.keys) { fields[id] = TextEditingController(text: initial == null ? '1' : method == 'exact' ? fromMinor(initial.shares.where((share) => share.personId == id).firstOrNull?.amountMinor ?? 0, profile.profile.currency).toString() : '1'); }
  await showEditor(context, title: initial == null ? 'Make it a fair share' : 'Edit bill', description: 'One person pays the bill. Everyone else owes that person their share. Splits are rounded fairly and always sum exactly to the total.', fields: (context, setLocal) => [formText(title, 'What was the occasion?', required: true), formText(amount, 'Total (${profile.profile.currency})', required: true, numeric: true), formDate(context, 'Date', date, (value) => setLocal(() => date = value)), formChips('Participants (include the payer)', participants, selected, (value) => setLocal(() { selected = value; if (!selected.contains(payer) && selected.isNotEmpty) payer = selected.first; })), OutlinedButton.icon(onPressed: () async { final name = await askText(context, 'Add someone', label: 'Name'); if (name != null) setLocal(() { final id = uuid.v4(); participants[id] = name; fields[id] = TextEditingController(text: '1'); selected.add(id); }); }, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Quick add participant')), if (selected.isNotEmpty) formSelect('Paid by', payer, selected.toList(), (value) => setLocal(() => payer = value), display: (id) => participants[id]!), formSelect('Split method', method, ['equally', 'percentage', 'exact', 'shares'], (value) => setLocal(() { method = value; if (method == 'percentage' && selected.isNotEmpty) { for (final id in selected) { fields[id]!.text = (100 / selected.length).toStringAsFixed(4); } } })), if (method != 'equally') for (final id in selected) formText(fields[id]!, '${participants[id]} · ${method == 'percentage' ? '%' : method == 'exact' ? profile.profile.currency : 'shares'}', required: true, numeric: true)], onSave: () async {
    if (selected.length < 2) throw const FormatException('Add at least two participants');
    final total = toMinor(evaluateAmount(amount.text), profile.profile.currency);
    final ids = selected.toList(); List<int> shares;
    final weights = ids.map((id) => method == 'equally' ? 1.0 : double.tryParse(fields[id]!.text) ?? -1).toList();
    if (weights.any((value) => !value.isFinite || value < 0)) throw const FormatException('Enter valid nonnegative shares');
    if (method == 'exact') {
      shares = weights.map((value) => toMinor(value, profile.profile.currency)).toList();
      if (shares.fold<int>(0, (a, b) => a + b) != total) throw const FormatException('Exact amounts must add up to the bill total');
    } else {
      if (method == 'percentage' && (weights.fold<double>(0, (a, b) => a + b) - 100).abs() > .001) throw const FormatException('Percentages must add up to 100');
      shares = splitWeighted(total, weights);
    }
    final result = [for (var index = 0; index < ids.length; index++) BillShare(personId: ids[index], name: participants[ids[index]]!, amountMinor: shares[index], settled: ids[index] == payer || (initial?.shares.any((share) => share.personId == ids[index] && share.settled && share.amountMinor == shares[index]) ?? false))];
    if (initial != null && initial.shares.any((share) => share.personId != initial.paidById && share.settled) && (total != initial.totalMinor || payer != initial.paidById)) throw const FormatException('Do not change totals or payer after settlement. Create a new adjustment bill instead.');
    await ref.read(appProvider.notifier).upsertBill(Bill(id: initial?.id ?? uuid.v4(), title: title.text.trim(), totalMinor: total, date: date, paidById: payer, paidByName: participants[payer]!, method: method, shares: result));
  });
  title.dispose(); amount.dispose(); for (final field in fields.values) { field.dispose(); }
}
class BillDetailScreen extends ConsumerWidget {
  final String id;
  const BillDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider)!;
    final bill = profile.bills.where((item) => item.id == id).firstOrNull;
    if (bill == null) return const Scaffold(body: EmptyState(title: 'Bill removed', message: 'Any debts already moved to loans are retained.'));
    return FeaturePage(title: bill.title, actions: [IconButton(tooltip: 'Edit bill', onPressed: () => editBill(context, ref, bill), icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: 'Delete bill', onPressed: () async { if (await confirm(context, 'Delete split bill?', 'Loan records created from this bill will be retained.') && context.mounted) { final done = await runSafe(context, () => ref.read(appProvider.notifier).deleteBill(id)); if (done && context.mounted) Navigator.pop(context); } }, icon: const Icon(Icons.delete_outline_rounded))], child: ListView(padding: const EdgeInsets.only(bottom: 100), children: [StatCard(title: 'Paid by ${bill.paidByName}', value: AmountText(bill.totalMinor), icon: Icons.groups_rounded, caption: '${DateFormat.yMMMd().format(bill.date)} · ${bill.method} split'), const SizedBox(height: 24), const SectionHeader('Who owes whom'), for (final share in bill.shares) Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Row(children: [ColorIcon('person', share.settled ? 0xffa4ca6a : 0xffb6a5e8, size: 40), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(share.name, style: const TextStyle(fontWeight: FontWeight.w600)), Text(share.personId == bill.paidById ? 'Own share · already paid' : share.settled ? 'Settled or moved to loan ✓' : 'Owes ${bill.paidByName}', style: Theme.of(context).textTheme.bodySmall)])), AmountText(share.amountMinor)]), if (!share.settled && share.personId != bill.paidById) ...[const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.end, children: [if (bill.paidById == 'me' || share.personId == 'me') TextButton(onPressed: () async { if (await confirm(context, 'Move this share to loans?', 'It will be tracked as a personal debt with a 30-day due date, and marked handled in this bill.', confirmLabel: 'Move to loans') && context.mounted) await runSafe(context, () => ref.read(appProvider.notifier).settleBill(id, share.personId, createLoan: true), success: 'Share moved to loans'); }, child: const Text('Move to loan')), FilledButton.tonal(onPressed: () => runSafe(context, () => ref.read(appProvider.notifier).settleBill(id, share.personId), success: 'Share settled · record any actual bank movement in Activity'), child: const Text('Mark settled'))])]]))))]));
  }
}
