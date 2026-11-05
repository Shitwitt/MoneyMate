import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/utils/dates.dart';
import '../../shared/widgets.dart';
import '../budgets/budgets_screen.dart';
import '../transactions/transaction_form.dart';
import 'net_worth_screen.dart';

class SafeToSpendCard extends ConsumerWidget {
  final Ledger ledger;
  const SafeToSpendCard(this.ledger, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ledger.safeToSpend(DateTime.now());
    final dark = AppColors.dark(context);
    final ink = dark ? Colors.white : AppColors.ink;
    final secondary = dark ? const Color(0xffC5BDD8) : AppColors.secondary;
    return ShineSurface(
      colors: dark
          ? const [Color(0xff30263F), Color(0xff1B1B23)]
          : const [Color(0xffF1ECFC), Color(0xffFFFFFF)],
      glow: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Safe to spend',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: ink),
                ),
              ),
              IconButton(
                tooltip: 'How safe to spend is calculated',
                onPressed: () => _explain(context, summary),
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: secondary,
                ),
              ),
            ],
          ),
          AmountText(
            summary.available,
            animate: true,
            style: Theme.of(context).textTheme.displayLarge
                ?.copyWith(color: ink, fontSize: 43, letterSpacing: -1.5),
          ),
          const SizedBox(height: 8),
          Text(
            summary.complete
                ? 'After planned outgoings · Estimate'
                : 'Review old recurring entries for a reliable estimate.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: secondary),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: dark ? const Color(0xff4C405F) : const Color(0xffD9CFF2),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => openPage(context, const NetWorthScreen()),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total net worth',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: secondary),
                      ),
                    ),
                    AmountText(
                      ledger.netWorth,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(color: ink),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _explain(
    BuildContext context,
    SafeToSpendSummary s,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A considered estimate',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on the records you enter—not a live bank balance. Savings, investments and future-dated income are excluded.',
          ),
          const SizedBox(height: 20),
          _row(context, 'Spendable account balances', s.balance),
          _row(context, 'Upcoming and recorded future outgoings', -s.upcoming),
          _row(context, 'Loans due before period end', -s.loans),
          _row(context, 'Manual goal allocations', -s.goals),
          const Divider(height: 32),
          _row(context, 'Safe to spend', s.available),
          const SizedBox(height: 16),
          Text(
            'Through ${DateFormat.yMMMd().format(s.end.subtract(const Duration(days: 1)))}. Budgets are spending limits, not another deduction. Overlapping commitments may make this estimate conservative. Review your records before making decisions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
  Widget _row(BuildContext context, String label, int amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 16),
        AmountText(amount, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    child: Row(
      children: [
        _action(
          context,
          'Expense',
          Icons.north_east_rounded,
          'expense',
          () => openTransactionSheet(context),
        ),
        _action(
          context,
          'Income',
          Icons.south_west_rounded,
          'income',
          () => openTransactionSheet(context, initialType: 'income'),
        ),
        _action(
          context,
          'Transfer',
          Icons.swap_horiz_rounded,
          'transfer',
          () => openTransactionSheet(context, initialType: 'transfer'),
        ),
        _action(
          context,
          'Budgets',
          Icons.pie_chart_outline_rounded,
          'budget',
          () => openPage(context, const BudgetsScreen()),
        ),
      ],
    ),
  );
  Widget _action(
    BuildContext context,
    String label,
    IconData icon,
    String type,
    VoidCallback onTap,
  ) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            CategoryIcon(
              icon: icon,
              color: switch (type) {
                'income' => AppColors.income,
                'expense' => AppColors.expense,
                'transfer' => AppColors.transfer,
                _ => AppColors.primary,
              },
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class MonthSummaryCard extends StatelessWidget {
  final Ledger ledger;
  const MonthSummaryCard(this.ledger, {super.key});
  @override
  Widget build(BuildContext context) {
    final month = financialMonth(DateTime.now(), ledger.settings.monthStart);
    final income = ledger.total('income', month),
        expense = ledger.total('expense', month);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Income',
                value: AmountText(
                  income,
                  compact: true,
                  style: TextStyle(
                    color: AppColors.semantic(context, 'income'),
                  ),
                ),
                icon: Icons.south_west_rounded,
                color: AppColors.semantic(context, 'income'),
                caption: 'This financial month',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Expenses',
                value: AmountText(
                  expense,
                  compact: true,
                  style: TextStyle(
                    color: AppColors.semantic(context, 'expense'),
                  ),
                ),
                icon: Icons.north_east_rounded,
                color: AppColors.semantic(context, 'expense'),
                caption: 'This financial month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Net balance',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              AmountText(
                income - expense,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.semantic(
                    context,
                    income >= expense ? 'income' : 'expense',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
