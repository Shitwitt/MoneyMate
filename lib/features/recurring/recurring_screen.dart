import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final rules = [...ledger.data.recurrings]
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return FeaturePage(
      title: 'Life, on repeat',
      subtitle: 'Subscriptions & recurring entries',
      actions: [
        IconButton(
          tooltip: 'New recurring entry',
          onPressed: () => editRecurring(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          StatCard(
            title: 'Your monthly rhythm',
            value: AmountText(ledger.monthlyBurn),
            icon: Icons.repeat_rounded,
            caption:
                '${rules.where((rule) => rule.enabled).length} active · normalized using 365.25 days / year',
          ),
          const SizedBox(height: 12),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Auto-posted entries are caught up when you open or resume the app. Notifications can remind you while it is closed; they do not silently change balances.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (rules.isEmpty)
            EmptyState(
              title: 'One less thing to remember',
              message: 'Rent, payday, your favourite music. Set it once and keep an eye on the rhythm.',
              icon: Icons.event_repeat_rounded,
              action: 'Add a recurring entry',
              onAction: () => editRecurring(context, ref),
            ),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat.MMM().format(rule.nextDue),
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              '${rule.nextDue.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 5),
                            AmountText(
                              rule.amountMinor,
                              currency: ledger.account(rule.accountId).currency,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${rule.enabled ? '${rule.interval > 1 ? 'Every ${rule.interval} ' : ''}${rule.frequency}' : 'Paused'} · ${rule.autoPost ? 'Auto-post' : 'Remind only'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (!rule.autoPost &&
                                rule.enabled &&
                                !rule.nextDue.isAfter(DateTime.now()))
                              TextButton.icon(
                                onPressed: () => runSafe(
                                  context,
                                  () => ref
                                      .read(appProvider.notifier)
                                      .processRecurring(recordNowId: rule.id),
                                  success: 'Recurring entry recorded',
                                ),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Record due entry'),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          final controller = ref.read(appProvider.notifier);
                          switch (action) {
                            case 'edit':
                              await editRecurring(context, ref, rule);
                            case 'pause':
                              await runSafe(
                                context,
                                () => controller.upsertRecurring(
                                  rule.copyWith(enabled: !rule.enabled),
                                ),
                              );
                            case 'skip':
                              await runSafe(
                                context,
                                () => controller.upsertRecurring(
                                  rule.copyWith(
                                    nextDue: nextOccurrence(rule, rule.nextDue),
                                  ),
                                ),
                              );
                            case 'delete':
                              if (await confirm(
                                    context,
                                    'Delete recurring rule?',
                                    'Already posted transactions will remain.',
                                  ) &&
                                  context.mounted) {
                                await runSafe(
                                  context,
                                  () => controller.deleteRecurring(rule.id),
                                );
                              }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'pause',
                            child: Text(rule.enabled ? 'Pause' : 'Resume'),
                          ),
                          const PopupMenuItem(
                            value: 'skip',
                            child: Text('Skip next occurrence'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> editRecurring(
  BuildContext context,
  WidgetRef ref, [
  Recurring? initial,
]) async {
  final profile = ref.read(profileProvider)!;
  var accountId =
          initial?.accountId ??
          profile.accounts.firstWhere((item) => !item.archived).id,
      type = initial?.type ?? 'expense',
      frequency = initial?.frequency ?? 'monthly';
  var categoryId =
      initial?.categoryId ??
      profile.categories.firstWhere((item) => item.type == 'expense').id;
  final name = TextEditingController(text: initial?.name ?? ''),
      amount = TextEditingController(
        text: initial == null
            ? ''
            : fromMinor(
                initial.amountMinor,
                profile.accounts
                    .firstWhere((item) => item.id == accountId)
                    .currency,
              ).toString(),
      ),
      interval = TextEditingController(text: '${initial?.interval ?? 1}'),
      notes = TextEditingController(text: initial?.notes ?? '');
  var start = initial?.start ?? DateTime.now().add(const Duration(days: 1));
  var end = initial?.end ?? DateTime.now().add(const Duration(days: 365));
  var hasEnd = initial?.end != null;
  var auto = initial?.autoPost ?? true;
  await showEditor(
    context,
    title: initial == null ? 'Set a little rhythm' : 'Edit recurring entry',
    fields: (context, setLocal) => [
      formText(name, 'Name', required: true),
      formSelect(
        'Type',
        type,
        ['expense', 'income'],
        (value) => setLocal(() {
          type = value;
          categoryId = profile.categories
              .firstWhere((item) => item.type == type)
              .id;
        }),
      ),
      formSelect(
        'Account',
        accountId,
        profile.accounts.map((item) => item.id).toList(),
        (value) => setLocal(() => accountId = value),
        display: (id) =>
            '${profile.accounts.firstWhere((item) => item.id == id).name} · ${profile.accounts.firstWhere((item) => item.id == id).currency}',
      ),
      formText(
        amount,
        'Amount (account currency)',
        required: true,
        numeric: true,
      ),
      formSelect(
        'Category',
        categoryId,
        profile.categories
            .where((item) => item.type == type)
            .map((item) => item.id)
            .toList(),
        (value) => setLocal(() => categoryId = value),
        display: (id) =>
            profile.categories.firstWhere((item) => item.id == id).name,
      ),
      formSelect(
        'Frequency',
        frequency,
        frequencies,
        (value) => setLocal(() => frequency = value),
      ),
      formText(
        interval,
        frequency == 'custom'
            ? 'Every N days'
            : 'Every N ${frequency == 'daily'
                  ? 'days'
                  : frequency == 'weekly'
                  ? 'weeks'
                  : frequency == 'yearly'
                  ? 'years'
                  : 'months'}',
        required: true,
        numeric: true,
      ),
      formDate(
        context,
        'Starts',
        start,
        (value) => setLocal(() => start = value),
        includeTime: true,
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('End on a date'),
        value: hasEnd,
        onChanged: (value) => setLocal(() => hasEnd = value),
      ),
      if (hasEnd)
        formDate(
          context,
          'Ends (inclusive)',
          end,
          (value) => setLocal(
            () => end = DateTime(value.year, value.month, value.day, 23, 59),
          ),
        ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Auto-create due entries'),
        subtitle: const Text('Otherwise remind me and let me confirm each one'),
        value: auto,
        onChanged: (value) => setLocal(() => auto = value),
      ),
      formText(notes, 'Notes', lines: 2),
    ],
    onSave: () async {
      final step = int.tryParse(interval.text);
      if (step == null || step < 1 || step > 365) {
        throw const FormatException('Interval must be 1–365');
      }
      final currency = profile.accounts
          .firstWhere((item) => item.id == accountId)
          .currency;
      await ref
          .read(appProvider.notifier)
          .upsertRecurring(
            Recurring(
              id: initial?.id ?? uuid.v4(),
              name: name.text.trim(),
              amountMinor: toMinor(evaluateAmount(amount.text), currency),
              accountId: accountId,
              categoryId: categoryId,
              start: start,
              nextDue: initial != null && initial.start == start
                  ? initial.nextDue
                  : start,
              type: type,
              frequency: frequency,
              interval: step,
              end: hasEnd ? end : null,
              autoPost: auto,
              enabled: initial?.enabled ?? true,
              notes: notes.text.trim(),
            ),
          );
      await ref.read(appProvider.notifier).processRecurring();
    },
  );
  for (final controller in [name, amount, interval, notes]) {
    controller.dispose();
  }
}
