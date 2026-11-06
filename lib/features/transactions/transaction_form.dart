import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/money.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
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
        profile.categories
            .firstWhere(
              (item) => item.type == (_type == 'transfer' ? 'expense' : _type),
              orElse: () => profile.categories.first,
            )
            .id;
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
    if (entry != null) {
      _people = entry.personIds.toSet();
      _placeId = entry.placeId;
      _goalId = entry.goalId;
      _loanId = entry.loanId;
      _date = entry.date;
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
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final controller = ref.read(appProvider.notifier);
    final saved = await runSafe(context, () async {
      final profile = ref.read(profileProvider)!;
      final currency = profile.accounts
          .firstWhere((item) => item.id == _accountId)
          .currency;
      final amount = toMinor(evaluateAmount(_amount.text), currency);
      if (amount <= 0) throw const FormatException('Amount rounds to zero');
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider)!;
    final account = profile.accounts.firstWhere(
      (item) => item.id == _accountId,
    );
    final categories =
        profile.categories
            .where(
              (item) =>
                  item.type == _type &&
                  (!item.hidden || item.id == _categoryId),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final suggestions = <String, int>{};
    for (final entry in profile.transactions) {
      suggestions[entry.name] = (suggestions[entry.name] ?? 0) + 1;
    }
    final frequent = suggestions.keys.toList()
      ..sort((a, b) => suggestions[b]!.compareTo(suggestions[a]!));
    final l = AppLocalizations.of(context);
    return FeaturePage(
      title: widget.templateOnly
          ? (widget.template == null ? 'New template' : 'Edit template')
          : widget.initial == null
          ? l.addTransaction
          : 'Edit transaction',
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'expense',
                  label: Text(l.expenses),
                  icon: const Icon(Icons.north_east_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text(l.income),
                  icon: const Icon(Icons.south_west_rounded, size: 16),
                ),
                if (!widget.templateOnly)
                  ButtonSegment(
                    value: 'transfer',
                    label: Text(l.transfer),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                setState(() {
                  _type = value.first;
                  _budgetId = '';
                  if (_type != 'transfer') {
                    _categoryId = profile.categories
                        .firstWhere((item) => item.type == _type)
                        .id;
                  }
                });
                _updateReceive();
              },
            ),
            const SizedBox(height: 24),
            Text(
              'AMOUNT · ${account.currency}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            TextFormField(
              controller: _amount,
              autofocus: widget.initial == null && widget.template == null,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFeatures: AppTextStyles.tabular,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText:
                    '${currencySymbols[account.currency] ?? account.currency} ',
                hintText: '0',
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: IconButton(
                  tooltip: 'Calculator',
                  onPressed: () => setState(() => _calculator = !_calculator),
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
            RawAutocomplete<String>(
              textEditingController: _name,
              focusNode: _nameFocus,
              optionsBuilder: (value) => frequent
                  .where(
                    (name) =>
                        value.text.isEmpty ||
                        name.toLowerCase().contains(value.text.toLowerCase()),
                  )
                  .take(6),
              fieldViewBuilder: (context, controller, focus, submit) =>
                  TextFormField(
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
                alignment: Alignment.topLeft,
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
                              leading: const Icon(
                                Icons.history_rounded,
                                size: 18,
                              ),
                              onTap: () => selected(option),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            formSelect(
              'From account',
              _accountId,
              profile.accounts
                  .where((item) => !item.archived || item.id == _accountId)
                  .map((item) => item.id)
                  .toList(),
              (id) {
                setState(() {
                  _accountId = id;
                  if (_toAccountId == id) {
                    _toAccountId =
                        profile.accounts
                            .where((item) => item.id != id && !item.archived)
                            .firstOrNull
                            ?.id ??
                        '';
                  }
                });
                _updateReceive();
              },
              display: (id) {
                final item = profile.accounts.firstWhere(
                  (item) => item.id == id,
                );
                return '${item.name} · ${item.currency}';
              },
            ),
            if (_type == 'transfer') ...[
              const SizedBox(height: 16),
              if (profile.accounts
                  .where((item) => item.id != _accountId && !item.archived)
                  .isEmpty)
                const Text(
                  'Create a second account before recording a transfer.',
                )
              else
                formSelect(
                  'To account',
                  _toAccountId,
                  profile.accounts
                      .where((item) => item.id != _accountId && !item.archived)
                      .map((item) => item.id)
                      .toList(),
                  (id) {
                    setState(() => _toAccountId = id);
                    _updateReceive();
                  },
                  display: (id) =>
                      '${profile.accounts.firstWhere((item) => item.id == id).name} · ${profile.accounts.firstWhere((item) => item.id == id).currency}',
                ),
              const SizedBox(height: 16),
              formText(
                _receive,
                'Receiving amount (editable conversion)',
                required: true,
                numeric: true,
              ),
            ],
            if (_type == 'transfer' &&
                profile.categories.any((c) => c.type == 'transfer')) ...[
              const SizedBox(height: 16),
              formSelect(
                'Transfer category (optional)',
                _transferCategoryId,
                [
                  '',
                  ...profile.categories
                      .where(
                        (c) =>
                            c.type == 'transfer' &&
                            (!c.hidden || c.id == _transferCategoryId),
                      )
                      .map((c) => c.id),
                ],
                (value) => setState(() => _transferCategoryId = value),
                display: (id) => id.isEmpty
                    ? 'Uncategorized transfer'
                    : profile.categories.firstWhere((c) => c.id == id).name,
              ),
            ],
            if (_type != 'transfer') ...[
              const SizedBox(height: 20),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: categories
                    .map(
                      (category) => ChoiceChip(
                        avatar: Icon(
                          iconFor(category.icon),
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Color(category.color)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        label: Text(category.name),
                        selected: _categoryId == category.id,
                        onSelected: (_) =>
                            setState(() => _categoryId = category.id),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (!widget.templateOnly) ...[
              const SizedBox(height: 20),
              formDate(
                context,
                'When',
                _date,
                (date) => setState(() => _date = date),
                includeTime: true,
              ),
            ],
            const SizedBox(height: 16),
            formText(_notes, 'A little note (optional)', lines: 3),
            const SizedBox(height: 20),
            if (_type != 'transfer' && !widget.templateOnly) ...[
              DropdownButtonFormField<String>(
                key: ValueKey('transaction-budget-$_type'),
                isExpanded: true,
                initialValue:
                    profile.budgets.any(
                      (b) => b.id == _budgetId && b.transactionType == _type,
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
              const SizedBox(height: 16),
            ],
            if (profile.entities.any((item) => item.kind == 'label')) ...[
              const SizedBox(height: 20),
              formChips(
                'Labels',
                {
                  for (final item in profile.entities.where(
                    (item) => item.kind == 'label',
                  ))
                    item.id: item.name,
                },
                _labels,
                (values) => setState(() => _labels = values),
              ),
            ],
            if (!widget.templateOnly) ...[
              if (profile.entities.any((item) => item.kind == 'person')) ...[
                const SizedBox(height: 20),
                formChips(
                  'People',
                  {
                    for (final item in profile.entities.where(
                      (item) => item.kind == 'person',
                    ))
                      item.id: item.name,
                  },
                  _people,
                  (values) => setState(() => _people = values),
                ),
              ],
              if (profile.entities.any((item) => item.kind == 'place')) ...[
                const SizedBox(height: 16),
                formSelect(
                  'Place',
                  _placeId,
                  [
                    '',
                    ...profile.entities
                        .where((item) => item.kind == 'place')
                        .map((item) => item.id),
                  ],
                  (id) => setState(() => _placeId = id),
                  display: (id) => id.isEmpty
                      ? 'None'
                      : profile.entities
                            .firstWhere((item) => item.id == id)
                            .name,
                ),
              ],
              if (profile.goals.isNotEmpty) ...[
                const SizedBox(height: 16),
                formSelect(
                  'Link a goal (income adds to progress)',
                  _goalId,
                  ['', ...profile.goals.map((item) => item.id)],
                  (id) => setState(() => _goalId = id),
                  display: (id) => id.isEmpty
                      ? 'None'
                      : profile.goals.firstWhere((item) => item.id == id).name,
                ),
              ],
              if (profile.loans.isNotEmpty) ...[
                const SizedBox(height: 16),
                formSelect(
                  'Link a loan (tag only)',
                  _loanId,
                  ['', ...profile.loans.map((item) => item.id)],
                  (id) => setState(() => _loanId = id),
                  display: (id) => id.isEmpty
                      ? 'None'
                      : profile.loans
                            .firstWhere((item) => item.id == id)
                            .personName,
                ),
              ],
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
                            visualDensity: VisualDensity.compact,
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
                  onChanged: (value) => setState(() => _template = value),
                ),
              if (widget.initial == null)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Keep adding'),
                  subtitle: const Text('Stay here for your next entry'),
                  value: _sequential,
                  onChanged: (value) => setState(() => _sequential = value),
                ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: widget.templateOnly ? 'Save template' : 'Save transaction',
              loading: _busy && !_saved,
              success: _saved,
              onPressed: _busy || (_type == 'transfer' && _toAccountId.isEmpty)
                  ? null
                  : _save,
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Only on your device. Always.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ],
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
                      controller.text = evaluateAmount(
                        controller.text,
                      ).toString();
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
