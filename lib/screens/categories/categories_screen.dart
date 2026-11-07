import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/icons.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_model.dart';
import '../../providers/paisa_provider.dart';
import '../budgets/budgets_screen.dart';
import 'quick_add_category_sheet.dart';

/// Category manager: rename, recolour, re-icon, set budgets and delete.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();

    final List<CategoryModel> expense = <CategoryModel>[];
    final List<CategoryModel> income = <CategoryModel>[];
    for (final CategoryModel category in provider.categories) {
      if (category.isIncome) {
        income.add(category);
      } else {
        expense.add(category);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add category',
            onPressed: () async {
              final CategoryModel? created = await showQuickAddCategorySheet(
                context,
                existingColors: <int>{
                  for (final CategoryModel category in provider.categories)
                    category.color,
                },
              );
              if (created != null) await provider.addCategory(created);
            },
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          if (expense.isNotEmpty) ...<Widget>[
            _GroupHeader(label: 'Expense categories'),
            for (final CategoryModel category in expense)
              _CategoryRow(
                category: category,
                onEdit: () => showCategoryEditor(context, category),
                onBudget: () => showBudgetEditor(
                  context,
                  category.id,
                  category.name,
                  initialBudget: category.budget,
                ),
                onDelete: () => _confirmDelete(context, category),
              ),
          ],
          if (income.isNotEmpty) ...<Widget>[
            _GroupHeader(label: 'Income categories'),
            for (final CategoryModel category in income)
              _CategoryRow(
                category: category,
                onEdit: () => showCategoryEditor(context, category),
                onBudget: () => showBudgetEditor(
                  context,
                  category.id,
                  category.name,
                  initialBudget: category.budget,
                ),
                onDelete: () => _confirmDelete(context, category),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryModel category,
  ) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content: const Text(
          'Transactions keep their history and fall back to "Uncategorised".',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteCategory(category.id);
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onBudget,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onBudget;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = context.watch<PaisaProvider>().formatter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onTap: onEdit,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(category.color).withOpacity(0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              ICONS.byCodePoint(category.icon),
              color: Color(category.color),
              size: 20,
            ),
          ),
          title: Text(category.name),
          subtitle: Text(
            category.description.trim().isEmpty
                ? (category.hasBudget
                    ? 'Budget ${formatter.formatWhole(category.budget)}'
                    : 'No budget')
                : category.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              if (category.isExpense)
                const PopupMenuItem<String>(
                  value: 'budget',
                  child: Text('Budget'),
                ),
              if (!category.isDefault)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
            ],
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'budget':
                  onBudget();
                case 'delete':
                  onDelete();
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Full category editor: name, description, icon, colour and budget.
Future<void> showCategoryEditor(
  BuildContext context,
  CategoryModel category,
) async {
  final PaisaProvider provider = context.read<PaisaProvider>();
  final TextEditingController name = TextEditingController(text: category.name);
  final TextEditingController description =
      TextEditingController(text: category.description);
  final TextEditingController budget = TextEditingController(
    text: category.budget > 0 ? category.budget.toStringAsFixed(0) : '',
  );
  String iconKey = ICONS.keyForCodePoint(category.icon) ?? 'others';
  int color = category.color;
  bool budgetActive = category.isBudgetActive;
  String? error;

  const List<int> palette = <int>[
    0xFFEF5350, 0xFFEC407A, 0xFFAB47BC, 0xFF7E57C2, 0xFF5C6BC0,
    0xFF42A5F5, 0xFF26C6DA, 0xFF26A69A, 0xFF66BB6A, 0xFF9CCC65,
    0xFFFFCA28, 0xFFFFA726, 0xFFFF7043, 0xFF8D6E63, 0xFF78909C,
  ];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final ThemeData theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (BuildContext context, ScrollController controller) {
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(color).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              ICONS.byKey(iconKey),
                              color: Color(color),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Edit category',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: <Widget>[
                          TextField(
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              errorText: error,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: description,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Colour',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              for (final int option in palette)
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => color = option),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Color(option),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: option == color
                                            ? theme.colorScheme.onSurface
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Icon',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String key in ICONS.categoryIconKeys)
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => iconKey = key),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: iconKey == key
                                          ? Color(color).withOpacity(0.18)
                                          : theme.colorScheme
                                              .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: iconKey == key
                                            ? Color(color)
                                            : Colors.transparent,
                                        width: 1.6,
                                      ),
                                    ),
                                    child: Icon(
                                      ICONS.byKey(key),
                                      size: 20,
                                      color: iconKey == key
                                          ? Color(color)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (category.isExpense) ...<Widget>[
                            const SizedBox(height: 18),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: budgetActive,
                              title: const Text('Monthly budget'),
                              onChanged: (bool value) =>
                                  setState(() => budgetActive = value),
                            ),
                            if (budgetActive)
                              TextField(
                                controller: budget,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Limit',
                                  prefixText: '${provider.formatter.symbol} ',
                                ),
                              ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () async {
                              final String trimmed = name.text.trim();
                              if (trimmed.isEmpty) {
                                setState(() => error = 'Add a name');
                                return;
                              }
                              final double limit =
                                  provider.formatter.parse(budget.text) ?? 0;
                              await provider.updateCategory(
                                category.copyWith(
                                  name: trimmed,
                                  description: description.text.trim(),
                                  icon: ICONS.codePointForKey(iconKey),
                                  color: color,
                                  budget: limit,
                                  isBudgetActive:
                                      category.isExpense && budgetActive && limit > 0,
                                ),
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            child: const Text('Save changes'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    },
  );

  name.dispose();
  description.dispose();
  budget.dispose();
}
