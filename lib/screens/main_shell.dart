import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/icons.dart';
import '../core/enum/filter_enums.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/paisa_colors.dart';
import '../data/models/account_model.dart';
import '../data/models/category_budget_stat.dart';
import '../data/models/debt_summary.dart';
import '../providers/paisa_provider.dart';
import '../widgets/avatar_view.dart';

/// The app shell.
///
/// **Step 2 scope:** this is the post-onboarding landing surface. It renders the
/// live financial engine — net balance, period income/expense, budget health and
/// loan totals — so the Step 2 maths is verifiable on device, and it wires the
/// period filter the Step 3 dashboard consumes.
///
/// Steps 3–6 replace the tab bodies with the real Home / Analytics / Debts /
/// Settings screens. The [NavigationBar] shell, provider wiring and shared
/// metric/empty-state widgets here are final.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final List<Widget> tabs = <Widget>[
      _OverviewTab(key: const PageStorageKey<String>('tab-overview')),
      _BudgetsTab(key: const PageStorageKey<String>('tab-budgets')),
      _DebtsTab(key: const PageStorageKey<String>('tab-debts')),
      _ProfileTab(key: const PageStorageKey<String>('tab-profile')),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // IndexedStack keeps every tab alive so scroll position, the selected
        // period filter and expanded rows survive a tab switch.
        child: IndexedStack(
          index: _index,
          children: tabs,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: context.tr('balance'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: const Icon(Icons.pie_chart_rounded),
            label: context.tr('budget'),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: provider.dueSoonDebts.isNotEmpty,
              child: const Icon(Icons.handshake_outlined),
            ),
            selectedIcon: const Icon(Icons.handshake_rounded),
            label: 'Loans',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

/// Avatar + greeting header used by every tab.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaProvider provider = context.watch<PaisaProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: <Widget>[
          PaisaAvatarView(
            key: const ValueKey<String>('header-avatar'),
            avatarIndex: provider.userAvatarIndex,
            imagePath: provider.customImagePath,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Hi, ${provider.greetingName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Period chips bound to `PaisaProvider.selectedTimeFilter`.
class _PeriodChips extends StatelessWidget {
  const _PeriodChips();

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: FilterExpense.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final FilterExpense filter = FilterExpense.values[index];
          return ChoiceChip(
            label: Text(_labelFor(context, filter)),
            selected: filter == provider.selectedTimeFilter,
            onSelected: (_) => provider.setSelectedTimeFilter(filter),
          );
        },
      ),
    );
  }

  static String _labelFor(BuildContext context, FilterExpense filter) {
    switch (filter) {
      case FilterExpense.daily:
        return context.tr('today');
      case FilterExpense.weekly:
        return context.tr('thisWeek');
      case FilterExpense.monthly:
        return context.tr('thisMonth');
      case FilterExpense.yearly:
        return context.tr('thisYear');
      case FilterExpense.all:
        return context.tr('allTime');
    }
  }
}

/// Rounded number card used across the shell.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.caption,
    this.tint,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? tint;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint ?? scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: valueColor,
              ),
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tonal square holding a category icon.
class _TintedIcon extends StatelessWidget {
  const _TintedIcon({
    required this.icon,
    required this.tint,
    this.size = 42,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color tint;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withAlpha(42),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: iconSize, color: tint),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — overview
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final PaisaColors colors = PaisaColors.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        const _GreetingHeader(title: 'Here is your money at a glance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  scheme.primaryContainer,
                  Color.alphaBlend(
                    scheme.tertiaryContainer.withAlpha(160),
                    scheme.primaryContainer,
                  ),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total net balance',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Hide amounts',
                      onPressed: () =>
                          provider.setHideAmounts(!provider.hideAmounts),
                      icon: Icon(
                        provider.hideAmounts
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                Text(
                  provider.formatter.format(provider.totalNetBalance),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.accounts.length} account'
                  '${provider.accounts.length == 1 ? '' : 's'} · '
                  '${provider.formatter.compact(provider.totalAssets)} in · '
                  '${provider.formatter.compact(provider.totalLiabilities)} owed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _PeriodChips(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  label: context.tr('income'),
                  value: provider.formatter.formatWhole(provider.periodIncome),
                  caption: '${provider.periodTransactionCount} entries',
                  tint: colors.incomeContainer,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: context.tr('expense'),
                  value: provider.formatter.formatWhole(provider.periodExpense),
                  caption: provider.periodTransferVolume > 0
                      ? '${provider.formatter.compact(provider.periodTransferVolume)} moved'
                      : 'Transfers excluded',
                  tint: colors.expenseContainer,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MetricCard(
            label: 'Net this period',
            value: provider.formatter.formatSigned(
              provider.periodNet,
              withDecimals: false,
            ),
            valueColor:
                provider.periodNet < 0 ? colors.expense : colors.income,
            caption:
                'Avg ${provider.formatter.formatWhole(provider.averageDailySpend)}/day · '
                '${provider.daysLeftInPeriod()} days left',
            tint: scheme.surfaceContainerHighest,
            icon: Icons.swap_vert_rounded,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Accounts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (provider.accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: _EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              message: 'Add a cash or bank account to start tracking.',
            ),
          )
        else
          for (final AccountModel account in provider.accounts)
            _AccountRow(account: account),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final double balance = provider.accountBalance(account.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: <Widget>[
            _TintedIcon(icon: account.cardType.icon, tint: Color(account.color)),
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
                    account.isDefault
                        ? '${account.cardType.label} · Default'
                        : account.cardType.label,
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — budgets
// ---------------------------------------------------------------------------

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final PaisaColors colors = PaisaColors.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<CategoryBudgetStat> stats = provider.categoryBudgetStats;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        const _GreetingHeader(title: 'This month’s budgets'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  label: context.tr('budget'),
                  value: provider.formatter
                      .formatWhole(provider.totalMonthlyBudget),
                  caption: '${provider.activeBudgets.length} categories',
                  tint: scheme.secondaryContainer,
                  icon: Icons.savings_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: context.tr('remaining'),
                  value: provider.formatter
                      .formatWhole(provider.totalBudgetRemaining),
                  valueColor: provider.totalBudgetRemaining < 0
                      ? colors.expense
                      : null,
                  caption:
                      'Safe ${provider.formatter.formatWhole(provider.safeDailySpend)}/day',
                  tint: provider.totalBudgetRemaining < 0
                      ? colors.expenseContainer
                      : colors.incomeContainer,
                  icon: Icons.today_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: provider.totalBudgetProgress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              color: provider.totalBudgetProgress >= 1
                  ? colors.expense
                  : scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${provider.formatter.formatWhole(provider.totalMonthlySpend)} spent '
            'of ${provider.formatter.formatWhole(provider.totalMonthlyBudget)} · '
            '${provider.daysLeftInMonth} days left this month',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (stats.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: _EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'No budgets yet',
              message: 'Set a monthly budget on a category to see it here.',
            ),
          )
        else
          for (final CategoryBudgetStat stat in stats) _BudgetRow(stat: stat),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.stat});

  final CategoryBudgetStat stat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final Color tint = Color(stat.category.color);
    final Color barColor = stat.isOverBudget
        ? colors.expense
        : stat.progress > 0.85
            ? colors.warning
            : tint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _TintedIcon(
                  icon: ICONS.byCodePoint(stat.category.icon),
                  tint: tint,
                  size: 34,
                  iconSize: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  stat.hasBudget
                      ? provider.formatter.formatWhole(stat.spent)
                      : 'No budget',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: stat.isOverBudget ? colors.expense : scheme.onSurface,
                  ),
                ),
              ],
            ),
            if (stat.hasBudget) ...<Widget>[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stat.progress,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: barColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${provider.formatter.formatWhole(stat.remaining)} left · '
                '${provider.formatter.formatWhole(stat.dailyAllowance)}/day safe',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — loans
// ---------------------------------------------------------------------------

class _DebtsTab extends StatelessWidget {
  const _DebtsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final PaisaColors colors = PaisaColors.of(context);
    final List<DebtSummary> summaries = provider.debtSummaries;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        const _GreetingHeader(title: 'Loans & lendings'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  label: 'You will get',
                  value: provider.formatter.formatWhole(provider.totalLent),
                  caption:
                      '${provider.debtsOfType(DebtType.debt).length} owe you',
                  tint: colors.incomeContainer,
                  icon: Icons.call_made_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'You owe',
                  value: provider.formatter.formatWhole(provider.totalBorrowed),
                  caption:
                      '${provider.debtsOfType(DebtType.credit).length} loans',
                  tint: colors.expenseContainer,
                  icon: Icons.call_received_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (summaries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: _EmptyState(
              icon: Icons.handshake_outlined,
              title: 'No loans tracked',
              message:
                  'Record money you lent or borrowed and MoneyMate keeps the balance straight.',
            ),
          )
        else
          for (final DebtSummary summary in summaries) _DebtRow(summary: summary),
      ],
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.summary});

  final DebtSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final double progress = provider.progressFor(summary.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _TintedIcon(
                  icon: summary.debtType.icon,
                  tint: summary.debtType == DebtType.debt
                      ? colors.debtGiven
                      : colors.debtTaken,
                  size: 34,
                  iconSize: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary.debt.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  provider.formatter.formatWhole(summary.outstandingAmount),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).round()}% settled · '
              '${provider.formatter.formatWhole(summary.paidAmount)} paid · '
              '${summary.daysRemaining() < 0 ? 'overdue' : '${summary.daysRemaining()} days left'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: summary.isOverdue()
                    ? colors.expense
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 4 — profile
// ---------------------------------------------------------------------------

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: <Widget>[
        Center(
          child: PaisaAvatarView(
            avatarIndex: provider.userAvatarIndex,
            imagePath: provider.customImagePath,
            size: 96,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            provider.userName.isEmpty ? 'Your profile' : provider.userName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Center(
          child: Text(
            '${provider.currency.code} · '
            '${AppLanguage.byCode(provider.languageCode).nativeName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SettingRow(
          icon: Icons.dark_mode_outlined,
          title: 'Appearance',
          value: provider.themeMode.label,
        ),
        _SettingRow(
          icon: Icons.palette_outlined,
          title: 'Seed colour',
          value: provider.seedColor.name,
        ),
        _SettingRow(
          icon: Icons.currency_exchange_rounded,
          title: 'Currency',
          value: provider.currency.pickerLabel,
        ),
        _SettingRow(
          icon: Icons.visibility_off_outlined,
          title: 'Hide amounts',
          value: provider.hideAmounts ? 'On' : 'Off',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => provider.updateSettings(
            provider.settings.copyWith(onboardingComplete: false),
          ),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Replay onboarding'),
        ),
        const SizedBox(height: 8),
        Text(
          'Step 2 of 6 · full Settings arrive in Step 6.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
