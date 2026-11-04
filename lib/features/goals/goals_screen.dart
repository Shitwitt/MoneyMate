import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../transactions/transaction_tile.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(profileProvider)!.goals;
    return FeaturePage(
      title: 'Savings goals',
      subtitle: 'Big dreams. Small steps.',
      actions: [
        IconButton(
          tooltip: 'Create savings goal',
          onPressed: () => editGoal(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: goals.isEmpty
          ? EmptyState(
              title: 'What are you dreaming of?',
              message:
                  'An emergency fund, a trip, a new beginning. Give your next dream a name.',
              icon: Icons.flag_rounded,
              action: 'Start a goal',
              onAction: () => editGoal(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 110),
              itemCount: goals.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GoalCard(goals[index]),
              ),
            ),
    );
  }
}

class GoalCard extends ConsumerWidget {
  final Goal goal;
  const GoalCard(this.goal, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final saved = ledger.goalSaved(goal);
    final progress = saved / goal.targetMinor;
    final days = goal.deadline.difference(DateTime.now()).inDays;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => openPage(context, GoalDetailScreen(goal.id)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ColorIcon(goal.icon, goal.color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress >= 1
                              ? 'You did it. Take a moment. ✨'
                              : days < 0
                              ? 'Past your target date. Keep going.'
                              : '$days days to make it happen',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    progress >= 1
                        ? Icons.verified_rounded
                        : Icons.chevron_right_rounded,
                    color: Color(goal.color),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              WavyProgress(progress, color: Color(goal.color)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AmountText(
                      saved,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text('of ', style: Theme.of(context).textTheme.bodySmall),
                  AmountText(
                    goal.targetMinor,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).round()}% of the way${goal.accountId.isNotEmpty ? ' · Linked account balance' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
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
    if (goal == null)
      return const Scaffold(
        body: EmptyState(
          title: 'Goal removed',
          message: 'Your accounts and transactions are unchanged.',
        ),
      );
    final saved = ledger.goalSaved(goal);
    return FeaturePage(
      title: goal.name,
      actions: [
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
          GoalCard(goal),
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
                        context.mounted)
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
