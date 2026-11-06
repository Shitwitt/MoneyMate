import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/widgets.dart';
import 'receipt_viewer.dart';
import 'transaction_form.dart';

class TransactionTile extends ConsumerWidget {
  final MoneyTransaction entry;
  final bool selected, selecting;
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
    final category = ledger.category(entry.categoryId),
        account = ledger.account(entry.accountId);
    final transfer = entry.type == 'transfer', now = DateTime.now();
    final future = entry.date.isAfter(now),
        color = AppColors.semantic(context, entry.type);
    final budget = ledger.data.budgets
        .where((b) => b.id == entry.budgetId)
        .firstOrNull;
    final loan = ledger.data.loans
        .where((l) => l.id == entry.loanId)
        .firstOrNull;
    final entities = ledger.data.entities
        .where(
          (e) =>
              entry.labelIds.contains(e.id) ||
              entry.personIds.contains(e.id) ||
              entry.placeId == e.id,
        )
        .toList();
    final day = dayOnly(entry.date), today = dayOnly(now);
    final date = day == today
        ? 'Today'
        : day == nextDay(today)
        ? 'Tomorrow'
        : DateFormat.MMMd(ledger.settings.locale).format(entry.date);
    Widget amounts() => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AmountText(
          entry.amountMinor,
          currency: account.currency,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: color,
          ),
        ),
        if (transfer || account.currency != ledger.currency) ...[
          const SizedBox(height: 3),
          AmountText(
            transfer ? entry.toAmountMinor : ledger.entryValue(entry),
            currency: transfer
                ? ledger.account(entry.toAccountId).currency
                : ledger.currency,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ],
    );
    final metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${DateFormat.jm(ledger.settings.locale).format(entry.date)} · $date · ${account.name}${transfer ? ' → ${ledger.account(entry.toAccountId).name}' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
        ),
        if (budget != null ||
            loan != null ||
            entities.isNotEmpty ||
            future) ...[
          const SizedBox(height: 5),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (budget != null)
                TransactionMetadataTag(
                  budget.name,
                  Color(budget.color),
                  Icons.savings_outlined,
                ),
              if (loan != null)
                TransactionMetadataTag(
                  loan.personName,
                  const Color(0xffD995A4),
                  Icons.handshake_outlined,
                ),
              for (final entity in entities)
                TransactionMetadataTag(
                  entity.name,
                  Color(entity.color),
                  entity.kind == 'person'
                      ? Icons.person_outline_rounded
                      : entity.kind == 'place'
                      ? Icons.place_outlined
                      : Icons.label_outline_rounded,
                ),
              if (future)
                const TransactionMetadataTag(
                  'Scheduled',
                  Color(0xffB7C9E5),
                  Icons.schedule_rounded,
                ),
            ],
          ),
        ],
      ],
    );
    return Semantics(
      label:
          '${transfer
              ? 'Transfer'
              : entry.type == 'income'
              ? 'Income'
              : 'Expense'}${future ? ', scheduled' : ''}',
      child: AnimatedContainer(
        duration: referenceMotion(context, 160),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: selecting
              ? onSelect
              : () => openPage(context, TransactionForm(initial: entry)),
          onLongPress: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: LayoutBuilder(
              builder: (context, box) {
                final large =
                    MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                    box.maxWidth < 310;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selecting)
                      SizedBox(
                        width: 40,
                        height: 48,
                        child: Checkbox(
                          value: selected,
                          onChanged: (_) => onSelect?.call(),
                        ),
                      )
                    else
                      ColorIcon(
                        transfer ? 'transfer' : category?.icon ?? 'category',
                        transfer ? 0xffAFA09A : category?.color ?? 0xffffb59a,
                        size: 46,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          metadata,
                          if (large) ...[
                            const SizedBox(height: 9),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: amounts(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!large) ...[
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: box.maxWidth * .31,
                        ),
                        child: amounts(),
                      ),
                    ],
                    if (entry.receipts.isNotEmpty)
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'View receipt',
                          onPressed: () =>
                              openPage(context, ReceiptViewer(entry.receipts)),
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionMetadataTag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const TransactionMetadataTag(this.label, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: AppColors.dark(context) ? .2 : .12),
      border: Border.all(color: color.withValues(alpha: .3)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(icon, size: 11, color: readableTint(context, color)),
          ),
          const TextSpan(text: ' '),
          TextSpan(text: label),
        ],
      ),
      style: TextStyle(
        fontSize: 10,
        height: 1.2,
        color: readableTint(context, color),
      ),
    ),
  );
}
