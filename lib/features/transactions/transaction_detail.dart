import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import '../accounts/accounts_screen.dart';
import '../catalog/catalog_screen.dart';
import '../catalog/labels_screen.dart';
import '../goals/goals_screen.dart';
import '../loans/loans_screen.dart';
import 'receipt_viewer.dart';
import 'transaction_form.dart';
import 'transactions_screen.dart';

Future<void> showTransactionDetail(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final navigator = Navigator.of(context);
  final route = ModalBottomSheetRoute<String>(
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (_) => Consumer(
      builder: (sheet, ref, _) {
        final ledger = ref.watch(ledgerProvider)!;
        final entry = ledger.data.transactions
            .where((e) => e.id == id)
            .firstOrNull;
        if (entry == null)
          return const SizedBox(
            height: 180,
            child: Center(child: Text('Transaction removed')),
          );
        final account = ledger.account(entry.accountId),
            category = ledger.category(entry.categoryId);
        final loan = ledger.data.loans
            .where((l) => l.id == entry.loanId)
            .firstOrNull;
        final goal = ledger.data.goals
            .where((g) => g.id == entry.goalId)
            .firstOrNull;
        Widget row(
          String title,
          String value,
          IconData icon, [
          String? action,
        ]) => ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Icon(icon),
          title: Text(title, style: Theme.of(sheet).textTheme.bodySmall),
          subtitle: Text(value, style: Theme.of(sheet).textTheme.titleMedium),
          trailing: action == null
              ? null
              : const Icon(Icons.chevron_right_rounded),
          onTap: action == null ? null : () => Navigator.pop(sheet, action),
        );
        return SizedBox(
          height: MediaQuery.sizeOf(sheet).height * .87,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        tooltip: 'Close transaction details',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheet),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ColorIcon(
                          category?.icon ?? 'transfer',
                          category?.color ?? 0xffffb59a,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.name,
                                style: Theme.of(sheet).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat.yMMMEd().add_jm().format(entry.date),
                              ),
                              const SizedBox(height: 12),
                              AmountText(
                                entry.amountMinor,
                                currency: account.currency,
                                style: Theme.of(sheet).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppColors.semantic(
                                        sheet,
                                        entry.type,
                                      ),
                                    ),
                              ),
                              if (account.currency != ledger.currency)
                                AmountText(
                                  ledger.entryValue(entry),
                                  prefix: 'Converted: ',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const SectionHeader('Transaction Details'),
                    row(
                      'Account',
                      account.name,
                      iconFor(account.icon),
                      'account:${account.id}',
                    ),
                    if (entry.type == 'transfer')
                      row(
                        'To account',
                        ledger.account(entry.toAccountId).name,
                        Icons.swap_horiz,
                        'account:${entry.toAccountId}',
                      ),
                    if (entry.type == 'transfer')
                      AmountText(
                        entry.toAmountMinor,
                        currency: ledger.account(entry.toAccountId).currency,
                        prefix: 'Received: ',
                      ),
                    if (category != null)
                      row(
                        'Category',
                        category.name,
                        iconFor(category.icon),
                        'category:${category.id}',
                      ),
                    for (final entity in ledger.data.entities.where(
                      (e) =>
                          entry.labelIds.contains(e.id) ||
                          entry.personIds.contains(e.id) ||
                          entry.placeId == e.id,
                    ))
                      row(
                        entity.kind == 'label'
                            ? 'Label'
                            : entity.kind == 'person'
                            ? 'Person'
                            : 'Place',
                        entity.name,
                        iconFor(entity.kind),
                        '${entity.kind}:${entity.id}',
                      ),
                    if (loan != null)
                      row(
                        'Loan',
                        loan.personName,
                        Icons.handshake_outlined,
                        'loan:${loan.id}',
                      ),
                    if (goal != null)
                      row(
                        'Goal',
                        goal.name,
                        Icons.flag_outlined,
                        'goal:${goal.id}',
                      ),
                    if (entry.notes.isNotEmpty)
                      row('Notes', entry.notes, Icons.notes_rounded),
                    if (entry.receipts.isNotEmpty)
                      row(
                        'Receipts',
                        '${entry.receipts.length} attachments',
                        Icons.receipt_long_outlined,
                        'receipts',
                      ),
                    const SizedBox(height: 22),
                    Text(
                      entry.createdAt == null
                          ? 'Creation date unavailable for this older record'
                          : 'Created on ${DateFormat.yMMMMd().format(entry.createdAt!)}',
                      style: Theme.of(sheet).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 12,
                    children: [
                      for (final action in [
                        ('delete', Icons.delete_outline, 'Delete'),
                        ('edit', Icons.edit_outlined, 'Edit'),
                        ('copy', Icons.copy_outlined, 'Copy'),
                      ])
                        TextButton.icon(
                          onPressed: () => Navigator.pop(sheet, action.$1),
                          icon: Icon(action.$2),
                          label: Text(action.$3),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  final action = await navigator.push(route);
  await route.completed;
  if (!context.mounted || action == null) return;
  final ledger = ref.read(ledgerProvider)!;
  final entry = ledger.data.transactions.where((e) => e.id == id).firstOrNull;
  if (entry == null) return;
  if (action == 'delete') {
    if (await confirm(
          context,
          'Delete transaction?',
          'This changes its account balance and linked totals. A linked repayment is removed from the loan too.',
        ) &&
        context.mounted)
      await runSafe(
        context,
        () => ref.read(appProvider.notifier).deleteTransactions({id}),
      );
    return;
  }
  if (action == 'edit' || action == 'copy') {
    openPage(
      context,
      action == 'copy'
          ? TransactionForm(copyFrom: entry)
          : TransactionForm(initial: entry),
    );
    return;
  }
  final parts = action.split(':');
  final target = parts.length > 1 ? parts[1] : '';
  final page = switch (parts.first) {
    'account' => AccountDetailScreen(target),
    'category' => CategoryDetailScreen(target),
    'label' => LabelDetailScreen(target),
    'loan' => LoanDetailScreen(target),
    'goal' => GoalDetailScreen(target),
    'person' => TransactionsScreen(
      initialFilter: TransactionFilter(people: {target}),
    ),
    'place' => TransactionsScreen(
      initialFilter: TransactionFilter(places: {target}),
    ),
    'receipts' => ReceiptViewer(entry.receipts),
    _ => null,
  };
  if (page != null) openPage(context, page);
}
