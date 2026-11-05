import 'dart:math' as math;

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
import '../transactions/transaction_tile.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int selected = 0;
  String sort = 'date';
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final goals =
        ledger.data.goals
            .where(
              (g) => selected == 2
                  ? g.archived
                  : !g.archived &&
                        (selected == 1
                            ? ledger.goalSaved(g) >= g.targetMinor
                            : ledger.goalSaved(g) < g.targetMinor),
            )
            .toList()
          ..sort(
            (a, b) => sort == 'name'
                ? a.name.compareTo(b.name)
                : a.deadline.compareTo(b.deadline),
          );
    return FeaturePage(
      title: 'Goals',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort goals',
          icon: const Icon(Icons.sort_rounded),
          onSelected: (value) => setState(() => sort = value),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'date', child: Text('Target date')),
            PopupMenuItem(value: 'name', child: Text('Name')),
          ],
        ),
        IconButton(
          tooltip: 'Create savings goal',
          onPressed: () => editGoal(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: Column(
        children: [
          PillTabs(
            labels: const ['Active', 'Completed', 'Archived'],
            selected: selected,
            onSelected: (value) => setState(() => selected = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: goals.isEmpty
                ? EmptyState(
                    title: selected == 2
                        ? 'Nothing archived'
                        : selected == 1
                        ? 'Keep taking little steps'
                        : 'What are you dreaming of?',
                    message: selected == 2
                        ? 'Archive a goal from its details without losing contributions.'
                        : selected == 1
                        ? 'Completed goals will appear here.'
                        : 'Give your next dream a name and a target date.',
                    icon: Icons.flag_outlined,
                    action: selected == 0 ? 'Start a goal' : null,
                    onAction: selected == 0
                        ? () => editGoal(context, ref)
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: goals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => GoalCard(goals[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class GoalCard extends ConsumerWidget {
  final Goal goal;
  final bool openDetails;
  const GoalCard(this.goal, {super.key, this.openDetails = true});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final saved = ledger.goalSaved(goal);
    final remaining = math.max(0, goal.targetMinor - saved);
    final days = calendarDaysBetween(DateTime.now(), goal.deadline);
    final dates = goal.contributions.map((e) => e.date).toList()..sort();
    final start =
        goal.start ??
        (dates.isEmpty ? ledger.data.profile.createdAt : dates.first);
    final duration = math.max(1, calendarDaysBetween(start, goal.deadline));
    final ink = readableTint(context, Color(goal.color));
    return TonalCard(
      color: Color.alphaBlend(
        Color(
          goal.color,
        ).withValues(alpha: AppColors.dark(context) ? .17 : .27),
        Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.all(18),
      onTap: openDetails
          ? () => openPage(context, GoalDetailScreen(goal.id))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColorIcon(goal.icon, goal.color, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              WavyRing(
                saved / goal.targetMinor,
                size: 46,
                color: ink,
                child: Text(
                  '${(saved / goal.targetMinor * 100).clamp(0, 100).round()}%',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 7,
            children: [
              Text(
                'From: ${DateFormat.MMMd().format(start)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'To: ${DateFormat.MMMd().format(goal.deadline)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              AmountText(
                days < 1 ? remaining : (remaining / days).ceil(),
                prefix: 'Daily: ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),
          SummaryColumns(
            labels: const ['Saved', 'Goal', 'Remaining'],
            values: [
              AmountText(saved),
              AmountText(goal.targetMinor),
              Text(
                days < 0
                    ? 'Target date passed'
                    : '${math.max(0, days)} / $duration days',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> editGoal(
  BuildContext context,
  WidgetRef ref, [
  Goal? initial,
]) async {
  final profile = ref.read(profileProvider)!;
  final name = TextEditingController(text: initial?.name ?? ''),
      target = TextEditingController(
        text: initial == null
            ? ''
            : fromMinor(
                initial.targetMinor,
                profile.profile.currency,
              ).toString(),
      );
  var deadline =
      initial?.deadline ?? DateTime.now().add(const Duration(days: 180));
  var icon = initial?.icon ?? 'goal', accountId = initial?.accountId ?? '';
  var color = initial?.color ?? palette[1];
  await showEditor(
    context,
    title: initial == null ? 'Give your dream a name' : 'Edit goal',
    description:
        'Manual contributions reserve money in your plan, not your accounts. Linking an account tracks its whole balance instead (do not link the same account to multiple goals unless intentional).',
    fields: (context, setLocal) => [
      formText(name, 'Goal name', required: true),
      formText(
        target,
        'Target (${profile.profile.currency})',
        required: true,
        numeric: true,
      ),
      formDate(
        context,
        'Dream date',
        deadline,
        (value) => setLocal(() => deadline = value),
      ),
      formSelect(
        'Progress source',
        accountId,
        ['', ...profile.accounts.map((item) => item.id)],
        (value) => setLocal(() => accountId = value),
        display: (id) => id.isEmpty
            ? 'Manual contributions + tagged income'
            : profile.accounts.firstWhere((item) => item.id == id).name,
      ),
      formColors(color, (value) => setLocal(() => color = value)),
      ExpansionTile(
        title: const Text('Choose an icon'),
        children: [formIcons(icon, (value) => setLocal(() => icon = value))],
      ),
    ],
    onSave: () => ref
        .read(appProvider.notifier)
        .upsertGoal(
          Goal(
            id: initial?.id ?? uuid.v4(),
            name: name.text.trim(),
            targetMinor: toMinor(
              evaluateAmount(target.text),
              profile.profile.currency,
            ),
            deadline: deadline,
            start: initial?.start ?? DateTime.now(),
            archived: initial?.archived ?? false,
            accountId: accountId,
            icon: icon,
            color: color,
            contributions: initial?.contributions ?? [],
          ),
        ),
  );
  name.dispose();
  target.dispose();
}

class GoalDetailScreen extends ConsumerWidget {
  final String id;
  const GoalDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final goal = ledger.data.goals.where((item) => item.id == id).firstOrNull;
    if (goal == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Goal removed',
          message: 'Your accounts and transactions are unchanged.',
        ),
      );
    }
    final saved = ledger.goalSaved(goal);
    return FeaturePage(
      title: goal.name,
      actions: [
        IconButton(
          tooltip: goal.archived ? 'Restore goal' : 'Archive goal',
          onPressed: () => runSafe(
            context,
            () => ref
                .read(appProvider.notifier)
                .upsertGoal(goal.copyWith(archived: !goal.archived)),
          ),
          icon: Icon(
            goal.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
          ),
        ),
        IconButton(
          tooltip: 'Edit goal',
          onPressed: () => editGoal(context, ref, goal),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete goal',
          onPressed: () async {
            if (await confirm(
                  context,
                  'Delete goal?',
                  'This removes its contributions, but does not move any actual money.',
                ) &&
                context.mounted) {
              final done = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteGoal(id),
              );
              if (done && context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          GoalCard(goal, openDetails: false),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final milestone in [25, 50, 75, 100])
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        saved / goal.targetMinor * 100 >= milestone
                            ? Icons.verified_rounded
                            : Icons.circle_outlined,
                        color: saved / goal.targetMinor * 100 >= milestone
                            ? Color(goal.color)
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 6),
                      Text('$milestone%'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (goal.accountId.isEmpty)
            FilledButton.icon(
              onPressed: () async {
                final amount = TextEditingController(),
                    note = TextEditingController();
                await showEditor(
                  context,
                  title: 'One step closer',
                  description:
                      'This is a savings allocation, not an account withdrawal.',
                  fields: (_, __) => [
                    formText(
                      amount,
                      'Contribution (${ledger.currency})',
                      required: true,
                      numeric: true,
                    ),
                    formText(note, 'A little note'),
                  ],
                  onSave: () => ref
                      .read(appProvider.notifier)
                      .contribute(
                        id,
                        toMinor(evaluateAmount(amount.text), ledger.currency),
                        note.text.trim(),
                      ),
                );
                amount.dispose();
                note.dispose();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a contribution'),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.link_rounded),
                title: Text(ledger.account(goal.accountId).name),
                subtitle: const Text(
                  'Progress automatically follows this account’s balance',
                ),
              ),
            ),
          const SizedBox(height: 16),
          const SectionHeader('Every step counts'),
          for (final event in goal.contributions.reversed)
            Card(
              child: ListTile(
                leading: ColorIcon('savings', goal.color, size: 40),
                title: AmountText(event.amountMinor),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(event.date)}${event.note.isEmpty ? '' : ' · ${event.note}'}',
                ),
                trailing: IconButton(
                  tooltip: 'Remove contribution',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () async {
                    if (await confirm(
                          context,
                          'Remove contribution?',
                          'Only this allocation will be removed.',
                        ) &&
                        context.mounted) {
                      await runSafe(
                        context,
                        () => ref
                            .read(appProvider.notifier)
                            .updateProfile(
                              (profile, app) => profile.copyWith(
                                goals: [
                                  for (final item in profile.goals)
                                    if (item.id == id)
                                      item.copyWith(
                                        contributions: item.contributions
                                            .where(
                                              (entry) => entry.id != event.id,
                                            )
                                            .toList(),
                                      )
                                    else
                                      item,
                                ],
                              ),
                            ),
                      );
                    }
                  },
                ),
              ),
            ),
          for (final entry in ledger.data.transactions.where(
            (entry) => entry.goalId == id,
          ))
            TransactionTile(entry),
          if (goal.contributions.isEmpty && saved == 0)
            const EmptyState(
              title: 'The first step is yours',
              message: 'Even a little is a beginning.',
              icon: Icons.savings_outlined,
            ),
        ],
      ),
    );
  }
}
