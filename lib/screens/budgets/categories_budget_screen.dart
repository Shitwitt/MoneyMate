import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/icons.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/theme/paisa_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_format.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_budget_stat.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/paisa_provider.dart';
import '../home/home_screen.dart';
import '../transactions/add_transaction_screen.dart';
import 'add_category_screen.dart';

/// The Budgets tab: a monthly overview plus every category, budgeted or not.
///
/// The progress colour is a three-step ramp — primary below 75%, amber from 75%
/// to 99%, error red at 100% and above — so a category turns amber while there is
/// still money left to react, and red only once it is genuinely overspent.
class CategoriesBudgetScreen extends StatelessWidget {
  const CategoriesBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = provider.formatter;

    final List<CategoryModel> categories = provider.categories;
    final bool showIncome = provider.incomeTrackingEnabled;

    final List<CategoryModel> expense = <CategoryModel>[
      for (final CategoryModel category in categories)
        if (!category.isIncome) category,
    ];
    final List<CategoryModel> income = <CategoryModel>[
      for (final CategoryModel category in categories)
        if (category.isIncome) category,
    ];

    // Budgeted categories first (most at risk on top), then the rest.
    final List<CategoryBudgetStat> stats = provider.categoryBudgetStats;
    final List<CategoryModel> ordered = <CategoryModel>[
      for (final CategoryBudgetStat stat in stats)
        if (!stat.category.isIncome) stat.category,
      for (final CategoryModel category in expense)
        if (provider.budgetStatFor(category.id) == null) category,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: <Widget>[
          // ---------------- Overview ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: BudgetOverviewCard(
              totalBudget: provider.totalMonthlyBudget,
              totalSpent: provider.totalMonthlySpend,
              remaining: provider.totalBudgetRemaining,
              safeDaily: provider.safeDailySpend,
              daysLeft: provider.daysLeftInMonth,
              budgetedCount: provider.activeBudgets.length,
              overspentCount: provider.overBudgetCategories.length,
              formatter: formatter,
            ),
          ),

          const SizedBox(height: 18),

          // ---------------- Category list ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${expense.length} expense'
                  '${showIncome && income.isNotEmpty ? ' · ${income.length} income' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Add category',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => openAddCategoryScreen(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                ),
              ],
            ),
          ),

          if (ordered.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.category_outlined,
                      size: 32,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No categories yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a category to start budgeting your month.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final CategoryModel category in ordered)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: CategoryBudgetCard(
                  category: category,
                  stat: provider.budgetStatFor(category.id),
                  transactionCount:
                      provider.transactionCountForCategory(category.id),
                  onShowTransactions: () =>
                      showCategoryTransactionsSheet(context, category),
                ),
              ),

          // ---------------- Income categories ----------------
          if (showIncome && income.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Income categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final CategoryModel category in income)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: CategoryBudgetCard(
                  category: category,
                  stat: provider.budgetStatFor(category.id),
                  transactionCount:
                      provider.transactionCountForCategory(category.id),
                  onShowTransactions: () =>
                      showCategoryTransactionsSheet(context, category),
                ),
              ),
          ],
        ],
      ),
    );
  }

}

/// Total budget vs total spent, with the daily safe-spend line.
class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.safeDaily,
    required this.daysLeft,
    required this.budgetedCount,
    required this.overspentCount,
    required this.formatter,
  });

  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double safeDaily;
  final int daysLeft;
  final int budgetedCount;
  final int overspentCount;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    final bool noBudget = totalBudget <= 0;
    final double ratio = noBudget ? 0 : totalSpent / totalBudget;
    final double progress = ratio.clamp(0.0, 1.0);
    final bool exceeded = ratio >= 1;

    final Color barColor = noBudget
        ? scheme.primary
        : exceeded
            ? colors.expense
            : ratio >= 0.75
                ? colors.warning
                : scheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.surfaceContainerHighest.withAlpha(120),
              scheme.primaryContainer,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 17,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly budget',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                noBudget ? 'Not set' : '${(ratio * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: exceeded ? colors.expense : scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: formatter.formatWhole(totalSpent),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  TextSpan(
                    text: noBudget
                        ? ' spent this month'
                        : '  of ${formatter.formatWhole(totalBudget)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerLow,
                  color: exceeded ? colors.expense : barColor,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _OverviewStat(
                  label: exceeded ? 'Over budget' : 'Remaining',
                  value: formatter.formatWhole(remaining.abs()),
                  color: exceeded ? colors.expense : colors.income,
                  icon: exceeded
                      ? Icons.warning_amber_rounded
                      : Icons.savings_outlined,
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  label: 'Safe / day',
                  value: noBudget ? '—' : formatter.formatWhole(safeDaily),
                  color: scheme.onPrimaryContainer,
                  icon: Icons.today_outlined,
                  caption: noBudget ? 'Set a budget' : '$daysLeft days left',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              _Pill(
                label: budgetedCount == 1
                    ? '1 budgeted category'
                    : '$budgetedCount budgeted categories',
                color: scheme.onPrimaryContainer,
              ),
              if (overspentCount > 0)
                _Pill(
                  label: overspentCount == 1
                      ? '1 over budget'
                      : '$overspentCount over budget',
                  color: colors.expense,
                  background: colors.expenseContainer,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One category with its spend, transaction count and budget bar.
class CategoryBudgetCard extends StatelessWidget {
  const CategoryBudgetCard({
    super.key,
    required this.category,
    required this.stat,
    required this.transactionCount,
    this.onShowTransactions,
  });

  final CategoryModel category;

  /// `null` when the category has neither spend nor a budget this month.
  final CategoryBudgetStat? stat;

  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final CurrencyFormatter formatter = context.watch<PaisaProvider>().formatter;

    final Color tint = Color(category.color);
    final double spent = stat?.spent ?? 0;
    final bool hasBudget = stat?.hasBudget ?? false;
    final double budget = stat?.budget ?? category.budget;
    final double ratio = hasBudget && budget > 0 ? spent / budget : 0;
    final bool exceeded = hasBudget && spent > budget;

    final Color barColor = !hasBudget
        ? scheme.primary
        : exceeded
            ? colors.expense
            : ratio >= 0.75
                ? colors.warning
                : scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
      onTap: () => openAddCategoryScreen(context, existing: category),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
          border: Border.all(
            color: exceeded ? colors.expense.withOpacity(0.4) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    ICONS.byCodePoint(category.icon),
                    size: 21,
                    color: tint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${formatter.formatWhole(spent)} this month · '
                        '$transactionCount txn${transactionCount == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (hasBudget)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: barColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(ratio * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: barColor,
                          ),
                        ),
                      )
                    else
                      Text(
                        'No budget',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (hasBudget)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${formatter.formatWhole(budget)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                if (onShowTransactions != null) ...<Widget>[
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'View transactions',
                    visualDensity: VisualDensity.compact,
                    onPressed: onShowTransactions,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (hasBudget) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Text(
                    '${formatter.formatWhole(spent)} / ${formatter.formatWhole(budget)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: exceeded ? colors.expense : scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (exceeded)
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.error_outline_rounded,
                          size: 13,
                          color: colors.expense,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Exceeded by ${formatter.formatWhole(spent - budget)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.expense,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${formatter.formatWhole(math.max(0, budget - spent))} left',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: barColor,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.caption,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    this.background,
  });

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The transactions behind a category's number, with per-row delete.
///
/// Deleting uses the same undo snack bar as the home ledger, so a mis-tap costs
/// nothing: the record comes back with its original id and timestamp.
Future<void> showCategoryTransactionsSheet(
  BuildContext context,
  CategoryModel category,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _CategoryTransactionsSheet(
      category: category,
    ),
  );
}

class _CategoryTransactionsSheet extends StatefulWidget {
  const _CategoryTransactionsSheet({required this.category});

  final CategoryModel category;

  @override
  State<_CategoryTransactionsSheet> createState() =>
      _CategoryTransactionsSheetState();
}

class _CategoryTransactionsSheetState
    extends State<_CategoryTransactionsSheet> {
  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = provider.formatter;
    final List<TransactionModel> rows =
        provider.transactionsForCategory(widget.category.id);
    final double total = rows.fold<double>(
      0,
      (double sum, TransactionModel row) => sum + row.amount,
    );
    final Color tint = Color(widget.category.color);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            // ---------------- Header ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tint.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      ICONS.byCodePoint(widget.category.icon),
                      size: 20,
                      color: tint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${formatter.formatWhole(total)} this month · '
                          '${rows.length} transaction${rows.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (widget.category.hasBudget)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (total / widget.category.budget).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: total > widget.category.budget
                              ? PaisaColors.of(context).expense
                              : tint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${((total / widget.category.budget) * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Divider(height: 1, color: scheme.outlineVariant),

            // ---------------- Rows ----------------
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No transactions in this category this month.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 60,
                        color: scheme.outlineVariant.withOpacity(0.5),
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final TransactionModel row = rows[index];
                        final AccountModel? account =
                            provider.accountById(row.accountId);
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            openAddTransactionScreen(context, existing: row);
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tint.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              row.isIncome
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              size: 18,
                              color: tint,
                            ),
                          ),
                          title: Text(
                            row.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${DateTimeFormat.date(row.time)} • '
                            '${account?.title ?? 'Deleted account'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '${row.isIncome ? '+' : '−'}'
                                '${formatter.formatWhole(row.amount)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: row.isIncome
                                      ? PaisaColors.of(context).income
                                      : PaisaColors.of(context).expense,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete transaction',
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  await deleteTransactionWithUndo(context, row);
                                },
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: scheme.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
