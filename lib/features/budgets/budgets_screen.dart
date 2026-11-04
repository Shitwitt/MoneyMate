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

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider)!;
    return FeaturePage(
      title: 'Budgets',
      subtitle: 'Make space for what matters',
      actions: [
        IconButton(
          tooltip: 'Create budget',
          onPressed: () => editBudget(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: profile.budgets.isEmpty
          ? EmptyState(
              title: 'A plan, not a restriction',
              message:
                  'Give your spending a little direction. Start with food, transport, or everything.',
              icon: Icons.donut_large_rounded,
              action: 'Create a budget',
              onAction: () => editBudget(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 110),
              itemCount: profile.budgets.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BudgetCard(profile.budgets[index]),
              ),
            ),
    );
  }
}

class BudgetCard extends ConsumerWidget {
  final Budget budget;
  const BudgetCard(this.budget, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final status = ledger.budgetStatus(budget, DateTime.now());
    final color = status.remaining < 0
        ? Theme.of(context).colorScheme.error
        : Color(budget.color);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => openPage(context, BudgetDetailScreen(budget.id)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ColorIcon('category', budget.color, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      budget.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${(status.progress * 100).round()}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              WavyProgress(status.progress, color: color),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AmountText(
                      status.spent,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text('of ', style: Theme.of(context).textTheme.bodySmall),
                  AmountText(
                    status.limit,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${status.label} · ${titleCase(budget.period)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AmountText(
                    status.remaining.abs(),
                    prefix: status.remaining < 0 ? 'Over ' : 'Left ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              if (status.carry != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AmountText(
                    status.carry,
                    prefix: 'Rollover ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
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
                BudgetCard(budget),
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
