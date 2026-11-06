import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/reference_editor.dart';
import '../../shared/widgets.dart';
import '../accounts/accounts_screen.dart';
import '../transactions/grouped_transactions.dart';
import '../transactions/transaction_form.dart';

Future<void> showGoalsHelp(BuildContext context) => showHowItWorks(
  context,
  title: 'How Goals Work',
  introduction:
      'Goals help you save toward specific targets by tracking your progress.',
  sections: const [
    (
      Icons.flag_outlined,
      'Goal Types',
      'Set a target amount, start date and deadline for anything you want to save for. A goal is a local plan, not a separate bank account.',
    ),
    (
      Icons.account_balance_outlined,
      'Linked Account',
      'Optionally link an account. Progress follows its whole book balance, converted with your saved rates: opening balance, deposits, withdrawals, transfers and scheduled records. Negative balances stay negative. Linking the same account to two goals counts the same money twice. Manual contributions remain saved but are not added on top of a linked balance.',
    ),
    (
      Icons.pie_chart_outline,
      'Progress',
      'Without an account, progress is manual allocations plus income tagged to this goal. See saved, still needed, daily amount needed and the uncapped percentage. The painted bar is bounded, not the underlying value. After the deadline, daily needed is unavailable.',
    ),
    (
      Icons.check_circle_outline,
      'Status',
      'A goal automatically becomes Completed at its target and Active if its balance drops below it. Archive or restore it without moving money or losing history. Delete removes only the goal and its allocations, not account transactions.',
    ),
    (
      Icons.sort,
      'Tracking',
      'Sort by name, target amount, deadline, percentage or saved amount. Group linked transactions by day, week, month or year. Linked-account history includes both sides of transfers; group net excludes transfers.',
    ),
  ],
);

Widget goalIcon(Goal goal, {double size = 48}) => goal.photoBase64.isEmpty
    ? ColorIcon(goal.icon, goal.color, size: size)
    : ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          base64Decode(goal.photoBase64),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              ColorIcon(goal.icon, goal.color, size: size),
        ),
      );

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
            (a, b) => switch (sort) {
              'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              'amount' => b.targetMinor.compareTo(a.targetMinor),
              'saved' => ledger.goalSaved(b).compareTo(ledger.goalSaved(a)),
              'progress' => (ledger.goalSaved(b) / b.targetMinor).compareTo(
                ledger.goalSaved(a) / a.targetMinor,
              ),
              _ => a.deadline.compareTo(b.deadline),
            },
          );
    return FeaturePage(
      title: 'Goals',
      subtitle: '${goals.length} goals',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort goals',
          icon: const Icon(Icons.sort_rounded),
          onSelected: (s) => setState(() => sort = s),
          itemBuilder: (_) => [
            for (final item in [
              ('name', 'Name'),
              ('amount', 'Target amount'),
              ('date', 'Deadline'),
              ('progress', 'Progress'),
              ('saved', 'Saved amount'),
            ])
              PopupMenuItem(value: item.$1, child: Text(item.$2)),
          ],
        ),
        IconButton(
          tooltip: 'How Goals Work',
          onPressed: () => showGoalsHelp(context),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      fab: FloatingActionButton(
        tooltip: 'Create savings goal',
        onPressed: () => editGoal(context, ref),
        child: const Icon(Icons.add),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: const ['Active', 'Completed', 'Archived'],
          selected: selected,
          onSelected: (n) => setState(() => selected = n),
        ),
      ),
      child: goals.isEmpty
          ? EmptyState(
              title: selected == 2
                  ? 'Nothing archived'
                  : selected == 1
                  ? 'Keep taking little steps'
                  : 'What are you dreaming of?',
              message:
                  'Track a target with a linked account or manual contributions.',
              icon: Icons.flag_outlined,
              action: selected == 0 ? 'Start a goal' : null,
              onAction: selected == 0 ? () => editGoal(context, ref) : null,
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 110),
              itemCount: goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (_, i) => GoalCard(goals[i]),
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
    final ledger = ref.watch(ledgerProvider)!,
        saved = ref.watch(ledgerProvider)!.goalSaved(goal);
    final remaining = math.max(0, goal.targetMinor - saved),
        days = calendarDaysBetween(DateTime.now(), goal.deadline);
    final color = readableTint(context, Color(goal.color));
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(goal.color).withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TonalCard(
        color: Color.alphaBlend(
          Color(goal.color).withValues(alpha: .07),
          Theme.of(context).colorScheme.surface,
        ),
        onTap: openDetails
            ? () => openPage(context, GoalDetailScreen(goal.id))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                goalIcon(goal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat.yMd().format(goal.deadline),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SmallTag(
                goal.archived
                    ? 'Archived'
                    : remaining == 0
                    ? 'Completed'
                    : days < 0
                    ? '${-days} days overdue'
                    : days == 0
                    ? 'Due today'
                    : '$days days left',
                color: color,
              ),
            ),
            const SizedBox(height: 18),
            SummaryColumns(
              labels: const ['Saved', 'Remaining'],
              values: [AmountText(saved), AmountText(remaining)],
            ),
            const SizedBox(height: 22),
            if (!ledger.settings.hideAmounts)
              WavyProgress(
                saved / goal.targetMinor,
                color: chartInk(
                  Color(goal.color),
                  Theme.of(context).colorScheme.surface,
                ),
              )
            else
              const Icon(Icons.visibility_off_outlined, size: 16),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                AmountText(goal.targetMinor, prefix: 'Goal: '),
                Text(
                  ledger.settings.hideAmounts
                      ? '•••%'
                      : '${(saved / goal.targetMinor * 100).round()}%',
                ),
              ],
            ),
          ],
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
  final currency = ref.read(profileProvider)!.profile.currency;
  final name = TextEditingController(text: initial?.name ?? ''),
      target = TextEditingController(
        text: initial == null
            ? ''
            : fromMinor(initial.targetMinor, currency).toString(),
      );
  DateTime? start =
      initial?.start ?? (initial == null ? dayOnly(DateTime.now()) : null);
  var deadline =
      initial?.deadline ?? DateTime.now().add(const Duration(days: 180));
  var icon = initial?.icon ?? 'goal',
      accountId = initial?.accountId ?? '',
      photo = initial?.photoBase64 ?? '';
  var color = initial?.color ?? 0xff009688;
  await showReferenceEditor(
    context,
    title: 'Goal',
    saveLabel: initial == null ? 'Create Goal' : 'Update Goal',
    description:
        'Linked progress uses the whole account book balance. Manual contributions reserve money only in this plan. Dates organize the goal; they do not filter that balance.',
    fields: (context, setLocal) {
      final profile = ref.read(profileProvider)!;
      return [
        Row(
          children: [
            ColorIcon(icon, color, size: 48),
            const SizedBox(width: 12),
            Expanded(child: formText(name, 'Goal name', required: true)),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(photo.isEmpty ? 'Add photo' : 'Change photo'),
              onPressed: () => runSafe(context, () async {
                final receipt = await ReceiptService.pick(ImageSource.gallery);
                if (receipt != null && context.mounted)
                  setLocal(() => photo = receipt.data);
              }),
            ),
            if (photo.isNotEmpty)
              TextButton(
                onPressed: () => setLocal(() => photo = ''),
                child: const Text('Remove photo'),
              ),
          ],
        ),
        formText(target, 'Target ($currency)', required: true, numeric: true),
        ReferenceDatePair(
          start: start,
          end: deadline,
          onStart: (v) => setLocal(() => start = v),
          onEnd: (v) => setLocal(() => deadline = v),
        ),
        ReferenceChoices(
          title: 'Select account',
          selected: accountId,
          choices: {
            '': 'Manual contributions + tagged income',
            for (final a in profile.accounts.where(
              (a) => !a.archived || a.id == accountId,
            ))
              a.id: '${a.name} · ${a.currency}',
          },
          onChanged: (v) => setLocal(() => accountId = v),
          onAdd: () async {
            await editAccount(context, ref);
            if (context.mounted) setLocal(() {});
          },
        ),
        ExpansionTile(
          title: const Text('Choose an icon'),
          children: [formIcons(icon, (v) => setLocal(() => icon = v))],
        ),
        ReferenceColorPicker(
          value: color,
          onChanged: (v) => setLocal(() => color = v),
        ),
      ];
    },
    onSave: () => ref
        .read(appProvider.notifier)
        .upsertGoal(
          Goal(
            id: initial?.id ?? uuid.v4(),
            name: name.text.trim(),
            targetMinor: toMinor(evaluateAmount(target.text), currency),
            deadline: deadline,
            start: start,
            archived: initial?.archived ?? false,
            accountId: accountId,
            icon: icon,
            color: color,
            photoBase64: photo,
            contributions: initial?.contributions ?? [],
          ),
        ),
  );
  name.dispose();
  target.dispose();
}

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const GoalDetailScreen(this.id, {super.key});
  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  int period = 0;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final goal = ledger.data.goals.where((g) => g.id == widget.id).firstOrNull;
    if (goal == null)
      return const FeaturePage(
        title: 'Goal removed',
        child: EmptyState(
          title: 'Your transactions are safe',
          message: 'Only the goal and its allocations were removed.',
        ),
      );
    final saved = ledger.goalSaved(goal),
        remaining = math.max(0, goal.targetMinor - ledger.goalSaved(goal));
    final days = calendarDaysBetween(DateTime.now(), goal.deadline);
    final entries = ledger.data.transactions
        .where(
          (e) => goal.accountId.isNotEmpty
              ? e.accountId == goal.accountId ||
                    e.type == 'transfer' && e.toAccountId == goal.accountId
              : e.goalId == goal.id,
        )
        .toList();
    Future<void> contribution() async {
      final amount = TextEditingController(), note = TextEditingController();
      await showEditor(
        context,
        title: 'One step closer',
        description: 'A manual allocation, not an account withdrawal.',
        fields: (_, _) => [
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
              goal.id,
              toMinor(evaluateAmount(amount.text), ledger.currency),
              note.text.trim(),
            ),
      );
      amount.dispose();
      note.dispose();
    }

    return FeaturePage(
      title: 'Goal Details',
      actions: [
        IconButton(
          tooltip: 'Delete goal',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final route = ModalRoute.of(context);
            if (await confirm(
                  context,
                  'Delete goal?',
                  'Contributions and this plan are removed, but actual account transactions stay unchanged.',
                ) &&
                context.mounted) {
              final done = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteGoal(goal.id),
              );
              if (done && context.mounted && route != null && route.isActive) {
                if (route.isCurrent) {
                  Navigator.pop(context);
                } else {
                  Navigator.of(context).removeRoute(route);
                }
              }
            }
          },
        ),
        IconButton(
          tooltip: goal.archived ? 'Restore goal' : 'Archive goal',
          icon: Icon(
            goal.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
          ),
          onPressed: () => runSafe(
            context,
            () => ref
                .read(appProvider.notifier)
                .upsertGoal(goal.copyWith(archived: !goal.archived)),
          ),
        ),
      ],
      fab: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => editGoal(context, ref, goal),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: transactionPeriods,
          selected: period,
          onSelected: (n) => setState(() => period = n),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    goalIcon(goal),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.archived ? 'Archived Goal' : 'Savings Goal',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            goal.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: readableTint(
                                    context,
                                    Color(goal.color),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  ledger.settings.hideAmounts
                      ? '•••% completed'
                      : '${(saved / goal.targetMinor * 100).round()}% completed',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    AmountText(saved, prefix: 'Saved: '),
                    AmountText(goal.targetMinor, prefix: 'Target: '),
                  ],
                ),
                const SizedBox(height: 16),
                if (!ledger.settings.hideAmounts)
                  WavyProgress(
                    saved / goal.targetMinor,
                    color: chartInk(
                      Color(goal.color),
                      Theme.of(context).colorScheme.surface,
                    ),
                  )
                else
                  const Icon(Icons.visibility_off_outlined),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, box) {
                    final columns =
                        box.maxWidth < 300 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.4
                        ? 1
                        : 2;
                    final tiles = <(String, Widget)>[
                      (
                        'Started',
                        Text(
                          goal.start == null
                              ? 'Not recorded'
                              : DateFormat.yMd().format(goal.start!),
                        ),
                      ),
                      (
                        'End date',
                        Text(DateFormat.yMd().format(goal.deadline)),
                      ),
                      (
                        'Remaining',
                        Text(
                          days < 0
                              ? '${-days} days overdue'
                              : days == 0
                              ? 'Due today'
                              : '$days days left',
                        ),
                      ),
                      ('Still needed', AmountText(remaining)),
                    ];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in tiles)
                          SizedBox(
                            width: (box.maxWidth - (columns - 1) * 8) / columns,
                            child: TonalCard(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.$1,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 10),
                                  t.$2,
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (days >= 0)
                  AmountText(
                    (remaining / (days + 1)).ceil(),
                    prefix: 'Daily needed (including today): ',
                  )
                else
                  const Text('Daily needed unavailable after the deadline'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (goal.accountId.isEmpty)
            FilledButton.icon(
              onPressed: goal.archived ? null : contribution,
              icon: const Icon(Icons.add),
              label: const Text('Add a contribution'),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.link),
                title: Text(ledger.account(goal.accountId).name),
                subtitle: const Text(
                  'Whole book balance, including opening and scheduled records',
                ),
                onTap: () =>
                    openPage(context, AccountDetailScreen(goal.accountId)),
              ),
            ),
          if (goal.accountId.isEmpty)
            OutlinedButton.icon(
              onPressed: () => openPage(
                context,
                TransactionForm(initialType: 'income', initialGoalId: goal.id),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add tagged income'),
            ),
          if (goal.contributions.isNotEmpty) ...[
            const SectionHeader('Manual allocations'),
            if (goal.accountId.isNotEmpty)
              const Text(
                'Saved history; not added to linked-account progress.',
              ),
            for (final event in goal.contributions.reversed)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: AmountText(event.amountMinor),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(event.date)} · ${event.note}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove contribution',
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      if (await confirm(
                            context,
                            'Remove contribution?',
                            'Only this manual allocation is removed.',
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
                                      if (item.id == goal.id)
                                        item.copyWith(
                                          contributions: item.contributions
                                              .where((e) => e.id != event.id)
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
          ],
          const SizedBox(height: 20),
          const SectionHeader('Transactions'),
          GroupedTransactions(entries, period: period),
        ],
      ),
    );
  }
}
