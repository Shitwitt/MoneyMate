import 'dart:math' as math;

import '../models/models.dart';
import '../utils/money.dart';
import 'ledger.dart';

/// A reporting-currency change must not reinterpret existing minor units.
/// Account-native amounts and locked transfer amounts stay untouched; profile-
/// denominated budgets, debts, assets and split shares are converted together.
ProfileData rebaseProfile(ProfileData data, String currency) {
  final old = data.profile.currency;
  if (old == currency) return data;
  int convert(int value) => convertMinor(value, old, currency, data.rates);
  int positive(int value) => math.max(1, convert(value));
  MoneyEvent event(MoneyEvent value) =>
      value.copyWith(amountMinor: convert(value.amountMinor));
  return data.copyWith(
    profile: data.profile.copyWith(currency: currency),
    budgets: data.budgets
        .map(
          (budget) => budget.copyWith(limitMinor: positive(budget.limitMinor)),
        )
        .toList(),
    goals: data.goals
        .map(
          (goal) => goal.copyWith(
            targetMinor: positive(goal.targetMinor),
            contributions: goal.contributions.map(event).toList(),
          ),
        )
        .toList(),
    loans: data.loans.map((loan) {
      final principal = positive(loan.principalMinor);
      final paid = loan.repayments.fold<int>(
        0,
        (sum, item) => sum + item.amountMinor,
      );
      final target = math.min(
        convert(paid),
        (principal * (1 + loan.interestPercent / 100)).round(),
      );
      final allocation = paid == 0 || target == 0
          ? List.filled(loan.repayments.length, 0)
          : splitWeighted(
              target,
              loan.repayments
                  .map((item) => item.amountMinor.toDouble())
                  .toList(),
            );
      return loan.copyWith(
        principalMinor: principal,
        repayments: [
          for (var i = 0; i < loan.repayments.length; i++)
            loan.repayments[i].copyWith(amountMinor: allocation[i]),
        ],
      );
    }).toList(),
    assets: data.assets
        .map(
          (asset) => asset.copyWith(
            valueMinor: convert(asset.valueMinor),
            purchaseMinor: convert(asset.purchaseMinor),
            history: asset.history.map(event).toList(),
          ),
        )
        .toList(),
    bills: data.bills.map((bill) {
      final total = positive(bill.totalMinor);
      final amounts = splitWeighted(
        total,
        bill.shares.map((share) => share.amountMinor.toDouble()).toList(),
      );
      return bill.copyWith(
        totalMinor: total,
        shares: [
          for (var i = 0; i < bill.shares.length; i++)
            bill.shares[i].copyWith(amountMinor: amounts[i]),
        ],
      );
    }).toList(),
  );
}
