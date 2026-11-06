import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/catalog_insights.dart';
import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/widgets.dart';
import '../transactions/grouped_transactions.dart';
import '../transactions/transaction_form.dart';
import 'catalog_screen.dart';

String contextTitle(String kind) => kind == 'person' ? 'People' : 'Places';
Future<void> showContextHelp(
  BuildContext context,
  String kind,
) => showHowItWorks(
  context,
  title: 'How ${contextTitle(kind)} Work',
  introduction: kind == 'person'
      ? 'People link local names to income and expenses. No contacts are uploaded or payment requests sent.'
      : 'Places tag where you spend and earn. No GPS tracking or location service is used.',
  sections: [
    (
      kind == 'person' ? Icons.person_add_alt : Icons.add_location_alt_outlined,
      kind == 'person' ? 'Linking' : 'Location Tagging',
      kind == 'person'
          ? 'Choose one or several people on a transaction. A person can also be linked to a loan, without turning ordinary tagged records into repayments.'
          : 'Choose a place on a transaction, or add an address/note for your own reference.',
    ),
    (
      Icons.insights_outlined,
      'Insights',
      'Tap a name for signed net, income, expense, counts and grouped history. Transfers count as records but contribute zero to net. Saved schedules are included in book totals; overlapping people must not be summed as a consolidated total.',
    ),
    (
      Icons.sort,
      'Organization',
      'Switch list/grid, choose financial-month or overall totals and sort by name, amount or record count. Edit icons, colors and names. Deleting a tag removes only its links, never the transactions.',
    ),
  ],
);

class ContextScreen extends ConsumerStatefulWidget {
  final String kind;
  const ContextScreen(this.kind, {super.key});
  @override
  ConsumerState<ContextScreen> createState() => _ContextScreenState();
}

class _ContextScreenState extends ConsumerState<ContextScreen> {
  int scope = 0;
  bool grid = false;
  String sort = 'name';
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!, kind = widget.kind;
    final window = financialMonth(DateTime.now(), ledger.settings.monthStart);
    List<MoneyTransaction> records(NamedEntity e) => ledger.data.transactions
        .where(
          (t) => entityMatches(e, t) && (scope == 1 || window.contains(t.date)),
        )
        .toList();
    final entities = ledger.data.entities.where((e) => e.kind == kind).toList()
      ..sort(
        (a, b) => switch (sort) {
          'amount' => transactionNet(
            ledger,
            records(b),
          ).compareTo(transactionNet(ledger, records(a))),
          'count' => records(b).length.compareTo(records(a).length),
          _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        },
      );
    return FeaturePage(
      title: contextTitle(kind),
      subtitle: '${entities.length} ${contextTitle(kind).toLowerCase()}',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort ${contextTitle(kind).toLowerCase()}',
          initialValue: sort,
          onSelected: (v) => setState(() => sort = v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'name', child: Text('Name')),
            PopupMenuItem(value: 'amount', child: Text('Net amount')),
            PopupMenuItem(value: 'count', child: Text('Transaction count')),
          ],
        ),
        IconButton(
          tooltip: grid ? 'Show $kind list' : 'Show $kind grid',
          onPressed: () => setState(() => grid = !grid),
          icon: Icon(grid ? Icons.view_list_outlined : Icons.grid_view_rounded),
        ),
        IconButton(
          tooltip: 'How ${contextTitle(kind)} Work',
          onPressed: () => showContextHelp(context, kind),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      fab: FloatingActionButton(
        tooltip: 'Add $kind',
        onPressed: () => editCatalogEntity(context, ref, kind),
        child: Icon(
          kind == 'person'
              ? Icons.person_add_alt
              : Icons.add_location_alt_outlined,
        ),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: const ['This month', 'Overall'],
          selected: scope,
          onSelected: (v) => setState(() => scope = v),
        ),
      ),
      child: entities.isEmpty
          ? EmptyState(
              title: kind == 'person'
                  ? 'People, not payment accounts'
                  : 'Where your story happens',
              message:
                  'Add local names, icons and notes. No tracking or bank connection.',
              action: 'Add $kind',
              onAction: () => editCatalogEntity(context, ref, kind),
            )
          : LayoutBuilder(
              builder: (context, box) {
                final columns =
                    grid &&
                        box.maxWidth >= 330 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.4
                    ? 2
                    : 1;
                Widget tile(NamedEntity e) {
                  final entries = records(e),
                      net = transactionNet(ledger, entries);
                  final value = AmountText(
                    net,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.semantic(
                        context,
                        net < 0 ? 'expense' : 'income',
                      ),
                    ),
                  );
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('${entries.length} transactions'),
                      if (e.notes.isNotEmpty)
                        Text(
                          e.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  );
                  final compact =
                      columns == 1 &&
                      box.maxWidth >= 330 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.4;
                  return InkWell(
                    onTap: () => openPage(context, ContextDetailScreen(e.id)),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: compact
                          ? Row(
                              children: [
                                ContextIcon(e),
                                const SizedBox(width: 12),
                                Expanded(child: text),
                                const SizedBox(width: 12),
                                Flexible(child: value),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ContextIcon(e),
                                const SizedBox(height: 12),
                                text,
                                const SizedBox(height: 12),
                                value,
                              ],
                            ),
                    ),
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
                                for (var i = 0; i < entities.length; i++) ...[
                                  if (i > 0) const Divider(height: 1),
                                  tile(entities[i]),
                                ],
                              ],
                            ),
                          )
                        : Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final e in entities)
                                SizedBox(
                                  width: (box.maxWidth - 12) / 2,
                                  child: TonalCard(
                                    padding: EdgeInsets.zero,
                                    child: tile(e),
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

class ContextIcon extends StatelessWidget {
  final NamedEntity entity;
  const ContextIcon(this.entity, {super.key});
  @override
  Widget build(BuildContext context) => entity.photoBase64.isEmpty
      ? ColorIcon(entity.icon.isEmpty ? entity.kind : entity.icon, entity.color)
      : ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            base64Decode(entity.photoBase64),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColorIcon(entity.kind, entity.color),
          ),
        );
}

class ContextDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ContextDetailScreen(this.id, {super.key});
  @override
  ConsumerState<ContextDetailScreen> createState() =>
      _ContextDetailScreenState();
}

class _ContextDetailScreenState extends ConsumerState<ContextDetailScreen> {
  int period = 0, type = 0;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final entity = ledger.data.entities
        .where((e) => e.id == widget.id)
        .firstOrNull;
    if (entity == null)
      return const FeaturePage(
        title: 'Tag removed',
        child: EmptyState(
          title: 'Your records are safe',
          message: 'Only the local tag was removed.',
        ),
      );
    final all = ledger.data.transactions
        .where((e) => entityMatches(entity, e))
        .toList();
    final income = all.where((e) => e.type == 'income').toList(),
        expense = all.where((e) => e.type == 'expense').toList();
    int sum(List<MoneyTransaction> entries) =>
        entries.fold<int>(0, (s, e) => s + ledger.entryValue(e));
    return FeaturePage(
      title: entity.name,
      actions: [
        IconButton(
          tooltip: 'Add ${entity.kind} transaction',
          onPressed: () => openPage(
            context,
            TransactionForm(
              initialPersonIds: entity.kind == 'person'
                  ? [entity.id]
                  : const [],
              initialPlaceId: entity.kind == 'place' ? entity.id : '',
            ),
          ),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Delete ${entity.kind}',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final route = ModalRoute.of(context);
            if (await confirm(
                  context,
                  'Delete ${entity.name}?',
                  'Its tags are removed, not the transactions.',
                ) &&
                context.mounted) {
              final saved = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteEntity(entity.id),
              );
              if (saved && context.mounted && route != null && route.isActive) {
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
        tooltip: 'Edit ${entity.kind}',
        onPressed: () => editCatalogEntity(context, ref, entity.kind, entity),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: transactionPeriods,
          selected: period,
          onSelected: (v) => setState(() => period = v),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ContextIcon(entity),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entity.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Book net · income minus expense'),
                AmountText(
                  transactionNet(ledger, all),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text('${all.length} transactions · saved schedules included'),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text('All · ${all.length}'),
                      selected: type == 0,
                      onSelected: (_) => setState(() => type = 0),
                    ),
                    FilterChip(
                      label: Text('Income · ${income.length}'),
                      selected: type == 1,
                      onSelected: (_) => setState(() => type = 1),
                    ),
                    FilterChip(
                      label: Text('Expense · ${expense.length}'),
                      selected: type == 2,
                      onSelected: (_) => setState(() => type = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SummaryColumns(
                  labels: const ['Income', 'Expense'],
                  values: [AmountText(sum(income)), AmountText(sum(expense))],
                ),
                if (entity.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(entity.notes),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GroupedTransactions(
            type == 1
                ? income
                : type == 2
                ? expense
                : all,
            period: period,
          ),
        ],
      ),
    );
  }
}
