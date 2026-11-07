import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/paisa_provider.dart';

/// Top-level app root. It connects the provider, dynamic Material theme,
/// localization, onboarding, and the working main shell.
class PaisaAppRoot extends StatelessWidget {
  const PaisaAppRoot({
    super.key,
    required this.provider,
    required this.themeEngine,
  });

  final PaisaProvider provider;
  final PaisaThemeEngine themeEngine;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaisaProvider>.value(
      value: provider,
      child: PaisaThemeBuilder(
        engine: themeEngine,
        builder: (
          BuildContext context,
          ThemeData lightTheme,
          ThemeData darkTheme,
          ThemeMode themeMode,
        ) {
          final PaisaProvider state = context.watch<PaisaProvider>();
          return MaterialApp(
            title: 'Paisa',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            locale: state.materialLocale,
            supportedLocales: PaisaLanguages.supportedLocales,
            localizationsDelegates:
                const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            home: state.isInitialized
                ? state.isOnboardingComplete
                    ? const PaisaMainShell()
                    : const PaisaOnboardingScreen()
                : const _PaisaSplashScreen(),
          );
        },
      ),
    );
  }
}

class _PaisaSplashScreen extends StatelessWidget {
  const _PaisaSplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PaisaLogo(size: 96),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing your wallet…'),
          ],
        ),
      ),
    );
  }
}

ThemeData _warmLightTheme(BuildContext context) {
  final ThemeData base = Theme.of(context);
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: PaisaSeedPalette.defaultColor.color,
    brightness: Brightness.light,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFFFF8F3),
    canvasColor: const Color(0xFFFFF8F3),
    cardColor: scheme.surfaceContainerLow,
    dialogBackgroundColor: scheme.surfaceContainerHighest,
    shadowColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFFFF8F3),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFFCEDE5),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: MaterialStateProperty.all<TextStyle?>(
        base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

ThemeData _darkOnboardingTheme(BuildContext context) {
  final ThemeData base = Theme.of(context);
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFBB69D),
    brightness: Brightness.dark,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF1A1014),
    canvasColor: const Color(0xFF1A1014),
    cardColor: scheme.surfaceContainerLow,
    dialogBackgroundColor: scheme.surfaceContainerHighest,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
  );
}

// ---------------------------------------------------------------------------
// Working main shell
// ---------------------------------------------------------------------------

class PaisaMainShell extends StatefulWidget {
  const PaisaMainShell({super.key});

  @override
  State<PaisaMainShell> createState() => _PaisaMainShellState();
}

class _PaisaMainShellState extends State<PaisaMainShell> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Home',
    'Accounts',
    'Budgets',
    'Debts',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _warmLightTheme(context),
      child: Consumer<PaisaProvider>(
        builder: (
          BuildContext context,
          PaisaProvider provider,
          Widget? _,
        ) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_titles[_selectedIndex]),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PaisaAvatar(
                    index: provider.userAvatarIndex,
                    customImagePath: provider.customImagePath,
                    size: 38,
                  ),
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: const <Widget>[
                _HomeDashboard(),
                _AccountsTab(),
                _BudgetsTab(),
                _DebtsTab(),
                _SettingsTab(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Accounts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: 'Budgets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_outlined),
                  selectedIcon: Icon(Icons.account_balance),
                  label: 'Debts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaisaProvider>(
      builder: (BuildContext context, PaisaProvider provider, Widget? _) {
        final PaisaPeriodSummary summary = provider.periodSummary();
        final PaisaPeriodSummary previous = provider.previousPeriodSummary();
        final List<PaisaCategoryBudgetInsight> budgets = provider.budgetInsights;
        final PaisaCategoryBudgetInsight? featuredBudget =
            budgets.isEmpty ? null : budgets.first;
        return Stack(
          children: <Widget>[
            const _ShellBackground(image: 'assets/onboarding/step2.jpg'),
            RefreshIndicator(
              onRefresh: () async => provider.initialize(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: <Widget>[
                  _HeroCard(
                    provider: provider,
                    summary: summary,
                    previous: previous,
                  ),
                  const SizedBox(height: 16),
                  _PeriodFilterChips(provider: provider),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          label: 'Income',
                          value: provider.format(summary.income),
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFF2E7D32),
                          surface: const Color(0xFFDFEEE0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'Expense',
                          value: provider.format(summary.expense),
                          icon: Icons.arrow_upward_rounded,
                          color: const Color(0xFFB04A3A),
                          surface: const Color(0xFFF8D9D3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (featuredBudget != null)
                    _BudgetHighlightCard(
                      provider: provider,
                      insight: featuredBudget,
                    ),
                  const SizedBox(height: 16),
                  _SectionHeading(
                    title: 'Accounts',
                    action: '${provider.accounts.length} active',
                  ),
                  ...provider.accounts.map(
                    (AccountModel account) => _AccountBalanceCard(
                      provider: provider,
                      account: account,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionHeading(
                    title: 'Recent activity',
                    action: '${provider.recentTransactions().length} entries',
                  ),
                  ...provider.recentTransactions().map(
                    (TransactionModel tx) => _TransactionTile(
                      provider: provider,
                      transaction: tx,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.provider,
    required this.summary,
    required this.previous,
  });

  final PaisaProvider provider;
  final PaisaPeriodSummary summary;
  final PaisaPeriodSummary previous;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double incomeDelta =
        previous.income == 0 ? 0 : (summary.income - previous.income) / previous.income;
    final double expenseDelta =
        previous.expense == 0 ? 0 : (summary.expense - previous.expense) / previous.expense;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF1E7),
            Color(0xFFFBE0D5),
            Color(0xFFF7E8DF),
          ],
        ),
        border: Border.all(color: const Color(0xFFF2D5C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Total balance',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF6E4A3F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                provider.selectedTimeFilterLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF8C6152),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              provider.totalNetBalanceFormatted,
              style: theme.textTheme.displaySmall?.copyWith(
                color: const Color(0xFF3B2A24),
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroMetric(
                  label: 'Income',
                  value: provider.format(summary.income),
                  previous: provider.format(previous.income),
                  delta: incomeDelta,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Expense',
                  value: provider.format(summary.expense),
                  previous: provider.format(previous.expense),
                  delta: expenseDelta,
                  color: const Color(0xFFB04A3A),
                  invertDeltaColor: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF8C6152)),
              const SizedBox(width: 6),
              Text(
                'Transfers excluded from income and expense · ${provider.format(summary.transferTotal)} moved',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8C6152),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.previous,
    required this.delta,
    required this.color,
    this.invertDeltaColor = false,
  });

  final String label;
  final String value;
  final String previous;
  final double delta;
  final Color color;
  final bool invertDeltaColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool good = invertDeltaColor ? delta <= 0 : delta >= 0;
    final Color deltaColor = good ? const Color(0xFF2E7D32) : const Color(0xFFB04A3A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF8C6152))),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${delta >= 0 ? '+' : ''}${CurrencyFormatter.percent(delta)} vs $previous',
          style: theme.textTheme.bodySmall?.copyWith(
            color: deltaColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PeriodFilterChips extends StatelessWidget {
  const _PeriodFilterChips({required this.provider});

  final PaisaProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FilterExpense.values.map((FilterExpense filter) {
        return ChoiceChip(
          label: Text(PaisaProvider.filterLabel(filter)),
          selected: provider.selectedTimeFilter == filter,
          onSelected: (_) {
            provider.setSelectedTimeFilter(filter);
          },
          showCheckmark: false,
          backgroundColor: const Color(0xFFF7E8DF),
          selectedColor: const Color(0xFFFBB69D),
          labelStyle: TextStyle(
            color: provider.selectedTimeFilter == filter
                ? const Color(0xFF3B2A24)
                : const Color(0xFF7A5346),
            fontWeight: FontWeight.w700,
          ),
          shape: const StadiumBorder(),
          side: BorderSide.none,
        );
      }).toList(growable: false),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surface,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.65),
            foregroundColor: color,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetHighlightCard extends StatelessWidget {
  const _BudgetHighlightCard({
    required this.provider,
    required this.insight,
  });

  final PaisaProvider provider;
  final PaisaCategoryBudgetInsight insight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E2D9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: insight.category.colorValue.withOpacity(0.28),
                foregroundColor: insight.category.colorValue,
                child: Icon(insight.category.iconData, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${insight.category.name} Budget',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A3128),
                  ),
                ),
              ),
              Text(
                '${CurrencyFormatter.percent(insight.percentUsed)} used',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF7A5346),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: insight.clampedPercent,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.65),
              valueColor: AlwaysStoppedAnimation<Color>(
                insight.isOverBudget ? const Color(0xFFB04A3A) : const Color(0xFFC97B54),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _BudgetStat(
                  label: 'Budget',
                  value: provider.format(insight.budget),
                ),
              ),
              Expanded(
                child: _BudgetStat(
                  label: 'Spent',
                  value: provider.format(insight.spend),
                ),
              ),
              Expanded(
                child: _BudgetStat(
                  label: 'Remaining',
                  value: provider.format(insight.remainingBudget),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Safe daily spend: ${provider.format(insight.dailyAllowance)} for ${insight.daysLeftInMonth} days left',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF7A5346),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  const _BudgetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF8C6152))),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF4A3128),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            action,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8C6152),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBalanceCard extends StatelessWidget {
  const _AccountBalanceCard({
    required this.provider,
    required this.account,
  });

  final PaisaProvider provider;
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: account.colorValue.withOpacity(0.22),
          foregroundColor: account.colorValue,
          child: Icon(
            account.isCard
                ? Icons.credit_card
                : account.isCash
                    ? Icons.wallet
                    : Icons.account_balance,
          ),
        ),
        title: Text(account.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text('${account.bankName} · ${account.maskedNumber}'),
        trailing: Text(
          provider.accountBalanceFormatted(account.id),
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF4A3128),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.provider,
    required this.transaction,
  });

  final PaisaProvider provider;
  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CategoryModel? category = transaction.categoryId == null
        ? null
        : provider.categoryById(transaction.categoryId!);
    final Color color = transaction.isIncome
        ? const Color(0xFF2E7D32)
        : transaction.isExpense
            ? const Color(0xFFB04A3A)
            : const Color(0xFF5C6BC0);
    final IconData icon = transaction.isIncome
        ? Icons.arrow_downward_rounded
        : transaction.isExpense
            ? Icons.arrow_upward_rounded
            : Icons.swap_horiz_rounded;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (category?.colorValue ?? color).withOpacity(0.18),
          foregroundColor: category?.colorValue ?? color,
          child: Icon(category?.iconData ?? icon, size: 20),
        ),
        title: Text(transaction.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${transaction.time.day}/${transaction.time.month}/${transaction.time.year} · ${transaction.type.label}',
        ),
        trailing: Text(
          provider.format(transaction.signedAmount, showPlusSign: true),
          style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ShellBackground extends StatelessWidget {
  const _ShellBackground({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.055,
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}

class _AccountsTab extends StatelessWidget {
  const _AccountsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaisaProvider>(
      builder: (BuildContext context, PaisaProvider provider, Widget? _) {
        return Stack(
          children: <Widget>[
            const _ShellBackground(image: 'assets/onboarding/step3.jpg'),
            ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _TotalCard(
                  label: 'Net balance across accounts',
                  value: provider.totalNetBalanceFormatted,
                  compact: provider.totalNetBalanceCompact,
                ),
                const SizedBox(height: 16),
                ...provider.accounts.map(
                  (AccountModel account) => _AccountBalanceCard(
                    provider: provider,
                    account: account,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final String compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E2D9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF7A5346))),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Chart axis: $compact', style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF8C6152))),
        ],
      ),
    );
  }
}

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaisaProvider>(
      builder: (BuildContext context, PaisaProvider provider, Widget? _) {
        return Stack(
          children: <Widget>[
            const _ShellBackground(image: 'assets/onboarding/step4.jpg'),
            ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _TotalCard(
                  label: 'Monthly budget',
                  value: provider.format(provider.totalMonthlyBudget),
                  compact: provider.formatCompact(provider.totalMonthlyBudget),
                ),
                const SizedBox(height: 12),
                Text(
                  'Spent ${provider.format(provider.totalMonthlyBudgetSpend)} · Remaining ${provider.format(provider.totalRemainingBudget)} · Daily ${provider.format(provider.totalDailyAllowance)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ...provider.budgetInsights.map(
                  (PaisaCategoryBudgetInsight insight) => _BudgetListCard(
                    provider: provider,
                    insight: insight,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BudgetListCard extends StatelessWidget {
  const _BudgetListCard({
    required this.provider,
    required this.insight,
  });

  final PaisaProvider provider;
  final PaisaCategoryBudgetInsight insight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: insight.category.colorValue.withOpacity(0.2),
                  foregroundColor: insight.category.colorValue,
                  child: Icon(insight.category.iconData, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.category.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  CurrencyFormatter.percent(insight.percentUsed),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: insight.clampedPercent,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: const Color(0xFFF0DED4),
              valueColor: AlwaysStoppedAnimation<Color>(
                insight.isOverBudget ? const Color(0xFFB04A3A) : const Color(0xFFC97B54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: Text('Spent ${provider.format(insight.spend)}')),
                Expanded(child: Text('Left ${provider.format(insight.remainingBudget)}')),
                Expanded(child: Text('Daily ${provider.format(insight.dailyAllowance)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtsTab extends StatelessWidget {
  const _DebtsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaisaProvider>(
      builder: (BuildContext context, PaisaProvider provider, Widget? _) {
        return Stack(
          children: <Widget>[
            const _ShellBackground(image: 'assets/onboarding/step6.jpg'),
            ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        label: 'Lent out',
                        value: provider.format(provider.totalOutstandingLent),
                        icon: Icons.call_made_rounded,
                        color: const Color(0xFF2E7D32),
                        surface: const Color(0xFFDFEEE0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Borrowed',
                        value: provider.format(provider.totalOutstandingBorrowed),
                        icon: Icons.call_received_rounded,
                        color: const Color(0xFFB04A3A),
                        surface: const Color(0xFFF8D9D3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...provider.debtInsights.map(
                  (PaisaDebtInsight insight) => _DebtCard(
                    provider: provider,
                    insight: insight,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.provider,
    required this.insight,
  });

  final PaisaProvider provider;
  final PaisaDebtInsight insight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: insight.isLent
                      ? const Color(0xFFDFEEE0)
                      : const Color(0xFFF8D9D3),
                  foregroundColor: insight.isLent
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFB04A3A),
                  child: Icon(insight.isLent ? Icons.call_made : Icons.call_received),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.debt.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  insight.debt.debtType.label,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: insight.progressPercentage,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: const Color(0xFFF0DED4),
              valueColor: AlwaysStoppedAnimation<Color>(
                insight.isLent ? const Color(0xFF2E7D32) : const Color(0xFFC97B54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: Text('Paid ${provider.format(insight.paidAmount)}')),
                Expanded(child: Text('Left ${provider.format(insight.remainingAmount)}')),
                Expanded(child: Text('${CurrencyFormatter.percent(insight.progressPercentage)} done')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Due ${insight.debt.expiryDateTime.day}/${insight.debt.expiryDateTime.month}/${insight.debt.expiryDateTime.year}',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF8C6152)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  Future<void> _pickImage(BuildContext context, PaisaProvider provider) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final String? path = result?.files.single.path;
    if (path == null || !File(path).existsSync()) return;
    await provider.setCustomImagePath(path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaisaProvider>(
      builder: (BuildContext context, PaisaProvider provider, Widget? _) {
        final ThemeData theme = Theme.of(context);
        return Stack(
          children: <Widget>[
            const _ShellBackground(image: 'assets/onboarding/step9.jpg'),
            ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: ListTile(
                    leading: PaisaAvatar(
                      index: provider.userAvatarIndex,
                      customImagePath: provider.customImagePath,
                      size: 52,
                    ),
                    title: Text(
                      provider.userName.isEmpty ? 'Paisa user' : provider.userName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${provider.currencySymbol} ${provider.currencyCode} · ${provider.language.nativeName}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: () => _pickImage(context, provider),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaisaLanguage>(
                  value: provider.language,
                  decoration: const InputDecoration(labelText: 'Language', prefixIcon: Icon(Icons.language)),
                  items: PaisaLanguages.all
                      .map(
                        (PaisaLanguage language) => DropdownMenuItem<PaisaLanguage>(
                          value: language,
                          child: Text('${language.flag} ${language.nativeName}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (PaisaLanguage? value) {
                    if (value != null) {
                      provider.setLanguage(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CurrencyMeta>(
                  value: provider.currencyMeta,
                  decoration: const InputDecoration(labelText: 'Currency', prefixIcon: Icon(Icons.currency_exchange)),
                  items: CurrencyFormatter.currencies
                      .map(
                        (CurrencyMeta meta) => DropdownMenuItem<CurrencyMeta>(
                          value: meta,
                          child: Text('${meta.displayLabel} · ${meta.name}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (CurrencyMeta? value) {
                    if (value != null) {
                      provider.setCurrency(value.code);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaisaThemeMode>(
                  value: provider.themeMode,
                  decoration: const InputDecoration(labelText: 'Theme', prefixIcon: Icon(Icons.palette_outlined)),
                  items: PaisaThemeMode.values
                      .map(
                        (PaisaThemeMode mode) => DropdownMenuItem<PaisaThemeMode>(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (PaisaThemeMode? value) {
                    if (value != null) {
                      provider.setThemeMode(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: provider.seedColor.value,
                  decoration: const InputDecoration(labelText: 'Seed color', prefixIcon: Icon(Icons.color_lens_outlined)),
                  items: PaisaSeedPalette.colors
                      .map(
                        (PaisaSeedColor color) => DropdownMenuItem<int>(
                          value: color.value,
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(radius: 9, backgroundColor: color.color),
                              const SizedBox(width: 10),
                              Text(color.name),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (int? value) {
                    if (value != null) {
                      provider.setSeedColor(Color(value));
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Dynamic Color'),
                  subtitle: const Text('Use Material You color on Android 12+'),
                  value: provider.useDynamicColor,
                  onChanged: (bool value) {
                    provider.setUseDynamicColor(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Biometric lock'),
                  subtitle: const Text('Require device authentication on launch'),
                  value: provider.biometricEnabled,
                  onChanged: (bool value) {
                    provider.setBiometricEnabled(value);
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.restart_alt),
                        title: const Text('Run onboarding again'),
                        onTap: () {
                          provider.resetOnboarding();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Clear all records'),
                        onTap: () {
                          provider.clearAllData();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Animated onboarding
// ---------------------------------------------------------------------------

class PaisaOnboardingScreen extends StatefulWidget {
  const PaisaOnboardingScreen({super.key});

  @override
  State<PaisaOnboardingScreen> createState() => _PaisaOnboardingScreenState();
}

class _PaisaOnboardingScreenState extends State<PaisaOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _blobController;
  late final TextEditingController _nameController;
  late final TextEditingController _currencySearchController;
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

  static const List<String> _pageTitles = <String>[
    'Welcome to Paisa',
    'Set up your profile',
    'Choose your accounts',
    'Pick your categories',
    'Select your currency',
  ];

  static const List<String> _pageSubtitles = <String>[
    'A calm, private, offline-first money companion.',
    'Tell Paisa what to call you and choose an avatar.',
    'Tap to add an account, then set its opening balance.',
    'Select the categories that match your everyday spending.',
    'Search the world currency list. Indian Rupee stays pinned.',
  ];

  static const List<String> _pageImages = <String>[
    'assets/onboarding/reference8.jpg',
    'assets/onboarding/reference13.jpg',
    'assets/onboarding/step2.jpg',
    'assets/onboarding/step7.jpg',
    'assets/onboarding/reference14.jpg',
  ];

  int _currentPage = 0;
  bool _movingBack = false;
  bool _isFinishing = false;
  PaisaLanguage _selectedLanguage = PaisaLanguages.english;
  int _selectedAvatarIndex = 0;
  String? _customImagePath;
  late Set<String> _selectedAccountIds;
  late Map<String, double> _accountBalances;
  late Set<String> _selectedCategoryIds;
  String _selectedCurrencyCode = 'INR';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _nameController = TextEditingController();
    _currencySearchController = TextEditingController();
    _selectedAccountIds = PaisaAccountPresets.defaults
        .map((PaisaAccountPreset preset) => preset.id)
        .toSet();
    _accountBalances = <String, double>{
      for (final PaisaAccountPreset preset in PaisaAccountPresets.defaults)
        preset.id: preset.initialAmount,
    };
    _selectedCategoryIds = PaisaCategoryPresets.defaults
        .map((PaisaCategoryPreset preset) => preset.id)
        .toSet();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blobController.dispose();
    _nameController.dispose();
    _currencySearchController.dispose();
    super.dispose();
  }

  List<PaisaAccountPreset> get _selectedAccounts {
    return PaisaAccountPresets.defaults
        .where((PaisaAccountPreset preset) => _selectedAccountIds.contains(preset.id))
        .map(
          (PaisaAccountPreset preset) => preset.copyWith(
            initialAmount: _accountBalances[preset.id] ?? preset.initialAmount,
          ),
        )
        .toList(growable: false);
  }

  List<PaisaCategoryPreset> get _selectedCategories {
    return PaisaCategoryPresets.defaults
        .where((PaisaCategoryPreset preset) => _selectedCategoryIds.contains(preset.id))
        .toList(growable: false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickCustomAvatar() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final String? path = result?.files.single.path;
    if (path == null || !File(path).existsSync()) return;
    setState(() => _customImagePath = path);
  }

  Future<void> _editAccountBalance(PaisaAccountPreset preset) async {
    final double? value = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _InitialBalanceDialog(
          accountName: preset.name,
          currencyCode: _selectedCurrencyCode,
          initialValue: _accountBalances[preset.id] ?? preset.initialAmount,
        );
      },
    );
    if (value == null) return;
    setState(() {
      _selectedAccountIds.add(preset.id);
      _accountBalances[preset.id] = value;
    });
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        final bool valid = _profileFormKey.currentState?.validate() ?? false;
        if (!valid) _showSnack('Please enter your name to continue.');
        return valid;
      case 2:
        if (_selectedAccountIds.isEmpty) {
          _showSnack('Select at least one account.');
          return false;
        }
        return true;
      case 3:
        if (_selectedCategoryIds.isEmpty) {
          _showSnack('Select at least one category.');
          return false;
        }
        return true;
      case 4:
        return true;
      default:
        return true;
    }
  }

  Future<void> _goToPage(int page, {bool back = false}) async {
    if (page < 0 || page > 4) return;
    setState(() => _movingBack = back);
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    setState(() => _currentPage = page);
  }

  Future<void> _next() async {
    if (!_validateCurrentPage()) return;
    if (_currentPage >= 4) {
      await _finish();
      return;
    }
    await _goToPage(_currentPage + 1);
  }

  Future<void> _back() async {
    if (_currentPage == 0) return;
    await _goToPage(_currentPage - 1, back: true);
  }

  Future<void> _finish() async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    setState(() => _isFinishing = true);
    try {
      await provider.completeOnboarding(
        userName: _nameController.text,
        avatarIndex: _selectedAvatarIndex,
        customImagePath: _customImagePath,
        language: _selectedLanguage,
        currencyCode: _selectedCurrencyCode,
        accounts: _selectedAccounts,
        categories: _selectedCategories,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => const PaisaMainShell(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Could not finish setup: $error');
      setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkOnboardingTheme(context),
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  _pageImages[_currentPage],
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            LavaLampBackground(animation: _blobController),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _OnboardingHeader(
                    currentPage: _currentPage,
                    title: _pageTitles[_currentPage],
                    subtitle: _pageSubtitles[_currentPage],
                  ),
                  _ProgressStrip(currentPage: _currentPage, movingBack: _movingBack),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int page) {
                        setState(() => _currentPage = page);
                      },
                      children: <Widget>[
                        _WelcomePage(
                          selectedLanguage: _selectedLanguage,
                          onLanguageChanged: (PaisaLanguage language) {
                            setState(() => _selectedLanguage = language);
                          },
                        ),
                        _ProfilePage(
                          formKey: _profileFormKey,
                          nameController: _nameController,
                          selectedAvatarIndex: _selectedAvatarIndex,
                          customImagePath: _customImagePath,
                          onAvatarSelected: (int index) {
                            setState(() {
                              _selectedAvatarIndex = index;
                              _customImagePath = null;
                            });
                          },
                          onPickImage: _pickCustomAvatar,
                        ),
                        _AccountsPage(
                          selectedIds: _selectedAccountIds,
                          balances: _accountBalances,
                          currencyCode: _selectedCurrencyCode,
                          onToggle: (String id) {
                            setState(() {
                              if (_selectedAccountIds.contains(id)) {
                                _selectedAccountIds.remove(id);
                              } else {
                                _selectedAccountIds.add(id);
                              }
                            });
                          },
                          onEditBalance: _editAccountBalance,
                        ),
                        _CategoriesPage(
                          selectedIds: _selectedCategoryIds,
                          onToggle: (String id) {
                            setState(() {
                              if (_selectedCategoryIds.contains(id)) {
                                _selectedCategoryIds.remove(id);
                              } else {
                                _selectedCategoryIds.add(id);
                              }
                            });
                          },
                        ),
                        _CurrencyPage(
                          searchController: _currencySearchController,
                          selectedCode: _selectedCurrencyCode,
                          onSelected: (String code) {
                            setState(() => _selectedCurrencyCode = code);
                          },
                        ),
                      ],
                    ),
                  ),
                  _OnboardingFooter(
                    currentPage: _currentPage,
                    isFinishing: _isFinishing,
                    onBack: _back,
                    onNext: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentPage,
    required this.title,
    required this.subtitle,
  });

  final int currentPage;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PaisaLogo(size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: Column(
                key: ValueKey<int>(currentPage),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${currentPage + 1} / 5',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.currentPage,
    required this.movingBack,
  });

  final int currentPage;
  final bool movingBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List<Widget>.generate(5, (int index) {
          final bool active = index <= currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: movingBack ? Curves.easeOutCubic : Curves.easeInOutCubic,
              margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
              height: 5,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFBB69D) : Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.currentPage,
    required this.isFinishing,
    required this.onBack,
    required this.onNext,
  });

  final int currentPage;
  final bool isFinishing;
  final VoidCallback onBack;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: <Widget>[
          if (currentPage > 0)
            OutlinedButton.icon(
              onPressed: isFinishing
                  ? null
                  : () {
                      onBack();
                    },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            )
          else
            const SizedBox(width: 96),
          const Spacer(),
          FilledButton(
            onPressed: isFinishing
                ? null
                : () {
                    onNext();
                  },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: isFinishing
                  ? const SizedBox(
                      key: ValueKey<String>('loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      currentPage == 4 ? 'Finish setup' : 'Continue',
                      key: const ValueKey<String>('label'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  final PaisaLanguage selectedLanguage;
  final ValueChanged<PaisaLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.88, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (BuildContext context, double scale, Widget? child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: const PaisaLogo(size: 132),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Paisa',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Spending tracker, budgets, loans and reports — all on your device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _FeatureHighlight(
            icon: Icons.lock_outline,
            title: 'Private by default',
            subtitle: 'No account, no cloud sync, no watermarks.',
          ),
          const _FeatureHighlight(
            icon: Icons.insights_outlined,
            title: 'Real financial math',
            subtitle: 'Transfers never inflate income or expenses.',
          ),
          const _FeatureHighlight(
            icon: Icons.palette_outlined,
            title: 'Material You',
            subtitle: 'Dynamic color, warm light screens, and 12 seed palettes.',
          ),
          const SizedBox(height: 18),
          Text(
            'Language',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaisaLanguages.featured.map((PaisaLanguage language) {
              return ChoiceChip(
                showCheckmark: false,
                avatar: Text(language.flag),
                label: Text(language.nativeName),
                selected: selectedLanguage.code == language.code,
                onSelected: (_) => onLanguageChanged(language),
                selectedColor: const Color(0xFFFBB69D),
                backgroundColor: Colors.white.withOpacity(0.10),
                labelStyle: TextStyle(
                  color: selectedLanguage.code == language.code
                      ? const Color(0xFF3B2A24)
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                shape: const StadiumBorder(),
                side: BorderSide.none,
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _FeatureHighlight extends StatelessWidget {
  const _FeatureHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withOpacity(0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: const Color(0xFF5A3328),
            foregroundColor: const Color(0xFFFBB69D),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.formKey,
    required this.nameController,
    required this.selectedAvatarIndex,
    required this.customImagePath,
    required this.onAvatarSelected,
    required this.onPickImage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final int selectedAvatarIndex;
  final String? customImagePath;
  final ValueChanged<int> onAvatarSelected;
  final Future<void> Function() onPickImage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: PaisaAvatar(
                index: selectedAvatarIndex,
                customImagePath: customImagePath,
                size: 108,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'What should we call you?',
                hintText: 'Your name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name should be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text(
                  'Choose an avatar',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    onPickImage();
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Pick image'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: PaisaAvatarSpec.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (BuildContext context, int index) {
                final bool selected = customImagePath == null && index == selectedAvatarIndex;
                return GestureDetector(
                  onTap: () => onAvatarSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? const Color(0xFFFBB69D) : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFFFBB69D).withOpacity(0.35),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : <BoxShadow>[],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: PaisaAvatar(index: index, size: 60),
                  ),
                );
              },
            ),
            if (customImagePath != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Custom image selected. Tap any preset avatar to switch back.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountsPage extends StatelessWidget {
  const _AccountsPage({
    required this.selectedIds,
    required this.balances,
    required this.currencyCode,
    required this.onToggle,
    required this.onEditBalance,
  });

  final Set<String> selectedIds;
  final Map<String, double> balances;
  final String currencyCode;
  final ValueChanged<String> onToggle;
  final Future<void> Function(PaisaAccountPreset) onEditBalance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${selectedIds.length} of ${PaisaAccountPresets.defaults.length} selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...PaisaAccountPresets.defaults.map(
            (PaisaAccountPreset preset) {
              final bool selected = selectedIds.contains(preset.id);
              final double balance = balances[preset.id] ?? preset.initialAmount;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? Color(preset.color).withOpacity(0.24)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? Color(preset.color) : Colors.white.withOpacity(0.08),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Color(preset.color),
                      foregroundColor: Colors.white,
                      child: Icon(
                        preset.cardType == AccountType.cash
                            ? Icons.wallet
                            : preset.cardType == AccountType.bank
                                ? Icons.account_balance
                                : Icons.credit_card,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            preset.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text('${preset.cardType.label} · ${preset.bankName}'),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(balance, code: currencyCode),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Edit opening balance',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            onEditBalance(preset);
                          },
                        ),
                        Checkbox(
                          value: selected,
                          onChanged: (_) => onToggle(preset.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoriesPage extends StatelessWidget {
  const _CategoriesPage({
    required this.selectedIds,
    required this.onToggle,
  });

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${selectedIds.length} of ${PaisaCategoryPresets.defaults.length} selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: PaisaCategoryPresets.defaults.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (BuildContext context, int index) {
              final PaisaCategoryPreset preset =
                  PaisaCategoryPresets.defaults[index];
              final bool selected = selectedIds.contains(preset.id);
              return GestureDetector(
                onTap: () => onToggle(preset.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? Color(preset.color).withOpacity(0.28)
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected ? Color(preset.color) : Colors.white.withOpacity(0.08),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(preset.color).withOpacity(0.34),
                            foregroundColor: Color(preset.color),
                            child: Icon(
                              IconData(preset.iconCodePoint, fontFamily: 'MaterialIcons'),
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            selected ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18,
                            color: selected ? Color(preset.color) : theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.isIncome ? 'Income' : preset.isBudgetActive ? 'Budget' : 'General',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CurrencyPage extends StatefulWidget {
  const _CurrencyPage({
    required this.searchController,
    required this.selectedCode,
    required this.onSelected,
  });

  final TextEditingController searchController;
  final String selectedCode;
  final ValueChanged<String> onSelected;

  @override
  State<_CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<_CurrencyPage> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<CurrencyMeta> currencies =
        CurrencyFormatter.search(widget.searchController.text);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: TextField(
            controller: widget.searchController,
            onChanged: (_) => _refresh(),
            decoration: InputDecoration(
              hintText: 'Search currency, code, or symbol',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: widget.searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        widget.searchController.clear();
                        _refresh();
                      },
                    ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: currencies.length,
            itemBuilder: (BuildContext context, int index) {
              final CurrencyMeta meta = currencies[index];
              final bool selected = meta.code == widget.selectedCode;
              final bool pinned = meta.code == 'INR';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: selected
                    ? const Color(0xFFFBB69D).withOpacity(0.28)
                    : null,
                child: ListTile(
                  onTap: () => widget.onSelected(meta.code),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      meta.symbol,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  title: Text(
                    meta.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${meta.displayLabel} · ${meta.locale}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (pinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.push_pin, size: 16),
                        ),
                      Icon(
                        selected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: selected ? const Color(0xFFFBB69D) : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InitialBalanceDialog extends StatefulWidget {
  const _InitialBalanceDialog({
    required this.accountName,
    required this.currencyCode,
    required this.initialValue,
  });

  final String accountName;
  final String currencyCode;
  final double initialValue;

  @override
  State<_InitialBalanceDialog> createState() => _InitialBalanceDialogState();
}

class _InitialBalanceDialogState extends State<_InitialBalanceDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final String normalized = _controller.text.replaceAll(',', '').trim();
    final double? value = double.tryParse(normalized);
    if (value == null || !value.isFinite) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.accountName} opening balance'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Current preview: ${CurrencyFormatter.format(widget.initialValue, code: widget.currencyCode)}',
            ),
            const SizedBox(height: 14),
            TextFormField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${CurrencyFormatter.symbol(widget.currencyCode)} ',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
              validator: (String? value) {
                final double? parsed = double.tryParse(
                  (value ?? '').replaceAll(',', '').trim(),
                );
                if (parsed == null || !parsed.isFinite) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Brand and avatar artwork
// ---------------------------------------------------------------------------

class PaisaLogo extends StatelessWidget {
  const PaisaLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final double cardWidth = size * 0.72;
    final double cardHeight = size * 0.48;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: size * 0.20,
            top: size * 0.10,
            child: Transform.rotate(
              angle: -0.21,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D4E2A),
                  borderRadius: BorderRadius.circular(size * 0.10),
                ),
              ),
            ),
          ),
          Positioned(
            left: size * 0.08,
            top: size * 0.28,
            child: Transform.rotate(
              angle: -0.10,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFFF7C873), Color(0xFFD99A3E)],
                  ),
                  borderRadius: BorderRadius.circular(size * 0.10),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: size * 0.10,
                      offset: Offset(0, size * 0.06),
                    ),
                  ],
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      right: cardWidth * 0.16,
                      top: cardHeight * 0.18,
                      child: Container(
                        width: cardWidth * 0.11,
                        height: cardWidth * 0.11,
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: cardWidth * 0.12,
                      right: cardWidth * 0.12,
                      bottom: cardHeight * 0.18,
                      child: Container(
                        height: cardHeight * 0.10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
}

class LavaLampBackground extends StatelessWidget {
  const LavaLampBackground({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFF1A1014),
                      Color(0xFF2A171E),
                      Color(0xFF160D11),
                    ],
                  ),
                ),
              ),
            ),
            _Blob(
              left: -70 + 70 * math.sin(t * math.pi),
              top: 80 + 60 * math.cos(t * math.pi),
              size: 260 + 30 * t,
              color: const Color(0xFFFBB69D).withOpacity(0.34),
            ),
            _Blob(
              right: -90 + 80 * math.cos((t + 0.25) * math.pi),
              top: 180 + 90 * math.sin((t + 0.25) * math.pi),
              size: 300 + 40 * (1 - t),
              color: const Color(0xFF7E57C2).withOpacity(0.25),
            ),
            _Blob(
              left: 90 + 90 * math.sin((t + 0.6) * math.pi),
              bottom: -60 + 80 * math.cos((t + 0.6) * math.pi),
              size: 280 + 30 * t,
              color: const Color(0xFF26A69A).withOpacity(0.20),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 44, sigmaY: 44),
                child: Container(color: Colors.black.withOpacity(0.10)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

@immutable
class PaisaAvatarSpec {
  const PaisaAvatarSpec({
    required this.label,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.head,
    required this.body,
    required this.accent,
    required this.pattern,
  });

  final String label;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color head;
  final Color body;
  final Color accent;
  final int pattern;

  static const List<PaisaAvatarSpec> all = <PaisaAvatarSpec>[
    PaisaAvatarSpec(label: 'Midnight floral', backgroundTop: Color(0xFF5A2D44), backgroundBottom: Color(0xFF150A12), head: Color(0xFF081015), body: Color(0xFFB5125B), accent: Color(0xFFF20574), pattern: 0),
    PaisaAvatarSpec(label: 'Peach', backgroundTop: Color(0xFFFFE0D2), backgroundBottom: Color(0xFFF5B18E), head: Color(0xFFFBB69D), body: Color(0xFFFBB69D), accent: Color(0xFF2B150D), pattern: 1),
    PaisaAvatarSpec(label: 'Mint', backgroundTop: Color(0xFFDFF5F1), backgroundBottom: Color(0xFF9FD8CF), head: Color(0xFFB3DFDB), body: Color(0xFF4EB7AD), accent: Color(0xFF173B38), pattern: 1),
    PaisaAvatarSpec(label: 'Indigo', backgroundTop: Color(0xFFDDE0FF), backgroundBottom: Color(0xFF8E96D9), head: Color(0xFFB9BEF4), body: Color(0xFF5C6BC0), accent: Color(0xFF171A3A), pattern: 2),
    PaisaAvatarSpec(label: 'Gold', backgroundTop: Color(0xFFFFF0CF), backgroundBottom: Color(0xFFE6BE6E), head: Color(0xFFF3D18B), body: Color(0xFFD89A35), accent: Color(0xFF3B2219), pattern: 3),
    PaisaAvatarSpec(label: 'Coral', backgroundTop: Color(0xFFFFDCD8), backgroundBottom: Color(0xFFFF8A80), head: Color(0xFFFFAB91), body: Color(0xFFFF6B6B), accent: Color(0xFF4A1F1C), pattern: 4),
    PaisaAvatarSpec(label: 'Teal', backgroundTop: Color(0xFFD4F2EC), backgroundBottom: Color(0xFF57BFAE), head: Color(0xFF80CBC4), body: Color(0xFF26A69A), accent: Color(0xFF123B36), pattern: 5),
    PaisaAvatarSpec(label: 'Violet', backgroundTop: Color(0xFFEDE1FF), backgroundBottom: Color(0xFFAA91D8), head: Color(0xFFCEB6F2), body: Color(0xFF7E57C2), accent: Color(0xFF281747), pattern: 6),
    PaisaAvatarSpec(label: 'Amber', backgroundTop: Color(0xFFFFF3D2), backgroundBottom: Color(0xFFE8B84B), head: Color(0xFFFFD54F), body: Color(0xFFFFA000), accent: Color(0xFF4A3007), pattern: 7),
    PaisaAvatarSpec(label: 'Sky', backgroundTop: Color(0xFFD9EEFF), backgroundBottom: Color(0xFF73B9E8), head: Color(0xFFB3E5FC), body: Color(0xFF29B6F6), accent: Color(0xFF123A52), pattern: 8),
    PaisaAvatarSpec(label: 'Rose', backgroundTop: Color(0xFFFFE0EC), backgroundBottom: Color(0xFFE58AAE), head: Color(0xFFF8BBD0), body: Color(0xFFEC407A), accent: Color(0xFF4A1B2C), pattern: 9),
    PaisaAvatarSpec(label: 'Slate', backgroundTop: Color(0xFFE6ECF0), backgroundBottom: Color(0xFF8FA3AF), head: Color(0xFFB0BEC5), body: Color(0xFF607D8B), accent: Color(0xFF1F3038), pattern: 10),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaisaAvatarSpec &&
          other.label == label &&
          other.pattern == pattern &&
          other.head.value == head.value;

  @override
  int get hashCode => Object.hash(label, pattern, head.value);
}

class PaisaAvatar extends StatelessWidget {
  const PaisaAvatar({
    super.key,
    required this.index,
    this.customImagePath,
    this.size = 64,
  });

  final int index;
  final String? customImagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String? path = customImagePath;
    if (path != null && File(path).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final PaisaAvatarSpec spec =
        PaisaAvatarSpec.all[index.clamp(0, 11).toInt() % PaisaAvatarSpec.all.length];
    return CustomPaint(
      painter: PaisaAvatarPainter(spec),
      size: Size.square(size),
    );
  }
}

class PaisaAvatarPainter extends CustomPainter {
  const PaisaAvatarPainter(this.spec);

  final PaisaAvatarSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Offset.zero & size;
    final Paint background = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        <Color>[spec.backgroundTop, spec.backgroundBottom],
      );
    canvas.drawCircle(center, radius, background);

    if (spec.pattern == 0) {
      _paintFloral(canvas, center, radius);
    } else {
      _paintFace(canvas, size, center);
    }

    if (spec.pattern == 2 || spec.pattern == 8) {
      _paintGlasses(canvas, center, radius);
    }
    if (spec.pattern == 6 || spec.pattern == 9) {
      _paintHair(canvas, center, radius);
    }
    if (spec.pattern == 3 || spec.pattern == 7) {
      _paintHighlight(canvas, center, radius);
    }

    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, radius * 0.045)
      ..color = Colors.white.withOpacity(0.30);
    canvas.drawCircle(center, radius - rim.strokeWidth / 2, rim);
    canvas.clipRect(rect);
  }

  void _paintFloral(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 14; i++) {
      final double angle = (i / 14) * math.pi * 2;
      final Offset petal = Offset(
        center.dx + math.cos(angle) * radius * 0.40,
        center.dy + math.sin(angle) * radius * 0.40,
      );
      canvas.drawCircle(petal, radius * 0.21, Paint()..color = spec.body.withOpacity(0.92));
      canvas.drawCircle(petal, radius * 0.11, Paint()..color = spec.accent.withOpacity(0.90));
      canvas.drawCircle(
        petal + Offset(radius * 0.04, radius * 0.03),
        radius * 0.04,
        Paint()..color = const Color(0xFFFFC7E7),
      );
    }
    canvas.drawCircle(center, radius * 0.26, Paint()..color = spec.head);
    canvas.drawCircle(
      center + Offset(-radius * 0.08, -radius * 0.05),
      radius * 0.035,
      Paint()..color = const Color(0xFFF7D774),
    );
    canvas.drawCircle(
      center + Offset(radius * 0.10, radius * 0.03),
      radius * 0.025,
      Paint()..color = const Color(0xFFF7D774),
    );
  }

  void _paintFace(Canvas canvas, Size size, Offset center) {
    final double radius = size.width / 2;
    final Paint bodyPaint = Paint()..color = spec.body;
    final Rect bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.62),
      width: radius * 1.65,
      height: radius * 1.15,
    );
    canvas.drawArc(bodyRect, math.pi, math.pi, true, bodyPaint);

    final Paint headPaint = Paint()..color = spec.head;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.18),
      radius * 0.36,
      headPaint,
    );

    final Paint eyePaint = Paint()
      ..color = spec.accent
      ..strokeWidth = math.max(2, radius * 0.055)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.13, center.dy - radius * 0.22),
      math.max(1.6, radius * 0.035),
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.13, center.dy - radius * 0.22),
      math.max(1.6, radius * 0.035),
      eyePaint,
    );

    final Paint smile = Paint()
      ..color = spec.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, radius * 0.045)
      ..strokeCap = StrokeCap.round;
    final Rect smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius * 0.10),
      width: radius * 0.34,
      height: radius * 0.20,
    );
    canvas.drawArc(smileRect, 0.15 * math.pi, 0.70 * math.pi, false, smile);
  }

  void _paintGlasses(Canvas canvas, Offset center, double radius) {
    final Paint frame = Paint()
      ..color = spec.accent.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, radius * 0.035);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.13, center.dy - radius * 0.22),
      radius * 0.10,
      frame,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.13, center.dy - radius * 0.22),
      radius * 0.10,
      frame,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.03, center.dy - radius * 0.22),
      Offset(center.dx + radius * 0.03, center.dy - radius * 0.22),
      frame,
    );
  }

  void _paintHair(Canvas canvas, Offset center, double radius) {
    final Paint hair = Paint()..color = spec.accent.withOpacity(0.82);
    final Path path = Path()
      ..moveTo(center.dx - radius * 0.38, center.dy - radius * 0.30)
      ..quadraticBezierTo(
        center.dx - radius * 0.12,
        center.dy - radius * 0.66,
        center.dx + radius * 0.36,
        center.dy - radius * 0.28,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.18,
        center.dy - radius * 0.44,
        center.dx - radius * 0.26,
        center.dy - radius * 0.22,
      )
      ..close();
    canvas.drawPath(path, hair);
  }

  void _paintHighlight(Canvas canvas, Offset center, double radius) {
    final Paint highlight = Paint()
      ..color = Colors.white.withOpacity(0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, radius * 0.05)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      -0.85 * math.pi,
      0.42 * math.pi,
      false,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant PaisaAvatarPainter oldDelegate) {
    return oldDelegate.spec != spec;
  }
}
