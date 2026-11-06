import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/reporting.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/reference_charts.dart';
import '../../shared/widgets.dart';
import '../goals/goals_screen.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transaction_tile.dart';

const budgetHelpSections = <HelpSection>[
  (
    Icons.swap_vert_rounded,
    'Budget For',
    'Expense Budget: set limits on how much you spend.\nIncome Budget: set goals for how much you earn. Transfers never count as income or expenses.',
  ),
  (
    Icons.category_outlined,
    'Budget Type',
    'Category Budget: track selected categories such as Food or Transport.\nOverall Budget: track the full amount, optionally excluding selected categories.',
  ),
  (
    Icons.tune_rounded,
    'Budget Mode',
    'Automatic: Tink matches recorded transactions by your category rules.\nManual: you choose which transactions count by linking them to the budget in the transaction editor. An explicit link also counts in an automatic budget.',
  ),
  (
    Icons.calendar_month_outlined,
    'Budget Period',
    'Choose Daily, Weekly, Monthly, Yearly, or a Custom date range. Monthly budgets can start on a custom day, such as the 25th for a salary cycle. Custom ranges do not renew.',
  ),
  (
    Icons.label_outline_rounded,
    'Categories',
    'For Category budgets select categories to include. For Overall budgets select categories to exclude. Include subcategories to match descendants of the categories you select.',
  ),
  (
    Icons.autorenew_rounded,
    'Rolling Budget',
    'For expense limits, unused allowance carries over and overspending reduces the next period’s allowance. For income targets, an unmet target carries forward and surplus reduces the next target. This is bookkeeping, not a transfer of money.',
  ),
  (
    Icons.insights_rounded,
    'Tracking',
    'Cards show the recorded amount, adjusted allowance or target, remaining amount and real progress. Expense status is On Track, Warning at 80%, or Exceeded. Income status shows progress toward its target.',
  ),
  (
    Icons.home_outlined,
    'Show Budget',
    'Turn Show Budget on in a budget’s details to include it in the Home tracking carousel. Future-dated recorded entries count in its allowance; the progress chart distinguishes posted activity from future dates.',
  ),
];

Future<void> showBudgetHelp(BuildContext context) => showHowItWorks(
  context,
  title: 'How Budgets Work',
  introduction: 'Budgets help you set spending limits and track your expenses, or plan income targets. Here’s how to get started.',
  sections: budgetHelpSections,
);

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Budgets'),
            Tab(text: 'Savings goals'),
          ],
        ),
      ),
      body: const TabBarView(children: [BudgetsScreen(), GoalsScreen()]),
    ),
  );
}

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});
  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  String sort = 'name';
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final budgets = [...ledger.data.budgets]
      ..sort(
        (a, b) => sort == 'amount'
            ? b.limitMinor.compareTo(a.limitMinor)
            : sort == 'progress'
            ? ledger
                  .budgetStatus(b, DateTime.now())
                  .progress
                  .compareTo(ledger.budgetStatus(a, DateTime.now()).progress)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return FeaturePage(
      title: 'Budgets',
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: Center(
            child: SmallTag(
              '${budgets.length}/${ledger.settings.isPro ? '∞' : freeBudgetLimit}',
            ),
          ),
        ),
      ],
      fab: FloatingActionButton(
        tooltip: 'Create budget',
        onPressed: () => editBudget(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      child: budgets.isEmpty
          ? EmptyState(
              title: 'A plan, not a restriction',
              message: 'Create a budget for the things that matter to you.',
              icon: Icons.savings_outlined,
              action: 'Create a budget',
              onAction: () => editBudget(context, ref),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                BudgetOverview(ledger: ledger),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${budgets.length} budgets',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Sort budgets',
                      icon: const Icon(Icons.sort_rounded),
                      onSelected: (v) => setState(() => sort = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'name', child: Text('Name')),
                        PopupMenuItem(
                          value: 'amount',
                          child: Text('Allowance · highest first'),
                        ),
                        PopupMenuItem(
                          value: 'progress',
                          child: Text('Progress · highest first'),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'How budgets work',
                      onPressed: () => showBudgetHelp(context),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final budget in budgets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BudgetCard(budget),
                  ),
              ],
            ),
    );
  }
}

class BudgetOverview extends StatefulWidget {
  final Ledger ledger;
  const BudgetOverview({super.key, required this.ledger});
  @override
  State<BudgetOverview> createState() => _BudgetOverviewState();
}

class _BudgetOverviewState extends State<BudgetOverview> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger;
    final budgets = ledger.data.budgets.where((b) => !b.income).toList();
    final statuses = budgets
        .map((b) => ledger.budgetStatus(b, DateTime.now()))
        .toList();
    final total = statuses.fold<int>(0, (s, b) => s + b.limit);
    final spent = statuses.fold<int>(0, (s, b) => s + b.spent);
    final large =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 360;
    Widget metric(String name, int value, int color, {bool count = false}) =>
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(
                count
                    ? Icons.check_circle_outline_rounded
                    : Icons.account_balance_wallet_outlined,
                color: const Color(0xff33231b),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xff33231b),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    count
                        ? Text(
                            '$value',
                            style: const TextStyle(
                              color: Color(0xff33231b),
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: AmountText(
                              value,
                              style: const TextStyle(
                                color: Color(0xff33231b),
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
    final ring = ProgressRing(
      total <= 0 ? (spent > 0 ? 1 : 0) : spent / total,
      size: 168,
      strokeWidth: 24,
      color: const Color(0xff20AE9D),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ledger.settings.hideAmounts
                ? '••'
                : '${total > 0 ? (spent / total * 100).round() : 0}%',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Text('Spent'),
        ],
      ),
    );
    final totals = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        metric('Total', total, 0xffBDBAFA),
        metric('Spent', spent, 0xffFFB0C5),
        metric('Remaining', total - spent, 0xff8CD7CA),
      ],
    );
    final counts = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        metric(
          'On Track',
          statuses.where((s) => s.remaining >= 0 && s.progress < .8).length,
          0xffE8C46B,
          count: true,
        ),
        metric(
          'Warning',
          statuses.where((s) => s.remaining >= 0 && s.progress >= .8).length,
          0xffA3C9FF,
          count: true,
        ),
        metric(
          'Exceeded',
          statuses.where((s) => s.remaining < 0).length,
          0xffFFB59F,
          count: true,
        ),
      ],
    );
    return Column(
      children: [
        SizedBox(
          height: large
              ? 430 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6)
              : 252,
          child: PageView(
            onPageChanged: (p) => setState(() => page = p),
            children: [
              large
                  ? Column(children: [ring, const SizedBox(height: 16), totals])
                  : Row(
                      children: [
                        Expanded(child: Center(child: ring)),
                        const SizedBox(width: 18),
                        Expanded(child: totals),
                      ],
                    ),
              Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: large ? double.infinity : 200,
                  child: counts,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 2; i++)
              AnimatedContainer(
                duration: referenceMotion(context, 160),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: i == page ? 1 : .25),
                ),
              ),
          ],
        ),
        if (ledger.data.budgets.any((b) => b.income))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Overview totals are expense allowances; income targets appear below.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

String budgetStatusLabel(Budget budget, BudgetStatus status) => budget.income
    ? status.remaining <= 0
          ? 'Reached'
          : 'In progress'
    : status.remaining < 0
    ? 'Exceeded'
    : status.progress >= .8
    ? 'Warning'
    : 'Good';

class BudgetCard extends ConsumerWidget {
  final Budget budget;
  final bool openDetails;
  const BudgetCard(this.budget, {super.key, this.openDetails = true});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!, now = DateTime.now();
    final status = ledger.budgetStatus(budget, now),
        color = readableTint(context, Color(budget.color));
    final days = math.max(
      0,
      calendarDaysBetween(
        dayOnly(now).isBefore(status.window.start)
            ? status.window.start
            : dayOnly(now),
        status.window.end,
      ),
    );
    final background = Color.alphaBlend(
      Color(budget.color)
          .withValues(alpha: AppColors.dark(context) ? .21 : .13),
      Theme.of(context).colorScheme.surface,
    );
    return BudgetWarningFrame(
      overLimit: !budget.income && status.remaining < 0,
      child: TonalCard(
        radius: 28,
        color: background,
        onTap: openDetails
            ? () => openPage(context, BudgetDetailScreen(budget.id))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ColorIcon(budget.icon, budget.color, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          SmallTag(titleCase(budget.period)),
                          SmallTag(budget.overall ? 'Overall' : 'Category'),
                          SmallTag(
                            titleCase(budget.mode),
                            icon: budget.mode == 'automatic'
                                ? Icons.autorenew_rounded
                                : Icons.tune_rounded,
                          ),
                          if (budget.income) const SmallTag('Income'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.income ? 'Received' : 'Spent',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      AmountText(
                        status.spent,
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 42,
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.income ? 'Target' : 'Budget',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      AmountText(
                        status.limit,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            WavyProgress(status.progress, color: color),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                SmallTag(
                  '${(status.progress * 100).round()}% · ${budgetStatusLabel(budget, status)}',
                  icon: Icons.check_circle_outline_rounded,
                ),
                if (!budget.income && days > 0 && status.remaining >= 0)
                  Text(
                    ledger.settings.hideAmounts
                        ? 'Daily allowance hidden'
                        : 'You can spend ${money((status.remaining / days).floor(), ledger.currency, locale: ledger.settings.locale)}/day for $days more days',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    status.remaining < 0
                        ? 'Over ${budget.income ? 'target' : 'budget'}'
                        : 'Remaining',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AmountText(
                    status.remaining.abs(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (status.carry != 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AmountText(
                  status.carry,
                  prefix: 'Rollover ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> editBudget(
  BuildContext context,
  WidgetRef ref, [
  Budget? initial,
]) async {
  final profile = ref.read(profileProvider)!;
  final name = TextEditingController(text: initial?.name ?? '');
  final amount = TextEditingController(
    text: initial == null
        ? ''
        : fromMinor(initial.limitMinor, profile.profile.currency).toString(),
  );
  var period = initial?.period ?? 'monthly',
      type = initial?.transactionType ?? 'expense',
      mode = initial?.mode ?? 'automatic';
  var overall = initial?.overall ?? false,
      includeChildren = initial?.includeSubcategories ?? true;
  var start =
      initial?.start ??
      financialMonth(
        DateTime.now(),
        ref.read(appProvider).settings.monthStart,
      ).start;
  var end =
      initial?.end ??
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  var categories = {...?initial?.categoryIds},
      rollover = initial?.rollover ?? false;
  var color = initial?.color ?? palette.first,
      icon = initial?.icon ?? 'savings';
  await showEditor(
    context,
    title: initial == null ? 'New budget' : 'Edit budget',
    description: 'Automatic matching or explicit transaction links. Rollover carries signed surplus/deficit; no money is moved.',
    fields: (context, setLocal) => [
      formText(name, 'Budget name', required: true),
      formText(
        amount,
        '${type == 'income' ? 'Target' : 'Allowance'} (${profile.profile.currency})',
        numeric: true,
        required: true,
      ),
      formSelect(
        'Budget for',
        type,
        const ['expense', 'income'],
        (v) => setLocal(() {
          type = v;
          categories = {};
        }),
      ),
      formSelect('Budget type', overall ? 'overall' : 'category', const [
        'category',
        'overall',
      ], (v) => setLocal(() => overall = v == 'overall')),
      formSelect('Budget mode', mode, const [
        'automatic',
        'manual',
      ], (v) => setLocal(() => mode = v)),
      if (mode == 'manual')
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Choose this budget in a transaction’s Budget field to count it. Category selections do not automatically add records.',
          ),
        ),
      formSelect(
        'Budget period',
        period,
        periods,
        (v) => setLocal(() => period = v),
      ),
      formDate(
        context,
        period == 'monthly' ? 'Start / monthly renewal day' : 'Starts on',
        start,
        (v) => setLocal(() => start = v),
      ),
      if (period == 'custom')
        formDate(
          context,
          'Ends on (inclusive)',
          end,
          (v) => setLocal(() => end = v),
        ),
      formChips(
        overall ? 'Excluded categories (optional)' : 'Included categories',
        {
          for (final c in profile.categories.where((c) => c.type == type))
            c.id: c.name,
        },
        categories,
        (v) => setLocal(() => categories = v),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Include subcategories'),
        value: includeChildren,
        onChanged: (v) => setLocal(() => includeChildren = v),
      ),
      if (period != 'custom')
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Rolling budget'),
          subtitle: const Text(
            'Carry unused allowance and overspending, or unmet income targets.',
          ),
          value: rollover,
          onChanged: (v) => setLocal(() => rollover = v),
        ),
      formColors(color, (v) => setLocal(() => color = v)),
      ExpansionTile(
        title: const Text('Budget icon'),
        children: [formIcons(icon, (v) => setLocal(() => icon = v))],
      ),
    ],
    onSave: () async {
      if (!overall && categories.isEmpty && mode == 'automatic')
        throw const FormatException(
          'Choose at least one category, or use an Overall budget.',
        );
      await ref
          .read(appProvider.notifier)
          .upsertBudget(
            Budget(
              id: initial?.id ?? uuid.v4(),
              name: name.text.trim(),
              limitMinor: toMinor(
                evaluateAmount(amount.text),
                profile.profile.currency,
              ),
              start: dayOnly(start),
              end: period == 'custom' ? dayOnly(end) : null,
              categoryIds: categories.toList(),
              period: period,
              rollover: period != 'custom' && rollover,
              color: color,
              transactionType: type,
              mode: mode,
              excludeCategories: overall,
              includeSubcategories: includeChildren,
              showOnHome: initial?.showOnHome ?? true,
              icon: icon,
            ),
          );
    },
  );
  name.dispose();
  amount.dispose();
}

class BudgetDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BudgetDetailScreen(this.id, {super.key});
  @override
  ConsumerState<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen> {
  bool saving = false;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final budget = ledger.data.budgets
        .where((b) => b.id == widget.id)
        .firstOrNull;
    if (budget == null)
      return const Scaffold(
        body: EmptyState(
          title: 'Budget removed',
          message: 'Your transaction history is unchanged.',
        ),
      );
    final now = DateTime.now(),
        status = ledger.budgetStatus(budget, DateTime.now());
    final entries = ledger.budgetEntries(budget, status.window)
      ..sort((a, b) => b.date.compareTo(a.date));
    final daily = <DateTime, int>{};
    for (final entry in entries.where((e) => !e.date.isAfter(now))) {
      daily.update(
        dayOnly(entry.date),
        (n) => n + ledger.entryValue(entry),
        ifAbsent: () => ledger.entryValue(entry),
      );
    }
    final flows = List.generate(math.min(366, status.window.days), (i) {
      final date = DateTime(
            status.window.start.year,
            status.window.start.month,
            status.window.start.day + i,
          ),
          total =
              daily[DateTime(
                status.window.start.year,
                status.window.start.month,
                status.window.start.day + i,
              )] ??
              0;
      return DailyFlow(
        date,
        budget.income ? total : 0,
        budget.income ? 0 : total,
        date.isAfter(dayOnly(now)),
      );
    });
    final color = readableTint(context, Color(budget.color));
    final groups = <String, int>{};
    for (final entry in entries)
      groups.update(
        entry.categoryId,
        (v) => v + ledger.entryValue(entry),
        ifAbsent: () => ledger.entryValue(entry),
      );
    return FeaturePage(
      title: 'Budget details',
      actions: [
        IconButton(
          tooltip: 'Add budget transaction',
          onPressed: () => openTransactionSheet(
            context,
            initialType: budget.transactionType,
            initialBudgetId: budget.id,
          ),
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: 'Delete budget',
          onPressed: () async {
            final route = ModalRoute.of(context);
            if (!await confirm(
                  context,
                  'Delete budget?',
                  'This clears its links, not your transactions.',
                ) ||
                !context.mounted)
              return;
            final saved = await runSafe(
              context,
              () => ref.read(appProvider.notifier).deleteBudget(budget.id),
            );
            if (saved && context.mounted && route != null && route.isActive) {
              if (route.isCurrent)
                Navigator.pop(context);
              else
                Navigator.of(context).removeRoute(route);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
      fab: FloatingActionButton.extended(
        backgroundColor: Color(budget.color),
        foregroundColor: Color(budget.color).computeLuminance() > .35
            ? Colors.black
            : Colors.white,
        onPressed: () => editBudget(context, ref, budget),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: .25)),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ColorIcon(budget.icon, budget.color, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              SmallTag(titleCase(budget.period)),
                              SmallTag(budget.overall ? 'Overall' : 'Category'),
                              SmallTag(titleCase(budget.mode)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${(status.progress * 100).round()}% ${budget.income ? 'reached' : 'Used'}',
                    ),
                    AmountText(
                      status.spent,
                      prefix: '${budget.income ? 'Received ' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SmallTag(budgetStatusLabel(budget, status)),
                  ],
                ),
                const SizedBox(height: 12),
                WavyProgress(status.progress, color: color),
                const SizedBox(height: 20),
                SummaryColumns(
                  labels: [
                    status.remaining < 0 ? 'Over' : 'Remaining',
                    budget.income ? 'Received' : 'Spent',
                  ],
                  values: [
                    AmountText(status.remaining.abs()),
                    AmountText(status.spent),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${DateFormat.yMMMd().format(status.window.start)} – ${DateFormat.yMMMd().format(status.window.end.subtract(const Duration(days: 1)))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TonalCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Budget'),
              subtitle: const Text('Track this budget on the Home screen'),
              value: budget.showOnHome,
              onChanged: saving
                  ? null
                  : (value) async {
                      setState(() => saving = true);
                      await runSafe(
                        context,
                        () => ref
                            .read(appProvider.notifier)
                            .upsertBudget(budget.copyWith(showOnHome: value)),
                      );
                      if (mounted) setState(() => saving = false);
                    },
            ),
          ),
          const SizedBox(height: 12),
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Progress',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: color),
                ),
                const SizedBox(height: 22),
                BudgetProgressChart(
                  ledger: ledger,
                  status: status,
                  flows: flows,
                  income: budget.income,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Posted records through today. Future recorded entries affect the allowance but are not plotted as actual spending.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Breakdown',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: color),
                ),
                const SizedBox(height: 18),
                if (groups.isEmpty)
                  const Text('No matching records in this period.'),
                for (final group in groups.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ColorIcon(
                              ledger.category(group.key)?.icon ?? 'category',
                              ledger.category(group.key)?.color ?? budget.color,
                              size: 34,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ledger.category(group.key)?.name ??
                                    'Uncategorized',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: AmountText(group.value)),
                          ],
                        ),
                        const SizedBox(height: 9),
                        WavyProgress(
                          status.spent <= 0 ? 0 : group.value / status.spent,
                          color: readableTint(
                            context,
                            Color(
                              ledger.category(group.key)?.color ?? budget.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader('Recent transactions'),
          if (entries.isEmpty)
            const Text(
              'Link a transaction or record matching category activity to get started.',
            ),
          for (final entry in entries.take(30)) TransactionTile(entry),
        ],
      ),
    );
  }
}
