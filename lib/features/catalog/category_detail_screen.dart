import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/catalog_insights.dart';
import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/reporting.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/analytics_chart.dart';
import '../../shared/reference_charts.dart';
import '../../shared/widgets.dart';
import '../transactions/grouped_transactions.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_screen.dart';
import 'catalog_screen.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CategoryDetailScreen(this.id, {super.key});
  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  String? only;
  int period = 0;
  bool donut = false, weekly = false, overall = false;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final category = ledger.category(widget.id);
    if (category == null)
      return const FeaturePage(
        title: 'Category removed',
        child: EmptyState(
          title: 'Nothing to display',
          message:
              'Return to your categories. Existing record protection remains in place.',
        ),
      );
    final ids = categorySubtree(ledger.data, category.id);
    final selected = only != null && ids.contains(only) ? only : null;
    final data = CategoryActivity(
      ledger,
      category,
      DateTime.now(),
      only: selected,
    );
    final breakdown = data.breakdown, total = data.total(true);
    final windows = weekly ? data.weeks : data.months;
    final type = category.type == 'transfer'
        ? 'Moved volume'
        : category.type == 'income'
        ? 'Income'
        : 'Spending';
    void records(DateWindow window) => openPage(
      context,
      TransactionsScreen(
        title: category.name,
        initialFilter: TransactionFilter(
          categories: data.ids,
          type: category.type,
          dates: window,
          postedOnly: true,
          includedOnly: true,
        ),
      ),
    );
    Widget panel(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TonalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
    final groups = [
      for (final entry in breakdown.entries)
        ReportGroup(
          id: entry.key,
          name: ledger.category(entry.key)?.name ?? 'Uncategorized',
          icon: ledger.category(entry.key)?.icon ?? 'category',
          color: ledger.category(entry.key)?.color ?? category.color,
          amount: entry.value,
          entries: data.entries
              .where((e) => e.categoryId == entry.key)
              .toList(),
        ),
    ];
    return FeaturePage(
      title: category.name,
      actions: [
        IconButton(
          tooltip: 'Category calculation methods',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showFeatureInfo(
            context,
            'Category calculations',
            'All charts and summaries use posted records from included accounts, converted with saved manual rates. All includes the complete subtree once per record; a named chip selects that exact category. Breakdown uses all posted history; overview switches financial-month/overall. Monthly points cover 18 financial months including the partial current month. Weekly bars cover eight calendar weeks, including this partial week. Missing records are not verified zero spending. Bottom tabs group activity only. Transfers show moved volume, never income or expense.',
          ),
        ),
        IconButton(
          tooltip: 'Add category transaction',
          icon: const Icon(Icons.add),
          onPressed: () => openPage(
            context,
            TransactionForm(
              initialType: category.type,
              initialCategoryId: selected ?? category.id,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Delete or hide category',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final used = ledger.data.transactions.any(
              (e) => e.categoryId == category.id,
            );
            if (await confirm(
                  context,
                  used ? 'Hide this category?' : 'Delete category?',
                  used
                      ? 'History is preserved. An in-use category cannot be deleted.'
                      : 'Only unused, unlinked categories can be removed.',
                  confirmLabel: used ? 'Hide' : 'Delete',
                ) &&
                context.mounted) {
              final saved = await runSafe(
                context,
                () => used
                    ? ref
                          .read(appProvider.notifier)
                          .upsertCategory(category.copyWith(hidden: true))
                    : ref
                          .read(appProvider.notifier)
                          .deleteCategory(category.id),
              );
              if (saved && !used && context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => editCatalogCategory(context, ref, category),
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
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selected == null,
                    onSelected: (_) => setState(() => only = null),
                  ),
                  const SizedBox(width: 8),
                  for (final c in ledger.data.categories.where(
                    (c) => ids.contains(c.id),
                  ))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          iconFor(c.icon),
                          color: readableTint(context, Color(c.color)),
                          size: 18,
                        ),
                        label: Text(c.name),
                        selected: selected == c.id,
                        onSelected: (_) => setState(() => only = c.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                panel('Category Breakdown', [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AmountText(
                        total,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Show stacked category breakdown',
                            isSelected: !donut,
                            onPressed: () => setState(() => donut = false),
                            icon: const Icon(Icons.bar_chart_rounded),
                          ),
                          IconButton(
                            tooltip: 'Show category donut',
                            isSelected: donut,
                            onPressed: () => setState(() => donut = true),
                            icon: const Icon(Icons.pie_chart_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'All posted history · $type · ${ledger.currency}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  if (donut)
                    ReferenceDonut(groups, ledger)
                  else if (!ledger.settings.hideAmounts && total > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 18,
                        child: Row(
                          children: [
                            for (final group in groups.where(
                              (g) => g.amount > 0,
                            ))
                              Expanded(
                                flex: group.amount,
                                child: ColoredBox(
                                  color: Color(group.color),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (groups.isEmpty) const Text('No matching posted records'),
                  for (final group in groups)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.circle,
                        size: 14,
                        color: readableTint(context, Color(group.color)),
                      ),
                      title: Text(
                        '${ledger.settings.hideAmounts
                            ? '•••'
                            : total == 0
                            ? '—'
                            : (group.amount / total * 100).toStringAsFixed(1)}% ${group.name}',
                      ),
                      subtitle: Text('${group.entries.length} records'),
                      trailing: SizedBox(
                        width: 100,
                        child: AmountText(group.amount),
                      ),
                      onTap: () => setState(() => only = group.id),
                    ),
                ]),
                panel(weekly ? 'Recent Weekly $type' : 'Monthly $type Trend', [
                  Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Monthly category line',
                        isSelected: !weekly,
                        onPressed: () => setState(() => weekly = false),
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                      IconButton(
                        tooltip: 'Weekly category bars',
                        isSelected: weekly,
                        onPressed: () => setState(() => weekly = true),
                        icon: const Icon(Icons.view_week_outlined),
                      ),
                    ],
                  ),
                  AnalyticsChart(
                    values: data.buckets(windows),
                    labels: [
                      for (final w in windows)
                        weekly
                            ? DateFormat.MMMd().format(w.start)
                            : DateFormat.MMM().format(w.start),
                    ],
                    pointLabels: [
                      for (final w in windows)
                        '${DateFormat.yMMMd().format(w.start)} – ${DateFormat.yMMMd().format(DateTime(w.end.year, w.end.month, w.end.day - 1))}',
                    ],
                    ledger: ledger,
                    bars: weekly,
                    curved: !weekly,
                    label: 'Recorded ${type.toLowerCase()}',
                    onOpenPoint: (i) => records(windows[i]),
                  ),
                  const Text(
                    'Posted only · final point is partial; empty buckets mean no records, not verified zero spending.',
                    style: TextStyle(fontSize: 12),
                  ),
                ]),
                panel('Overview', [
                  PillTabs(
                    labels: const ['This month', 'Overall'],
                    selected: overall ? 1 : 0,
                    onSelected: (v) => setState(() => overall = v == 1),
                  ),
                  const SizedBox(height: 20),
                  SummaryColumns(
                    labels: ['Total $type', 'Transactions'],
                    values: [
                      AmountText(data.total(overall)),
                      Text('${data.scope(overall).length}'),
                    ],
                  ),
                  const Divider(height: 28),
                  SummaryColumns(
                    labels: ['Average per record', 'Largest record'],
                    values: [
                      AmountText(data.average(overall)),
                      AmountText(data.largest(overall)),
                    ],
                  ),
                ]),
                panel('Transaction Insights', [
                  SummaryColumns(
                    labels: const [
                      'This financial month',
                      'Transactions / elapsed day',
                    ],
                    values: [
                      Text('${data.scope(false).length} transactions'),
                      Text(data.entriesPerElapsedDay.toStringAsFixed(2)),
                    ],
                  ),
                  const Divider(height: 28),
                  Text(
                    data.lastDate == null
                        ? 'No recorded transaction'
                        : calendarDaysBetween(
                                data.lastDate!.toLocal(),
                                DateTime.now(),
                              ) ==
                              0
                        ? 'Last transaction · Today'
                        : 'Last transaction · ${calendarDaysBetween(data.lastDate!.toLocal(), DateTime.now())} days ago',
                  ),
                ]),
                const SectionHeader('Transactions'),
                GroupedTransactions(data.entries, period: period),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
