import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/achievements.dart';
import '../../core/data/financial_pulse.dart';
import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/recurring_schedule.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/actions.dart';
import '../../shared/daily_spend_chart.dart';
import '../../shared/widgets.dart';
import '../accounts/accounts_screen.dart';
import '../achievements/achievements_screen.dart';
import '../assets/assets_screen.dart';
import '../bills/bills_screen.dart';
import '../budgets/budgets_screen.dart';
import '../catalog/catalog_screen.dart';
import '../goals/goals_screen.dart';
import '../loans/loans_screen.dart';
import '../recurring/recurring_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/analytics_screen.dart';
import '../settings/help_screen.dart';
import '../settings/layout_screen.dart';
import '../settings/premium_screen.dart';
import '../settings/profiles_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/templates_screen.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_screen.dart';
import 'more_screen.dart';
import 'home_reference_sections.dart';
import 'net_worth_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider), ledger = ref.watch(ledgerProvider)!;
    final profile = ledger.data, settings = app.settings;
    final now = DateTime.now();
    final ids = settings.homeCards
        .where(
          (id) =>
              !settings.hiddenCards.contains(id) &&
              !(id == 'premium' && settings.isPro),
        )
        .toList();
    final columns =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 &&
            MediaQuery.sizeOf(context).width < 600
        ? 1
        : 2;
    final sections = <Widget>[];
    var index = 0;
    var overviewAdded = false;
    while (index < ids.length) {
      final id = ids[index];
      if (['balance', 'cashflow'].contains(id)) {
        final together =
            id == 'balance' &&
            index + 1 < ids.length &&
            ids[index + 1] == 'cashflow';
        sections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: _BalanceOverview(
              ledger: ledger,
              now: now,
              showBalance: id == 'balance' || together,
              showCashflow: id == 'cashflow' || together,
            ),
          ),
        );
        index += together ? 2 : 1;
        continue;
      }
      if ([
        'recent',
        'templates',
        'heatmap',
        'trend',
        'trackedBudgets',
        'upcoming',
      ].contains(id)) {
        sections.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: switch (id) {
              'recent' => _LastEarned(ledger: ledger),
              'templates' => _TemplatesStrip(ledger: ledger),
              'heatmap' => HomeCalendarHeatmap(ledger),
              'trend' => HomeCashflowTrend(ledger),
              'trackedBudgets' => HomeTrackedBudgets(ledger),
              _ => UpcomingTransactionsSection(ledger),
            },
          ),
        );
        index++;
        continue;
      }
      if (!overviewAdded) {
        sections.add(const SectionHeader('Overview'));
        overviewAdded = true;
      }
      final row = [id];
      index++;
      if (columns == 2 &&
          index < ids.length &&
          ![
            'recent',
            'templates',
            'balance',
            'cashflow',
            'heatmap',
            'trend',
            'trackedBudgets',
            'upcoming',
          ].contains(ids[index]))
        row.add(ids[index++]);
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: columns == 1
              ? _DashboardTile(id: id, ledger: ledger, now: now)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _DashboardTile(
                          id: row[0],
                          ledger: ledger,
                          now: now,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: row.length == 2
                            ? _DashboardTile(
                                id: row[1],
                                ledger: ledger,
                                now: now,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leadingWidth: 80,
        leading: Tooltip(
          message: 'Customize home layout',
          child: TextButton(
            onPressed: () => openPage(context, const LayoutScreen()),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'New',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'All tools',
            onPressed: () => openPage(context, const MoreScreen()),
            icon: const Icon(Icons.widgets_outlined),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: IconButton.filledTonal(
              tooltip: 'Profiles & settings',
              onPressed: () => showProfileMenu(context, ref),
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: RefreshIndicator(
            onRefresh: () => runSafe(
              context,
              () => ref.read(appProvider.notifier).processRecurring(),
            ).then((_) {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
              children: [
                _HomeGreeting(
                  name: profile.profile.name,
                  notifications: settings.notificationsEnabled,
                  earned: profile.achievements.length,
                  now: now,
                ),
                const SizedBox(height: 18),
                ...sections,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplatesStrip extends StatelessWidget {
  final Ledger ledger;
  const _TemplatesStrip({required this.ledger});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(
        'Templates',
        action: 'See all',
        onTap: () => openPage(context, const TemplatesScreen()),
      ),
      if (ledger.data.templates.isEmpty)
        TonalCard(
          onTap: () => openPage(context, const TemplatesScreen()),
          child: const Text(
            'Create a template for those everyday little payments.',
          ),
        ),
      if (ledger.data.templates.isNotEmpty)
        SizedBox(
          height: 160 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ledger.data.templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final template = ledger.data.templates[index],
                  category = ledger.category(
                    ledger.data.templates[index].categoryId,
                  );
              return SizedBox(
                width: 186,
                child: TonalCard(
                  onTap: () =>
                      openTransactionSheet(context, template: template),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ColorIcon(
                            category?.icon ?? 'bills',
                            category?.color ?? 0xffffb59a,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: AmountText(
                                template.amountMinor,
                                currency: ledger
                                    .account(template.accountId)
                                    .currency,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        template.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        titleCase(template.type),
                        style: Theme.of(context).textTheme.bodySmall,
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

class _HomeGreeting extends StatelessWidget {
  final String name;
  final bool notifications;
  final int earned;
  final DateTime now;
  const _HomeGreeting({
    required this.name,
    required this.notifications,
    required this.earned,
    required this.now,
  });
  @override
  Widget build(BuildContext context) {
    final greeting = now.hour < 5
        ? 'Good late night'
        : now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : now.hour < 21
        ? 'Good evening'
        : 'Good night';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$greeting '),
          TextSpan(
            text: name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '. You have '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              notifications
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              size: 18,
            ),
          ),
          TextSpan(
            text: notifications
                ? ' notifications on and '
                : ' notifications off and ',
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.star_outline_rounded, size: 18),
          ),
          TextSpan(text: ' $earned milestones.'),
        ],
      ),
      style: Theme.of(context).textTheme.bodyLarge
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.5),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String id;
  final Ledger ledger;
  final DateTime now;
  const _DashboardTile({
    required this.id,
    required this.ledger,
    required this.now,
  });
  @override
  Widget build(BuildContext context) {
    final data = ledger.data, l = AppLocalizations.of(context);
    final records = data.transactions
        .where((e) => !e.date.isAfter(now))
        .toList();
    final eligible = records
        .where((e) => !ledger.account(e.accountId).excluded)
        .toList();
    final activeRules = data.recurrings.where(recurringActive).toList();
    final goals = data.goals.where((g) => !g.archived).toList();
    final goalSaved = goals.fold<int>(0, (s, g) => s + ledger.goalSaved(g)),
        goalTarget = goals.fold<int>(0, (s, g) => s + g.targetMinor);
    final today = dayOnly(now),
        weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - ledger.settings.weekStart + 7) % 7,
        );
    final week = DateWindow(
      weekStart,
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7),
    );
    final lastWeek = DateWindow(
      DateTime(weekStart.year, weekStart.month, weekStart.day - 7),
      weekStart,
    );
    final month = DateWindow(
      DateTime(today.year, today.month, today.day - 29),
      nextDay(today),
    );
    int expense(DateWindow window) => eligible
        .where((e) => e.type == 'expense' && window.contains(e.date))
        .fold(0, (s, e) => s + ledger.entryValue(e));
    final title =
        <String, String>{
          'accounts': l.accounts,
          'reports': l.reports,
          'budgets': l.budgets,
          'assets': l.assets,
          'splits': 'Bill Splitter',
          'loans': l.loans,
          'goals': l.goals,
          'labels': l.labels,
          'categories': l.categories,
          'places': l.places,
          'people': 'Person',
          'score': 'Analytics',
          'achievements': l.achievements,
        }[id] ??
        homeCardNames[id] ??
        id;
    final icon = switch (id) {
      'accounts' => Icons.account_balance_outlined,
      'reports' => Icons.bar_chart_outlined,
      'budgets' => Icons.savings_outlined,
      'assets' => Icons.account_balance_wallet_outlined,
      'splits' => Icons.call_split_rounded,
      'loans' => Icons.payments_outlined,
      'goals' => Icons.my_location_rounded,
      'labels' => Icons.label_rounded,
      'analytics' => Icons.trending_up_rounded,
      'recurring' => Icons.event_repeat_rounded,
      'categories' => Icons.category_rounded,
      'weekly' => Icons.view_week_outlined,
      'last30' => Icons.trending_up_rounded,
      'places' => Icons.place_rounded,
      'people' => Icons.person_rounded,
      'score' => Icons.psychology_outlined,
      'achievements' => Icons.emoji_events_outlined,
      _ => Icons.auto_awesome_outlined,
    };
    final page = switch (id) {
      'analytics' => const AnalyticsScreen(),
      'accounts' => const AccountsScreen(),
      'budgets' => const BudgetsScreen(),
      'assets' => const AssetsScreen(),
      'splits' => const BillsScreen(),
      'loans' => const LoansScreen(),
      'goals' => const GoalsScreen(),
      'recurring' => const RecurringScreen(),
      'categories' => const CatalogScreen('category'),
      'labels' => const CatalogScreen('label'),
      'places' => const CatalogScreen('place'),
      'people' => const CatalogScreen('person'),
      'achievements' => const AchievementsScreen(),
      'premium' => const PremiumScreen(),
      'weekly' => TransactionsScreen(
        title: 'This week',
        initialFilter: TransactionFilter(dates: week),
      ),
      'last30' => TransactionsScreen(
        title: 'Last 30 days',
        initialFilter: TransactionFilter(dates: month),
      ),
      _ => const ReportsScreen(),
    };
    final ink = Theme.of(context).colorScheme.onSurfaceVariant,
        valueInk = AppColors.dark(context)
            ? Theme.of(context).colorScheme.primary
            : AppColors.primaryInk;
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35);
    Widget moneyValue(int amount, {double size = 26}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: AmountText(
        amount,
        compact: true,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: valueInk,
        ),
      ),
    );
    Widget countLine(int count, String label) => Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueInk,
            ),
          ),
          TextSpan(text: ' $label', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
    Widget topEntity(String kind) {
      final entities = data.entities.where((e) => e.kind == kind).toList();
      var maximum = 0;
      String? name;
      for (final entity in entities) {
        final amount = eligible
            .where(
              (e) =>
                  e.type == 'expense' &&
                  (kind == 'label'
                      ? e.labelIds.contains(entity.id)
                      : kind == 'person'
                      ? e.personIds.contains(entity.id)
                      : e.placeId == entity.id),
            )
            .fold<int>(0, (s, e) => s + ledger.entryValue(e));
        if (amount > maximum) {
          maximum = amount;
          name = entity.name;
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          countLine(entities.length, kind == 'person' ? 'Person' : title),
          const SizedBox(height: 10),
          Text(
            name == null
                ? 'Add tags to see recorded spending here.'
                : ledger.settings.hideAmounts
                ? 'Most used: $name · amount hidden'
                : 'You have spent the most ${kind == 'place'
                      ? 'at'
                      : kind == 'person'
                      ? 'with'
                      : 'on'} $name, totaling ${money(maximum, ledger.currency, compact: true, locale: ledger.settings.locale)}.',
            style: small,
          ),
        ],
      );
    }

    final budgets = data.budgets
        .where((b) => !b.income)
        .map((b) => ledger.budgetStatus(b, now))
        .toList();
    final budgetSpent = budgets.fold<int>(0, (s, b) => s + b.spent),
        budgetLimit = budgets.fold<int>(0, (s, b) => s + b.limit);
    final expenseRecords = eligible.where((e) => e.type == 'expense').toList();
    final categories = data.categories.where((c) => !c.hidden).toList();
    final categoryTotals = [...categories]
      ..sort(
        (a, b) => expenseRecords
            .where((e) => e.categoryId == b.id)
            .fold<int>(0, (s, e) => s + ledger.entryValue(e))
            .compareTo(
              expenseRecords
                  .where((e) => e.categoryId == a.id)
                  .fold<int>(0, (s, e) => s + ledger.entryValue(e)),
            ),
      );
    final pulse = FinancialPulse.fromLedger(ledger, now);
    final history = DateWindow(
      DateTime(now.year, now.month, now.day - 36),
      DateTime(now.year, now.month, now.day - 6),
    );
    final baseline = expense(history) / history.days;
    var under = 0;
    for (var i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      if (expense(DateWindow(date, nextDay(date))) <= baseline) under++;
    }
    final detail = switch (id) {
      'accounts' => <Widget>[
        Text(
          '${data.accounts.where((a) => !a.archived).length} accounts',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 8),
        moneyValue(ledger.accountsTotal, size: 20),
      ],
      'reports' => <Widget>[
        Text(
          '${records.length} transactions',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 8),
        moneyValue(
          expenseRecords.fold<int>(0, (s, e) => s + ledger.entryValue(e)),
          size: 20,
        ),
      ],
      'budgets' => <Widget>[
        countLine(data.budgets.length, 'Budgets'),
        const SizedBox(height: 12),
        WavyProgress(budgetLimit <= 0 ? 0 : budgetSpent / budgetLimit),
        const SizedBox(height: 10),
        Text(
          '${budgetLimit <= 0 ? 0 : (budgetSpent / budgetLimit * 100).round()}% of total budget spent',
          style: small,
        ),
        moneyValue(budgetSpent, size: 16),
      ],
      'assets' => <Widget>[
        countLine(data.assets.length, 'Assets'),
        const SizedBox(height: 10),
        moneyValue(ledger.assetsTotal),
        const SizedBox(height: 4),
        Text('Total', style: small),
      ],
      'splits' => <Widget>[
        countLine(data.bills.length, 'Bills'),
        const SizedBox(height: 5),
        countLine(
          data.bills
              .where(
                (b) => b.shares.any(
                  (share) => !share.settled && share.personId != b.paidById,
                ),
              )
              .length,
          'Active',
        ),
      ],
      'loans' => <Widget>[
        countLine(
          data.loans
              .where(
                (l) => l.direction == 'lent' && ledger.loanRemaining(l) > 0,
              )
              .length,
          'Lending',
        ),
        countLine(
          data.loans
              .where(
                (l) => l.direction == 'borrowed' && ledger.loanRemaining(l) > 0,
              )
              .length,
          'Borrowing',
        ),
        const SizedBox(height: 6),
        moneyValue(ledger.toReceive - ledger.toPay),
        Text('Loan Balance', style: small),
      ],
      'goals' => <Widget>[
        countLine(goals.length, 'Active'),
        const SizedBox(height: 12),
        WavyProgress(goalTarget <= 0 ? 0 : goalSaved / goalTarget),
        const SizedBox(height: 8),
        Text(
          ledger.settings.hideAmounts
              ? 'Progress hidden'
              : 'Progress: ${money(goalSaved, ledger.currency, compact: true)} / ${money(goalTarget, ledger.currency, compact: true)}',
          style: small,
        ),
      ],
      'labels' => <Widget>[topEntity('label')],
      'places' => <Widget>[topEntity('place')],
      'people' => <Widget>[topEntity('person')],
      'analytics' => <Widget>[
        Text('This month spending', style: small),
        const SizedBox(height: 7),
        moneyValue(expense(financialMonth(now, ledger.settings.monthStart))),
        const SizedBox(height: 14),
        _SpendingComparison(
          current: expense(financialMonth(now, ledger.settings.monthStart)),
          previous: expense(previousMonth(now, ledger.settings.monthStart)),
          hidden: ledger.settings.hideAmounts,
        ),
      ],
      'recurring' => <Widget>[
        countLine(activeRules.length, 'Active'),
        const SizedBox(height: 12),
        moneyValue(ledger.monthlyBurn),
        const SizedBox(height: 5),
        Text('Monthly Payment', style: small),
        Text('Planning estimate', style: small),
      ],
      'categories' => <Widget>[
        countLine(categories.length, 'Categories'),
        const SizedBox(height: 16),
        for (final category in categoryTotals.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(
                  iconFor(category.icon),
                  size: 16,
                  color: readableTint(context, Color(category.color)),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: AmountText(
                    expenseRecords
                        .where((e) => e.categoryId == category.id)
                        .fold<int>(0, (s, e) => s + ledger.entryValue(e)),
                    compact: true,
                    style: small,
                  ),
                ),
              ],
            ),
          ),
      ],
      'weekly' => <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This week', style: small),
                  moneyValue(expense(week), size: 13),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Last Week', style: small),
                  moneyValue(expense(lastWeek), size: 13),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DailySpendChart(
          ledger: ledger,
          window: week,
          now: now,
          color: valueInk,
        ),
      ],
      'last30' => <Widget>[
        moneyValue(expense(month)),
        const SizedBox(height: 8),
        _SpendingComparison(
          current: expense(month),
          previous: expense(
            DateWindow(
              DateTime(now.year, now.month, now.day - 59),
              month.start,
            ),
          ),
          hidden: ledger.settings.hideAmounts,
        ),
        const SizedBox(height: 14),
        DailySpendChart(
          ledger: ledger,
          window: month,
          now: now,
          color: const Color(0xffF15D50),
          cumulative: true,
        ),
      ],
      'score' => <Widget>[
        Text(
          baseline <= 0
              ? 'Add history for comparisons'
              : '$under days under average!',
          style: small?.copyWith(color: AppColors.warning),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            WavyRing(
              (pulse.score ?? 0) / 100,
              size: 58,
              color: const Color(0xffB5D978),
              child: Text(
                pulse.score == null ? '—' : '${pulse.score}',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in categoryTotals.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${c.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: small,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Record-derived planning indicators', style: small),
      ],
      'achievements' => <Widget>[
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${data.achievements.length}',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              TextSpan(text: ' / ${badges.length} unlocked', style: small),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${(data.achievements.length / math.max(1, badges.length) * 100).round()}% completed',
          style: small,
        ),
        const SizedBox(height: 14),
        WavyProgress(data.achievements.length / math.max(1, badges.length)),
      ],
      _ => <Widget>[Text('Local Pro simulation. No payments.', style: small)],
    };
    return Semantics(
      button: true,
      label: title,
      child: TonalCard(
        radius: 28,
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(16),
        onTap: () => openPage(context, page),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                176.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 21, color: ink),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 15, color: ink),
                    ),
                  ),
                  if (![
                    'weekly',
                    'last30',
                    'score',
                    'achievements',
                  ].contains(id))
                    Icon(Icons.chevron_right_rounded, size: 20, color: ink),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showProfileMenu(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final app = sheetRef.watch(appProvider);
          void open(Widget page) {
            Navigator.pop(sheetContext);
            openPage(context, page);
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final data in app.profiles)
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline_rounded),
                      ),
                      title: Text(data.profile.name),
                      subtitle: Text(data.profile.currency),
                      trailing: data.profile.id == app.activeProfileId
                          ? const Icon(Icons.check_circle_outline_rounded)
                          : null,
                      onTap: () {
                        final controller = sheetRef.read(appProvider.notifier);
                        Navigator.pop(sheetContext);
                        runSafe(
                          context,
                          () => controller.switchProfile(data.profile.id),
                        );
                      },
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: const Text('Customize home'),
                    onTap: () => open(const LayoutScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () => open(const SettingsScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Manage profiles'),
                    onTap: () => open(const ProfilesScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.grid_view_rounded),
                    title: const Text('All tools'),
                    onTap: () => open(const MoreScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('Help & FAQ'),
                    onTap: () => open(const HelpScreen()),
                  ),
                  if (!app.isDemo)
                    ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: const Text('Try demo mode'),
                      subtitle: const Text(
                        'Sample data in memory. Your finances stay untouched.',
                      ),
                      onTap: () {
                        final controller = sheetRef.read(appProvider.notifier);
                        Navigator.pop(sheetContext);
                        runSafe(context, () => controller.startDemo());
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

class _BalanceOverview extends ConsumerWidget {
  final Ledger ledger;
  final DateTime now;
  final bool showBalance, showCashflow;
  const _BalanceOverview({
    required this.ledger,
    required this.now,
    this.showBalance = true,
    this.showCashflow = true,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    final l = AppLocalizations.of(context);
    final balanceVisible =
            showBalance && !settings.hiddenCards.contains('balance'),
        flowVisible =
            showCashflow && !settings.hiddenCards.contains('cashflow');
    if (!balanceVisible && !flowVisible) return const SizedBox.shrink();
    final current = financialMonth(now, settings.monthStart),
        previous = previousMonth(now, settings.monthStart);
    int total(String type, DateWindow window) => ledger.data.transactions
        .where(
          (e) =>
              e.type == type &&
              window.contains(e.date) &&
              !e.date.isAfter(now) &&
              !ledger.account(e.accountId).excluded,
        )
        .fold(0, (sum, e) => sum + ledger.entryValue(e));
    final dark = AppColors.dark(context);
    final ink = dark ? const Color(0xffFFE0D2) : AppColors.ink;
    Widget flow(String title, String type) {
      final amount = total(type, current), last = total(type, previous);
      final change = last == 0 ? null : (amount - last) / last * 100;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: ink, fontSize: 13)),
          const SizedBox(height: 3),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AmountText(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              if (change != null && !settings.hideAmounts)
                Text(
                  '${change >= 0 ? '↑' : '↓'}${change.abs().toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            settings.hideAmounts
                ? 'Compared to •••• last month'
                : 'Compared to ${money(last, ledger.currency, locale: settings.locale, indian: settings.numberFormat == 'indian')} last month',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: ink.withValues(alpha: .9),
            ),
          ),
        ],
      );
    }

    return TonalCard(
      radius: 28,
      color: dark ? const Color(0xff72361E) : const Color(0xffFFE1D1),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (balanceVisible) ...[
            Text(
              'Total balance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: AmountText(
                      ledger.accountsTotal,
                      animate: true,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Balance details & safe to spend',
                  onPressed: () => openPage(context, const NetWorthScreen()),
                  icon: Icon(Icons.info_outline_rounded, color: ink, size: 18),
                ),
                IconButton(
                  tooltip: settings.hideAmounts
                      ? 'Show amounts'
                      : 'Hide amounts',
                  onPressed: () => runSafe(
                    context,
                    () => ref
                        .read(appProvider.notifier)
                        .settings(
                          (s) => s.copyWith(hideAmounts: !s.hideAmounts),
                        ),
                  ),
                  icon: Icon(
                    settings.hideAmounts
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: ink,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
          if (flowVisible) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: flow(l.income, 'income')),
                const SizedBox(width: 16),
                Expanded(child: flow(l.expenses, 'expense')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LastEarned extends StatelessWidget {
  final Ledger ledger;
  const _LastEarned({required this.ledger});
  @override
  Widget build(BuildContext context) {
    final earned = [...ledger.data.achievements]
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    if (earned.isEmpty) return const SizedBox.shrink();
    final definition = badges.where((b) => b.id == earned.first.id).firstOrNull;
    return TonalCard(
      color: AppColors.dark(context)
          ? const Color(0xff72361E)
          : const Color(0xffFFE1D1),
      onTap: () => openPage(context, const AchievementsScreen()),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xffB87D39),
            child: Icon(Icons.emoji_events_outlined, color: Color(0xffFFF1D6)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST EARNED',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.dark(context)
                        ? AppColors.primary
                        : AppColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  definition?.name ?? earned.first.id,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat.MMMd().format(earned.first.unlockedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SpendingComparison extends StatelessWidget {
  final int current, previous;
  final bool hidden;
  const _SpendingComparison({
    required this.current,
    required this.previous,
    required this.hidden,
  });
  @override
  Widget build(BuildContext context) {
    final change = previous == 0 ? null : (current - previous) / previous * 100;
    return Text(
      hidden
          ? '••••'
          : change == null
          ? 'No previous period amount'
          : '${change >= 0 ? '↗' : '↘'} ${change.abs().toStringAsFixed(1)}% vs previous period',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.semantic(context, 'expense')),
    );
  }
}
