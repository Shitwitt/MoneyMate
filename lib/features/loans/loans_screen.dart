import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../transactions/transaction_tile.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    return FeaturePage(
      title: 'Money between people',
      actions: [
        IconButton(
          tooltip: 'New loan',
          onPressed: () => editLoan(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'To receive',
                  value: AmountText(ledger.toReceive, compact: true),
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'To pay',
                  value: AmountText(ledger.toPay, compact: true),
                  icon: Icons.north_east_rounded,
                  color: const Color(0xffbc7d5a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (ledger.data.loans.isEmpty)
            EmptyState(
              title: 'Keep the money, not the awkwardness',
              message: 'Remember what you lent, borrowed, and paid back. All privately.',
              action: 'Add a loan',
              onAction: () => editLoan(context, ref),
              icon: Icons.handshake_outlined,
            ),
          for (final loan in ledger.data.loans)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: ColorIcon(
                    'person',
                    loan.direction == 'lent' ? 0xffa4ca6a : 0xfff2b88f,
                  ),
                  title: Text(
                    loan.personName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${loan.direction == 'lent' ? 'You lent' : 'You borrowed'} · ${ledger.loanRemaining(loan) == 0 ? 'Repaid ✓' : 'Due ${DateFormat.MMMd().format(loan.due)}'}',
                  ),
                  trailing: AmountText(
                    ledger.loanRemaining(loan),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => openPage(context, LoanDetailScreen(loan.id)),
                ),
              ),
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
