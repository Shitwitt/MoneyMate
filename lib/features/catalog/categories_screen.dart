import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/data/ledger.dart';
import '../../core/models/models.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import '../transactions/transactions_screen.dart';

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
  int selected = 0;
  String sort = 'amount';
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final type = ['expense', 'income', 'transfer'][selected];
    final all = [...ledger.data.categories]
      ..sort((a, b) => a.order.compareTo(b.order));
    final records = ledger.data.transactions
        .where((e) => e.type == type && !e.date.isAfter(DateTime.now()))
        .toList();
    int total(String id) => records
        .where((e) => e.categoryId == id)
        .fold(0, (sum, e) => sum + ledger.entryValue(e));
    final categories = all.where((c) => c.type == type).toList();
    if (sort == 'amount') {
      categories.sort((a, b) => total(b.id).compareTo(total(a.id)));
    }
    if (sort == 'name') {
      categories.sort((a, b) => a.name.compareTo(b.name));
    }
    final unassigned = records
        .where((e) => !categories.any((c) => c.id == e.categoryId))
        .toList();
    return FeaturePage(
      title: 'Categories',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort categories',
          icon: const Icon(Icons.sort_rounded),
          initialValue: sort,
          onSelected: (value) => setState(() => sort = value),
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
          tooltip: 'Add category',
          onPressed: () => widget.onEdit(null, type),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: Column(
        children: [
          PillTabs(
            labels: const ['Expense', 'Income', 'Transfer'],
            selected: selected,
            onSelected: (value) => setState(() => selected = value),
          ),
          const SizedBox(height: 14),
          if (type == 'transfer')
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Transfers move money between your own accounts, not income or expenses.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (unassigned.isNotEmpty)
            ListTile(
              leading: const ColorIcon('transfer', 0xffb7c9e5),
              title: const Text('Uncategorized transfers'),
              subtitle: Text('${unassigned.length} transactions'),
              onTap: () => openPage(
                context,
                const TransactionsScreen(
                  initialFilter: TransactionFilter(type: 'transfer'),
                ),
              ),
            ),
          Expanded(
            child: categories.isEmpty
                ? EmptyState(
                    title: 'Make it your own',
                    message:
                        'Create a custom $type category for clearer records.',
                    icon: Icons.category_outlined,
                    action: 'Add category',
                    onAction: () => widget.onEdit(null, type),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: sort == 'custom',
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: categories.length,
                    onReorder: (oldIndex, newIndex) {
                      if (sort != 'custom') return;
                      if (newIndex > oldIndex) newIndex--;
                      final reordered = [...categories];
                      reordered.insert(newIndex, reordered.removeAt(oldIndex));
                      var cursor = 0;
                      final ids = categories.map((c) => c.id).toSet();
                      runSafe(
                        context,
                        () => ref.read(appProvider.notifier).reorderCategories([
                          for (final item in all)
                            if (ids.contains(item.id))
                              reordered[cursor++]
                            else
                              item,
                        ]),
                      );
                    },
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final count = records
                          .where((e) => e.categoryId == category.id)
                          .length;
                      return Column(
                        key: ValueKey(category.id),
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 0,
                            ),
                            leading: ColorIcon(
                              category.icon,
                              category.color,
                              size: 46,
                            ),
                            title: Text(category.name),
                            subtitle: Text(
                              '$count transactions${category.hidden ? ' · Hidden' : ''}',
                            ),
                            onTap: () => widget.onOpen(category),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width * .23,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: AmountText(
                                      total(category.id),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: '${category.name} options',
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      widget.onEdit(category, type);
                                    }
                                    if (action == 'hide') {
                                      await runSafe(
                                        context,
                                        () => ref
                                            .read(appProvider.notifier)
                                            .upsertCategory(
                                              category.copyWith(
                                                hidden: !category.hidden,
                                              ),
                                            ),
                                      );
                                    }
                                    if (action == 'delete' &&
                                        await confirm(
                                          context,
                                          'Delete category?',
                                          'Only unused categories can be deleted. Hide an in-use category to keep its history.',
                                        ) &&
                                        context.mounted) {
                                      await runSafe(
                                        context,
                                        () => ref
                                            .read(appProvider.notifier)
                                            .deleteCategory(category.id),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'hide',
                                      child: Text(
                                        category.hidden
                                            ? 'Show category'
                                            : 'Hide category',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(indent: 62),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
