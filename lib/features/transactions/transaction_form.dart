import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/providers.dart';
import '../../core/data/catalog_insights.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/money.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/reference_editor.dart';
import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../catalog/catalog_screen.dart';
import '../goals/goals_screen.dart';
import '../loans/loans_screen.dart';
import '../../shared/widgets.dart';
import 'receipt_viewer.dart';

class TransactionForm extends ConsumerStatefulWidget {
  final MoneyTransaction? initial;
  final MoneyTransaction? copyFrom;
  final TransactionTemplate? template;
  final String? accountId;
  final String initialType;
  final String initialBudgetId;
  final List<String> initialLabelIds;
  final String initialGoalId;
  final String initialCategoryId, initialPlaceId;
  final List<String> initialPersonIds;
  final bool templateOnly;
  const TransactionForm({
    super.key,
    this.initial,
    this.copyFrom,
    this.template,
    this.accountId,
    this.initialType = 'expense',
    this.initialBudgetId = '',
    this.initialLabelIds = const [],
    this.initialGoalId = '',
    this.initialCategoryId = '',
    this.initialPlaceId = '',
    this.initialPersonIds = const [],
    this.templateOnly = false,
  });
  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _name = TextEditingController(),
      _notes = TextEditingController(),
      _receive = TextEditingController();
  final _nameFocus = FocusNode();
  late String _type, _accountId, _categoryId;
  String _toAccountId = '', _placeId = '', _goalId = '', _loanId = '';
  String _transferCategoryId = '';
  String _budgetId = '';
  DateTime _date = DateTime.now();
  Set<String> _labels = {}, _people = {};
  List<Receipt> _receipts = [];
  bool _calculator = false,
      _template = false,
      _sequential = false,
      _busy = false,
      _saved = false;
  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider)!;
    final entry = widget.initial ?? widget.copyFrom;
    final template = widget.template;
    _type = entry?.type ?? template?.type ?? widget.initialType;
    _budgetId = entry?.budgetId ?? widget.initialBudgetId;
    if (!profile.budgets.any(
      (b) => b.id == _budgetId && b.transactionType == _type,
    ))
      _budgetId = '';
    if (entry?.type == 'transfer' &&
        profile.categories.any(
          (c) => c.id == entry!.categoryId && c.type == 'transfer',
        )) {
      _transferCategoryId = entry!.categoryId;
    }
    _accountId =
        entry?.accountId ??
        template?.accountId ??
        widget.accountId ??
        profile.accounts
            .firstWhere(
              (item) => !item.archived,
              orElse: () => profile.accounts.first,
            )
            .id;
    _categoryId =
        entry?.categoryId ??
        template?.categoryId ??
        (widget.initialCategoryId.isNotEmpty
            ? widget.initialCategoryId
            : null) ??
        profile.categories
            .where((c) => c.type == _type && !c.hidden)
            .firstOrNull
            ?.id ??
        '';
    _toAccountId =
        entry?.toAccountId ??
        profile.accounts
            .where((item) => item.id != _accountId && !item.archived)
            .firstOrNull
            ?.id ??
        '';
    final account = profile.accounts.firstWhere(
      (item) => item.id == _accountId,
    );
    final amount = entry?.amountMinor ?? template?.amountMinor;
    if (amount != null) {
      _amount.text = fromMinor(
        amount,
        account.currency,
      ).toStringAsFixed(decimalsFor(account.currency));
    }
    _name.text = entry?.name ?? template?.name ?? '';
    _notes.text = entry?.notes ?? template?.notes ?? '';
    _labels = {
      ...widget.initialLabelIds,
      ...?entry?.labelIds,
      ...?template?.labelIds,
    };
    _goalId = widget.initialGoalId;
    _people = widget.initialPersonIds.toSet();
    _placeId = widget.initialPlaceId;
    if (_type == 'transfer' &&
        profile.categories.any(
          (c) => c.id == widget.initialCategoryId && c.type == 'transfer',
        ))
      _transferCategoryId = widget.initialCategoryId;
    if (entry != null) {
      _people = entry.personIds.toSet();
      _placeId = entry.placeId;
      _goalId = entry.goalId;
      _loanId = entry.loanId;
      _date = entry.date.toLocal();
      _receipts = [...entry.receipts];
      if (entry.toAccountId.isNotEmpty) {
        _receive.text =
            fromMinor(
              entry.toAmountMinor,
              profile.accounts
                  .firstWhere((item) => item.id == entry.toAccountId)
                  .currency,
            ).toStringAsFixed(
              decimalsFor(
                profile.accounts
                    .firstWhere((item) => item.id == entry.toAccountId)
                    .currency,
              ),
            );
      }
    }
    _amount.addListener(_updateReceive);
  }

  void _updateReceive() {
    if (_type == 'transfer' && _toAccountId.isNotEmpty) {
      try {
        final profile = ref.read(profileProvider)!;
        final from = profile.accounts.firstWhere(
              (item) => item.id == _accountId,
            ),
            to = profile.accounts.firstWhere((item) => item.id == _toAccountId);
        _receive.text = fromMinor(
          convertMinor(
            toMinor(evaluateAmount(_amount.text), from.currency),
            from.currency,
            to.currency,
            profile.rates,
          ),
          to.currency,
        ).toStringAsFixed(decimalsFor(to.currency));
      } catch (_) {
        /* Invalid intermediate expressions remain editable. */
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amount.removeListener(_updateReceive);
    for (final controller in [_amount, _name, _notes, _receive]) {
      controller.dispose();
    }
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      toast(context, 'Check the required name and amount above.', error: true);
      return;
    }
    setState(() => _busy = true);
    final controller = ref.read(appProvider.notifier);
    final saved = await runSafe(context, () async {
      final profile = ref.read(profileProvider)!;
      final currency = profile.accounts
          .firstWhere((item) => item.id == _accountId)
          .currency;
      final amount = toMinor(evaluateAmount(_amount.text), currency);
      if (amount <= 0) throw const FormatException('Amount rounds to zero');
      if (_type != 'transfer' &&
          !profile.categories.any(
            (c) => c.id == _categoryId && c.type == _type,
          )) {
        throw const FormatException(
          'Choose or add a category that matches this transaction type.',
        );
      }
      if (widget.templateOnly) {
        await controller.saveTemplate(
          TransactionTemplate(
            id: widget.template?.id ?? uuid.v4(),
            name: _name.text.trim(),
            type: _type,
            amountMinor: amount,
            accountId: _accountId,
            categoryId: _categoryId,
            notes: _notes.text.trim(),
            labelIds: _labels.toList(),
          ),
        );
      } else {
        final receiving = _type == 'transfer'
            ? toMinor(
                evaluateAmount(_receive.text),
                profile.accounts
                    .firstWhere((item) => item.id == _toAccountId)
                    .currency,
              )
            : 0;
        final entry = MoneyTransaction(
          id: widget.initial?.id ?? uuid.v4(),
          name: _name.text.trim(),
          type: _type,
          amountMinor: amount,
          accountId: _accountId,
          categoryId: _type == 'transfer' ? _transferCategoryId : _categoryId,
          date: _date,
          toAccountId: _type == 'transfer' ? _toAccountId : '',
          toAmountMinor: receiving,
          notes: _notes.text.trim(),
          labelIds: _labels.toList(),
          personIds: _people.toList(),
          placeId: _placeId,
          goalId: _goalId,
          loanId: _loanId,
          receipts: _receipts,
          recurringId: widget.initial?.recurringId ?? '',
          budgetId: _type == 'transfer' ? '' : _budgetId,
          createdAt: widget.initial?.createdAt ?? DateTime.now(),
        );
        await controller.saveTransaction(
          entry,
          asTemplate: _template && _type != 'transfer',
        );
      }
    });
    if (!mounted) return;
    if (saved) {
      setState(() => _saved = true);
      if (!MediaQuery.disableAnimationsOf(context))
        await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
    }
    setState(() {
      _busy = false;
      _saved = false;
    });
    if (saved) {
      if (_sequential && widget.initial == null && !widget.templateOnly) {
        _amount.clear();
        _name.clear();
        _notes.clear();
        setState(() {
          _receipts = [];
          _date = DateTime.now();
          _template = false;
        });
        toast(
          context,
          'Saved on your device. Ready for the next one.',
          success: true,
        );
      } else {
        final route = ModalRoute.of(context);
        if (route != null && !route.isActive) return;
        // An achievement can open above this form during the save check.
        // Close this route, never that dialog (and never leave a saved form).
        if (route != null && !route.isCurrent) {
          Navigator.of(context).removeRoute(route, true);
        } else {
          Navigator.pop(context, true);
        }
      }
    }
  }

  Future<void> _receipt(ImageSource source) async {
    await runSafe(context, () async {
      final receipt = await ReceiptService.pick(source);
      if (receipt != null && mounted) {
        setState(() => _receipts = [..._receipts, receipt]);
      }
    });
  }

  bool _expandAll = true;
  final _categorySection = GlobalKey();

  Future<void> _pickTemplate() async {
    FocusScope.of(context).unfocus();
    final profile = ref.read(profileProvider)!;
    final template = await showModalBottomSheet<TransactionTemplate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * .7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader('Quick templates'),
              if (profile.templates.isEmpty)
                const Text(
                  'No templates yet. Save a transaction as a quick template, or create one from Your toolkit.',
                ),
              for (final t in profile.templates)
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(t.name),
                  subtitle: Text(
                    '${t.type} · ${profile.accounts.where((a) => a.id == t.accountId).firstOrNull?.name ?? 'Missing account'}',
                  ),
                  onTap: () => Navigator.pop(sheet, t),
                ),
            ],
          ),
        ),
      ),
    );
    if (template == null || !mounted) return;
    if ((_name.text.trim().isNotEmpty || _amount.text.trim().isNotEmpty) &&
        !await confirm(
          context,
          'Use this template?',
          'Replace this draft’s name, amount, type, account, category, notes and labels. Other links, date and receipts stay unchanged. No saved record is modified.',
          confirmLabel: 'Use template',
        ))
      return;
    if (!mounted) return;
    final account = profile.accounts
        .where((a) => a.id == template.accountId)
        .firstOrNull;
    if (account == null) {
      toast(context, 'The template account no longer exists.', error: true);
      return;
    }
    setState(() {
      _type = template.type;
      _accountId = account.id;
      _categoryId = template.categoryId;
      if (!profile.budgets.any(
        (b) => b.id == _budgetId && b.transactionType == _type,
      ))
        _budgetId = '';
      _name.text = template.name;
      _amount.text = fromMinor(
        template.amountMinor,
        account.currency,
      ).toStringAsFixed(decimalsFor(account.currency));
      _notes.text = template.notes;
      _labels = template.labelIds.toSet();
    });
    _updateReceive();
  }

  Widget _choice(
    String title,
    String selected,
    Map<String, String> values,
    ValueChanged<String> change, {
    VoidCallback? add,
  }) => ReferenceChoices(
    key: ValueKey('transaction-$title-$_expandAll'),
    title: title,
    selected: selected,
    choices: values,
    expanded: _expandAll,
    onChanged: (v) {
      if (!_busy) change(v);
    },
    onAdd: add,
  );
  Widget _many(
    String title,
    Set<String> selected,
    Map<String, String> values,
    ValueChanged<Set<String>> change,
    VoidCallback add,
  ) => ExpansionTile(
    key: ValueKey('transaction-$title-$_expandAll'),
    initiallyExpanded: _expandAll,
    maintainState: true,
    tilePadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(
      selected.isEmpty
          ? 'None'
          : selected.map((id) => values[id] ?? 'Removed tag').join(', '),
    ),
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in values.entries)
              FilterChip(
                label: Text(e.value),
                selected: selected.contains(e.key),
                onSelected: (on) {
                  if (_busy) return;
                  final next = {...selected};
                  on ? next.add(e.key) : next.remove(e.key);
                  change(next);
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.add_circle_outline),
              label: const Text('Add'),
              onPressed: add,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
  Future<void> _addEntity(String kind) async {
    FocusScope.of(context).unfocus();
    await editCatalogEntity(context, ref, kind);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider)!;
    final account = profile.accounts.firstWhere((a) => a.id == _accountId);
    final category = profile.categories
        .where(
          (c) =>
              c.id == (_type == 'transfer' ? _transferCategoryId : _categoryId),
        )
        .firstOrNull;
    var root = category;
    final visited = <String>{};
    while (root != null && root.parentId.isNotEmpty && visited.add(root.id)) {
      final parent = profile.categories
          .where((c) => c.id == root!.parentId)
          .firstOrNull;
      if (parent == null) break;
      root = parent;
    }
    final rootId = root?.id ?? '';
    final descendants =
        rootId.isEmpty ? <String>{} : categorySubtree(profile, rootId)
          ..remove(rootId);
    final suggestions = <String, int>{};
    for (final e in profile.transactions) {
      suggestions[e.name] = (suggestions[e.name] ?? 0) + 1;
    }
    final frequent = suggestions.keys.toList()
      ..sort((a, b) => suggestions[b]!.compareTo(suggestions[a]!));
    final l = AppLocalizations.of(context);
    final nameField = RawAutocomplete<String>(
      textEditingController: _name,
      focusNode: _nameFocus,
      optionsBuilder: (value) => frequent
          .where(
            (name) =>
                value.text.isEmpty ||
                name.toLowerCase().contains(value.text.toLowerCase()),
          )
          .take(6),
      fieldViewBuilder: (context, controller, focus, submit) => TextFormField(
        key: const ValueKey('transaction-name'),
        enabled: !_busy,
        controller: controller,
        focusNode: focus,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'What was it for?',
          prefixIcon: Icon(Icons.edit_note_rounded),
        ),
        validator: requiredText,
      ),
      optionsViewBuilder: (context, selected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: mathMin(MediaQuery.sizeOf(context).width - 48, 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              children: options
                  .map(
                    (option) => ListTile(
                      dense: true,
                      title: Text(option),
                      leading: const Icon(Icons.history_rounded, size: 18),
                      onTap: () => selected(option),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
    final linkedRepayment =
        widget.initial != null &&
        profile.loans.any(
          (loan) =>
              loan.repayments.any((p) => p.transactionId == widget.initial!.id),
        );
    final saveLabel = widget.templateOnly
        ? 'Save template'
        : widget.initial == null
        ? l.addTransaction
        : 'Save transaction';
    return FeaturePage(
      title: widget.templateOnly
          ? (widget.template == null ? 'New template' : 'Edit template')
          : widget.initial == null
          ? l.addTransaction
          : 'Edit transaction',
      bottomBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: saveLabel,
                    loading: _busy && !_saved,
                    success: _saved,
                    onPressed:
                        _busy || (_type == 'transfer' && _toAccountId.isEmpty)
                        ? null
                        : _save,
                    icon: Icons.check_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: _expandAll
                      ? 'Collapse extra fields'
                      : 'Expand extra fields',
                  onPressed: _busy
                      ? null
                      : () => setState(() => _expandAll = !_expandAll),
                  icon: Icon(
                    _expandAll ? Icons.unfold_less : Icons.unfold_more,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Only on your device. No real payment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
      child: Form(
        key: _form,
        child: AbsorbPointer(
          absorbing: _busy,
          child: SingleChildScrollView(
            key: const ValueKey('transaction-editor-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PillTabs(
                  labels: [
                    l.expenses,
                    l.income,
                    if (!widget.templateOnly) l.transfer,
                  ],
                  selected: _type == 'expense'
                      ? 0
                      : _type == 'income'
                      ? 1
                      : 2,
                  onSelected: (index) {
                    if (_busy) return;
                    if (linkedRepayment) {
                      toast(
                        context,
                        'Keep a dedicated repayment’s direction. Its loan controls lending/borrowing.',
                      );
                      return;
                    }
                    setState(() {
                      _type = ['expense', 'income', 'transfer'][index];
                      _budgetId = '';
                      if (_type != 'transfer')
                        _categoryId =
                            profile.categories
                                .where((c) => c.type == _type && !c.hidden)
                                .firstOrNull
                                ?.id ??
                            '';
                    });
                    _updateReceive();
                  },
                ),
                const SizedBox(height: 18),
                if (widget.initial == null && !widget.templateOnly)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _pickTemplate,
                      icon: const Icon(Icons.bookmark_outline),
                      label: const Text('Templates'),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: 'Selected category',
                      child: ColorIcon(
                        category?.icon ?? _type,
                        category?.color ?? 0xffffb59a,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: nameField),
                  ],
                ),
                if (_type != 'transfer' && category == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No matching category selected. Choose one below, or use Add in the Category section.',
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  'AMOUNT · ${account.currency}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                TextFormField(
                  key: const ValueKey('transaction-amount'),
                  controller: _amount,
                  enabled: !_busy,
                  autofocus: false,
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(fontFeatures: AppTextStyles.tabular),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (${account.currency})',
                    prefixText:
                        '${currencySymbols[account.currency] ?? account.currency} ',
                    hintText: '0',
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: IconButton(
                      tooltip: 'Calculator',
                      onPressed: () =>
                          setState(() => _calculator = !_calculator),
                      icon: const Icon(Icons.calculate_outlined),
                    ),
                  ),
                  validator: (value) {
                    try {
                      evaluateAmount(value ?? '');
                      return null;
                    } catch (_) {
                      return 'Enter a positive amount or expression';
                    }
                  },
                ),
                if (_calculator) ...[
                  _Calculator(controller: _amount),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                formText(_notes, 'A little note (optional)', lines: 3),
                const SizedBox(height: 16),
                if (!widget.templateOnly)
                  formDate(
                    context,
                    'When',
                    _date,
                    (v) => setState(() => _date = v),
                    includeTime: true,
                  ),
                const SizedBox(height: 20),
                _choice(
                  'From account',
                  _accountId,
                  {
                    for (final a in profile.accounts.where(
                      (a) => !a.archived || a.id == _accountId,
                    ))
                      a.id: '${a.name} · ${a.currency}',
                  },
                  (id) {
                    setState(() {
                      _accountId = id;
                      if (_toAccountId == id)
                        _toAccountId =
                            profile.accounts
                                .where((a) => a.id != id && !a.archived)
                                .firstOrNull
                                ?.id ??
                            '';
                    });
                    _updateReceive();
                  },
                  add: () async {
                    FocusScope.of(context).unfocus();
                    await editAccount(context, ref);
                    if (mounted) setState(() {});
                  },
                ),
                if (_type == 'transfer') ...[
                  _choice(
                    'To account',
                    _toAccountId,
                    {
                      for (final a in profile.accounts.where(
                        (a) => a.id != _accountId && !a.archived,
                      ))
                        a.id: '${a.name} · ${a.currency}',
                    },
                    (v) {
                      setState(() => _toAccountId = v);
                      _updateReceive();
                    },
                    add: () async {
                      await editAccount(context, ref);
                      if (mounted) setState(() {});
                    },
                  ),
                  if (_toAccountId.isEmpty)
                    const Text(
                      'Create a second account before recording a transfer.',
                    ),
                  const SizedBox(height: 16),
                  formText(
                    _receive,
                    'Receiving amount (editable conversion)',
                    required: true,
                    numeric: true,
                  ),
                  _choice(
                    'Transfer category (optional)',
                    _transferCategoryId,
                    {
                      '': 'No transfer category',
                      for (final c in profile.categories.where(
                        (c) =>
                            c.type == 'transfer' &&
                            (!c.hidden || c.id == _transferCategoryId),
                      ))
                        c.id: categoryPath(profile, c.id),
                    },
                    (v) => setState(() => _transferCategoryId = v),
                    add: () async {
                      await editCatalogCategory(context, ref, null, 'transfer');
                      if (mounted) setState(() {});
                    },
                  ),
                ] else ...[
                  KeyedSubtree(
                    key: _categorySection,
                    child: _choice(
                      'Category',
                      rootId,
                      {
                        for (final c in profile.categories.where(
                          (c) =>
                              c.type == _type &&
                              (!c.hidden || c.id == rootId) &&
                              (c.parentId.isEmpty || c.id == rootId),
                        ))
                          c.id: c.name,
                      },
                      (v) => setState(() => _categoryId = v),
                      add: () async {
                        await editCatalogCategory(context, ref, null, _type);
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                  _choice(
                    'Subcategory',
                    _categoryId == rootId ? '' : _categoryId,
                    {
                      '': 'No subcategory · use parent',
                      for (final c in profile.categories.where(
                        (c) =>
                            descendants.contains(c.id) &&
                            (!c.hidden || c.id == _categoryId),
                      ))
                        c.id: categoryPath(profile, c.id),
                    },
                    (v) => setState(() => _categoryId = v.isEmpty ? rootId : v),
                    add: () async {
                      await editCatalogCategory(context, ref, null, _type);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
                if (_type != 'transfer' && !widget.templateOnly)
                  ExpansionTile(
                    key: ValueKey('transaction-Budget-$_expandAll-$_type'),
                    initiallyExpanded: _expandAll,
                    maintainState: true,
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Budget'),
                    subtitle: Text(
                      profile.budgets
                              .where((b) => b.id == _budgetId)
                              .firstOrNull
                              ?.name ??
                          'Automatic matching only',
                    ),
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey('transaction-budget-$_type'),
                        isExpanded: true,
                        initialValue:
                            profile.budgets.any(
                              (b) =>
                                  b.id == _budgetId &&
                                  b.transactionType == _type,
                            )
                            ? _budgetId
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Budget (optional)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text(
                              'Automatic matching only',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          for (final b in profile.budgets.where(
                            (b) => b.transactionType == _type,
                          ))
                            DropdownMenuItem(
                              value: b.id,
                              child: Text(
                                '${b.name} · ${b.mode}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _budgetId = v ?? ''),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () async {
                            await editBudget(context, ref);
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add budget'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                _many(
                  'Labels',
                  _labels,
                  {
                    for (final e in profile.entities.where(
                      (e) => e.kind == 'label',
                    ))
                      e.id: e.name,
                  },
                  (v) => setState(() => _labels = v),
                  () => _addEntity('label'),
                ),
                if (!widget.templateOnly) ...[
                  _many(
                    'People / payee',
                    _people,
                    {
                      for (final e in profile.entities.where(
                        (e) => e.kind == 'person',
                      ))
                        e.id: e.name,
                    },
                    (v) => setState(() => _people = v),
                    () => _addEntity('person'),
                  ),
                  _choice(
                    'Place',
                    _placeId,
                    {
                      '': 'None',
                      for (final e in profile.entities.where(
                        (e) => e.kind == 'place',
                      ))
                        e.id: e.name,
                    },
                    (v) => setState(() => _placeId = v),
                    add: () => _addEntity('place'),
                  ),
                  _choice(
                    'Link a loan (tag only)',
                    _loanId,
                    {
                      '': 'None',
                      for (final loan in profile.loans)
                        loan.id: loan.personName,
                    },
                    (v) => setState(() => _loanId = v),
                    add: () async {
                      await editLoan(context, ref);
                      if (mounted) setState(() {});
                    },
                  ),
                  _choice(
                    'Link a goal (income adds to progress)',
                    _goalId,
                    {'': 'None', for (final g in profile.goals) g.id: g.name},
                    (v) => setState(() => _goalId = v),
                    add: () async {
                      await editGoal(context, ref);
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Keep the receipt'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < _receipts.length; i++)
                        Stack(
                          children: [
                            InkWell(
                              onTap: () => openPage(
                                context,
                                ReceiptViewer(_receipts, initialIndex: i),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  base64Decode(_receipts[i].data),
                                  width: 82,
                                  height: 82,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Receipt ${i + 1}',
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton.filled(
                                tooltip: 'Remove receipt',

                                icon: const Icon(Icons.close, size: 14),
                                onPressed: () =>
                                    setState(() => _receipts.removeAt(i)),
                              ),
                            ),
                          ],
                        ),
                      if (_receipts.length < 5) ...[
                        IconButton.outlined(
                          tooltip: 'Choose receipt photo',
                          onPressed: () => _receipt(ImageSource.gallery),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                        IconButton.outlined(
                          tooltip: 'Photograph receipt',
                          onPressed: () => _receipt(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_type != 'transfer')
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Save as a quick template'),
                      value: _template,
                      onChanged: (v) => setState(() => _template = v),
                    ),
                  if (widget.initial == null)
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Keep adding'),
                      subtitle: const Text('Stay here for your next entry'),
                      value: _sequential,
                      onChanged: (v) => setState(() => _sequential = v),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double mathMin(double a, double b) => a < b ? a : b;

class _Calculator extends StatelessWidget {
  final TextEditingController controller;
  const _Calculator({required this.controller});
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 4,
    childAspectRatio: 1.9,
    mainAxisSpacing: 6,
    crossAxisSpacing: 6,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children:
        [
              '7',
              '8',
              '9',
              '÷',
              '4',
              '5',
              '6',
              '×',
              '1',
              '2',
              '3',
              '−',
              '.',
              '0',
              '⌫',
              '+',
              '(',
              ')',
              '%',
              '=',
            ]
            .map(
              (key) => OutlinedButton(
                onPressed: () {
                  if (key == '⌫') {
                    if (controller.text.isNotEmpty) {
                      controller.text = controller.text.substring(
                        0,
                        controller.text.length - 1,
                      );
                    }
                  } else if (key == '=') {
                    try {
                      controller.text = evaluateAmount(controller.text)
                          .toString();
                    } catch (_) {
                      toast(context, 'Finish the expression first');
                    }
                  } else {
                    controller.text += key == '−' ? '-' : key;
                  }
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                },
                child: Text(key, style: const TextStyle(fontSize: 20)),
              ),
            )
            .toList(),
  );
}

Future<void> openTransactionSheet(
  BuildContext context, {
  String initialType = 'expense',
  String initialBudgetId = '',
  TransactionTemplate? template,
}) => showModalBottomSheet<void>(
  context: context,
  sheetAnimationStyle: const AnimationStyle(
    duration: Duration(milliseconds: 260),
    reverseDuration: Duration(milliseconds: 220),
  ),
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  constraints: const BoxConstraints(maxWidth: 720),
  builder: (context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .94,
      child: TransactionForm(
        initialType: initialType,
        initialBudgetId: initialBudgetId,
        template: template,
      ),
    ),
  ),
);
