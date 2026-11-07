import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/theme/paisa_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_format.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/account_card.dart';
import '../../widgets/transaction_tile.dart';
import '../home/home_screen.dart';
import '../transactions/add_transaction_screen.dart';
import 'add_account_screen.dart';

/// Accounts tab — a swipeable carousel of bank/cash cards with the focused
/// account's live totals and full history underneath.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  static const double _viewportFraction = 0.9;

  late final PageController _controller =
      PageController(viewportFraction: _viewportFraction);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the selection valid when an account is added or deleted.
  void _clampIndex(int length) {
    if (length == 0) {
      _index = 0;
      return;
    }
    if (_index > length - 1) {
      _index = length - 1;
      // Jump after the frame so the page view is already laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(_index);
      });
    }
  }

  Future<void> _addAccount() async {
    final AccountModel? created = await openAddAccountScreen(context);
    if (created == null || !mounted) return;
    final int length = context.read<PaisaProvider>().accounts.length;
    final int index = context
        .read<PaisaProvider>()
        .accounts
        .indexWhere((AccountModel a) => a.id == created.id);
    setState(() => _index = index < 0 ? math.max(0, length - 1) : index);
    if (_controller.hasClients) {
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _editAccount(AccountModel account) async {
    final AccountModel? updated =
        await openAddAccountScreen(context, existing: account);
    if (updated == null || !mounted) return;
    final int length = context.read<PaisaProvider>().accounts.length;
    setState(() => _index = _index.clamp(0, math.max(0, length - 1)));
  }

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final CurrencyFormatter formatter = provider.formatter;
    final List<AccountModel> accounts = provider.accounts;

    _clampIndex(accounts.length);

    if (accounts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LedgerEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No accounts yet',
            message:
                'Add a cash wallet, bank account or card to start tracking where '
                'your money lives.',
            action: FilledButton.icon(
              onPressed: _addAccount,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add account'),
            ),
          ),
        ),
      );
    }

    final AccountModel selected = accounts[_index.clamp(0, accounts.length - 1)];
    final _AccountTotals totals = _AccountTotals.of(
      provider.transactions,
      selected.id,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      children: <Widget>[
        // ---------------- Header ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Your accounts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatter.formatWhole(provider.totalNetBalance),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // ---------------- Carousel ----------------
        SizedBox(
          height: AccountCardView.height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: accounts.length,
            onPageChanged: (int index) => setState(() => _index = index),
            itemBuilder: (BuildContext context, int index) {
              final AccountModel account = accounts[index];
              final int count = accounts.length;
              final double sidePadding = index == 0
                  ? 20
                  : index == count - 1
                      ? 20
                      : 6;
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 20 : 6,
                  right: sidePadding,
                ),
                child: AccountCardView(
                  title: account.title,
                  holderName: account.name,
                  maskedNumber: account.carouselNumber,
                  type: account.cardType,
                  style: AccountStyle.forColor(account.color),
                  balanceLabel:
                      formatter.format(provider.accountBalance(account.id)),
                  balanceCaption: switch (account.cardType) {
                    AccountType.cash => 'Cash in hand',
                    AccountType.bank => 'Available balance',
                    AccountType.card => 'Outstanding balance',
                  },
                  balanceNegative: provider.accountBalance(account.id) < 0,
                  isDefault: account.isDefault,
                  hideBalance: provider.hideAmounts,
                  onTap: () => _editAccount(account),
                ),
              );
            },
          ),
        ),

        // ---------------- Dots ----------------
        CarouselDots(
          count: accounts.length,
          index: _index.clamp(0, accounts.length - 1),
          onTap: (int index) {
            setState(() => _index = index);
            _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          },
        ),

        // ---------------- Selected summary ----------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  icon: Icons.south_west_rounded,
                  label: 'Income',
                  amount: formatter.formatWhole(totals.income),
                  caption: totals.incomeCount == 1
                      ? '1 credit'
                      : '${totals.incomeCount} credits',
                  accent: colors.income,
                  background: colors.incomeContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.north_east_rounded,
                  label: 'Expense',
                  amount: formatter.formatWhole(totals.expense),
                  caption: totals.expenseCount == 1
                      ? '1 debit'
                      : '${totals.expenseCount} debits',
                  accent: colors.expense,
                  background: colors.expenseContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _TinyStat(
                  label: 'Opening',
                  value: formatter.formatWhole(selected.initialAmount),
                ),
              ),
              Expanded(
                child: _TinyStat(
                  label: 'Transferred in',
                  value: formatter.formatWhole(totals.transferIn),
                ),
              ),
              Expanded(
                child: _TinyStat(
                  label: 'Transferred out',
                  value: formatter.formatWhole(totals.transferOut),
                ),
              ),
            ],
          ),
        ),

        // ---------------- Quick actions ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openAddTransactionScreen(
                    context,
                    initialAccountId: selected.id,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Transaction'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openAddTransactionScreen(
                    context,
                    initialType: TransactionType.transfer,
                    initialAccountId: selected.id,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Transfer'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Edit account',
                onPressed: () => _editAccount(selected),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
        ),

        // ---------------- History header ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${selected.title} activity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (totals.count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${totals.count}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ---------------- History list ----------------
        _AccountHistory(account: selected),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: _addAccount,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Add another account'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Balances are derived, never stored: opening balance plus every '
            'income, minus every expense, plus transfers in, minus transfers out.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// The selected account's history: income, expense, transfer in and transfer out.
class _AccountHistory extends StatelessWidget {
  const _AccountHistory({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;

    final List<TransactionModel> rows = provider.transactions
        .where((TransactionModel transaction) =>
            transaction.accountId == account.id ||
            transaction.toAccountId == account.id)
        .toList(growable: false);

    if (rows.isEmpty) {
      return const LedgerEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No activity yet',
        message:
            'Transactions paid from, received into or transferred through this '
            'account will appear here.',
      );
    }

    final List<TransactionDayGroup> groups = groupTransactionsByDay(
      rows,
      formatter: formatter,
      locale: provider.locale,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
              child: _AccountRow(
                transaction: transaction,
                accountId: account.id,
              ),
            ),
        ],
      ],
    );
  }
}

/// A history row that makes the direction explicit for transfers.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.transaction, required this.accountId});

  final TransactionModel transaction;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;

    if (transaction.type != TransactionType.transfer) {
      return TransactionTile(
        transaction: transaction,
        formatter: formatter,
        category: provider.categoryById(transaction.categoryId),
        account: provider.accountById(transaction.accountId),
        hideAmounts: provider.hideAmounts,
        onTap: () => openAddTransactionScreen(context, existing: transaction),
        onDelete: () => deleteTransactionWithUndo(context, transaction),
      );
    }

    final bool incoming = transaction.toAccountId == accountId;
    final AccountModel? source = provider.accountById(transaction.accountId);
    final AccountModel? destination =
        provider.accountById(transaction.toAccountId);
    final ThemeData theme = Theme.of(context);
    final Color transferColor = PaisaColors.of(context).transfer;

    return Dismissible(
      key: ValueKey<String>('account-tx-${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await deleteTransactionWithUndo(context, transaction);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: PaisaColors.of(context).expenseContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: PaisaColors.of(context).expense,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openAddTransactionScreen(context, existing: transaction),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: transferColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    incoming
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    size: 22,
                    color: transferColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        incoming
                            ? 'Transfer in from ${source?.title ?? 'account'}'
                            : 'Transfer out to ${destination?.title ?? 'account'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${transaction.name} • '
                        '${DateTimeFormat.time(transaction.time, locale: provider.locale)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  provider.hideAmounts
                      ? CurrencyFormatter.maskedAmount
                      : '${incoming ? '+' : '−'}${formatter.formatWhole(transaction.amount)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: transferColor,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two tonal summary cards under the carousel.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.caption,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String amount;
  final String caption;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Text(
            caption,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Income / expense / transfer totals for one account.
@immutable
class _AccountTotals {
  const _AccountTotals({
    required this.income,
    required this.expense,
    required this.transferIn,
    required this.transferOut,
    required this.incomeCount,
    required this.expenseCount,
    required this.count,
  });

  final double income;
  final double expense;
  final double transferIn;
  final double transferOut;
  final int incomeCount;
  final int expenseCount;
  final int count;

  /// Linked debt installments are part of the balance but are reported on the
  /// Loans tab, so they are excluded from the account's income/expense totals to
  /// avoid a repayment showing up twice.
  static _AccountTotals of(List<TransactionModel> source, String accountId) {
    double income = 0;
    double expense = 0;
    double transferIn = 0;
    double transferOut = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    int count = 0;

    for (final TransactionModel transaction in source) {
      final bool touches = transaction.accountId == accountId ||
          transaction.toAccountId == accountId;
      if (!touches) continue;
      count++;
      if (PaisaProvider.isLinkedDebtTransaction(transaction)) continue;

      switch (transaction.type) {
        case TransactionType.income:
          if (transaction.accountId == accountId) {
            income += transaction.amount;
            incomeCount++;
          }
        case TransactionType.expense:
          if (transaction.accountId == accountId) {
            expense += transaction.amount;
            expenseCount++;
          }
        case TransactionType.transfer:
          if (transaction.accountId == accountId) transferOut += transaction.amount;
          if (transaction.toAccountId == accountId) transferIn += transaction.amount;
      }
    }

    return _AccountTotals(
      income: income,
      expense: expense,
      transferIn: transferIn,
      transferOut: transferOut,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      count: count,
    );
  }
}
