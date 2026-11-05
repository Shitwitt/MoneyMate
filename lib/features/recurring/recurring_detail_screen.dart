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
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ColorIcon(
                          category?.icon ?? 'bills',
                          category?.color ?? 0xfff6bb96,
                          size: 58,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            rule.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: AmountText(
                        rule.amountMinor,
                        currency: account.currency,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        SmallTag(recurrenceLabel(rule)),
                        SmallTag(rule.type == 'income' ? 'Income' : 'Expense'),
                        SmallTag(
                          rule.archived
                              ? 'Archived'
                              : active
                              ? 'Active'
                              : 'Paused / ended',
                        ),
                        if (rule.autoPost)
                          const SmallTag(
                            'Auto processing',
                            icon: Icons.auto_awesome_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      due
                          ? (days < 0 ? '${-days} days overdue' : 'Due now')
                          : !active
                          ? 'Schedule is not processing'
                          : days == 0
                          ? 'Later today'
                          : 'Next payment in $days days',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    WavyProgress(
                      occurrenceProgress(rule, now),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Next occurrence · ${DateFormat.yMMMd().add_jm().format(rule.nextDue)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (active) ...[
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: busy || !due
                            ? null
                            : () => action(rule, true),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(busy ? 'Saving…' : 'Process'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => action(rule, false),
                        icon: const Icon(Icons.skip_next_outlined),
                        label: const Text('Skip next'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                'Details',
                trailing: IconButton(
                  tooltip: 'How recurring works',
                  onPressed: () => showRecurringHelp(context),
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ),
              TonalCard(
                padding: EdgeInsets.zero,
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
