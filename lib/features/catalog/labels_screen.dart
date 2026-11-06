import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/data/ledger.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/widgets.dart';
import '../transactions/grouped_transactions.dart';
import '../transactions/transaction_form.dart';
import 'catalog_screen.dart';

Future<void> showLabelsHelp(BuildContext context) => showHowItWorks(
  context,
  title: 'How Labels Work',
  introduction: 'Labels add context to your transactions and help you organize your money.',
  sections: const [
    (
      Icons.label_outline,
      'Tagging',
      'Add one or more labels to a transaction. The same record can belong to several labels; this never duplicates it in your accounts.',
    ),
    (
      Icons.filter_list,
      'Filtering',
      'Tap a label to see its records, income, expenses and signed net total. This month follows your financial month setting. Book totals include scheduled records; transfers are shown but do not change income, expense or net.',
    ),
    (
      Icons.palette_outlined,
      'Organization',
      'Customize names, icons and colors. Delete a label without deleting its transactions. Totals across different labels can overlap because tagging is many-to-many.',
    ),
  ],
);
int labelNet(Ledger ledger, Iterable<MoneyTransaction> entries) =>
    entries.fold<int>(
      0,
      (sum, e) =>
          sum +
          (e.type == 'income'
              ? ledger.entryValue(e)
              : e.type == 'expense'
              ? -ledger.entryValue(e)
              : 0),
    );

class LabelsScreen extends ConsumerStatefulWidget {
  const LabelsScreen({super.key});
  @override
  ConsumerState<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends ConsumerState<LabelsScreen> {
  bool grid = false;
  int scope = 0;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final labels = ledger.data.entities.where((e) => e.kind == 'label').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final window = financialMonth(DateTime.now(), ledger.settings.monthStart);
    return FeaturePage(
      title: 'Labels',
      subtitle: '${labels.length} labels',
      actions: [
        IconButton(
          tooltip: grid ? 'Show label list' : 'Show label grid',
          onPressed: () => setState(() => grid = !grid),
          icon: Icon(grid ? Icons.view_list_outlined : Icons.grid_view_rounded),
        ),
        IconButton(
          tooltip: 'How Labels Work',
          onPressed: () => showLabelsHelp(context),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      fab: FloatingActionButton(
        tooltip: 'Add label',
        onPressed: () => editCatalogEntity(context, ref, 'label'),
        child: const Icon(Icons.add),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: const ['This month', 'Overall'],
          selected: scope,
          onSelected: (n) => setState(() => scope = n),
        ),
      ),
      child: labels.isEmpty
          ? EmptyState(
              title: 'Make it yours',
              message: 'Tag transactions with useful names and colors.',
              icon: Icons.label_outline,
              action: 'Add label',
              onAction: () => editCatalogEntity(context, ref, 'label'),
            )
          : LayoutBuilder(
              builder: (context, box) {
                final columns =
                    grid &&
                        box.maxWidth >= 330 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.4
                    ? 2
                    : 1;
                Widget item(NamedEntity label) {
                  final entries = ledger.data.transactions
                      .where(
                        (e) =>
                            e.labelIds.contains(label.id) &&
                            (scope == 1 || window.contains(e.date)),
                      )
                      .toList();
                  return _LabelRow(
                    label: label,
                    count: entries.length,
                    net: labelNet(ledger, entries),
                    grid: columns > 1,
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: columns == 1
                        ? TonalCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (var i = 0; i < labels.length; i++) ...[
                                  if (i > 0) const Divider(height: 1),
                                  item(labels[i]),
                                ],
                              ],
                            ),
                          )
                        : Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final label in labels)
                                SizedBox(
                                  width: (box.maxWidth - 12) / 2,
                                  child: TonalCard(
                                    padding: EdgeInsets.zero,
                                    child: item(label),
                                  ),
                                ),
                            ],
                          ),
                  ),
                );
              },
            ),
    );
  }
}

class LabelDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const LabelDetailScreen(this.id, {super.key});
  @override
  ConsumerState<LabelDetailScreen> createState() => _LabelDetailScreenState();
}

class _LabelDetailScreenState extends ConsumerState<LabelDetailScreen> {
  int period = 0;
  String type = 'all';
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final label = ledger.data.entities
        .where((e) => e.id == widget.id && e.kind == 'label')
        .firstOrNull;
    if (label == null)
      return const FeaturePage(
        title: 'Label removed',
        child: EmptyState(
          title: 'Transactions are safe',
          message: 'Only their label was removed.',
        ),
      );
    final entries = ledger.data.transactions
        .where((e) => e.labelIds.contains(label.id))
        .toList();
    final income = entries
        .where((e) => e.type == 'income')
        .fold<int>(0, (s, e) => s + ledger.entryValue(e));
    final expense = entries
        .where((e) => e.type == 'expense')
        .fold<int>(0, (s, e) => s + ledger.entryValue(e));
    return FeaturePage(
      title: label.name,
      actions: [
        IconButton(
          tooltip: 'Add labeled transaction',
          onPressed: () =>
              openPage(context, TransactionForm(initialLabelIds: [label.id])),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Delete label',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final route = ModalRoute.of(context);
            if (await confirm(
                  context,
                  'Delete ${label.name}?',
                  'Only the tag will be removed. Transactions and other labels stay unchanged.',
                ) &&
                context.mounted) {
              final done = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteEntity(label.id),
              );
              if (done && context.mounted && route != null && route.isActive) {
                if (route.isCurrent) {
                  Navigator.pop(context);
                } else {
                  Navigator.of(context).removeRoute(route);
                }
              }
            }
          },
        ),
      ],
      fab: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tooltip: 'Edit label',
        onPressed: () => editCatalogEntity(context, ref, 'label', label),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: transactionPeriods,
          selected: period,
          onSelected: (n) => setState(() => period = n),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          TonalCard(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Total'),
                const SizedBox(height: 10),
                AmountText(
                  labelNet(ledger, entries),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text('${entries.length} transactions'),
                const SizedBox(height: 20),
                if (ledger.settings.hideAmounts)
                  const Icon(Icons.visibility_off_outlined, size: 16)
                else if (income + expense > 0)
                  Semantics(
                    label: 'Income and expense share. Exact amounts below.',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            if (income > 0)
                              Expanded(
                                flex: income,
                                child: ColoredBox(
                                  color: chartInk(
                                    AppColors.semantic(context, 'income'),
                                    Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            if (expense > 0)
                              Expanded(
                                flex: expense,
                                child: ColoredBox(
                                  color: chartInk(
                                    AppColors.semantic(context, 'expense'),
                                    Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, box) {
                    final columns =
                        box.maxWidth < 260 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.4
                        ? 1
                        : 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final kind in ['income', 'expense'])
                          SizedBox(
                            width:
                                (box.maxWidth - (columns - 1) * 10) / columns,
                            child: Semantics(
                              button: true,
                              selected: type == kind,
                              child: TonalCard(
                                radius: 18,
                                padding: const EdgeInsets.all(12),
                                color: Color.alphaBlend(
                                  AppColors.semantic(
                                    context,
                                    kind,
                                  ).withValues(alpha: type == kind ? .25 : .12),
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                                onTap: () => setState(
                                  () => type = type == kind ? 'all' : kind,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${kind == 'income' ? 'Income' : 'Expense'} · ${entries.where((e) => e.type == kind).length}',
                                      style: TextStyle(
                                        color: readableTint(
                                          context,
                                          AppColors.semantic(context, kind),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AmountText(
                                      kind == 'income' ? income : expense,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: readableTint(
                                          context,
                                          AppColors.semantic(context, kind),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            type == 'all'
                ? 'All tagged records · transfers excluded from net'
                : '$type only · tap summary again to show all',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          GroupedTransactions(
            entries.where((e) => type == 'all' || e.type == type).toList(),
            period: period,
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final NamedEntity label;
  final int count, net;
  final bool grid;
  const _LabelRow({
    required this.label,
    required this.count,
    required this.net,
    required this.grid,
  });
  @override
  Widget build(BuildContext context) {
    final large =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 350;
    final value = AmountText(
      net,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.semantic(context, net < 0 ? 'expense' : 'income'),
      ),
    );
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          '$count transactions',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (large || grid) ...[const SizedBox(height: 10), value],
      ],
    );
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => openPage(context, LabelDetailScreen(label.id)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: grid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ColorIcon(
                    label.icon.isEmpty ? 'label' : label.icon,
                    label.color,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  name,
                ],
              )
            : Row(
                children: [
                  ColorIcon(
                    label.icon.isEmpty ? 'label' : label.icon,
                    label.color,
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: name),
                  if (!large) ...[
                    const SizedBox(width: 10),
                    Flexible(child: value),
                  ],
                ],
              ),
      ),
    );
  }
}
