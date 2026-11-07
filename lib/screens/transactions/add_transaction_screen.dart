import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/theme/paisa_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/paisa_provider.dart';
import '../categories/quick_add_category_sheet.dart';
import 'widgets/account_selector.dart';
import 'widgets/amount_field.dart';
import 'widgets/calculator_sheet.dart';
import 'widgets/category_selector.dart';
import 'widgets/date_time_cards.dart';

/// Full-screen Add / Edit transaction form.
///
/// Pass [existing] to edit — the form pre-fills every field, the title becomes
/// "Edit transaction" and a Delete action appears.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.existing,
    this.initialType,
    this.initialAccountId,
    this.initialToAccountId,
    this.initialCategoryId,
    this.initialDate,
    this.initialAmount,
  });

  /// The transaction being edited, or `null` when adding.
  final TransactionModel? existing;

  final TransactionType? initialType;
  final String? initialAccountId;
  final String? initialToAccountId;
  final String? initialCategoryId;
  final DateTime? initialDate;
  final double? initialAmount;

  bool get isEditing => existing != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  late TransactionType _type;
  late DateTime _dateTime;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;

  bool _saving = false;
  String? _amountError;
  String? _titleError;
  String? _accountError;
  String? _toAccountError;
  String? _categoryError;

  PaisaProvider get _provider => context.read<PaisaProvider>();
  CurrencyFormatter get _formatter => _provider.formatter;

  /// Categories shown in the grid.
  ///
  /// Expense mode lists expense categories, income mode lists the seeded income
  /// categories, and a transfer hides the grid entirely (money only moves
  /// between the user's own accounts). Income-ness comes from
  /// [CategoryModel.isIncome] so the picker and the manager never disagree.
  List<CategoryModel> get _categories {
    final bool wantsIncome = _type == TransactionType.income;
    return _provider.categories
        .where((CategoryModel c) =>
            _type == TransactionType.transfer
                ? false
                : c.isIncome == wantsIncome)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final TransactionModel? existing = widget.existing;
    final PaisaProvider provider = context.read<PaisaProvider>();
    _type = existing?.type ?? widget.initialType ?? TransactionType.expense;
    _dateTime = existing?.time ?? widget.initialDate ?? DateTime.now();
    _accountId = existing?.accountId ??
        widget.initialAccountId ??
        provider.defaultAccount?.id;
    _toAccountId = existing?.toAccountId ?? widget.initialToAccountId;
    _categoryId = existing?.categoryId ?? widget.initialCategoryId;

    if (existing != null) {
      _amountController.text = _formatter.forInput(existing.amount);
      _titleController.text = existing.name;
      _descriptionController.text = existing.description ?? '';
    } else if (widget.initialAmount != null) {
      _amountController.text = _formatter.forInput(widget.initialAmount!);
    }

    if (_type == TransactionType.transfer) {
      _categoryId = null;
      _ensureDistinctTransferAccounts();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  /// Keeps `from` and `to` different whenever the account list or the selection
  /// changes (deleting an account mid-edit, switching type, …).
  void _ensureDistinctTransferAccounts() {
    final List<AccountModel> accounts = _provider.accounts;
    if (accounts.length < 2) {
      _toAccountId = null;
      return;
    }
    if (_accountId == null || _provider.accountById(_accountId) == null) {
      _accountId = accounts.first.id;
    }
    if (_toAccountId == _accountId || _provider.accountById(_toAccountId) == null) {
      _toAccountId = accounts
          .firstWhere((AccountModel a) => a.id != _accountId)
          .id;
    }
  }

  void _setType(TransactionType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _clearErrors();
      if (type == TransactionType.transfer) {
        _categoryId = null;
        _ensureDistinctTransferAccounts();
      } else {
        _toAccountId = null;
      }
    });
  }

  void _clearErrors() {
    _amountError = null;
    _titleError = null;
    _accountError = null;
    _toAccountError = null;
    _categoryError = null;
  }

  /// Parses the amount field. Returns `null` and sets the error when invalid.
  double? _parseAmount() {
    final String raw = _amountController.text.trim();
    if (raw.isEmpty) {
      setState(() => _amountError = 'Enter an amount');
      return null;
    }
    final double? parsed = _formatter.parse(raw);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      setState(() => _amountError = 'Enter a valid amount');
      return null;
    }
    if (parsed <= 0) {
      setState(() => _amountError = 'Amount must be greater than zero');
      return null;
    }
    if (parsed > 999999999) {
      setState(() => _amountError = 'That amount is too large');
      return null;
    }
    return double.parse(parsed.toStringAsFixed(2));
  }

  Future<void> _openCalculator() async {
    final double? result = await showCalculatorSheet(
      context,
      formatter: _formatter,
      initialValue: _formatter.parse(_amountController.text) ?? 0,
      title: 'Amount',
    );
    if (result == null || !mounted) return;
    setState(() {
      _amountController.text = _formatter.forInput(result);
      _amountError = null;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Select date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      helpText: 'Select time',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _addCategory() async {
    final CategoryModel? created = await showQuickAddCategorySheet(
      context,
      existingColors: _provider.categories
          .map((CategoryModel c) => c.color)
          .toSet(),
    );
    if (created == null || !mounted) return;
    await _provider.addCategory(created);
    if (!mounted) return;
    setState(() => _categoryId = created.id);
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(_clearErrors);

    final double? amount = _parseAmount();
    final String title = _titleController.text.trim();
    bool valid = amount != null;

    if (title.isEmpty) {
      setState(() => _titleError = 'Add a title');
      valid = false;
    }
    if (_accountId == null) {
      setState(() => _accountError = 'Choose an account');
      valid = false;
    }
    if (_type == TransactionType.transfer) {
      if (_toAccountId == null) {
        setState(() => _toAccountError = 'Choose a destination account');
        valid = false;
      } else if (_toAccountId == _accountId) {
        setState(() => _toAccountError = 'Use a different account');
        valid = false;
      }
    }
    if (_type != TransactionType.transfer && _categoryId == null) {
      setState(() => _categoryError = 'Pick a category');
      valid = false;
    }
    if (!valid) return;

    setState(() => _saving = true);
    final TransactionModel draft = TransactionModel(
      id: widget.existing?.id ?? IdGenerator.newId(),
      name: title,
      amount: amount!,
      time: _dateTime,
      type: _type,
      accountId: _accountId!,
      toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
      categoryId: _type == TransactionType.transfer ? null : _categoryId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await _provider.updateTransaction(draft);
      } else {
        await _provider.addTransaction(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(draft);
    } on TransactionException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _amountError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $error')),
      );
    }
  }

  Future<void> _delete() async {
    final TransactionModel? existing = widget.existing;
    if (existing == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          '“${existing.name}” will be removed. You can undo this straight after.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _provider.deleteTransaction(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _provider.addTransaction(existing),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<AccountModel> accounts = context.watch<PaisaProvider>().accounts;
    final bool isTransfer = _type == TransactionType.transfer;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit transaction' : 'Add transaction'),
        actions: <Widget>[
          if (widget.isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
            // ---------------- Type switcher ----------------
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TransactionType>(
                style: PaisaTheme.segmentedButtonStyle(context),
                segments: const <ButtonSegment<TransactionType>>[
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.south_west_rounded, size: 18),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.north_east_rounded, size: 18),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.transfer,
                    label: Text('Transfer'),
                    icon: Icon(Icons.swap_horiz_rounded, size: 18),
                  ),
                ],
                selected: <TransactionType>{_type},
                showSelectedIcon: false,
                onSelectionChanged: (Set<TransactionType> selection) =>
                    _setType(selection.first),
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- Amount ----------------
            AmountField(
              controller: _amountController,
              formatter: _formatter,
              type: _type,
              focusNode: _amountFocus,
              errorText: _amountError,
              onOpenCalculator: _openCalculator,
            ),
            const SizedBox(height: 20),

            // ---------------- Title & description ----------------
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 60,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: isTransfer ? 'e.g. ATM withdrawal' : 'e.g. Groceries',
                prefixIcon: const Icon(Icons.edit_outlined),
                counterText: '',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add a note, bill number or person',
                prefixIcon: Icon(Icons.notes_rounded),
                counterText: '',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- Accounts ----------------
            if (isTransfer) ...<Widget>[
              AccountSelectorRow(
                label: 'Transfer from account',
                icon: Icons.call_made_rounded,
                accounts: accounts,
                selectedId: _accountId,
                excludedId: _toAccountId,
                balances: _provider.accountBalances,
                formatter: _formatter,
                errorText: _accountError,
                onSelect: (String id) => setState(() {
                  _accountId = id;
                  _accountError = null;
                  if (_toAccountId == id) {
                    _toAccountId = accounts
                        .firstWhere((AccountModel a) => a.id != id)
                        .id;
                  }
                }),
              ),
              const SizedBox(height: 16),
              AccountSelectorRow(
                label: 'Transfer to account',
                icon: Icons.call_received_rounded,
                accounts: accounts,
                selectedId: _toAccountId,
                excludedId: _accountId,
                balances: _provider.accountBalances,
                formatter: _formatter,
                errorText: _toAccountError,
                onSelect: (String id) => setState(() {
                  _toAccountId = id;
                  _toAccountError = null;
                }),
              ),
            ] else
              AccountSelectorRow(
                label: 'Account',
                icon: Icons.account_balance_wallet_outlined,
                accounts: accounts,
                selectedId: _accountId,
                balances: _provider.accountBalances,
                formatter: _formatter,
                errorText: _accountError,
                onSelect: (String id) => setState(() {
                  _accountId = id;
                  _accountError = null;
                }),
              ),
            const SizedBox(height: 20),

            // ---------------- Category ----------------
            if (!isTransfer) ...<Widget>[
              CategorySelectorGrid(
                categories: _categories,
                selectedId: _categoryId,
                errorText: _categoryError,
                onAddCategory: _addCategory,
                onSelect: (String id) => setState(() {
                  _categoryId = id;
                  _categoryError = null;
                }),
              ),
              const SizedBox(height: 20),
            ],

            // ---------------- Date & time ----------------
            DateTimePickerCards(
              dateTime: _dateTime,
              locale: _provider.locale,
              onPickDate: _pickDate,
              onPickTime: _pickTime,
            ),
            const SizedBox(height: 20),

            // ---------------- Live preview note ----------------
            _ImpactPreview(
              type: _type,
              accountId: _accountId,
              toAccountId: _toAccountId,
              amount: _formatter.parse(_amountController.text) ?? 0,
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
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Save transaction'),
              ),
            ),
            if (widget.isEditing) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: PaisaColors.of(context).expense,
                  ),
                  label: Text(
                    'Delete transaction',
                    style: TextStyle(color: PaisaColors.of(context).expense),
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

/// Shows the effect the transaction will have on the selected account(s) before
/// it is saved — a small but genuinely useful guard against wrong-account
/// entries.
class _ImpactPreview extends StatelessWidget {
  const _ImpactPreview({
    required this.type,
    required this.accountId,
    required this.toAccountId,
    required this.amount,
  });

  final TransactionType type;
  final String? accountId;
  final String? toAccountId;
  final double amount;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0 || accountId == null) return const SizedBox.shrink();
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;
    final PaisaColors colors = PaisaColors.of(context);
    final ThemeData theme = Theme.of(context);

    final AccountModel? source = provider.accountById(accountId);
    final AccountModel? destination = provider.accountById(toAccountId);
    final double sourceBalance = provider.accountBalance(accountId!);

    String text;
    Color color;
    switch (type) {
      case TransactionType.expense:
        text = '${source?.title ?? 'Account'} becomes '
            '${formatter.format(sourceBalance - amount)}';
        color = colors.expense;
      case TransactionType.income:
        text = '${source?.title ?? 'Account'} becomes '
            '${formatter.format(sourceBalance + amount)}';
        color = colors.income;
      case TransactionType.transfer:
        final String target = destination == null
            ? 'the other account'
            : destination.title;
        text = '${formatter.format(sourceBalance - amount)} in '
            '${source?.title ?? 'source'} · '
            '${formatter.format(provider.accountBalance(destination?.id ?? '') + amount)} in $target';
        color = colors.transfer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience launcher used by the shell FAB, the home list and search.
Future<TransactionModel?> openAddTransactionScreen(
  BuildContext context, {
  TransactionModel? existing,
  TransactionType? initialType,
  String? initialAccountId,
  String? initialCategoryId,
  DateTime? initialDate,
  double? initialAmount,
}) {
  return Navigator.of(context).push<TransactionModel>(
    MaterialPageRoute<TransactionModel>(
      builder: (BuildContext context) => AddTransactionScreen(
        existing: existing,
        initialType: initialType,
        initialAccountId: initialAccountId,
        initialCategoryId: initialCategoryId,
        initialDate: initialDate,
        initialAmount: initialAmount,
      ),
    ),
  );
}
