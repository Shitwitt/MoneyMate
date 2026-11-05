import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../goals/goals_screen.dart';
import '../transactions/transactions_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('A little intention goes a long way'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Budgets', icon: Icon(Icons.donut_large_rounded)),
            Tab(text: 'Savings goals', icon: Icon(Icons.flag_outlined)),
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
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return FeaturePage(
      title: 'Budgets',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort budgets',
          icon: const Icon(Icons.sort_rounded),
          onSelected: (value) => setState(() => sort = value),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'name', child: Text('Name')),
            PopupMenuItem(
              value: 'amount',
              child: Text('Allowance · highest first'),
            ),
          ],
        ),
        IconButton(
          tooltip: 'About budgets',
          onPressed: () => showFeatureInfo(
            context,
            'Budgets',
            'Set an allowance for all expenses or selected categories. Weekly, monthly and yearly periods renew automatically. Custom periods end on the date you choose. Rollover carries the actual previous surplus or deficit; it does not move money.',
          ),
          icon: const Icon(Icons.info_outline_rounded),
        ),
        IconButton(
          tooltip: 'Create budget',
          onPressed: () => editBudget(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: budgets.isEmpty
          ? EmptyState(
              title: 'A plan, not a restriction',
              message:
                  'Create a spending plan for the things that matter to you.',
              icon: Icons.pie_chart_outline_rounded,
              action: 'Create a budget',
              onAction: () => editBudget(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: budgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => BudgetCard(budgets[index]),
            ),
    );
  }
}

class BudgetCard extends ConsumerWidget {
  final Budget budget;
  final bool openDetails;
  const BudgetCard(this.budget, {super.key, this.openDetails = true});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final status = ledger.budgetStatus(budget, DateTime.now());
    final color = readableTint(context, Color(budget.color));
    final category = ledger.data.categories
        .where((c) => budget.categoryIds.contains(c.id))
        .firstOrNull;
    final background = Color.alphaBlend(
      Color(
        budget.color,
      ).withValues(alpha: AppColors.dark(context) ? .16 : .22),
      Theme.of(context).colorScheme.surface,
    );
    return BudgetWarningFrame(
      overLimit: status.remaining < 0,
      child: TonalCard(
        color: background,
        onTap: openDetails
            ? () => openPage(context, BudgetDetailScreen(budget.id))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ColorIcon(category?.icon ?? 'savings', budget.color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          SmallTag(titleCase(budget.period)),
                          SmallTag(
                            budget.categoryIds.isEmpty
                                ? 'All expenses'
                                : 'Category',
                          ),
                          if (budget.period != 'custom')
                            const SmallTag(
                              'Auto',
                              icon: Icons.autorenew_rounded,
                            ),
                          if (budget.rollover) const SmallTag('Rollover'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            WavyProgress(status.progress, color: color),
            const SizedBox(height: 20),
            SummaryColumns(
              labels: [
                'Spent',
                'Budget',
                status.remaining < 0 ? 'Over budget' : 'Remaining',
              ],
              values: [
                AmountText(status.spent),
                AmountText(status.limit),
                AmountText(status.remaining.abs()),
              ],
            ),
            if (status.carry != 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
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
  final name = TextEditingController(text: initial?.name ?? ''),
      amount = TextEditingController(
        text: initial == null
            ? ''
            : fromMinor(
                initial.limitMinor,
                profile.profile.currency,
              ).toString(),
      );
  var period = initial?.period ?? 'monthly';
  var start =
      initial?.start ??
      financialMonth(
        DateTime.now(),
        ref.read(appProvider).settings.monthStart,
      ).start;
  var end =
      initial?.end ??
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  var categories = {...?initial?.categoryIds};
  var rollover = initial?.rollover ?? false;
  var color = initial?.color ?? palette.first;
  await showEditor(
    context,
    title: initial == null ? 'A little plan for your money' : 'Edit budget',
    description:
        'An empty category selection includes all expenses. Rollover carries unused allowance AND deducts overspending from the next period.',
    fields: (context, setLocal) => [
      formText(name, 'Budget name', required: true),
      formText(
        amount,
        'Allowance (${profile.profile.currency})',
        numeric: true,
        required: true,
      ),
      formSelect(
        'Period',
        period,
        periods,
        (value) => setLocal(() => period = value),
      ),
      formDate(
        context,
        period == 'monthly' ? 'Start / monthly renewal day' : 'Starts on',
        start,
        (value) => setLocal(() => start = value),
      ),
      if (period == 'custom')
        formDate(
          context,
          'Ends on (inclusive)',
          end,
          (value) => setLocal(() => end = value),
        ),
      formChips(
        'Included categories',
        {
          for (final item in profile.categories.where(
            (item) => item.type == 'expense',
          ))
            item.id: item.name,
        },
        categories,
        (value) => setLocal(() => categories = value),
      ),
      if (period != 'custom')
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Rollover unused or overspent money'),
          value: rollover,
          onChanged: (value) => setLocal(() => rollover = value),
        ),
      formColors(color, (value) => setLocal(() => color = value)),
    ],
    onSave: () => ref
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
          ),
        ),
  );
  name.dispose();
  amount.dispose();
}

class BudgetDetailScreen extends ConsumerWidget {
  final String id;
  const BudgetDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final budget = ledger.data.budgets
        .where((item) => item.id == id)
        .firstOrNull;
    if (budget == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Budget removed',
          message: 'Your transaction history is unchanged.',
        ),
      );
    }
    final status = ledger.budgetStatus(budget, DateTime.now());
    return FeaturePage(
      title: budget.name,
      padded: false,
      actions: [
        IconButton(
          tooltip: 'Edit budget',
          onPressed: () => editBudget(context, ref, budget),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete budget',
          onPressed: () async {
            if (await confirm(
                  context,
                  'Delete budget?',
                  'This does not delete any transactions.',
                ) &&
                context.mounted) {
              final saved = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteBudget(id),
              );
              if (saved && context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${DateFormat.yMMMd().format(status.window.start)} — ${DateFormat.yMMMd().format(status.window.end.subtract(const Duration(days: 1)))}',
                ),
                const SizedBox(height: 14),
                BudgetCard(budget, openDetails: false),
              ],
            ),
          ),
          Expanded(
            child: TransactionsScreen(
              title: 'Actual spending',
              initialFilter: TransactionFilter(
                dates: status.window,
                type: 'expense',
                categories: budget.categoryIds.toSet(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
