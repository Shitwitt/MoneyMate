import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../home/home_screen.dart';
import '../transactions/add_transaction_screen.dart';

/// The Accounts tab: a horizontal carousel of account cards plus per-account
/// statements.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<AccountModel> accounts = provider.accounts;

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: <Widget>[
              Text(
                'Your accounts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${accounts.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (accounts.isEmpty)
          LedgerEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No accounts yet',
            message:
                'Accounts arrive with onboarding. If you skipped it, add one here to start tracking.',
            action: FilledButton.icon(
              onPressed: () => _showAddAccountSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add account'),
            ),
          )
        else ...<Widget>[
          SizedBox(
            height: 172,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.86),
              padEnds: false,
              itemCount: accounts.length,
              itemBuilder: (BuildContext context, int index) {
                final AccountModel account = accounts[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 20 : 8,
                    right: 8,
                  ),
                  child: _AccountCarouselCard(
                    account: account,
                    balance: provider.accountBalance(account.id),
                    formatter: provider.formatter,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => _showAddAccountSheet(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add account'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => openAddTransactionScreen(context),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Transfer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Statements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final AccountModel account in accounts)
            _AccountStatementTile(
              account: account,
              balance: provider.accountBalance(account.id),
            ),
        ],
      ],
    );
  }
}

class _AccountCarouselCard extends StatelessWidget {
  const _AccountCarouselCard({
    required this.account,
    required this.balance,
    required this.formatter,
  });

  final AccountModel account;
  final double balance;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = Color(account.color);
    final bool isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              AccountStatementScreen(accountId: account.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                tint.withAlpha(isDark ? 90 : 220),
                isDark ? const Color(0xFF141414) : tint,
              ),
              Color.alphaBlend(
                tint.withAlpha(isDark ? 40 : 130),
                isDark ? const Color(0xFF0C0C0C) : tint,
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    account.cardType.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    account.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (account.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Default',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              account.maskedNumber,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.75),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatter.format(balance),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${account.cardType.label} · ${account.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatementTile extends StatelessWidget {
  const _AccountStatementTile({required this.account, required this.balance});

  final AccountModel account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final PaisaColors colors = PaisaColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                AccountStatementScreen(accountId: account.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color(account.color).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  account.cardType.icon,
                  size: 20,
                  color: Color(account.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      account.number.isEmpty
                          ? account.cardType.label
                          : '${account.cardType.label} · •••• ${account.number}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                provider.formatter.format(balance),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: balance < 0 ? colors.expense : scheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One account's transaction statement.
class AccountStatementScreen extends StatelessWidget {
  const AccountStatementScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final AccountModel? account = provider.accountById(accountId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const LedgerEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Account deleted',
          message: 'This account no longer exists.',
        ),
      );
    }

    final List<TransactionModel> transactions = provider.transactions
        .where((TransactionModel t) =>
            t.accountId == accountId || t.toAccountId == accountId)
        .toList(growable: false);

    final double balance = provider.accountBalance(accountId);
    final double inflow = transactions.fold<double>(
      0,
      (double sum, TransactionModel t) =>
          sum + math.max(0, t.deltaForAccount(accountId) ?? 0),
    );
    final double outflow = transactions.fold<double>(
      0,
      (double sum, TransactionModel t) =>
          sum + math.max(0, -(t.deltaForAccount(accountId) ?? 0)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(account.title)),
      body: GroupedTransactionList(
        transactions: transactions,
        onTapTransaction: (TransactionModel transaction) =>
            openAddTransactionScreen(context, existing: transaction),
        emptyTitle: 'No activity yet',
        emptyMessage: 'Transactions on ${account.title} will appear here.',
        header: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: _StatementHeader(
            account: account,
            balance: balance,
            inflow: inflow,
            outflow: outflow,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddTransactionScreen(
          context,
          initialAccountId: accountId,
        ),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _StatementHeader extends StatelessWidget {
  const _StatementHeader({
    required this.account,
    required this.balance,
    required this.inflow,
    required this.outflow,
  });

  final AccountModel account;
  final double balance;
  final double inflow;
  final double outflow;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final CurrencyFormatter formatter = context.watch<PaisaProvider>().formatter;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Current balance',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            formatter.format(balance),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: balance < 0 ? colors.expense : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  label: 'Money in',
                  value: formatter.formatWhole(inflow),
                  color: colors.income,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Money out',
                  value: formatter.formatWhole(outflow),
                  color: colors.expense,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Opening',
                  value: formatter.formatWhole(account.initialAmount),
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimal but complete "add account" sheet (Step 4 expands this into the full
/// account manager with editing, colours and default selection).
Future<void> _showAddAccountSheet(BuildContext context) async {
  final PaisaProvider provider = context.read<PaisaProvider>();
  final TextEditingController holder = TextEditingController(
    text: provider.userName,
  );
  final TextEditingController title = TextEditingController();
  final TextEditingController opening = TextEditingController();
  final TextEditingController last4 = TextEditingController();
  AccountType type = AccountType.bank;
  int color = 0xFF1E88E5;

  const List<int> palette = <int>[
    0xFF43A047,
    0xFF1E88E5,
    0xFF8E24AA,
    0xFFF4511E,
    0xFF00897B,
    0xFF3949AB,
  ];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final ThemeData theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'Add account',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SegmentedButton<AccountType>(
                  segments: <ButtonSegment<AccountType>>[
                    for (final AccountType value in AccountType.values)
                      ButtonSegment<AccountType>(
                        value: value,
                        label: Text(value.label),
                        icon: Icon(value.icon, size: 16),
                      ),
                  ],
                  selected: <AccountType>{type},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<AccountType> selection) =>
                      setState(() => type = selection.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Account name',
                    hintText: 'e.g. HDFC Savings',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: holder,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Holder name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: opening,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Opening balance',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 116,
                      child: TextField(
                        controller: last4,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: 'Last 4',
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    children: <Widget>[
                      for (final int option in palette)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => color = option),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(option),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: option == color
                                    ? theme.colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final String name = title.text.trim();
                    if (name.isEmpty) return;
                    final double amount =
                        provider.formatter.parse(opening.text) ?? 0;
                    await provider.addAccount(
                      AccountModel(
                        id: 'account-${DateTime.now().microsecondsSinceEpoch}',
                        name: holder.text.trim().isEmpty
                            ? 'Me'
                            : holder.text.trim(),
                        bankName: name,
                        number: last4.text.trim(),
                        cardType: type,
                        initialAmount: amount,
                        color: color,
                        isDefault: provider.accounts.isEmpty,
                      ),
                    );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Add account'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  holder.dispose();
  title.dispose();
  opening.dispose();
  last4.dispose();
}
