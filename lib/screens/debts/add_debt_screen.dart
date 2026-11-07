import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_format.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/debt_transaction_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/transaction_tile.dart';

/// Creates or edits a loan / lending record.
///
/// A debt has no interest maths of its own — Paisa treats a loan as an amount
/// plus installments against it — but it does capture the description, where the
/// user writes "12% reducing balance, 24 EMIs", so the note travels with the
/// record and shows on the card.
class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key, this.existing, this.initialType});

  /// The record being edited, or `null` when creating.
  final DebtModel? existing;

  /// Pre-selects `Money Lent` or `Money Borrowed`.
  final DebtType? initialType;

  bool get isEditing => existing != null;

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _amount = TextEditingController();

  late DebtType _type;
  late DateTime _startDate;
  late DateTime _dueDate;
  bool _saving = false;

  PaisaProvider get _provider => context.read<PaisaProvider>();
  CurrencyFormatter get _formatter => _provider.formatter;

  @override
  void initState() {
    super.initState();
    final DebtModel? existing = widget.existing;
    final DateTime now = DateTime.now();
    _type = existing?.debtType ?? widget.initialType ?? DebtType.debt;
    _startDate = existing?.dateTime ?? DateTime(now.year, now.month, now.day);
    _dueDate = existing?.expiryDateTime ??
        DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 30));

    if (existing != null) {
      _name.text = existing.name;
      _description.text = existing.description;
      _amount.text = _formatter.forInput(existing.amount);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime anchor = isStart ? _startDate : _dueDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: anchor,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: isStart ? 'Start date' : 'Due date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (!_dueDate.isAfter(_startDate)) {
          _dueDate = _startDate.add(const Duration(days: 30));
        }
      } else {
        _dueDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final double? amount = _formatter.parse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    if (!_dueDate.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The due date must be after the start date')),
      );
      return;
    }

    final DebtModel record = DebtModel(
      id: widget.existing?.id ?? IdGenerator.newId(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      amount: amount,
      dateTime: _startDate,
      expiryDateTime: _dueDate,
      debtType: _type,
    );

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await _provider.updateDebt(record);
      } else {
        await _provider.addDebt(record);
      }
      if (!mounted) return;
      Navigator.of(context).pop(record);
    } on TransactionException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  Future<void> _delete() async {
    final DebtModel? existing = widget.existing;
    if (existing == null) return;
    final PaisaProvider provider = _provider;
    final double paid = provider.paidAmountFor(existing.id);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete ${existing.name}?'),
        content: Text(
          paid > 0
              ? 'The record and its ${_formatter.formatWhole(paid)} of installments '
                  'will be removed. The transactions those installments logged in '
                  'your accounts are deleted as well, so balances stay truthful.'
              : 'This record will be removed. No payments were logged against it.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    // Remove installments first so their mirror rows go with them.
    final List<DebtTransactionModel> installments =
        provider.debtSummaryById(existing.id)?.installments ??
            const <DebtTransactionModel>[];
    for (final DebtTransactionModel installment in installments) {
      await provider.deleteDebtInstallment(installment.id);
    }
    await provider.deleteDebt(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop(existing);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final bool lent = _type == DebtType.debt;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit record' : 'New record'),
        actions: <Widget>[
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete record',
              onPressed: _saving ? null : _delete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: <Widget>[
            // ---------------- Direction ----------------
            SegmentedButton<DebtType>(
              segments: const <ButtonSegment<DebtType>>[
                ButtonSegment<DebtType>(
                  value: DebtType.debt,
                  label: Text('Money lent'),
                  icon: Icon(Icons.call_made_rounded, size: 16),
                ),
                ButtonSegment<DebtType>(
                  value: DebtType.credit,
                  label: Text('Loan / EMI'),
                  icon: Icon(Icons.call_received_rounded, size: 16),
                ),
              ],
              selected: <DebtType>{_type},
              showSelectedIcon: false,
              onSelectionChanged: (Set<DebtType> selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lent ? colors.incomeContainer : colors.expenseContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    lent ? Icons.savings_outlined : Icons.account_balance_outlined,
                    size: 18,
                    color: lent ? colors.income : colors.expense,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lent
                          ? 'Money you gave someone. Repayments you record are '
                              'income into the account you pick.'
                          : 'A loan or EMI you repay. Payments you record are '
                              'expenses from the account you pick.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: lent ? colors.income : colors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ---------------- Amount ----------------
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              validator: (String? value) {
                final String raw = (value ?? '').trim();
                if (raw.isEmpty) return 'Enter the amount';
                final double? parsed = _formatter.parse(raw);
                if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                if (parsed > 999999999) return 'That amount is too large';
                return null;
              },
              decoration: InputDecoration(
                labelText: lent ? 'Amount lent' : 'Loan amount',
                prefixText: '${_formatter.symbol} ',
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // ---------------- Name ----------------
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 48,
              validator: (String? value) => (value ?? '').trim().isEmpty
                  ? lent
                      ? 'Who did you lend to?'
                      : 'Which loan is this?'
                  : null,
              decoration: InputDecoration(
                labelText: lent ? 'Person' : 'Lender / loan name',
                hintText: lent ? 'e.g. Ravi' : 'e.g. HDFC car loan',
                prefixIcon: Icon(
                  lent ? Icons.person_outline_rounded : Icons.account_balance,
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            // ---------------- Description ----------------
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 120,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. 12% reducing balance, 24 EMIs',
                prefixIcon: Icon(Icons.notes_rounded),
                counterText: '',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),

            // ---------------- Dates ----------------
            Row(
              children: <Widget>[
                Expanded(
                  child: _DateTile(
                    label: 'Start date',
                    icon: Icons.event_available_rounded,
                    value: DateTimeFormat.date(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: lent ? 'Expected back' : 'Final due date',
                    icon: Icons.event_outlined,
                    value: DateTimeFormat.date(_dueDate),
                    highlight: _dueDate.isBefore(
                      DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                    ),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final int days in <int>[30, 60, 90, 180, 365])
                  ActionChip(
                    label: Text(days >= 365 ? '1 year' : '$days days'),
                    onPressed: () => setState(() {
                      _dueDate = _startDate.add(Duration(days: days));
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!widget.isEditing)
              Text(
                'Save the record, then add individual payments from the card. '
                'Every payment can log a real transaction in the account that '
                'received or paid the money.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(
                        widget.isEditing ? 'Save changes' : 'Save record',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            if (widget.isEditing) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  label: Text(
                    'Delete record',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens the debt editor (create when [existing] is null).
Future<DebtModel?> openAddDebtScreen(
  BuildContext context, {
  DebtModel? existing,
  DebtType? initialType,
}) {
  return Navigator.of(context).push<DebtModel>(
    MaterialPageRoute<DebtModel>(
      builder: (BuildContext context) => AddDebtScreen(
        existing: existing,
        initialType: initialType,
      ),
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: highlight
              ? colors.expenseContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 15,
                  color: highlight ? colors.expense : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        highlight ? colors.expense : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? colors.expense : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the shared empty-state widget reachable from this screen's tests.
class DebtEmptyState extends StatelessWidget {
  const DebtEmptyState({
    super.key,
    required this.lent,
    required this.onAdd,
  });

  final bool lent;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LedgerEmptyState(
      icon: lent ? Icons.handshake_outlined : Icons.account_balance_outlined,
      title: lent ? 'Nobody owes you right now' : 'No loans to repay',
      message: lent
          ? 'Record money you lent and MoneyMate tracks every repayment against '
              'the people who owe you.'
          : 'Add a loan, credit card EMI or a personal borrowing and every '
              'payment updates the outstanding balance.',
      action: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text(lent ? 'Record money lent' : 'Add a loan'),
      ),
    );
  }
}
