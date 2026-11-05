import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/money.dart';
import '../../core/utils/dates.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../transactions/transaction_tile.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});
  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  int direction = 0;
  String sort = 'date';
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final loans =
        ledger.data.loans
            .where((l) => l.direction == (direction == 0 ? 'lent' : 'borrowed'))
            .toList()
          ..sort(
            (a, b) => sort == 'amount'
                ? ledger.loanRemaining(b).compareTo(ledger.loanRemaining(a))
                : a.due.compareTo(b.due),
          );
    final balance = ledger.toReceive - ledger.toPay;
    return FeaturePage(
      title: 'Loans',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort loans',
          icon: const Icon(Icons.sort_rounded),
          onSelected: (value) => setState(() => sort = value),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'date', child: Text('Due date')),
            PopupMenuItem(value: 'amount', child: Text('Remaining amount')),
          ],
        ),
        IconButton(
          tooltip: 'About loans',
          onPressed: () => showFeatureInfo(
            context,
            'Your private loan ledger',
            'Lending is money owed to you; borrowing is money you owe. Net loan balance is lending minus borrowing. Repayments reduce the outstanding balance. Interest is a flat lifetime percentage, not APR. This records agreements only; it does not issue loans, collect payments, or contact anyone.',
          ),
          icon: const Icon(Icons.info_outline_rounded),
        ),
        IconButton(
          tooltip: 'New loan',
          onPressed: () => editLoan(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          TonalCard(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: .55),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Lending'),
                          const SizedBox(height: 10),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AmountText(
                              ledger.toReceive,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.semantic(
                                      context,
                                      'expense',
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Borrowing'),
                          const SizedBox(height: 10),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AmountText(
                              ledger.toPay,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.semantic(
                                      context,
                                      'income',
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net loan balance',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            balance < 0
                                ? 'You owe more than you’re owed'
                                : balance > 0
                                ? 'You’re owed more than you owe'
                                : 'Your outstanding loans are balanced',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AmountText(
                          balance,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.semantic(
                                  context,
                                  balance < 0 ? 'expense' : 'income',
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PillTabs(
            labels: const ['Lending', 'Borrowing'],
            selected: direction,
            onSelected: (value) => setState(() => direction = value),
          ),
          const SizedBox(height: 20),
          if (loans.isEmpty)
            EmptyState(
              title: direction == 0
                  ? 'Nothing lent yet'
                  : 'Nothing borrowed yet',
              message: 'Keep a private record of money and repayments between people.',
              icon: Icons.handshake_outlined,
              action: 'Add a loan',
              onAction: () => editLoan(context, ref),
            ),
          for (final completed in [false, true]) ...[
            if (loans.any((l) => (ledger.loanRemaining(l) == 0) == completed))
              SectionHeader(completed ? 'Completed' : 'Active'),
            for (final loan in loans.where(
              (l) => (ledger.loanRemaining(l) == 0) == completed,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LoanCard(loan),
              ),
          ],
        ],
      ),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final Loan loan;
  const _LoanCard(this.loan);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final total = (loan.principalMinor * (1 + loan.interestPercent / 100))
        .round();
    final remaining = ledger.loanRemaining(loan);
    final days = calendarDaysBetween(DateTime.now(), loan.due);
    final color = AppColors.semantic(
      context,
      loan.direction == 'lent' ? 'expense' : 'income',
    );
    return TonalCard(
      color: Color.alphaBlend(
        color.withValues(alpha: .11),
        Theme.of(context).colorScheme.surface,
      ),
      onTap: () => openPage(context, LoanDetailScreen(loan.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_outlined, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.personName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (loan.notes.isNotEmpty)
                      Text(
                        loan.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SmallTag(
                  remaining == 0
                      ? 'Repaid'
                      : days < 0
                      ? '${-days} days late'
                      : '$days days',
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              AmountText(
                total - remaining,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color),
              ),
              const Text('/'),
              AmountText(total, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          WavyProgress(
            total == 0 ? 0 : (total - remaining) / total,
            color: color,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Due ${DateFormat.yMMMd().format(loan.due)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> editLoan(
  BuildContext context,
  WidgetRef ref, [
  Loan? initial,
]) async {
  final profile = ref.read(profileProvider)!;
  final name = TextEditingController(text: initial?.personName ?? ''),
      principal = TextEditingController(
        text: initial == null
            ? ''
            : fromMinor(
                initial.principalMinor,
                profile.profile.currency,
              ).toString(),
      ),
      interest = TextEditingController(
        text: (initial?.interestPercent ?? 0).toString(),
      ),
      notes = TextEditingController(text: initial?.notes ?? '');
  var direction = initial?.direction ?? 'lent',
      personId = initial?.personId ?? '',
      accountId = '';
  var due = initial?.due ?? DateTime.now().add(const Duration(days: 30));
  await showEditor(
    context,
    title: initial == null ? 'Keep things clear' : 'Edit loan',
    description: 'Interest is a flat lifetime percentage, not APR. For a new disbursement, optionally create a matching account entry to keep net worth balanced.',
    fields: (context, setLocal) => [
      formSelect('You…', direction, [
        'lent',
        'borrowed',
      ], (value) => setLocal(() => direction = value)),
      if (profile.entities.any((item) => item.kind == 'person'))
        formSelect(
          'Link a person',
          personId,
          [
            '',
            ...profile.entities
                .where((item) => item.kind == 'person')
                .map((item) => item.id),
          ],
          (value) => setLocal(() {
            personId = value;
            if (value.isNotEmpty) {
              name.text = profile.entities
                  .firstWhere((item) => item.id == value)
                  .name;
            }
          }),
          display: (id) => id.isEmpty
              ? 'Quick name instead'
              : profile.entities.firstWhere((item) => item.id == id).name,
        ),
      formText(name, 'Person’s name', required: true),
      formText(
        principal,
        'Principal (${profile.profile.currency})',
        required: true,
        numeric: true,
      ),
      formText(interest, 'Flat interest (%)', numeric: true),
      formDate(
        context,
        'Due date',
        due,
        (value) => setLocal(() => due = value),
      ),
      if (initial == null)
        formSelect(
          'Disbursement account entry',
          accountId,
          [
            '',
            ...profile.accounts
                .where((item) => !item.archived)
                .map((item) => item.id),
          ],
          (value) => setLocal(() => accountId = value),
          display: (id) => id.isEmpty
              ? 'Tracking only · no money moves'
              : profile.accounts.firstWhere((item) => item.id == id).name,
        ),
      formText(notes, 'Notes', lines: 3),
    ],
    onSave: () async {
      final rate = double.tryParse(interest.text);
      if (rate == null || !rate.isFinite || rate < 0 || rate > 1000) {
        throw const FormatException(
          'Enter a valid flat interest rate (0–1000%)',
        );
      }
      await ref
          .read(appProvider.notifier)
          .upsertLoan(
            Loan(
              id: initial?.id ?? uuid.v4(),
              personName: name.text.trim(),
              principalMinor: toMinor(
                evaluateAmount(principal.text),
                profile.profile.currency,
              ),
              due: due,
              direction: direction,
              personId: personId,
              interestPercent: rate,
              notes: notes.text.trim(),
              repayments: initial?.repayments ?? [],
            ),
            disburseAccountId: accountId,
          );
    },
  );
  for (final controller in [name, principal, interest, notes]) {
    controller.dispose();
  }
}

class LoanDetailScreen extends ConsumerWidget {
  final String id;
  const LoanDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final loan = ledger.data.loans.where((item) => item.id == id).firstOrNull;
    if (loan == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Loan removed',
          message: 'Any posted repayments remain in your transaction history.',
        ),
      );
    }
    final remaining = ledger.loanRemaining(loan);
    final total = (loan.principalMinor * (1 + loan.interestPercent / 100))
        .round();
    return FeaturePage(
      title: loan.personName,
      actions: [
        IconButton(
          tooltip: 'Edit loan',
          onPressed: () => editLoan(context, ref, loan),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete loan',
          onPressed: () async {
            if (await confirm(
                  context,
                  'Delete loan?',
                  'Repayment and disbursement account entries are retained; only the debt tracker is removed.',
                ) &&
                context.mounted) {
              final done = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteLoan(id),
              );
              if (done && context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.direction == 'lent'
                        ? 'Still to receive'
                        : 'Still to pay',
                  ),
                  const SizedBox(height: 12),
                  AmountText(
                    remaining,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 18),
                  WavyProgress((total - remaining) / total),
                  const SizedBox(height: 12),
                  Text(
                    '${remaining == 0 ? 'All settled' : 'Due ${DateFormat.yMMMd().format(loan.due)}'} · ${loan.interestPercent}% flat interest',
                  ),
                  if (loan.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(loan.notes),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: remaining == 0
                ? null
                : () async {
                    final amount = TextEditingController(
                          text: fromMinor(
                            remaining,
                            ledger.currency,
                          ).toString(),
                        ),
                        notes = TextEditingController();
                    var accountId = '';
                    await showEditor(
                      context,
                      title: 'A little less to remember',
                      fields: (context, setLocal) => [
                        formText(
                          amount,
                          'Repaid (${ledger.currency})',
                          required: true,
                          numeric: true,
                        ),
                        formText(notes, 'Notes'),
                        formSelect(
                          'Account entry',
                          accountId,
                          [
                            '',
                            ...ledger.data.accounts
                                .where((item) => !item.archived)
                                .map((item) => item.id),
                          ],
                          (value) => setLocal(() => accountId = value),
                          display: (id) => id.isEmpty
                              ? 'Tracking only · already recorded elsewhere'
                              : ledger.account(id).name,
                        ),
                      ],
                      onSave: () => ref
                          .read(appProvider.notifier)
                          .repayLoan(
                            id,
                            toMinor(
                              evaluateAmount(amount.text),
                              ledger.currency,
                            ),
                            notes.text.trim(),
                            accountId: accountId,
                          ),
                    );
                    amount.dispose();
                    notes.dispose();
                  },
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Record a repayment'),
          ),
          const SizedBox(height: 18),
          const SectionHeader('Repayment timeline'),
          for (final event in loan.repayments.reversed)
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: AmountText(event.amountMinor),
              subtitle: Text(
                '${DateFormat.yMMMd().format(event.date)} · ${event.note}',
              ),
            ),
          if (loan.repayments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No repayments yet. Every small payment is progress.',
              ),
            ),
          const SectionHeader('Linked account entries'),
          for (final entry in ledger.data.transactions.where(
            (entry) => entry.loanId == id,
          ))
            TransactionTile(entry),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
