import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/paisa_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_model.dart';
import '../../providers/paisa_provider.dart';
import 'add_category_screen.dart';
import 'categories_budget_screen.dart';

/// The category manager as a pushed route: the same overview card and the same
/// cards as the Budgets tab, wrapped in its own app bar so Settings can open it
/// without hosting the shell.
Future<void> openCategoryManager(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => const CategoryManagerScreen(),
    ),
  );
}

/// Categories & budgets for a route context.
class CategoryManagerScreen extends StatelessWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = provider.formatter;

    final List<CategoryModel> expense = <CategoryModel>[
      for (final CategoryModel category in provider.categories)
        if (!category.isIncome) category,
    ];
    final List<CategoryModel> income = <CategoryModel>[
      for (final CategoryModel category in provider.categories)
        if (category.isIncome) category,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & budgets'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add category',
            onPressed: () => openAddCategoryScreen(context),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Expense categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final CategoryModel category in expense)
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
          if (income.isNotEmpty) ...<Widget>[
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
              ),
              child: Text(
                'Budgets reset on the 1st. Spending counts every expense '
                'transaction recorded in the current month; income categories '
                'never carry a budget.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
