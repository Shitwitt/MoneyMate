import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/recurring_schedule.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import 'recurring_calendar.dart';
import 'recurring_detail_screen.dart';
import 'recurring_editor.dart';
import 'recurring_help.dart';
export 'recurring_editor.dart';

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});
  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  int section = 0, view = 0;
  String sort = 'date';
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final now = DateTime.now();
    final all = ledger.data.recurrings;
    final active = all.where(recurringActive).toList();
    final due = active.where((r) => recurringDue(r, now)).toList();
    final archived = all.where((r) => !recurringActive(r)).toList();
    final rules =
        [
          ...[active, due, archived][section],
        ]..sort(
          (a, b) => switch (sort) {
            'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            'amount' =>
              ledger
                  .inBase(b.amountMinor, ledger.account(b.accountId).currency)
                  .compareTo(
                    ledger.inBase(
                      a.amountMinor,
                      ledger.account(a.accountId).currency,
                    ),
                  ),
            _ => a.nextDue.compareTo(b.nextDue),
          },
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort recurring',
            icon: const Icon(Icons.sort_rounded),
            initialValue: sort,
            onSelected: (value) => setState(() => sort = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date', child: Text('Next payment')),
              PopupMenuItem(value: 'name', child: Text('Name')),
              PopupMenuItem(
                value: 'amount',
                child: Text('Amount · highest first'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'How recurring works',
            onPressed: () => showRecurringHelp(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              RecurringOverview(ledger: ledger, now: now),
              const SizedBox(height: 20),
              PillTabs(
                labels: const ['All', 'Calendar'],
                selected: view,
                icons: const [
                  Icons.view_list_outlined,
                  Icons.calendar_month_outlined,
                ],
                onSelected: (index) => setState(() => view = index),
              ),
              const SizedBox(height: 16),
              SectionHeader('${rules.length} recurring'),
              if (view == 1)
                RecurringCalendar(
                  rules: rules,
                  ledger: ledger,
                  onOpen: (rule) =>
                      openPage(context, RecurringDetailScreen(rule.id)),
                ),
              if (view == 0 && rules.isEmpty)
                EmptyState(
                  title: section == 1
                      ? 'You’re all caught up!'
                      : section == 2
                      ? 'Nothing archived'
                      : 'Make room for a rhythm',
                  message: section == 1
                      ? 'No active payments are due right now.'
                      : section == 2
                      ? 'Paused, ended, and archived schedules will appear here.'
                      : 'Track a subscription, rent, salary, or another repeating entry.',
                  icon: section == 1
                      ? Icons.task_alt_rounded
                      : Icons.repeat_rounded,
                  action: section == 0 ? 'New recurring' : null,
                  onAction: section == 0
                      ? () => editRecurring(context, ref)
                      : null,
                ),
              if (view == 0)
                for (final rule in rules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecurringRuleCard(rule),
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New recurring entry',
        onPressed: () => editRecurring(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PillTabs(
            labels: [
              'Active · ${active.length}',
              'Due · ${due.length}',
              'Archived · ${archived.length}',
            ],
            selected: section,
            onSelected: (index) => setState(() => section = index),
          ),
        ),
      ),
    );
  }
}

class RecurringOverview extends StatelessWidget {
  final Ledger ledger;
  final DateTime now;
  const RecurringOverview({super.key, required this.ledger, required this.now});
  @override
  Widget build(BuildContext context) {
    final active = ledger.data.recurrings.where(recurringActive).toList();
    int monthly(String type) => active
        .where((r) => r.type == type)
        .fold<double>(0, (sum, r) => sum + ledger.monthlyCost(r))
        .round();
    final expenses = monthly('expense'), income = monthly('income');
    final month = DateWindow(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    );
    final dueAmount = active.fold<int>(
      0,
      (sum, rule) =>
          sum +
          projectedOccurrences(rule, month).length *
              ledger.inBase(
                rule.amountMinor,
                ledger.account(rule.accountId).currency,
              ),
    );
    Widget metric(
      String title,
      int amount,
      IconData icon,
      Color background,
      Color ink,
      String description,
    ) => Tooltip(
      message: description,
      child: TonalCard(
        color: background,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(
                amount,
                style: TextStyle(
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final dark = AppColors.dark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tooltip(
          message:
              'Monthly expense estimate from active schedules in ${ledger.currency}. Not recorded spending.',
          child: TonalCard(
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insert_chart_outlined_rounded,
                      size: 22,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Monthly average',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: AmountText(
                    expenses,
                    style: TextStyle(
                      fontSize: 31,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: metric(
                  'Due this month',
                  dueAmount,
                  Icons.event_repeat_outlined,
                  dark ? const Color(0xff72361E) : const Color(0xffFFE1D1),
                  dark ? const Color(0xffFFE0D2) : AppColors.primaryInk,
                  'Scheduled occurrences this calendar month, converted to ${ledger.currency}. Includes income and expenses, not a statement of payments made.',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: metric(
                  'Total yearly',
                  expenses * 12,
                  Icons.calendar_month_outlined,
                  dark ? const Color(0xff49430C) : const Color(0xffF2E7B6),
                  dark ? const Color(0xffF5E6A7) : const Color(0xff514809),
                  'Annualized expense projection from active schedules.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: metric(
                  'Income',
                  income,
                  Icons.trending_up_rounded,
                  dark ? const Color(0xff074926) : AppColors.successBackground,
                  dark ? const Color(0xffA7E3B0) : AppColors.incomeInk,
                  'Monthly income projection from active schedules.',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: metric(
                  'Expense',
                  expenses,
                  Icons.trending_down_rounded,
                  dark ? const Color(0xff700F18) : AppColors.errorBackground,
                  dark ? const Color(0xffFFBDC3) : AppColors.expenseInk,
                  'Monthly expense projection from active schedules.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RecurringRuleCard extends ConsumerStatefulWidget {
  final Recurring rule;
  final VoidCallback? onOpen;
  const RecurringRuleCard(this.rule, {super.key, this.onOpen});
  @override
  ConsumerState<RecurringRuleCard> createState() => _RecurringRuleCardState();
}

class _RecurringRuleCardState extends ConsumerState<RecurringRuleCard> {
  bool busy = false;
  Future<void> act(bool process) async {
    if (busy) return;
    setState(() => busy = true);
    final rule = widget.rule;
    await runSafe(
      context,
      () => process
          ? ref
                .read(appProvider.notifier)
                .processRecurringOccurrence(rule.id, expectedDue: rule.nextDue)
          : ref
                .read(appProvider.notifier)
                .skipRecurringOccurrence(rule.id, expectedDue: rule.nextDue),
      success: process
          ? 'Occurrence recorded'
          : 'Occurrence skipped · no balance changed',
    );
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final ledger = ref.watch(ledgerProvider)!;
    final category = ledger.category(rule.categoryId);
    final account = ledger.account(rule.accountId);
    final due = recurringDue(rule, DateTime.now());
    final tint = readableTint(context, Color(category?.color ?? 0xfff6bb96));
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: tint.withValues(alpha: .25),
      ),
      child: TonalCard(
        radius: 27,
        onTap:
            widget.onOpen ??
            () => openPage(context, RecurringDetailScreen(rule.id)),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ColorIcon(
                  category?.icon ?? 'bills',
                  category?.color ?? 0xfff6bb96,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          SmallTag(recurrenceLabel(rule)),
                          SmallTag(
                            rule.type == 'income' ? 'Income' : 'Expense',
                            color: AppColors.semantic(context, rule.type),
                          ),
                          if (!recurringActive(rule))
                            SmallTag(
                              rule.archived ? 'Archived' : 'Paused / ended',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        due ? 'Payment due' : 'Next payment',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat.yMMMd().format(rule.nextDue),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: AmountText(
                          rule.amountMinor,
                          currency: account.currency,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.semantic(context, rule.type),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (due) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => act(false),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : () => act(true),
                      child: Text(busy ? 'Saving…' : 'Process'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
