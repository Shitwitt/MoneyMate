import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/icons.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_budget_stat.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/transaction_tile.dart';

/// Budgets — monthly limits per category with live progress.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final PaisaColors colors = PaisaColors.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = provider.formatter;
    final List<CategoryBudgetStat> stats = provider.categoryBudgetStats;

    final double over = stats
        .where((CategoryBudgetStat s) => s.isOverBudget)
        .fold<double>(0, (double sum, CategoryBudgetStat s) => sum + s.remaining.abs());

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: <Widget>[
              Text(
                'Monthly budgets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.daysLeftInMonth} days left',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ---------------- Summary ----------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'Spent this month',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatter.percent(
                        provider.totalMonthlyBudget <= 0
                            ? 0
                            : provider.totalMonthlySpend /
                                provider.totalMonthlyBudget,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: provider.totalBudgetProgress >= 1
                            ? colors.expense
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatter.formatWhole(provider.totalMonthlySpend),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                Text(
                  'of ${formatter.formatWhole(provider.totalMonthlyBudget)} budgeted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: provider.totalBudgetProgress,
                    minHeight: 9,
                    backgroundColor: scheme.surfaceContainerLow,
                    color: provider.totalBudgetProgress >= 1
                        ? colors.expense
                        : scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MiniMetric(
                        label: 'Left',
                        value: formatter.formatWhole(provider.totalBudgetRemaining),
                        color: provider.totalBudgetRemaining < 0
                            ? colors.expense
                            : colors.income,
                      ),
                    ),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Safe / day',
                        value: formatter.formatWhole(provider.safeDailySpend),
                        color: scheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Overspent',
                        value: formatter.formatWhole(over),
                        color: over > 0 ? colors.expense : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Text(
                'Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.activeBudgets.length} with budget',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (stats.isEmpty)
          const LedgerEmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No budgets yet',
            message:
                'Tap a category below and set a monthly limit to start tracking.',
          )
        else
          for (final CategoryBudgetStat stat in stats)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _BudgetCategoryCard(stat: stat),
            ),

        // ---------------- Categories without a budget yet ----------------
        if (provider.categories.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Set a limit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final stat in provider.categories)
                  if (provider.budgetStatFor(stat.id) == null)
                    ActionChip(
                      avatar: Icon(
                        ICONS.byCodePoint(stat.icon),
                        size: 16,
                        color: Color(stat.color),
                      ),
                      label: Text(stat.name),
                      onPressed: () =>
                          showBudgetEditor(context, stat.id, stat.name),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({required this.stat});

  final CategoryBudgetStat stat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final Color tint = Color(stat.category.color);

    final Color barColor = stat.isOverBudget
        ? colors.expense
        : stat.progress > 0.85
            ? colors.warning
            : tint;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => showBudgetEditor(
        context,
        stat.categoryId,
        stat.name,
        initialBudget: stat.budget,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tint.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ICONS.byCodePoint(stat.category.icon),
                    size: 19,
                    color: tint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        stat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        stat.hasBudget
                            ? '${provider.formatter.formatWhole(stat.spent)} of '
                                '${provider.formatter.formatWhole(stat.budget)}'
                            : '${provider.formatter.formatWhole(stat.spent)} spent · no budget',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      provider.formatter.percent(stat.usedFraction),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: stat.isOverBudget ? colors.expense : scheme.onSurface,
                      ),
                    ),
                    if (stat.hasBudget)
                      Text(
                        '${provider.formatter.formatWhole(stat.remaining)} left',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (stat.hasBudget) ...<Widget>[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stat.progress,
                  minHeight: 7,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: barColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Icon(
                    stat.isOverBudget
                        ? Icons.warning_amber_rounded
                        : Icons.today_outlined,
                    size: 13,
                    color: stat.isOverBudget ? colors.expense : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stat.isOverBudget
                        ? 'Over by ${provider.formatter.formatWhole(stat.remaining.abs())}'
                        : '${provider.formatter.formatWhole(stat.dailyAllowance)}/day safe · '
                            '${stat.daysLeftInPeriod} days left',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: stat.isOverBudget
                          ? colors.expense
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that sets (or clears) a monthly budget for one category.
Future<void> showBudgetEditor(
  BuildContext context,
  String categoryId,
  String categoryName, {
  double initialBudget = 0,
}) async {
  final PaisaProvider provider = context.read<PaisaProvider>();
  final TextEditingController controller = TextEditingController(
    text: initialBudget == 0 ? '' : initialBudget.toStringAsFixed(0),
  );
  bool active = initialBudget > 0;
  String? error;

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
              left: 20,
              right: 20,
              top: 8,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '$categoryName budget',
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
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monthly limit',
                    prefixText: '${provider.formatter.symbol} ',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  title: const Text('Track this budget'),
                  onChanged: (bool value) => setState(() => active = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    if (initialBudget > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await provider.setCategoryBudget(
                              categoryId,
                              budget: 0,
                              active: false,
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                    if (initialBudget > 0) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final double? value =
                              provider.formatter.parse(controller.text.trim());
                          if (value == null || value < 0) {
                            setState(() => error = 'Enter a valid amount');
                            return;
                          }
                          await provider.setCategoryBudget(
                            categoryId,
                            budget: value,
                            active: active && value > 0,
                          );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        child: const Text('Save budget'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );

  controller.dispose();
}
