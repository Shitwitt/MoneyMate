import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/data/recurring_schedule.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import '../settings/notifications_screen.dart';
import '../transactions/transaction_tile.dart';
import 'recurring_editor.dart';
import 'recurring_help.dart';

class RecurringDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const RecurringDetailScreen(this.id, {super.key});
  @override
  ConsumerState<RecurringDetailScreen> createState() =>
      _RecurringDetailScreenState();
}

class _RecurringDetailScreenState extends ConsumerState<RecurringDetailScreen> {
  bool busy = false;
  Future<void> action(Recurring rule, bool process) async {
    if (busy) return;
    setState(() => busy = true);
    await runSafe(
      context,
      () => process
          ? ref
                .read(appProvider.notifier)
                .processRecurringOccurrence(rule.id, expectedDue: rule.nextDue)
          : ref
                .read(appProvider.notifier)
                .skipRecurringOccurrence(rule.id, expectedDue: rule.nextDue),
      success: process ? 'Occurrence recorded' : 'Next occurrence skipped',
    );
    if (mounted) setState(() => busy = false);
  }

  Future<void> menu(Recurring rule, String action) async {
    if (action == 'edit') {
      await editRecurring(context, ref, rule);
      return;
    }
    if (action == 'archive') {
      await runSafe(
        context,
        () => ref
            .read(appProvider.notifier)
            .upsertRecurring(
              rule.copyWith(archived: !rule.archived, enabled: rule.archived),
            ),
        success: rule.archived ? 'Schedule restored' : 'Schedule archived',
      );
    } else if (action == 'resume') {
      await runSafe(
        context,
        () => ref
            .read(appProvider.notifier)
            .upsertRecurring(rule.copyWith(enabled: !rule.enabled)),
      );
    } else if (action == 'delete') {
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context);
      if (await confirm(
            context,
            'Delete recurring?',
            'This removes the schedule. Already recorded transactions are kept.',
          ) &&
          mounted) {
        final saved = await runSafe(
          context,
          () => ref.read(appProvider.notifier).deleteRecurring(rule.id),
        );
        if (saved && route != null && route.isActive) {
          if (route.isCurrent) {
            navigator.pop();
          } else {
            navigator.removeRoute(route);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final rule = ledger.data.recurrings
        .where((r) => r.id == widget.id)
        .firstOrNull;
    if (rule == null)
      return const FeaturePage(
        title: 'Recurring',
        child: Center(
          child: Text(
            'This schedule was deleted. Its recorded transactions remain in your ledger.',
          ),
        ),
      );
    final category = ledger.category(rule.categoryId);
    final account = ledger.account(rule.accountId);
    final now = DateTime.now();
    final due = recurringDue(rule, now), active = recurringActive(rule);
    final days = calendarDaysBetween(now, rule.nextDue);
    final history =
        ledger.data.transactions.where((e) => e.recurringId == rule.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final recorded = history.where((e) => !e.date.isAfter(now)).toList();
    final total = recorded.fold<int>(0, (sum, e) => sum + ledger.entryValue(e));
    final tint = Color(category?.color ?? 0xfff6bb96);
    final hero = AppColors.dark(context)
        ? Color.alphaBlend(tint.withValues(alpha: .14), AppColors.darkCard)
        : Color.alphaBlend(tint.withValues(alpha: .20), AppColors.card);
    String entityNames(Iterable<String> ids) => ledger.data.entities
        .where((e) => ids.contains(e.id))
        .map((e) => e.name)
        .join(', ');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring details'),
        actions: [
          IconButton(
            tooltip: 'Edit recurring',
            onPressed: () => editRecurring(context, ref, rule),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Recurring options',
            onSelected: (value) => menu(rule, value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(rule.archived ? 'Restore from archive' : 'Archive'),
              ),
              if (!rule.archived)
                PopupMenuItem(
                  value: 'resume',
                  child: Text(rule.enabled ? 'Pause' : 'Resume'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete recurring'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              TonalCard(
                color: hero,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RecurringDetailHeading(
                      rule: rule,
                      category: category,
                      account: account,
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          due
                              ? Icons.event_busy_outlined
                              : Icons.event_outlined,
                          color: due
                              ? AppColors.semantic(context, 'expense')
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next occurrence',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  rule.nextDue,
                                ),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: SmallTag(
                            due
                                ? days < 0
                                      ? 'Overdue'
                                      : 'Due now'
                                : active
                                ? 'Upcoming'
                                : 'Inactive',
                            color: due
                                ? AppColors.semantic(context, 'expense')
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    WavyProgress(
                      occurrenceProgress(rule, now),
                      color: readableTint(context, tint),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            due
                                ? days < 0
                                      ? '${-days} ${days == -1 ? 'day' : 'days'} overdue'
                                      : 'Due now'
                                : !active
                                ? 'Not processing'
                                : days == 0
                                ? 'Later today'
                                : 'In $days days',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${(occurrenceProgress(rule, now) * 100).round()}%',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (active) ...[
                const SizedBox(height: 12),
                _RecurringDetailActions(
                  busy: busy,
                  due: due,
                  process: () => action(rule, true),
                  skip: () => action(rule, false),
                ),
              ],
              const SizedBox(height: 20),
              SectionHeader(
                'Details',
                trailing: IconButton(
                  tooltip: 'How recurring works',
                  onPressed: () => showRecurringHelp(context),
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ),
              Card.outlined(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    DetailRow(
                      Icons.account_balance_wallet_outlined,
                      'Paid from',
                      '${account.name} · ${account.currency}',
                    ),
                    DetailRow(
                      Icons.category_outlined,
                      'Category',
                      category?.name ?? 'Uncategorized',
                    ),
                    DetailRow(
                      Icons.event_outlined,
                      'Start date',
                      DateFormat.yMMMd().format(rule.start),
                    ),
                    DetailRow(
                      Icons.repeat_rounded,
                      'Frequency',
                      recurrenceLabel(rule),
                    ),
                    DetailRow(
                      Icons.notifications_none_rounded,
                      'Reminder',
                      '${rule.reminderDays == 0 ? 'On the due date' : '${rule.reminderDays} days before'} · ${ref.watch(appProvider).settings.notificationsEnabled ? 'Enabled' : 'Notifications off'}',
                      onTap: () =>
                          openPage(context, const NotificationsScreen()),
                    ),
                    if (rule.end != null)
                      DetailRow(
                        Icons.event_busy_outlined,
                        'End date · inclusive',
                        DateFormat.yMMMd().format(rule.end!),
                      ),
                    if (rule.budgetId.isNotEmpty)
                      DetailRow(
                        Icons.pie_chart_outline_rounded,
                        'Linked budget',
                        ledger.data.budgets
                                .where((b) => b.id == rule.budgetId)
                                .firstOrNull
                                ?.name ??
                            'No budget',
                      ),
                    if (rule.labelIds.isNotEmpty)
                      DetailRow(
                        Icons.sell_outlined,
                        'Labels',
                        entityNames(rule.labelIds),
                      ),
                    if (rule.personIds.isNotEmpty)
                      DetailRow(
                        Icons.people_outline_rounded,
                        'People',
                        entityNames(rule.personIds),
                      ),
                    if (rule.placeId.isNotEmpty)
                      DetailRow(
                        Icons.place_outlined,
                        'Place',
                        entityNames([rule.placeId]),
                      ),
                    if (rule.notes.isNotEmpty)
                      DetailRow(Icons.notes_rounded, 'Notes', rule.notes),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader('Statistics'),
              _Statistics(
                count: recorded.length,
                total: total,
                monthly: ledger.monthlyCost(rule).round(),
              ),
              const SizedBox(height: 10),
              Text(
                'Totals use recorded transactions up to today, converted to ${ledger.data.profile.currency}. Monthly average is a schedule projection, not money spent.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              SectionHeader(
                'History',
                trailing: SmallTag('${history.length} transactions'),
              ),
              if (history.isEmpty)
                const TonalCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 32),
                        SizedBox(height: 12),
                        Text(
                          'No payments recorded yet.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              if (history.isNotEmpty)
                TonalCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final entry in history) TransactionTile(entry),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Statistics extends StatelessWidget {
  final int count, total, monthly;
  const _Statistics({
    required this.count,
    required this.total,
    required this.monthly,
  });
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: TonalCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    [
                      Icons.receipt_outlined,
                      Icons.payments_outlined,
                      Icons.calendar_month_outlined,
                    ][i],
                    size: 20,
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: i == 0
                        ? Text(
                            '$count',
                            style: Theme.of(context).textTheme.titleLarge,
                          )
                        : AmountText(
                            i == 1 ? total : monthly,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ['Occurrences', 'Total recorded', 'Monthly average'][i],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _RecurringDetailActions extends StatelessWidget {
  final bool busy, due;
  final VoidCallback process, skip;
  const _RecurringDetailActions({
    required this.busy,
    required this.due,
    required this.process,
    required this.skip,
  });
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
    );
    final first = FilledButton.icon(
      onPressed: busy || !due ? null : process,
      style: FilledButton.styleFrom(
        textStyle: style,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        minimumSize: const Size(0, 52),
      ),
      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
      label: Text(busy ? 'Saving…' : 'Process'),
    );
    final second = OutlinedButton.icon(
      onPressed: busy ? null : skip,
      style: OutlinedButton.styleFrom(
        textStyle: style,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        minimumSize: const Size(0, 52),
      ),
      icon: const Icon(Icons.skip_next_outlined, size: 20),
      label: const Text('Skip next'),
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 360) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 10), second],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }
}

class _RecurringDetailHeading extends StatelessWidget {
  final Recurring rule;
  final Category? category;
  final Account account;
  const _RecurringDetailHeading({
    required this.rule,
    required this.category,
    required this.account,
  });
  @override
  Widget build(BuildContext context) {
    final active = recurringActive(rule);
    final icon = ColorIcon(
      category?.icon ?? 'bills',
      category?.color ?? 0xfff6bb96,
      size: 48,
    );
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rule.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            SmallTag(recurrenceLabel(rule)),
            SmallTag(
              rule.type == 'income' ? 'Income' : 'Expense',
              color: AppColors.semantic(context, rule.type),
            ),
            if (!active)
              SmallTag(rule.archived ? 'Archived' : 'Paused / ended'),
            if (rule.autoPost) const SmallTag('Auto processing'),
          ],
        ),
      ],
    );
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: AmountText(
        rule.amountMinor,
        currency: account.currency,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.semantic(context, rule.type),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 360 ||
        rule.amountMinor.abs() > 999999999) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(child: label),
            ],
          ),
          const SizedBox(height: 14),
          amount,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(child: label),
        const SizedBox(width: 8),
        Flexible(child: amount),
      ],
    );
  }
}
