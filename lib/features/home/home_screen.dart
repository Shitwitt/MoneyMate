import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/charts.dart';
import '../../shared/widgets.dart';
import '../accounts/accounts_screen.dart';
import '../achievements/achievements_screen.dart';
import '../assets/assets_screen.dart';
import '../budgets/budgets_screen.dart';
import '../goals/goals_screen.dart';
import '../loans/loans_screen.dart';
import '../recurring/recurring_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/layout_screen.dart';
import '../settings/premium_screen.dart';
import '../settings/profiles_screen.dart';
import '../transactions/templates_screen.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transaction_tile.dart';
import '../transactions/transactions_screen.dart';
import 'home_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final ledger = ref.watch(ledgerProvider)!;
    final profile = ledger.data;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final ids = app.settings.homeCards
        .where(
          (id) =>
              !app.settings.hiddenCards.contains(id) &&
              !(id == 'premium' && app.settings.isPro),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _profiles(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
                child: Text(
                  profile.profile.name.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            profile.profile.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more_rounded, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: app.settings.hideAmounts ? 'Show amounts' : 'Hide amounts',
            onPressed: () => runSafe(
              context,
              () => ref
                  .read(appProvider.notifier)
                  .settings((s) => s.copyWith(hideAmounts: !s.hideAmounts)),
            ),
            icon: Icon(
              app.settings.hideAmounts
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Search everything',
            onPressed: () => openPage(
              context,
              const TransactionsScreen(title: 'Find a little detail'),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: () => runSafe(
              context,
              () => ref.read(appProvider.notifier).processRecurring(),
            ).then((_) {}),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              header: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your overview',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM yyyy',
                        app.settings.locale,
                      ).format(DateTime.now()),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              itemCount: ids.length,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final visible = [...ids];
                visible.insert(newIndex, visible.removeAt(oldIndex));
                var cursor = 0;
                final all = [
                  for (final id in app.settings.homeCards)
                    if (ids.contains(id)) visible[cursor++] else id,
                ];
                runSafe(
                  context,
                  () => ref
                      .read(appProvider.notifier)
                      .settings((s) => s.copyWith(homeCards: all)),
                );
              },
              itemBuilder: (context, index) {
                final id = ids[index];
                return Padding(
                  key: ValueKey(id),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (id != 'balance')
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                homeCardNames[id]!,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Tap for options; hold to rearrange',
                              iconSize: 19,
                              child: ReorderableDelayedDragStartListener(
                                index: index,
                                child: const SizedBox.square(
                                  dimension: 48,
                                  child: Icon(
                                    Icons.more_horiz_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                              onSelected: (action) {
                                if (action == 'hide') {
                                  runSafe(
                                    context,
                                    () => ref
                                        .read(appProvider.notifier)
                                        .settings(
                                          (s) => s.copyWith(
                                            hiddenCards: {
                                              ...s.hiddenCards,
                                              id,
                                            }.toList(),
                                          ),
                                        ),
                                  );
                                } else {
                                  openPage(context, const LayoutScreen());
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'hide',
                                  child: Text('Hide this card'),
                                ),
                                PopupMenuItem(
                                  value: 'customize',
                                  child: Text('Customize home'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (id != 'balance') const SizedBox(height: 10),
                      Entrance(
                        index: index,
                        child: _card(context, ref, ledger, id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, Ledger ledger, String id) {
    final profile = ledger.data;
    switch (id) {
      case 'balance':
        return Column(
          children: [
            SafeToSpendCard(ledger),
            const SizedBox(height: 16),
            const HomeQuickActions(),
          ],
        );
      case 'cashflow':
        return MonthSummaryCard(ledger);
      case 'accounts':
        return SizedBox(
          height:
              170 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount:
                profile.accounts.where((account) => !account.archived).length +
                1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final accounts = profile.accounts
                  .where((account) => !account.archived)
                  .toList();
              if (index == accounts.length) {
                return SizedBox(
                  width: 160,
                  child: OutlinedButton(
                    onPressed: () => editAccount(context, ref),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded),
                        SizedBox(height: 12),
                        Text('New account'),
                      ],
                    ),
                  ),
                );
              }
              final account = accounts[index];
              return SizedBox(
                width: 235,
                child: Card(
                  color: null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () =>
                        openPage(context, AccountDetailScreen(account.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(iconFor(account.icon), size: 24),
                              const Spacer(),
                              Text(
                                account.currency,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            account.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          AmountText(
                            ledger.accountBalance(account.id),
                            currency: account.currency,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      case 'trend':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                TrendChart(ledger),
                TextButton(
                  onPressed: () => openPage(context, const ReportsScreen()),
                  child: const Text('Explore your story →'),
                ),
              ],
            ),
          ),
        );
      case 'budgets':
        return profile.budgets.isEmpty
            ? Card(
                child: EmptyState(
                  title: 'Give your spending a direction',
                  message: 'A little plan makes room for more.',
                  icon: Icons.donut_large_rounded,
                  action: 'Create a budget',
                  onAction: () => editBudget(context, ref),
                ),
              )
            : Column(
                children: [
                  for (final budget in profile.budgets.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BudgetCard(budget),
                    ),
                  TextButton(
                    onPressed: () => openPage(context, const BudgetsScreen()),
                    child: const Text('All budgets →'),
                  ),
                ],
              );
      case 'goals':
        return profile.goals.isEmpty
            ? Card(
                child: EmptyState(
                  title: 'Your next dream starts here',
                  message: 'Name it. Save a little. Watch it grow.',
                  icon: Icons.flag_outlined,
                  action: 'Start a goal',
                  onAction: () => editGoal(context, ref),
                ),
              )
            : Column(
                children: [
                  GoalCard(profile.goals.first),
                  TextButton(
                    onPressed: () => openPage(context, const GoalsScreen()),
                    child: const Text('All savings goals →'),
                  ),
                ],
              );
      case 'recent':
        final entries = [...profile.transactions]
          ..sort((a, b) => b.date.compareTo(a.date));
        final groups = <DateTime, List<MoneyTransaction>>{};
        for (final entry in entries.take(5)) {
          groups.putIfAbsent(dayOnly(entry.date), () => []).add(entry);
        }
        return Card(
          child: entries.isEmpty
              ? EmptyState(
                  title: 'Every little entry counts',
                  message: 'Start with something you spent or earned today.',
                  icon: Icons.receipt_long_outlined,
                  action: 'Add your first entry',
                  onAction: () => openPage(context, const TransactionForm()),
                )
              : Column(
                  children: [
                    for (final group in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.key == dayOnly(DateTime.now())
                                    ? 'Today'
                                    : DateFormat.MMMd().format(group.key),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            AmountText(
                              profile.transactions
                                  .where(
                                    (entry) =>
                                        dayOnly(entry.date) == group.key &&
                                        entry.type != 'transfer',
                                  )
                                  .fold<int>(
                                    0,
                                    (sum, entry) =>
                                        sum +
                                        ledger.entryValue(entry) *
                                            (entry.type == 'income' ? 1 : -1),
                                  ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      for (final entry in group.value) TransactionTile(entry),
                    ],
                    TextButton(
                      onPressed: () =>
                          openPage(context, const TransactionsScreen()),
                      child: const Text('All activity →'),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
        );
      case 'templates':
        return profile.templates.isEmpty
            ? OutlinedButton.icon(
                onPressed: () => openPage(
                  context,
                  const TransactionForm(templateOnly: true),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Make your everyday a one-tap entry'),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: profile.templates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final template = profile.templates[index];
                        final category = ledger.category(template.categoryId);
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => runSafe(
                              context,
                              () => ref
                                  .read(appProvider.notifier)
                                  .applyTemplate(template),
                              success: '${template.name} added on your device',
                            ),
                            onLongPress: () => openPage(
                              context,
                              TransactionForm(
                                templateOnly: true,
                                template: template,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ColorIcon(
                                    category?.icon ?? 'category',
                                    category?.color ?? palette.first,
                                    size: 38,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      AmountText(
                                        template.amountMinor,
                                        currency: ledger
                                            .account(template.accountId)
                                            .currency,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.add_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => openPage(context, const TemplatesScreen()),
                    child: const Text('Manage templates →'),
                  ),
                ],
              );
      case 'recurring':
        return StatCard(
          title: 'Monthly subscription rhythm',
          value: AmountText(ledger.monthlyBurn),
          icon: Icons.event_repeat_rounded,
          caption:
              '${profile.recurrings.where((rule) => rule.enabled).length} active · tap to review',
          onTap: () => openPage(context, const RecurringScreen()),
        );
      case 'assets':
        return StatCard(
          title: 'The things you’re building',
          value: AmountText(ledger.assetsTotal),
          icon: Icons.landscape_outlined,
          caption: '${profile.assets.length} assets · manually valued',
          onTap: () => openPage(context, const AssetsScreen()),
        );
      case 'loans':
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(22),
            leading: const ColorIcon('loan', 0xff88c7b5),
            title: const Text('Money between people'),
            subtitle: Row(
              children: [
                AmountText(ledger.toReceive, compact: true, prefix: 'Receive '),
                const SizedBox(width: 12),
                AmountText(ledger.toPay, compact: true, prefix: 'Pay '),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openPage(context, const LoansScreen()),
          ),
        );
      case 'reports':
        return Card(
          color: const Color(0xffb6a5e8).withValues(alpha: .25),
          child: ListTile(
            contentPadding: const EdgeInsets.all(24),
            leading: const Icon(Icons.insights_rounded, size: 32),
            title: const Text('A little perspective'),
            subtitle: const Text(
              'Spot patterns. Build habits. Find your rhythm.',
            ),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: () => openPage(context, const ReportsScreen()),
          ),
        );
      case 'achievements':
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: const ColorIcon('gift', 0xffe4c569),
            title: const Text('Progress, not perfection'),
            subtitle: Text(
              '${profile.achievements.length} little wins collected',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openPage(context, const AchievementsScreen()),
          ),
        );
      default:
        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded),
                const SizedBox(height: 14),
                Text(
                  'Dream a little bigger.',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlimited plans, deeper insights, and a little more possibility.',
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () => openPage(context, const PremiumScreen()),
                  child: const Text('Explore Pro · free simulation'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _profiles(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 600),
        builder: (sheetContext) => Consumer(
          builder: (sheetContext, sheetRef, _) {
            final app = sheetRef.watch(appProvider);
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final profile in app.profiles)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(profile.profile.color),
                          child: Text(
                            profile.profile.name.characters.first.toUpperCase(),
                          ),
                        ),
                        title: Text(profile.profile.name),
                        trailing: profile.profile.id == app.activeProfileId
                            ? const Icon(Icons.check_circle_rounded)
                            : null,
                        onTap: () async {
                          final controller = sheetRef.read(
                            appProvider.notifier,
                          );
                          Navigator.pop(sheetContext);
                          await runSafe(
                            context,
                            () => controller.switchProfile(profile.profile.id),
                          );
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.manage_accounts_outlined),
                      title: const Text('Manage your private spaces'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        openPage(context, const ProfilesScreen());
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
