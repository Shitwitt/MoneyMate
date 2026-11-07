import 'package:flutter/material.dart';

import 'categories_budget_screen.dart';

/// The Budgets destination of the shell.
///
/// All of the real work lives in [CategoriesBudgetScreen], which is also
/// reachable as a full route from Settings; this class exists so the shell's
/// tab list stays a list of plain destinations.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoriesBudgetScreen();
  }
}
