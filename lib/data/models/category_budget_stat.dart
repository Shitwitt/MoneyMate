import 'package:flutter/foundation.dart';

import 'category_model.dart';

/// One category's budget health for a period (used by the home budget rings,
/// the analytics screen and the "safe to spend" advisor).
///
/// All money values are in the user's selected currency and always positive.
@immutable
class CategoryBudgetStat {
  const CategoryBudgetStat({
    required this.category,
    required this.spent,
    required this.daysLeftInPeriod,
  });

  final CategoryModel category;

  /// Amount spent in this category in the current period (usually a month).
  final double spent;

  /// Whole days left in the period, including today. Never below `1`.
  final int daysLeftInPeriod;

  String get categoryId => category.id;
  String get name => category.name;

  /// Configured budget. `0` when no budget is set.
  double get budget => category.budget;

  /// Whether this category has an enforceable budget.
  bool get hasBudget => category.isBudgetActive && category.budget > 0;

  /// `spent / budget`. `0` when there is no budget. Not clamped, so the UI can
  /// show `128%` and warn the user.
  double get usedFraction {
    if (!hasBudget) return 0;
    return spent / category.budget;
  }

  /// Clamped `0..1` progress for rings and bars.
  double get progress => usedFraction.clamp(0.0, 1.0);

  /// Budget left; goes negative when overspent.
  double get remaining => hasBudget ? category.budget - spent : 0;

  /// `true` when spending has exceeded the budget.
  bool get isOverBudget => hasBudget && spent > category.budget;

  /// Remaining budget split across the days left, floored at zero.
  ///
  /// This is the "safe daily spend" allowance: spending no more than this per
  /// day keeps the month inside budget.
  double get dailyAllowance {
    if (!hasBudget) return 0;
    final double left = remaining;
    if (left <= 0) return 0;
    return left / daysLeftInPeriod;
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryBudgetStat &&
      other.category == category &&
      other.spent == spent &&
      other.daysLeftInPeriod == daysLeftInPeriod;

  @override
  int get hashCode => Object.hash(category, spent, daysLeftInPeriod);

  @override
  String toString() =>
      'CategoryBudgetStat(${category.name}, spent: $spent / ${category.budget})';
}
