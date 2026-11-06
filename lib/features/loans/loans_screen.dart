import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/data/ledger.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/reference_editor.dart';
import '../../shared/widgets.dart';
import '../accounts/accounts_screen.dart';
import '../catalog/catalog_screen.dart';
import '../transactions/transaction_tile.dart';
import '../transactions/transactions_screen.dart';

Future<void> showLoansHelp(BuildContext context) => showHowItWorks(
  context,
  title: 'How Loans Work',
  introduction: 'Loans help you track money you have lent to others or borrowed, with payment progress.',
  sections: const [
    (
      Icons.swap_vert,
      'Loan Types',
      'Lending: money you gave to someone; they owe you. Borrowing: money you received; you owe them. This is private bookkeeping, not a lending or payment service. Interest, if used, is a flat lifetime percentage, not APR.',
    ),
    (
      Icons.payments_outlined,
      'Payments',
      'Use the plus button to record partial or full repayments. Optionally post a matching account entry, converted using saved exchange rates. Tracking-only payments do not move account money. Other loan-tagged transactions are history, not automatically repayments. Editing or deleting a linked repayment entry updates its payment; older tracking-only payments stay independent.',
    ),
    (
      Icons.account_balance_wallet_outlined,
      'Summary',
      'View outstanding lending, borrowing and net balance at the top. Net is lending minus borrowing. Manually closed loans are excluded without inventing a payment.',
    ),
    (
      Icons.check_circle_outline,
      'Status',
      'A loan completes automatically when posted repayments cover its total. Mark as Done closes it without changing cash or paid amounts; reopen to track its unpaid balance again.',
    ),
    (
      Icons.person_outline,
      'People',
      'Link a person to see who you lent to or borrowed from. Loan name and person are separate. Changing a loan does not rewrite its existing account entries.',
    ),
    (
      Icons.event_outlined,
      'Due Dates',
      'Set start and end dates. Calendar-day countdowns and overdue flags update automatically. Older loans with no start date say Not recorded.',
    ),
    (
      Icons.trending_up,
      'Progress',
      'See actual paid amount, unpaid balance, total including flat interest and uncapped percentage. Scheduled repayments count only once their date arrives. Manual closure is not repayment.',
    ),
    (
      Icons.sort,
      'Sorting',
      'Sort loans by name, original amount, remaining amount or due date. Fully paid and manually closed loans appear under Completed.',
    ),
  ],
);

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
            (a, b) => switch (sort) {
              'name' => a.personName.toLowerCase().compareTo(
                b.personName.toLowerCase(),
              ),
              'amount' => b.principalMinor.compareTo(a.principalMinor),
              'remaining' =>
                ledger.loanRemaining(b).compareTo(ledger.loanRemaining(a)),
              _ => a.due.compareTo(b.due),
            },
          );
    return FeaturePage(
      title: 'Loans',
      subtitle: '${loans.length} loans',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Sort loans',
          icon: const Icon(Icons.sort),
          onSelected: (v) => setState(() => sort = v),
          itemBuilder: (_) => [
            for (final item in [
              ('name', 'Name'),
              ('amount', 'Original amount'),
              ('remaining', 'Remaining amount'),
              ('date', 'Due date'),
            ])
              PopupMenuItem(value: item.$1, child: Text(item.$2)),
          ],
        ),
        IconButton(
          tooltip: 'How Loans Work',
          onPressed: () => showLoansHelp(context),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      fab: FloatingActionButton(
        tooltip: 'New loan',
        onPressed: () => editLoan(context, ref),
        child: const Icon(Icons.add),
      ),
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: PillTabs(
          labels: const ['Lending', 'Borrowing'],
          selected: direction,
          onSelected: (n) => setState(() => direction = n),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          TonalCard(
            child: Column(
              children: [
                SummaryColumns(
                  labels: const ['Lending', 'Borrowing'],
                  values: [
                    AmountText(ledger.toReceive),
                    AmountText(ledger.toPay),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                SummaryColumns(
                  labels: const ['Net loan balance'],
                  values: [AmountText(ledger.toReceive - ledger.toPay)],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (loans.isEmpty)
            EmptyState(
              title: direction == 0
                  ? 'Nothing lent yet'
                  : 'Nothing borrowed yet',
              message: 'Keep a private record of agreements and repayments.',
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
                padding: const EdgeInsets.only(bottom: 14),
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
    final days = calendarDaysBetween(DateTime.now(), loan.due),
        paid = ledger.loanPaid(loan),
        total = ledger.loanTotal(loan);
    return TonalCard(
      color: Color.alphaBlend(
        Color(loan.color).withValues(alpha: .10),
        Theme.of(context).colorScheme.surface,
      ),
      onTap: () => openPage(context, LoanDetailScreen(loan.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColorIcon(loan.icon, loan.color, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loan.personName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              SmallTag(
                loan.completed
                    ? 'Marked done'
                    : ledger.loanRemaining(loan) == 0
                    ? 'Repaid'
                    : days < 0
                    ? '${-days} days overdue'
                    : days == 0
                    ? 'Due today'
                    : '$days days left',
              ),
              if (loan.personId.isNotEmpty)
                Text(
                  ledger.data.entities
                          .where((e) => e.id == loan.personId)
                          .firstOrNull
                          ?.name ??
                      '',
                ),
            ],
          ),
          const SizedBox(height: 18),
          SummaryColumns(
            labels: const ['Paid', 'Remaining', 'Total'],
            values: [
              AmountText(paid),
              AmountText(ledger.loanUnpaid(loan)),
              AmountText(total),
            ],
          ),
          const SizedBox(height: 18),
          if (!ledger.settings.hideAmounts)
            WavyProgress(
              paid / total,
              color: chartInk(
                Color(loan.color),
                Theme.of(context).colorScheme.surface,
              ),
            )
          else
            const Icon(Icons.visibility_off_outlined, size: 16),
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
  final currency = ref.read(profileProvider)!.profile.currency;
  final name = TextEditingController(text: initial?.personName ?? ''),
      principal = TextEditingController(
        text: initial == null
            ? ''
            : fromMinor(initial.principalMinor, currency).toString(),
      ),
      interest = TextEditingController(
        text: (initial?.interestPercent ?? 0).toString(),
      ),
      notes = TextEditingController(text: initial?.notes ?? '');
  var direction = initial?.direction ?? 'lent',
      personId = initial?.personId ?? '',
      accountId = initial?.accountId ?? '',
      categoryId = initial?.categoryId ?? '',
      icon = initial?.icon ?? 'loan';
  final categoryDrafts = <String, String>{direction: categoryId};
  var color = initial?.color ?? 0xffe91e63;
  DateTime? start =
      initial?.start ?? (initial == null ? dayOnly(DateTime.now()) : null);
  final today = dayOnly(DateTime.now());
  var due = initial?.due ?? DateTime(today.year, today.month, today.day + 30);
  await showReferenceEditor(
    context,
    title: 'Loan',
    saveLabel: initial == null ? 'Create Loan' : 'Update Loan',
    description: initial == null
        ? 'Choose an account to also create a disbursement entry, or leave None for tracking only. All loan amounts use $currency.'
        : 'Changing this tracker never rewrites existing account entries. Account and category are retained as preferences; no new disbursement is posted.',
    header: (context, setLocal) => PillTabs(
      labels: const ['Lending', 'Borrowing'],
      selected: direction == 'lent' ? 0 : 1,
      onSelected: (n) {
        final next = n == 0 ? 'lent' : 'borrowed';
        if (next == direction) return;
        setLocal(() {
          categoryDrafts[direction] = categoryId;
          direction = next;
          categoryId = categoryDrafts[direction] ?? '';
        });
      },
    ),
    fields: (context, setLocal) {
      final profile = ref.read(profileProvider)!;
      final type = direction == 'lent' ? 'expense' : 'income';
      return [
        Row(
          children: [
            ColorIcon(icon, color, size: 48),
            const SizedBox(width: 12),
            Expanded(child: formText(name, 'Loan name', required: true)),
          ],
        ),
        formText(
          principal,
          'Principal ($currency)',
          required: true,
          numeric: true,
        ),
        formText(notes, 'Notes', lines: 3),
        ReferenceDatePair(
          start: start,
          end: due,
          onStart: (v) => setLocal(() => start = v),
          onEnd: (v) => setLocal(() => due = v),
        ),
        ReferenceChoices(
          title: 'Person',
          selected: personId,
          expanded: false,
          choices: {
            '': 'No linked person',
            for (final e in profile.entities.where((e) => e.kind == 'person'))
              e.id: e.name,
          },
          onChanged: (v) => setLocal(() => personId = v),
          onAdd: () async {
            await editCatalogEntity(context, ref, 'person');
            if (context.mounted) setLocal(() {});
          },
        ),
        ReferenceChoices(
          title: 'Account',
          selected: accountId,
          choices: {
            '': 'None · tracking only',
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
        ReferenceChoices(
          key: ValueKey(type),
          title: 'Category',
          selected: categoryId,
          choices: {
            '': 'Default $type category',
            for (final c in profile.categories.where(
              (c) => c.type == type && (!c.hidden || c.id == categoryId),
            ))
              c.id: c.name,
          },
          onChanged: (v) => setLocal(() => categoryId = v),
          onAdd: () async {
            await editCatalogCategory(context, ref, null, type);
            if (context.mounted) setLocal(() {});
          },
        ),
        ExpansionTile(
          title: const Text('Interest and icon'),
          children: [
            formText(
              interest,
              'Flat lifetime interest (%) · not APR',
              numeric: true,
            ),
            const SizedBox(height: 16),
            formIcons(icon, (v) => setLocal(() => icon = v)),
          ],
        ),
        ReferenceColorPicker(
          value: color,
          onChanged: (v) => setLocal(() => color = v),
        ),
      ];
    },
    onSave: () async {
      final rate = double.tryParse(interest.text);
      if (rate == null || !rate.isFinite || rate < 0 || rate > 1000)
        throw const FormatException(
          'Enter a flat lifetime interest rate from 0 to 1000 percent',
        );
      if (initial != null &&
          initial.repayments.isNotEmpty &&
          direction != initial.direction)
        throw const FormatException(
          'This loan has payments. Keep its direction or create a new loan instead.',
        );
      await ref
          .read(appProvider.notifier)
          .upsertLoan(
            Loan(
              id: initial?.id ?? uuid.v4(),
              personName: name.text.trim(),
              principalMinor: toMinor(evaluateAmount(principal.text), currency),
              due: due,
              start: start,
              direction: direction,
              personId: personId,
              accountId: accountId,
              categoryId: categoryId,
              icon: icon,
              color: color,
              interestPercent: rate,
              notes: notes.text.trim(),
              completed: initial?.completed ?? false,
              repayments: initial?.repayments ?? [],
            ),
            disburseAccountId: initial == null ? accountId : '',
          );
    },
  );
  for (final c in [name, principal, interest, notes]) {
    c.dispose();
  }
}

Future<void> recordLoanPayment(
  BuildContext context,
  WidgetRef ref,
  Loan loan,
) async {
  final ledger = ref.read(ledgerProvider)!;
  if (loan.completed || ledger.loanRemaining(loan) == 0) {
    toast(
      context,
      'This loan is already completed. Reopen a manually closed loan to add a payment.',
    );
    return;
  }
  final amount = TextEditingController(
        text: fromMinor(ledger.loanRemaining(loan), ledger.currency).toString(),
      ),
      note = TextEditingController();
  var accountId = loan.accountId;
  await showEditor(
    context,
    title: 'Record a repayment',
    description:
        'Amount uses ${ledger.currency}. A chosen account gets a matching entry using saved exchange rates. None records tracking only.',
    fields: (context, setLocal) => [
      formText(
        amount,
        'Repaid (${ledger.currency})',
        required: true,
        numeric: true,
      ),
      formText(note, 'Notes'),
      formSelect(
        'Account entry',
        accountId,
        [
          '',
          ...ledger.data.accounts
              .where((a) => !a.archived || a.id == accountId)
              .map((a) => a.id),
        ],
        (v) => setLocal(() => accountId = v),
        display: (id) =>
            id.isEmpty ? 'None · tracking only' : ledger.account(id).name,
      ),
    ],
    onSave: () => ref
        .read(appProvider.notifier)
        .repayLoan(
          loan.id,
          toMinor(evaluateAmount(amount.text), ledger.currency),
          note.text.trim(),
          accountId: accountId,
        ),
  );
  amount.dispose();
  note.dispose();
}

class LoanDetailScreen extends ConsumerWidget {
  final String id;
  const LoanDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final loan = ledger.data.loans.where((l) => l.id == id).firstOrNull;
    if (loan == null)
      return const FeaturePage(
        title: 'Loan removed',
        child: EmptyState(
          title: 'Account entries are retained',
          message: 'Only the debt tracker was removed.',
        ),
      );
    final paid = ledger.loanPaid(loan),
        total = ledger.loanTotal(loan),
        remaining = ledger.loanUnpaid(loan),
        days = calendarDaysBetween(DateTime.now(), loan.due);
    final person = ledger.data.entities
        .where((e) => e.id == loan.personId)
        .firstOrNull;
    return FeaturePage(
      title: loan.personName,
      actions: [
        IconButton(
          tooltip: 'Record a repayment',
          onPressed: () => recordLoanPayment(context, ref, loan),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Delete loan',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final route = ModalRoute.of(context);
            if (await confirm(
                  context,
                  'Delete loan?',
                  'The debt tracker is removed. Disbursement and repayment account entries stay in your history.',
                ) &&
                context.mounted) {
              final done = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteLoan(id),
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
      ],
      fab: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => editLoan(context, ref, loan),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SmallTag(
                loan.direction == 'lent' ? 'Lending' : 'Borrowing',
                color: readableTint(context, Color(loan.color)),
              ),
              SmallTag(
                loan.completed
                    ? 'Marked done'
                    : remaining == 0
                    ? 'Repaid'
                    : days < 0
                    ? '${-days} days overdue'
                    : days == 0
                    ? 'Due today'
                    : '$days days left',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            loan.direction == 'lent' ? 'Amount Lent' : 'Amount Borrowed',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          AmountText(
            loan.principalMinor,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 28),
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Repayment Progress'),
                const SizedBox(height: 16),
                if (!ledger.settings.hideAmounts)
                  WavyProgress(paid / total)
                else
                  const Icon(Icons.visibility_off_outlined),
                const SizedBox(height: 18),
                SummaryColumns(
                  labels: const ['Paid', 'Remaining', 'Total'],
                  values: [
                    AmountText(paid),
                    AmountText(remaining),
                    AmountText(total),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ledger.settings.hideAmounts
                      ? '•••% repaid'
                      : '${(paid / total * 100).toStringAsFixed(1)}% repaid · ${loan.interestPercent}% flat lifetime interest',
                ),
                if (loan.completed)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Manually closed without an additional payment. Unpaid amount is shown above but excluded from outstanding totals.',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader('Loan Details'),
          TonalCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    loan.direction == 'lent' ? 'Lent to' : 'Borrowed from',
                  ),
                  subtitle: Text(person?.name ?? 'No linked person'),
                  onTap: person == null
                      ? null
                      : () => openPage(
                          context,
                          TransactionsScreen(
                            title: person.name,
                            initialFilter: TransactionFilter(
                              people: {person.id},
                            ),
                          ),
                        ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Start date'),
                  subtitle: Text(
                    loan.start == null
                        ? 'Not recorded'
                        : DateFormat.yMd().format(loan.start!),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('End date'),
                  subtitle: Text(DateFormat.yMd().format(loan.due)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notes),
                  title: const Text('Notes'),
                  subtitle: Text(loan.notes.isEmpty ? 'No notes' : loan.notes),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dark(context)
                  ? const Color(0xff604219)
                  : AppColors.warningBackground,
              foregroundColor: AppColors.dark(context)
                  ? const Color(0xffffe0b2)
                  : AppColors.warningInk,
            ),
            onPressed: remaining == 0 && !loan.completed
                ? null
                : () async {
                    if (await confirm(
                          context,
                          loan.completed ? 'Reopen loan?' : 'Mark as Done?',
                          '${loan.completed ? 'Restore this unpaid balance to outstanding totals.' : 'Close this tracker without recording a payment or changing accounts.'} Paid amounts remain unchanged.',
                          confirmLabel: loan.completed
                              ? 'Reopen'
                              : 'Mark as Done',
                        ) &&
                        context.mounted)
                      await runSafe(
                        context,
                        () => ref
                            .read(appProvider.notifier)
                            .setLoanCompleted(id, !loan.completed),
                      );
                  },
            icon: Icon(loan.completed ? Icons.undo : Icons.check),
            label: Text(
              loan.completed
                  ? 'Reopen Loan'
                  : remaining == 0
                  ? 'Fully Repaid'
                  : 'Mark as Done',
            ),
          ),
          const SizedBox(height: 30),
          const SectionHeader('Payment History'),
          for (final event
              in loan.repayments
                  .where((e) => e.transactionId.isEmpty)
                  .toList()
                  .reversed)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: AmountText(event.amountMinor),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(event.date)} · Tracking only${event.note.isEmpty ? '' : ' · ${event.note}'}',
                ),
                trailing: IconButton(
                  tooltip: 'Remove tracking-only payment',
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    if (await confirm(
                          context,
                          'Remove repayment?',
                          'This changes the tracked debt, not any account entry.',
                        ) &&
                        context.mounted)
                      await runSafe(
                        context,
                        () => ref
                            .read(appProvider.notifier)
                            .updateProfile(
                              (profile, app) => profile.copyWith(
                                loans: [
                                  for (final item in profile.loans)
                                    if (item.id == id)
                                      item.copyWith(
                                        repayments: item.repayments
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
          const Text(
            'Linked account entries · only explicit repayments affect paid amounts',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final entries =
                  ledger.data.transactions.where((e) => e.loanId == id).toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
              return Card(
                child: Column(
                  children: [
                    for (final e in entries) TransactionTile(e),
                    if (entries.isEmpty && loan.repayments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No repayments or linked transactions yet.',
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
