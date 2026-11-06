import 'dart:math' as math;

import '../utils/dates.dart';
import 'ledger.dart';

class PulseMetric {
  final String label, explanation;
  final double? value;
  const PulseMetric(this.label, this.value, this.explanation);
}

/// Transparent, local record-based planning indicators, not a credit score,
/// recommendation, bank feed, insurance assessment or predicted return.
class FinancialPulse {
  final List<PulseMetric> metrics;
  const FinancialPulse(this.metrics);
  int? get score {
    final known = metrics.where((m) => m.value != null).toList();
    if (known.length < 2) return null;
    return (known.fold<double>(0, (sum, m) => sum + m.value!) / known.length)
        .round();
  }

  String get status => score == null
      ? 'Your story is unfolding'
      : score! >= 70
      ? 'Finding your balance'
      : score! >= 40
      ? 'A steady chapter'
      : 'Room to grow';
  factory FinancialPulse.fromLedger(Ledger source, DateTime now) {
    final ledger = Ledger(
      source.data.copyWith(
        transactions: source.data.transactions
            .where((t) => !t.date.isAfter(now))
            .toList(),
      ),
      source.settings,
    );
    final window = financialMonth(now, ledger.settings.monthStart);
    final eligible = ledger.data.transactions
        .where((t) => !ledger.account(t.accountId).excluded)
        .toList();
    final income = ledger.total('income', window, entries: eligible);
    final expense = ledger.total('expense', window, entries: eligible);
    final windows = monthlyWindows(now, ledger.settings.monthStart, 3);
    final averageSpend =
        windows.fold<int>(
          0,
          (s, w) => s + ledger.total('expense', w, entries: eligible),
        ) /
        3;
    var liquid = 0, creditDebt = 0;
    for (final a in ledger.data.accounts.where(
      (a) => !a.archived && !a.excluded,
    )) {
      final amount = ledger.inBase(ledger.accountBalance(a.id), a.currency);
      if (amount < 0) creditDebt += -amount;
      if (a.type != 'investment' && a.type != 'credit card')
        liquid += math.max(0, amount);
    }
    final goals = ledger.data.goals.where((g) => g.targetMinor > 0).toList();
    final records = eligible;
    final start = DateTime(now.year, now.month, now.day - 27);
    final days = records
        .where((t) => !dayOnly(t.date).isBefore(start))
        .map((t) => dayOnly(t.date))
        .toSet()
        .length;
    final recorded =
        records.isNotEmpty || liquid > 0 || ledger.toPay > 0 || creditDebt > 0;
    double bounded(double v) => v.clamp(0.0, 100.0).toDouble();
    return FinancialPulse([
      PulseMetric(
        'Buffer',
        averageSpend > 0 ? bounded(liquid / (averageSpend * 3) * 100) : null,
        'Positive included liquid-account balances divided by three months of the recorded three-month average expense. Savings accounts included; investments excluded.',
      ),
      PulseMetric(
        'Spending',
        income > 0 ? bounded((income - expense) / income * 100) : null,
        'This financial month’s recorded income remaining after expenses, as a percentage. No recorded income means unavailable, not a guessed score.',
      ),
      PulseMetric(
        'Goals',
        goals.isEmpty
            ? null
            : bounded(
                goals.fold<double>(
                      0,
                      (s, g) =>
                          s +
                          (ledger.goalSaved(g) / g.targetMinor).clamp(0.0, 1.0),
                    ) /
                    goals.length *
                    100,
              ),
        'Mean completion of your recorded goals, capped at 100% per goal. No goals means unavailable.',
      ),
      PulseMetric(
        'Debt',
        recorded
            ? creditDebt + ledger.toPay == 0
                  ? 100.0
                  : bounded(
                      liquid /
                          math.max(1, liquid + creditDebt + ledger.toPay) *
                          100,
                    )
            : null,
        'Included positive liquid balances as a share of those balances plus recorded negative account balances and outstanding borrowed loans. No recorded debt maps to 100 when records exist. Not an assessment of unrecorded debt.',
      ),
      PulseMetric(
        'Record coverage',
        records.isEmpty ? null : bounded(days / 28 * 100),
        'Distinct days with an entry from an included account in the past 28 calendar days. Daily logging is not a financial-health requirement.',
      ),
    ]);
  }
}
