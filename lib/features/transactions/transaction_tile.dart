import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../shared/widgets.dart';
import 'receipt_viewer.dart';
import 'transaction_form.dart';

class TransactionTile extends ConsumerWidget {
  final MoneyTransaction entry;
  final bool selected;
  final bool selecting;
  final VoidCallback? onSelect;
  const TransactionTile(
    this.entry, {
    super.key,
    this.selected = false,
    this.selecting = false,
    this.onSelect,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final category = ledger.category(entry.categoryId);
    final account = ledger.account(entry.accountId);
    final transfer = entry.type == 'transfer';
    final labels = ledger.data.entities
        .where((item) => entry.labelIds.contains(item.id))
        .take(2)
        .map((item) => item.name)
        .join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      selected: selected,
      leading: selecting
          ? Checkbox(value: selected, onChanged: (_) => onSelect?.call())
          : ColorIcon(
              transfer ? 'transfer' : category?.icon ?? 'category',
              transfer ? 0xff88bacc : category?.color ?? 0xffb9b7aa,
              size: 44,
            ),
      title: Text(
        entry.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${transfer ? '${account.name} → ${ledger.account(entry.toAccountId).name}' : '${category?.name ?? 'Other'} · ${account.name}'}${labels.isEmpty ? '' : '\n$labels'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.receipts.isNotEmpty)
            IconButton(
              tooltip: '${entry.receipts.length} receipt photos',
              visualDensity: VisualDensity.compact,
              onPressed: () => openPage(context, ReceiptViewer(entry.receipts)),
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                entry.amountMinor,
                currency: account.currency,
                prefix: transfer
                    ? '↔ '
                    : entry.type == 'income'
                    ? '+ '
                    : '− ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: entry.type == 'income'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                DateFormat.jm().format(entry.date),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: selecting
          ? onSelect
          : () => openPage(context, TransactionForm(initial: entry)),
      onLongPress: onSelect,
    );
  }
}
