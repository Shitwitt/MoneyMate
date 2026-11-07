import 'package:flutter/foundation.dart';

import '../../core/enum/filter_enums.dart';
import 'debt_model.dart';
import 'debt_transaction_model.dart';

/// A [DebtModel] joined with every installment paid against it.
///
/// Held in memory only — Hive stores the two tables separately so a debt and its
/// installments can be edited without rewriting each other.
@immutable
class DebtSummary {
  const DebtSummary({
    required this.debt,
    this.installments = const <DebtTransactionModel>[],
  });

  final DebtModel debt;

  /// All installments, sorted newest-first.
  final List<DebtTransactionModel> installments;

  String get id => debt.id;
  DebtType get debtType => debt.debtType;

  /// Total repaid / collected so far.
  double get paidAmount => installments.fold<double>(
        0,
        (double sum, DebtTransactionModel entry) => sum + entry.amount,
      );

  /// Remaining balance; never negative.
  double get outstandingAmount {
    final double remaining = debt.amount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  /// `0..1` repayment progress.
  double get progress => debt.progress(paidAmount);

  /// True once the full amount is settled.
  bool get isSettled => debt.isSettled(paidAmount);

  /// Whole days until the due date.
  int daysRemaining([DateTime? now]) => debt.daysRemaining(now);

  bool isOverdue([DateTime? now]) => !isSettled && debt.isOverdue(now);

  bool isDueSoon({int withinDays = 7, DateTime? now}) =>
      !isSettled && debt.isDueSoon(withinDays: withinDays, now: now);

  /// Most recent installment, if any.
  DebtTransactionModel? get lastInstallment =>
      installments.isEmpty ? null : installments.first;

  /// Groups summaries by debt type.
  static Map<DebtType, List<DebtSummary>> groupByType(
    Iterable<DebtSummary> summaries,
  ) {
    final Map<DebtType, List<DebtSummary>> grouped =
        <DebtType, List<DebtSummary>>{
      DebtType.debt: <DebtSummary>[],
      DebtType.credit: <DebtSummary>[],
    };
    for (final DebtSummary summary in summaries) {
      grouped[summary.debtType]!.add(summary);
    }
    return grouped;
  }

  /// Net effect on the user's net worth: lent money adds, borrowed money
  /// subtracts, and both are reduced by what has already been settled.
  double get netWorthImpact =>
      outstandingAmount * debtType.netWorthSign;

  @override
  bool operator ==(Object other) =>
      other is DebtSummary &&
      other.debt == debt &&
      listEquals(other.installments, installments);

  @override
  int get hashCode => Object.hash(debt, Object.hashAll(installments));
}
