import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/catalog_insights.dart';
import '../../core/data/providers.dart';
import '../../core/data/ledger.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/widgets.dart';
import '../transactions/transactions_screen.dart';

Future<void> showCategoriesHelp(BuildContext context) => showHowItWorks(
  context,
  title: 'How Categories Work',
  introduction: 'Categories describe what a local transaction was for. They organize your records; they do not move money.',
  sections: const [
    (
      Icons.category_outlined,
      'Types',
      'Expense, income and transfer categories stay separate. Transfers are movements between your accounts, not income or expense; their net is zero, with moved volume available in details.',
    ),
    (
      Icons.account_tree_outlined,
      'Subcategories',
      'Build a hierarchy within one type. A parent total includes all descendants once per record. A named detail chip selects that exact category. IDs, not names, define relationships. Cycles and missing parents are rejected.',
    ),
    (
      Icons.savings_outlined,
      'Budgets',
      'Automatic category budgets include descendants; a manually linked budget overrides matching where applicable. Manual budgets count explicit links only. Income targets are separate from expense limits.',
    ),
    (
      Icons.insights_outlined,
      'Insights',
      'Tap for allocation, 18 financial-month points, eight recent calendar-week bars, summaries and grouped records. Posted, included-account scopes and saved manual rates are disclosed. Future schedules remain saved but are not actual spending.',
    ),
    (
      Icons.edit_outlined,
      'Organization',
      'Sort totals or names, or choose Custom order to drag every node. Custom mode shows all nodes; parent and child rows must not be added as a consolidated total. Add icons/colors/parents. In-use categories may be hidden, not silently deleted from history.',
    ),
  ],
);

class CategoriesScreen extends ConsumerStatefulWidget {
  final void Function(Category?, String) onEdit;
  final ValueChanged<Category> onOpen;
  const CategoriesScreen({
    super.key,
    required this.onEdit,
    required this.onOpen,
  });
  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int selected = 0, scope = 1;
  String sort = 'amount';
  DateWindow? range;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!, now = DateTime.now();
    final type = ['expense', 'income', 'transfer'][selected];
    final all = [...ledger.data.categories]
      ..sort((a, b) => a.order.compareTo(b.order));
    final categories = all.where((c) => c.type == type).toList();
    final window =
        range ??
        (scope == 0 ? financialMonth(now, ledger.settings.monthStart) : null);
    final records = ledger.data.transactions
        .where(
          (e) =>
              e.type == type &&
              !e.date.isAfter(now) &&
              !ledger.account(e.accountId).excluded &&
              (window == null || window.contains(e.date)),
        )
        .toList();
    final subtrees = {
      for (final c in categories) c.id: categorySubtree(ledger.data, c.id),
    };
    List<MoneyTransaction> entries(Category c) =>
        records.where((e) => subtrees[c.id]!.contains(e.categoryId)).toList();
    int total(Category c) =>
        entries(c).fold<int>(0, (s, e) => s + ledger.entryValue(e));
    var roots = sort == 'custom'
        ? categories
        : categories
              .where(
                (c) =>
                    c.parentId.isEmpty ||
                    !categories.any((p) => p.id == c.parentId),
              )
              .toList();
    if (roots.isEmpty && categories.isNotEmpty) roots = categories;
    if (sort == 'amount') roots.sort((a, b) => total(b).compareTo(total(a)));
    if (sort == 'name')
      roots.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    final unassigned = records.where((e) => e.categoryId.isEmpty).toList();
    return FeaturePage(
      title: 'Categories',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort categories',
          icon: const Icon(Icons.sort_rounded),
          initialValue: sort,
          onSelected: (v) => setState(() => sort = v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'amount', child: Text('Total amount')),
            PopupMenuItem(value: 'name', child: Text('Name')),
            PopupMenuItem(
              value: 'custom',
              child: Text('Custom order · drag to rearrange'),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Category date range',
          onPressed: () async {
            final dates = await showDateRangePicker(
              context: context,
              firstDate: DateTime(1970),
              lastDate: DateTime(2200),
            );
            if (dates != null && mounted)
              setState(
                () => range = DateWindow(
                  dayOnly(dates.start),
                  nextDay(dates.end),
                ),
              );
          },
          icon: Badge(
            isLabelVisible: range != null,
            child: const Icon(Icons.calendar_month_outlined),
          ),
        ),
        IconButton(
          tooltip: 'How Categories Work',
          onPressed: () => showCategoriesHelp(context),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      fab: FloatingActionButton(
        tooltip: 'Add category',
        onPressed: () => widget.onEdit(null, type),
        child: const Icon(Icons.add),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: const ['This month', 'Overall'],
          selected: scope,
          onSelected: (v) => setState(() {
            scope = v;
            range = null;
          }),
        ),
      ),
      child: Column(
        children: [
          PillTabs(
            labels: const ['Expense', 'Income', 'Transfer'],
            selected: selected,
            onSelected: (v) => setState(() => selected = v),
          ),
          const SizedBox(height: 12),
          if (range != null)
            TextButton.icon(
              onPressed: () => setState(() => range = null),
              icon: const Icon(Icons.close),
              label: Text(
                '${DateFormat.yMMMd().format(range!.start)} – ${DateFormat.yMMMd().format(DateTime(range!.end.year, range!.end.month, range!.end.day - 1))}',
              ),
            ),
          const Text(
            'Posted, included accounts · signed net. Parent totals include descendants once.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (type == 'transfer')
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Transfer net is zero. Open a category for moved volume.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (unassigned.isNotEmpty)
            ListTile(
              leading: const ColorIcon('transfer', 0xffb7c9e5),
              title: const Text('Uncategorized transfers'),
              subtitle: Text('${unassigned.length} records'),
              onTap: () => openPage(
                context,
                TransactionsScreen(
                  initialFilter: TransactionFilter(
                    type: 'transfer',
                    categories: const {''},
                    dates: window,
                    postedOnly: true,
                    includedOnly: true,
                  ),
                ),
              ),
            ),
          Expanded(
            child: roots.isEmpty
                ? EmptyState(
                    title: 'Make it your own',
                    message:
                        'Create a custom $type category for clearer records.',
                    action: 'Add category',
                    onAction: () => widget.onEdit(null, type),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: sort == 'custom',
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: roots.length,
                    onReorder: (oldIndex, newIndex) {
                      if (sort != 'custom') return;
                      if (newIndex > oldIndex) newIndex--;
                      final reordered = [...roots];
                      reordered.insert(newIndex, reordered.removeAt(oldIndex));
                      var cursor = 0;
                      final ids = roots.map((c) => c.id).toSet();
                      runSafe(
                        context,
                        () => ref.read(appProvider.notifier).reorderCategories([
                          for (final c in all)
                            if (ids.contains(c.id)) reordered[cursor++] else c,
                        ]),
                      );
                    },
                    itemBuilder: (context, index) {
                      final c = roots[index],
                          children = categories
                              .where((child) => child.parentId == c.id)
                              .toList();
                      final count = entries(c).length,
                          value = type == 'expense'
                              ? -total(c)
                              : type == 'income'
                              ? total(c)
                              : 0;
                      return Padding(
                        key: ValueKey(c.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TonalCard(
                          onTap: () => widget.onOpen(c),
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final stacked =
                                  box.maxWidth < 300 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.3;
                              final identity = Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ColorIcon(c.icon, c.color),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Text('$count transactions'),
                                        if (c.hidden) const Text('Hidden'),
                                        if (sort == 'custom' &&
                                            c.parentId.isNotEmpty)
                                          Text(
                                            categoryPath(ledger.data, c.id),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                              final amount = AmountText(
                                value,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ledger.settings.hideAmounts
                                      ? Theme.of(context).colorScheme.onSurface
                                      : AppColors.semantic(
                                          context,
                                          type == 'expense'
                                              ? 'expense'
                                              : 'income',
                                        ),
                                ),
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (stacked) ...[
                                    identity,
                                    const SizedBox(height: 12),
                                    amount,
                                  ] else
                                    Row(
                                      children: [
                                        Expanded(child: identity),
                                        const SizedBox(width: 12),
                                        Flexible(child: amount),
                                      ],
                                    ),
                                  if (children.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final child in children)
                                          ActionChip(
                                            avatar: Icon(
                                              iconFor(child.icon),
                                              size: 18,
                                            ),
                                            label: Text(child.name),
                                            onPressed: () =>
                                                widget.onOpen(child),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
