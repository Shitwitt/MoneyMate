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
import '../../l10n/generated/app_localizations.dart';
import '../../shared/actions.dart';
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
import '../settings/help_screen.dart';
import '../settings/layout_screen.dart';
import '../settings/premium_screen.dart';
import '../settings/profiles_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/templates_screen.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_screen.dart';
import 'more_screen.dart';
import 'net_worth_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final ledger = ref.watch(ledgerProvider)!;
    final profile = ledger.data;
    final settings = app.settings;
    final now = DateTime.now();
    final ids = settings.homeCards
        .where(
          (id) =>
              !settings.hiddenCards.contains(id) &&
              !['balance', 'cashflow', 'recent', 'templates'].contains(id) &&
              !(id == 'premium' && settings.isPro),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Center(
            child: IconButton.filledTonal(
              tooltip: 'Profiles & settings',
              onPressed: () => showProfileMenu(context, ref),
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ),
        ),
        titleSpacing: 10,
        title: InkWell(
          onTap: () => showProfileMenu(context, ref),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                now.hour < 12
                    ? 'Good morning,'
                    : now.hour < 17
                    ? 'Good afternoon,'
                    : 'Good evening,',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                profile.profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'All tools',
            onPressed: () => openPage(context, const MoreScreen()),
            icon: const Icon(Icons.grid_view_rounded),
          ),
          IconButton(
            tooltip: 'Customize home',
            onPressed: () => openPage(context, const LayoutScreen()),
            icon: const Icon(Icons.dashboard_customize_outlined),
          ),
          const SizedBox(width: 4),
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
                _BalanceOverview(ledger: ledger, now: now),
                const SizedBox(height: 22),
                const SectionHeader('Overview'),
                for (var row = 0; row < ids.length; row += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _DashboardTile(
                              id: ids[row],
                              ledger: ledger,
                              now: now,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: row + 1 < ids.length
                                ? _DashboardTile(
                                    id: ids[row + 1],
                                    ledger: ledger,
                                    now: now,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (settings.homeCards.contains('recent') &&
                    !settings.hiddenCards.contains('recent')) ...[
                  const SizedBox(height: 8),
                  _LastEarned(ledger: ledger),
                ],
                if (settings.homeCards.contains('templates') &&
                    !settings.hiddenCards.contains('templates')) ...[
                  const SizedBox(height: 24),
                  SectionHeader(
                    'Templates',
                    action: 'View all',
                    onTap: () => openPage(context, const TemplatesScreen()),
                  ),
                  if (profile.templates.isEmpty)
                    TonalCard(
                      onTap: () => openPage(context, const TemplatesScreen()),
                      child: const Text(
                        'Create a template for those everyday little payments.',
                      ),
                    ),
                  if (profile.templates.isNotEmpty)
                    SizedBox(
                      height:
                          134 *
                          MediaQuery.textScalerOf(
                            context,
                          ).scale(1).clamp(1, 1.6),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: profile.templates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final template = profile.templates[index];
                          final category = ledger.category(template.categoryId);
                          return SizedBox(
                            width: 176,
                            child: TonalCard(
                              onTap: () => openTransactionSheet(
                                context,
                                template: template,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ColorIcon(
                                    category?.icon ?? 'bills',
                                    category?.color ?? 0xfff6bb96,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    template.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: AmountText(
                                      template.amountMinor,
                                      currency: ledger
                                          .account(template.accountId)
                                          .currency,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
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
    final data = ledger.data;
    final l = AppLocalizations.of(context);
    final records = data.transactions
        .where((e) => !e.date.isAfter(now))
        .toList();
    final activeRules = data.recurrings.where(recurringActive).toList();
    final pulse = FinancialPulse.fromLedger(ledger, now);
    final statuses = data.budgets
        .map((b) => ledger.budgetStatus(b, now))
        .toList();
    final goalSaved = data.goals.fold<int>(
      0,
      (sum, g) => sum + ledger.goalSaved(g),
    );
    final goalTarget = data.goals.fold<int>(0, (sum, g) => sum + g.targetMinor);
    final week = DateWindow(
      DateTime(now.year, now.month, now.day - 6),
      nextDay(now),
    );
    final month = DateWindow(
      DateTime(now.year, now.month, now.day - 29),
      nextDay(now),
    );
    int expense(DateWindow period) => records
        .where((e) => e.type == 'expense' && period.contains(e.date))
        .fold(0, (sum, e) => sum + ledger.entryValue(e));
    final names = {
      'accounts': l.accounts,
      'reports': l.reports,
      'budgets': l.budgets,
      'assets': l.assets,
      'loans': l.loans,
      'goals': l.goals,
      'labels': l.labels,
      'categories': l.categories,
      'places': l.places,
      'people': l.people,
      'achievements': l.achievements,
    };
    final title = names[id] ?? homeCardNames[id] ?? id;
    final icon = switch (id) {
      'accounts' => Icons.account_balance_wallet_outlined,
      'reports' => Icons.bar_chart_rounded,
      'budgets' => Icons.pie_chart_outline_rounded,
      'assets' => Icons.diamond_outlined,
      'splits' => Icons.call_split_rounded,
      'loans' => Icons.handshake_outlined,
      'goals' => Icons.flag_outlined,
      'labels' => Icons.sell_outlined,
      'analytics' || 'trend' => Icons.analytics_outlined,
      'recurring' => Icons.repeat_rounded,
      'categories' => Icons.category_outlined,
      'weekly' => Icons.calendar_view_week_outlined,
      'last30' => Icons.calendar_month_outlined,
      'places' => Icons.place_outlined,
      'people' => Icons.people_outline_rounded,
      'score' => Icons.speed_rounded,
      'achievements' => Icons.emoji_events_outlined,
      _ => Icons.auto_awesome_outlined,
    };
    Widget page = switch (id) {
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
    final tint = switch (id) {
      'accounts' => const Color(0xffDDE7D0),
      'reports' => const Color(0xffF5DAC7),
      'budgets' => const Color(0xffE7DCC6),
      'assets' => const Color(0xffDFD2E9),
      'splits' => const Color(0xffDEE4CE),
      'loans' => const Color(0xffE8D6CB),
      'goals' => const Color(0xffDCE6D1),
      'labels' => const Color(0xffE7D4DE),
      'score' => const Color(0xffF2D7BE),
      _ => const Color(0xffE8DCCD),
    };
    final background = AppColors.dark(context) ? const Color(0xff271E19) : tint;
    final ink = AppColors.dark(context)
        ? const Color(0xffE7D1C7)
        : AppColors.ink;
    final valueInk = AppColors.dark(context)
        ? Theme.of(context).colorScheme.primary
        : AppColors.primaryInk;
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: ink.withValues(alpha: .80));
    Widget money(int value, {double size = 27}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: AmountText(
        value,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: valueInk,
        ),
      ),
    );
    Widget number(int value, String label) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: valueInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: small),
      ],
    );
    final details = switch (id) {
      'accounts' => [
        number(
          data.accounts.where((a) => !a.archived).length,
          'Active accounts',
        ),
        const SizedBox(height: 10),
        money(ledger.accountsTotal, size: 21),
      ],
      'reports' => [
        money(expense(month)),
        const SizedBox(height: 10),
        Text('Expenses · last 30 days', style: small),
        const SizedBox(height: 14),
        _MiniBars(ledger: ledger, now: now, color: ink),
      ],
      'budgets' => [
        number(data.budgets.length, 'Spending plans'),
        const SizedBox(height: 14),
        WavyProgress(
          statuses.isEmpty
              ? 0
              : statuses.fold<int>(0, (s, b) => s + b.spent) /
                    math.max(1, statuses.fold<int>(0, (s, b) => s + b.limit)),
          color: ink,
        ),
        const SizedBox(height: 8),
        Text(
          '${statuses.where((b) => b.remaining < 0).length} over allowance',
          style: small,
        ),
      ],
      'assets' => [
        money(ledger.assetsTotal),
        const SizedBox(height: 8),
        Text('${data.assets.length} recorded assets', style: small),
      ],
      'splits' => [
        number(data.bills.length, 'Shared bills'),
        const SizedBox(height: 8),
        Text(
          '${data.bills.expand((b) => b.shares.where((s) => !s.settled && s.personId != b.paidById)).length} unsettled shares',
          style: small,
        ),
      ],
      'loans' => [
        money(ledger.toReceive - ledger.toPay),
        const SizedBox(height: 7),
        Text('To receive − to pay', style: small),
        const SizedBox(height: 8),
        Text('${data.loans.length} private loans', style: small),
      ],
      'goals' => [
        Row(
          children: [
            ProgressRing(
              goalTarget == 0 ? 0 : goalSaved / goalTarget,
              size: 50,
              strokeWidth: 4,
              color: ink,
              child: Icon(Icons.flag_outlined, color: ink, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: number(data.goals.length, 'Goals')),
          ],
        ),
        const SizedBox(height: 10),
        money(goalSaved, size: 21),
      ],
      'labels' || 'places' || 'people' => [
        number(
          data.entities
              .where(
                (e) =>
                    e.kind ==
                    {
                      'labels': 'label',
                      'places': 'place',
                      'people': 'person',
                    }[id],
              )
              .length,
          'Saved ${title.toLowerCase()}',
        ),
        const SizedBox(height: 10),
        Text(
          data.entities
              .where(
                (e) =>
                    e.kind ==
                    {
                      'labels': 'label',
                      'places': 'place',
                      'people': 'person',
                    }[id],
              )
              .take(2)
              .map((e) => e.name)
              .join(' · '),
          style: small,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      'analytics' || 'trend' => [
        number(
          records.where((e) => month.contains(e.date)).length,
          'Entries · last 30 days',
        ),
        const SizedBox(height: 12),
        _MiniBars(ledger: ledger, now: now, color: ink),
      ],
      'recurring' => [
        number(activeRules.length, 'Active schedules'),
        const SizedBox(height: 10),
        Text(
          '${activeRules.where((r) => recurringDue(r, now)).length} due now',
          style: small,
        ),
      ],
      'categories' => [
        number(
          data.categories.where((c) => !c.hidden).length,
          'Visible categories',
        ),
        const SizedBox(height: 8),
        Text('Income, expense & transfer', style: small),
      ],
      'weekly' || 'last30' => [
        money(expense(id == 'weekly' ? week : month)),
        const SizedBox(height: 8),
        Text(
          id == 'weekly' ? 'Expenses · past 7 days' : 'Expenses · past 30 days',
          style: small,
        ),
        const SizedBox(height: 12),
        _MiniBars(
          ledger: ledger,
          now: now,
          color: ink,
          days: id == 'weekly' ? 7 : 30,
        ),
      ],
      'score' => [
        Row(
          children: [
            WavyRing(
              (pulse.score ?? 0) / 100,
              size: 62,
              color: ink,
              child: Text(
                pulse.score == null ? '—' : '${pulse.score}',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Based only on your records. Not a credit or health score.',
          style: small,
        ),
      ],
      'achievements' => [
        number(data.achievements.length, 'of ${badges.length} earned'),
        const SizedBox(height: 10),
        Text(
          data.achievements.isEmpty
              ? 'Little steps count.'
              : badges
                    .where((b) => data.achievements.any((a) => a.id == b.id))
                    .map((b) => b.name)
                    .first,
          style: small,
        ),
      ],
      _ => [Text('Local simulation. No payment.', style: small)],
    };
    return Semantics(
      button: true,
      label: title,
      child: TonalCard(
        color: background,
        onTap: () => openPage(context, page),
        padding: const EdgeInsets.all(18),
        radius: 26,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: ink),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  180 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 21, color: ink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: ink, fontSize: 17),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded, size: 23, color: ink),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: details,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  final Ledger ledger;
  final DateTime now;
  final Color color;
  final int days;
  const _MiniBars({
    required this.ledger,
    required this.now,
    required this.color,
    this.days = 7,
  });
  @override
  Widget build(BuildContext context) {
    final bucketCount = days == 7 ? 7 : 10;
    final values = List<int>.filled(bucketCount, 0);
    final start = DateTime(now.year, now.month, now.day - days + 1);
    for (final entry in ledger.data.transactions.where(
      (e) =>
          e.type == 'expense' &&
          !e.date.isBefore(start) &&
          !e.date.isAfter(now),
    )) {
      final index =
          (calendarDaysBetween(start, entry.date) * bucketCount ~/ days).clamp(
            0,
            bucketCount - 1,
          );
      values[index] += ledger.entryValue(entry);
    }
    final maxValue = values.fold<int>(1, math.max);
    return Semantics(
      label:
          'Recorded daily expenses over the past $days days. ${values.where((v) => v > 0).length} nonzero chart buckets.',
      child: SizedBox(
        height: 32,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final value in values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: value == 0 ? 2 : 5 + value / maxValue * 27,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: value == 0 ? .15 : .65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
          ],
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
  const _BalanceOverview({required this.ledger, required this.now});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    final l = AppLocalizations.of(context);
    final balanceVisible = !settings.hiddenCards.contains('balance'),
        flowVisible = !settings.hiddenCards.contains('cashflow');
    if (!balanceVisible && !flowVisible) return const SizedBox.shrink();
    final current = financialMonth(now, settings.monthStart),
        previous = previousMonth(now, settings.monthStart);
    int total(String type, DateWindow window) => ledger.data.transactions
        .where(
          (e) =>
              e.type == type && window.contains(e.date) && !e.date.isAfter(now),
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
          Text(title, style: TextStyle(color: ink, fontSize: 14)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AmountText(
              amount,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          if (change != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                settings.hideAmounts
                    ? '••••'
                    : '${change >= 0 ? '↑' : '↓'} ${change.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  color: dark ? const Color(0xffF8D0BF) : AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            settings.hideAmounts
                ? 'Compared to •••• last month'
                : last == 0
                ? 'No previous month amount'
                : 'Compared to last month',
            style: TextStyle(fontSize: 12, color: ink.withValues(alpha: .85)),
          ),
          if (last != 0 && !settings.hideAmounts)
            AmountText(last, style: TextStyle(fontSize: 13, color: ink)),
        ],
      );
    }

    return TonalCard(
      radius: 28,
      color: dark ? const Color(0xff72361E) : const Color(0xffFFE1D1),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (balanceVisible) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total balance',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
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
                    size: 23,
                  ),
                ),
              ],
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
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Balance details & safe to spend',
                  onPressed: () => openPage(context, const NetWorthScreen()),
                  icon: Icon(Icons.info_outline_rounded, color: ink, size: 20),
                ),
              ],
            ),
          ],
          if (flowVisible) ...[
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: flow(l.income, 'income')),
                const SizedBox(width: 20),
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
