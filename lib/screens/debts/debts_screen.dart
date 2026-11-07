import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/theme/paisa_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_format.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/account_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/debt_summary.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/transaction_tile.dart';

/// Loans, EMIs and borrowings.
///
/// Step 3 ships the read-only surface plus installment recording; Step 5 adds the
/// full create/edit flow and debt detail screens.
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  DebtType _tab = DebtType.debt;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final PaisaColors colors = PaisaColors.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final List<DebtSummary> lent = provider.debtsOfType(DebtType.debt);
    final List<DebtSummary> borrowed = provider.debtsOfType(DebtType.credit);
    final List<DebtSummary> visible =
        _tab == DebtType.debt ? lent : borrowed;

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Loans & lendings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _SummaryTile(
                  label: 'You will get',
                  value: provider.formatter.formatWhole(provider.totalLent),
                  count: lent.length,
                  accent: colors.income,
                  background: colors.incomeContainer,
                  icon: Icons.call_made_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'You owe',
                  value: provider.formatter.formatWhole(provider.totalBorrowed),
                  count: borrowed.length,
                  accent: colors.expense,
                  background: colors.expenseContainer,
                  icon: Icons.call_received_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<DebtType>(
            style: PaisaTheme.segmentedButtonStyle(context),
            segments: <ButtonSegment<DebtType>>[
              ButtonSegment<DebtType>(
                value: DebtType.debt,
                label: Text('Lent (${lent.length})'),
                icon: const Icon(Icons.call_made_rounded, size: 16),
              ),
              ButtonSegment<DebtType>(
                value: DebtType.credit,
                label: Text('Borrowed (${borrowed.length})'),
                icon: const Icon(Icons.call_received_rounded, size: 16),
              ),
            ],
            selected: <DebtType>{_tab},
            showSelectedIcon: false,
            onSelectionChanged: (Set<DebtType> selection) =>
                setState(() => _tab = selection.first),
          ),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          LedgerEmptyState(
            icon: Icons.handshake_outlined,
            title: _tab == DebtType.debt
                ? 'Nobody owes you right now'
                : 'No loans to repay',
            message: _tab == DebtType.debt
                ? 'Record money you lent and MoneyMate tracks the repayments.'
                : 'Add a loan or EMI and every installment updates your balance.',
            action: FilledButton.icon(
              onPressed: () => _showAddDebtSheet(context, _tab),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a record'),
            ),
          )
        else
          for (final DebtSummary summary in visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _DebtCard(summary: summary),
            ),
        const SizedBox(height: 8),
        if (visible.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _showAddDebtSheet(context, _tab),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a record'),
            ),
          ),
        if (provider.overdueDebts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.warningContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: colors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${provider.overdueDebts.length} record'
                      '${provider.overdueDebts.length == 1 ? '' : 's'} past the due date',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.count,
    required this.accent,
    required this.background,
    required this.icon,
  });

  final String label;
  final String value;
  final int count;
  final Color accent;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count == 1 ? '1 record' : '$count records',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.summary});

  final DebtSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;

    final double progress = provider.progressFor(summary.id);
    final bool settled = summary.isSettled;
    final Color accent = summary.debtType == DebtType.debt
        ? colors.debtGiven
        : colors.debtTaken;
    final int days = summary.daysRemaining();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(summary.debtType.icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary.debt.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      settled
                          ? 'Settled'
                          : days < 0
                              ? 'Overdue by ${days.abs()} days'
                              : 'Due ${DateTimeFormat.date(summary.debt.expiryDateTime)} · $days days left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: settled
                            ? colors.success
                            : (days < 0 ? colors.expense : scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatter.formatWhole(summary.outstandingAmount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'of ${formatter.formatWhole(summary.debt.amount)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: scheme.surfaceContainerHighest,
              color: settled ? colors.success : accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                '${(progress * 100).round()}% settled · '
                '${formatter.formatWhole(summary.paidAmount)} paid',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (!settled)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showInstallmentSheet(context, summary),
                  icon: const Icon(Icons.add_card_rounded, size: 16),
                  label: const Text('Installment'),
                ),
            ],
          ),
          if (summary.installments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Last: ${formatter.formatWhole(summary.lastInstallment!.amount)} '
              'on ${DateTimeFormat.date(summary.lastInstallment!.dateTime)}'
              '${summary.lastInstallment!.note.isEmpty ? '' : ' · ${summary.lastInstallment!.note}'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Records an installment against [summary].
///
/// For borrowed money this writes an expense; for lent money an income — the
/// provider handles that, this sheet only collects the facts.
Future<void> _showInstallmentSheet(
  BuildContext context,
  DebtSummary summary,
) async {
  final PaisaProvider provider = context.read<PaisaProvider>();
  final TextEditingController amount = TextEditingController();
  final TextEditingController note = TextEditingController();
  String? accountId = provider.defaultAccount?.id;
  DateTime date = DateTime.now();
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final ThemeData theme = Theme.of(context);
          final ColorScheme scheme = theme.colorScheme;
          final double remaining = provider.remainingAmountFor(summary.id);

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          summary.debtType == DebtType.debt
                              ? 'Received from ${summary.debt.name}'
                              : 'Pay ${summary.debt.name}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    '${provider.formatter.formatWhole(remaining)} remaining of '
                    '${provider.formatter.formatWhole(summary.debt.amount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amount,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Installment amount',
                      prefixText: '${provider.formatter.symbol} ',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'e.g. EMI 4 of 12',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(DateTimeFormat.date(date)),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Paid from',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final AccountModel account in provider.accounts)
                        ChoiceChip(
                          selected: account.id == accountId,
                          avatar: Icon(
                            account.cardType.icon,
                            size: 15,
                            color: Color(account.color),
                          ),
                          label: Text(account.title),
                          onSelected: (bool _) =>
                              setState(() => accountId = account.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final double? value =
                          provider.formatter.parse(amount.text.trim());
                      if (value == null || value <= 0) {
                        setState(() => error = 'Enter a valid amount');
                        return;
                      }
                      try {
                        await provider.addDebtInstallment(
                          parentId: summary.id,
                          amount: value,
                          dateTime: date,
                          accountId: accountId,
                          note: note.text.trim(),
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      } on TransactionException catch (e) {
                        setState(() => error = e.message);
                      }
                    },
                    child: const Text('Record installment'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  amount.dispose();
  note.dispose();
}

/// Minimal debt creation sheet. Step 5 replaces it with the full editor
/// (interest, EMI schedule, reminders).
Future<void> _showAddDebtSheet(BuildContext context, DebtType type) async {
  final PaisaProvider provider = context.read<PaisaProvider>();
  final TextEditingController name = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController note = TextEditingController();
  DateTime start = DateTime.now();
  DateTime due = DateTime.now().add(const Duration(days: 30));
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final ThemeData theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          type == DebtType.debt
                              ? 'Money I lent'
                              : 'Money I borrowed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: type == DebtType.debt
                          ? 'Who owes you?'
                          : 'Lender / loan name',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Total amount',
                      prefixText: '${provider.formatter.symbol} ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Interest rate, EMI details…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: due,
                              firstDate: start,
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 3650)),
                            );
                            if (picked != null) setState(() => due = picked);
                          },
                          child: Text('Due ${DateTimeFormat.date(due)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final String title = name.text.trim();
                      final double? value =
                          provider.formatter.parse(amount.text.trim());
                      if (title.isEmpty) {
                        setState(() => error = 'Add a name');
                        return;
                      }
                      if (value == null || value <= 0) {
                        setState(() => error = 'Enter a valid amount');
                        return;
                      }
                      await provider.addDebt(
                        DebtModel(
                          id: IdGenerator.newId(),
                          name: title,
                          description: note.text.trim(),
                          amount: value,
                          dateTime: start,
                          expiryDateTime: due,
                          debtType: type,
                        ),
                      );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
          ),
          );
        },
      );
    },
  );

  name.dispose();
  amount.dispose();
  note.dispose();
}
