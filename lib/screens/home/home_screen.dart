import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_format.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/period_summary.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_transaction_screen.dart';

/// The dashboard.
///
/// * [BalanceHeroCard] — total net balance + this period's income/expense.
/// * [PeriodFilterChips] — Daily / Weekly / Monthly / Yearly / All.
/// * A chronologically grouped ledger: `Today`, `Yesterday`, then `07 Nov 2026`,
///   each with its net daily total and swipe-to-delete rows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// App bar is owned by `MainShell`; this screen only renders content.
  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;

    final List<TransactionModel> periodTransactions = provider
        .transactionsInPeriod()
        .where((TransactionModel t) => !PaisaProvider.isLinkedDebtTransaction(t))
        .toList(growable: false);

    final List<TransactionDayGroup> groups = groupTransactionsByDay(
      periodTransactions,
      formatter: formatter,
    );

    return RefreshIndicator(
      onRefresh: () async => provider.refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          // ---------------- Hero ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: BalanceHeroCard(
              totalBalance: provider.totalNetBalance,
              periodIncome: provider.periodIncome,
              periodExpense: provider.periodExpense,
              incomeCount: periodTransactions
                  .where((TransactionModel t) => t.isIncome)
                  .length,
              expenseCount: periodTransactions
                  .where((TransactionModel t) => t.isExpense)
                  .length,
              formatter: formatter,
              hideAmounts: provider.hideAmounts,
              periodLabel: periodLabelFor(provider.selectedTimeFilter),
              onTogglePrivacy: () =>
                  provider.setHideAmounts(!provider.hideAmounts),
              footer: _BudgetHint(provider: provider),
            ),
          ),

          const SizedBox(height: 16),

          // ---------------- Filters ----------------
          PeriodFilterChips(
            selected: provider.selectedTimeFilter,
            onSelected: provider.setSelectedTimeFilter,
          ),
          const SizedBox(height: 8),

          // ---------------- Section title ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: <Widget>[
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${periodTransactions.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                if (provider.periodTransferVolume > 0)
                  Text(
                    '${formatter.compact(provider.periodTransferVolume)} moved',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PaisaColors.of(context).transfer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),

          // ---------------- Ledger ----------------
          if (groups.isEmpty)
            LedgerEmptyState(
              icon: Icons.receipt_long_outlined,
              title: provider.selectedTimeFilter == FilterExpense.monthly
                  ? 'Nothing this month yet'
                  : 'No transactions in this period',
              message:
                  'Tap the + button to record your first expense, income or transfer.',
              action: FilledButton.icon(
                onPressed: () => openAddTransactionScreen(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add transaction'),
              ),
            )
          else
            for (final TransactionDayGroup group in groups)
              _DaySection(group: group),
        ],
      ),
    );
  }
}

/// A small nudge inside the hero card: how much is left to spend today.
class _BudgetHint extends StatelessWidget {
  const _BudgetHint({required this.provider});

  final PaisaProvider provider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final double budget = provider.totalMonthlyBudget;

    if (budget <= 0) {
      return Row(
        children: <Widget>[
          Icon(
            Icons.tips_and_updates_outlined,
            size: 15,
            color: scheme.onPrimaryContainer.withAlpha(190),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Set a monthly budget to see a daily safe-to-spend figure.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer.withAlpha(190),
              ),
            ),
          ),
        ],
      );
    }

    final double remaining = provider.totalBudgetRemaining;
    final Color accent = remaining < 0 ? colors.expense : scheme.onPrimaryContainer;

    return Row(
      children: <Widget>[
        Icon(Icons.savings_outlined, size: 15, color: accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            remaining < 0
                ? 'Over budget by ${provider.formatter.formatWhole(remaining.abs())} this month'
                : '${provider.formatter.formatWhole(provider.safeDailySpend)} / day safe to spend · '
                    '${provider.daysLeftInMonth} days left',
            style: theme.textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// One day header plus its rows.
class _DaySection extends StatelessWidget {
  const _DaySection({required this.group});

  final TransactionDayGroup group;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TransactionDayHeader(
            label: group.label,
            net: group.net,
            formatter: formatter,
            transactionCount: group.transactions.length,
            hideAmounts: provider.hideAmounts,
          ),
        ),
        for (final TransactionModel transaction in group.transactions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TransactionTile(
              transaction: transaction,
              formatter: formatter,
              category: provider.categoryById(transaction.categoryId),
              account: provider.accountById(transaction.accountId),
              toAccount: provider.accountById(transaction.toAccountId),
              hideAmounts: provider.hideAmounts,
              onTap: () => openAddTransactionScreen(
                context,
                existing: transaction,
              ),
              onDelete: () => deleteTransactionWithUndo(context, transaction),
            ),
          ),
      ],
    );
  }
}

/// Deletes [transaction] and offers an Undo action for as long as the snack bar
/// is visible. Restoring re-saves the exact same model (same id, same time), so
/// balances and ordering come back unchanged.
Future<void> deleteTransactionWithUndo(
  BuildContext context,
  TransactionModel transaction,
) async {
  final PaisaProvider provider = context.read<PaisaProvider>();
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  await provider.deleteTransaction(transaction.id);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('“${transaction.name}” deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.addTransaction(transaction),
        ),
      ),
    );
}

/// A day bucket in the grouped ledger.
@immutable
class TransactionDayGroup {
  const TransactionDayGroup({
    required this.date,
    required this.label,
    required this.transactions,
    required this.net,
  });

  final DateTime date;
  final String label;
  final List<TransactionModel> transactions;

  /// Income − expense for the day. Transfers are net zero for the total and are
  /// therefore excluded.
  final double net;
}

/// Groups [transactions] by calendar day, newest day first, newest entry first
/// inside each day, and labels the buckets `Today` / `Yesterday` / `07 Nov 2026`.
List<TransactionDayGroup> groupTransactionsByDay(
  List<TransactionModel> transactions, {
  required CurrencyFormatter formatter,
  DateTime? now,
  String locale = 'en_IN',
}) {
  final DateTime reference = now ?? DateTime.now();
  final Map<DateTime, List<TransactionModel>> buckets =
      <DateTime, List<TransactionModel>>{};

  for (final TransactionModel transaction in transactions) {
    final DateTime day = DateTimeFormat.dayOnly(transaction.time);
    buckets.putIfAbsent(day, () => <TransactionModel>[]).add(transaction);
  }

  final List<DateTime> days = buckets.keys.toList(growable: true)
    ..sort((DateTime a, DateTime b) => b.compareTo(a));

  final List<TransactionDayGroup> groups = <TransactionDayGroup>[];
  for (final DateTime day in days) {
    final List<TransactionModel> items = buckets[day]!
      ..sort((TransactionModel a, TransactionModel b) {
        final int byTime = b.time.compareTo(a.time);
        if (byTime != 0) return byTime;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    double net = 0;
    for (final TransactionModel item in items) {
      if (item.isIncome) net += item.amount;
      if (item.isExpense) net -= item.amount;
    }

    groups.add(
      TransactionDayGroup(
        date: day,
        label: DateTimeFormat.relativeDay(
          day,
          now: reference,
          locale: locale,
        ),
        transactions: items,
        net: net,
      ),
    );
  }
  return groups;
}

/// The list body used by account statements — same grouping, no hero card.
class GroupedTransactionList extends StatelessWidget {
  const GroupedTransactionList({
    super.key,
    required this.transactions,
    this.onTapTransaction,
    this.emptyTitle = 'No transactions yet',
    this.emptyMessage = 'Transactions for this account will appear here.',
    this.header,
  });

  final List<TransactionModel> transactions;
  final ValueChanged<TransactionModel>? onTapTransaction;
  final String emptyTitle;
  final String emptyMessage;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;
    final List<TransactionDayGroup> groups = groupTransactionsByDay(
      transactions,
      formatter: formatter,
      locale: provider.locale,
    );

    if (groups.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8),
        children: <Widget>[
          if (header != null) header!,
          LedgerEmptyState(
            icon: Icons.receipt_long_outlined,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        if (header != null) header!,
        for (final TransactionDayGroup group in groups) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TransactionDayHeader(
              label: group.label,
              net: group.net,
              formatter: formatter,
              transactionCount: group.transactions.length,
              hideAmounts: provider.hideAmounts,
            ),
          ),
          for (final TransactionModel transaction in group.transactions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TransactionTile(
                transaction: transaction,
                formatter: formatter,
                category: provider.categoryById(transaction.categoryId),
                account: provider.accountById(transaction.accountId),
                toAccount: provider.accountById(transaction.toAccountId),
                hideAmounts: provider.hideAmounts,
                onTap: onTapTransaction == null
                    ? null
                    : () => onTapTransaction!(transaction),
                onDelete: () => deleteTransactionWithUndo(context, transaction),
              ),
            ),
        ],
      ],
    );
  }
}

