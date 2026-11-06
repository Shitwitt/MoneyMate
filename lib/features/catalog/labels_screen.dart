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
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final label in labels)
                        SizedBox(
                          width: (box.maxWidth - (columns - 1) * 12) / columns,
                          child: Builder(
                            builder: (context) {
                              final entries = ledger.data.transactions
                                  .where(
                                    (e) =>
                                        e.labelIds.contains(label.id) &&
                                        (scope == 1 || window.contains(e.date)),
                                  )
                                  .toList();
                              final content = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${entries.length} transactions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 10),
                                  AmountText(
                                    labelNet(ledger, entries),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: readableTint(
                                        context,
                                        Color(label.color),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                              return TonalCard(
                                onTap: () => openPage(
                                  context,
                                  LabelDetailScreen(label.id),
                                ),
                                child: columns == 1
                                    ? Row(
                                        children: [
                                          ColorIcon(
                                            label.icon.isEmpty
                                                ? 'label'
                                                : label.icon,
                                            label.color,
                                            size: 48,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(child: content),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ColorIcon(
                                            label.icon.isEmpty
                                                ? 'label'
                                                : label.icon,
                                            label.color,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 16),
                                          content,
                                        ],
                                      ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 100, width: double.infinity),
                    ],
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
          const Text('Total'),
          const SizedBox(height: 10),
          AmountText(
            labelNet(ledger, entries),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text('${entries.length} transactions'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final kind in ['income', 'expense'])
                ActionChip(
                  avatar: Icon(
                    kind == 'income' ? Icons.south_west : Icons.north_east,
                  ),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${kind == 'income' ? 'Income' : 'Expense'} · ${entries.where((e) => e.type == kind).length}',
                      ),
                      AmountText(
                        entries
                            .where((e) => e.type == kind)
                            .fold<int>(0, (s, e) => s + ledger.entryValue(e)),
                      ),
                    ],
                  ),
                  backgroundColor: type == kind
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  onPressed: () =>
                      setState(() => type = type == kind ? 'all' : kind),
                ),
            ],
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
