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
          IconButton(
            tooltip: 'New recurring entry',
            onPressed: () => editRecurring(context, ref),
            icon: const Icon(Icons.add_rounded),
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
    final expenses = active
        .where((r) => r.type == 'expense')
        .fold<double>(0, (sum, r) => sum + ledger.monthlyCost(r))
        .round();
    final income = active
        .where((r) => r.type == 'income')
        .fold<double>(0, (sum, r) => sum + ledger.monthlyCost(r))
        .round();
    final month = DateWindow(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    );
    var dueAmount = 0, occurrences = 0;
    for (final rule in active) {
      final count = projectedOccurrences(rule, month).length;
      occurrences += count;
      dueAmount +=
          count *
          ledger.inBase(
            rule.amountMinor,
            ledger.account(rule.accountId).currency,
          );
    }
    final due = active.where((r) => recurringDue(r, now)).length;
    Widget metric(
      String title,
      int amount,
      IconData icon,
      Color tint,
      String caption,
    ) => TonalCard(
      color: AppColors.dark(context)
          ? Color.alphaBlend(tint.withValues(alpha: .10), AppColors.darkCard)
          : tint,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 10),
          Text(title),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AmountText(
              amount,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 4),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TonalCard(
          color: Theme.of(context).colorScheme.primary,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            child: IconTheme(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat_rounded, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Monthly average',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${active.length} active',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: AmountText(
                      expenses,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  WavyProgress(
                    active.isEmpty ? 0 : due / active.length,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$due due · expense projection in ${ledger.data.profile.currency}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: metric(
                  'Due this month',
                  dueAmount,
                  Icons.calendar_month_outlined,
                  const Color(0xffE8D5D0),
                  '$occurrences scheduled occurrences',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: metric(
                  'Yearly',
                  expenses * 12,
                  Icons.calendar_today_outlined,
                  const Color(0xffE9DDBF),
                  'Expense projection',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: metric(
                  'Income',
                  income,
                  Icons.south_west_rounded,
                  AppColors.successBackground,
                  'Monthly projection',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: metric(
                  'Expenses',
                  expenses,
                  Icons.north_east_rounded,
                  AppColors.errorBackground,
                  'Monthly projection',
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
    return TonalCard(
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
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: AmountText(
                    rule.amountMinor,
                    currency: account.currency,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: tint),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_outlined, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due ? 'Payment due' : 'Next payment',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat.yMMMd().add_jm().format(rule.nextDue),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SmallTag(
                  account.name,
                  icon: Icons.account_balance_wallet_outlined,
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
    );
  }
}
