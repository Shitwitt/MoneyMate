import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/account_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/account_card.dart';

/// Creates or edits an account.
///
/// Everything on this screen is live: the card preview at the top re-renders as
/// the user types the bank name, flips the type, changes the last four digits or
/// picks a new colour. Saving validates the name and the opening balance, then
/// writes one record — no partial state.
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key, this.existing, this.initialType});

  /// The account being edited, or `null` when creating.
  final AccountModel? existing;

  /// Pre-selects the type for a new account.
  final AccountType? initialType;

  bool get isEditing => existing != null;

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _bankName = TextEditingController();
  final TextEditingController _holderName = TextEditingController();
  final TextEditingController _last4 = TextEditingController();
  final TextEditingController _opening = TextEditingController();

  late AccountType _type;
  late AccountStyle _style;
  bool _makeDefault = false;
  bool _saving = false;

  PaisaProvider get _provider => context.read<PaisaProvider>();

  @override
  void initState() {
    super.initState();
    final AccountModel? existing = widget.existing;
    final PaisaProvider provider = context.read<PaisaProvider>();

    _type = existing?.cardType ?? widget.initialType ?? AccountType.bank;
    _style = AccountStyle.forColor(
      existing?.color ?? _styleForType(_type).value,
    );
    _makeDefault = existing?.isDefault ?? provider.accounts.isEmpty;

    if (existing != null) {
      _bankName.text = existing.bankName;
      _holderName.text = existing.name;
      _last4.text = existing.number;
      _opening.text = provider.formatter.forInput(existing.initialAmount);
    } else {
      _holderName.text = provider.userName;
    }
  }

  @override
  void dispose() {
    _bankName.dispose();
    _holderName.dispose();
    _last4.dispose();
    _opening.dispose();
    super.dispose();
  }

  /// A sensible default colour for each account type; the user can override it.
  AccountStyle _styleForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return AccountStyle.byId('card-emerald');
      case AccountType.bank:
        return AccountStyle.byId('card-ocean');
      case AccountType.card:
        return AccountStyle.byId('card-indigo');
    }
  }

  void _setType(AccountType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      // Only auto-shift the theme while the user has not chosen one explicitly.
      _style = _styleForType(type);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final CurrencyFormatter formatter = _provider.formatter;
    final double opening = _opening.text.trim().isEmpty
        ? 0
        : (formatter.parse(_opening.text.trim()) ?? 0);

    final AccountModel account = AccountModel(
      id: widget.existing?.id ?? IdGenerator.newId(),
      name: _holderName.text.trim().isEmpty ? 'Me' : _holderName.text.trim(),
      bankName: _bankName.text.trim(),
      number: _last4.text.trim(),
      cardType: _type,
      initialAmount: opening,
      color: _style.value,
      isDefault: _makeDefault,
    );

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await _provider.updateAccount(account);
        if (_makeDefault) await _provider.setDefaultAccount(account.id);
      } else {
        await _provider.addAccount(account);
        if (_makeDefault) await _provider.setDefaultAccount(account.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(account);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the account: $error')),
      );
    }
  }

  Future<void> _delete() async {
    final AccountModel? existing = widget.existing;
    if (existing == null) return;

    final PaisaProvider provider = _provider;
    final bool isLast = provider.accounts.length <= 1;
    final int linked = provider.transactions
        .where((transaction) =>
            transaction.accountId == existing.id ||
            transaction.toAccountId == existing.id)
        .length;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete ${existing.title}?'),
        content: Text(
          isLast
              ? 'This is your only account, so it cannot be deleted. Add another '
                  'account first.'
              : 'This removes the account and its opening balance. '
                  '$linked transaction${linked == 1 ? '' : 's'} recorded on it '
                  'will be deleted too, because their balance has nowhere to go.',
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
            onPressed: isLast
                ? null
                : () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    await provider.deleteAccount(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop(existing);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = context.watch<PaisaProvider>().formatter;
    final String previewOpening = _opening.text.trim().isEmpty
        ? formatter.format(0)
        : formatter.format(
            formatter.parse(_opening.text.trim()) ?? 0,
            withDecimals: false,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit account' : 'Add account'),
        actions: <Widget>[
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete account',
              onPressed: _saving ? null : _delete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
            // ---------------- Live preview ----------------
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AccountCardView(
                  title: _bankName.text.trim().isEmpty
                      ? _type.label
                      : _bankName.text.trim(),
                  holderName: _holderName.text.trim(),
                  maskedNumber: _type == AccountType.cash &&
                          _last4.text.trim().isEmpty
                      ? 'Cash in hand'
                      : AccountModel(
                          id: 'preview',
                          name: _holderName.text,
                          bankName: _bankName.text,
                          number: _last4.text,
                          cardType: _type,
                          initialAmount: 0,
                          color: _style.value,
                        ).carouselNumber,
                  type: _type,
                  style: _style,
                  balanceLabel: previewOpening,
                  balanceCaption: _type == AccountType.cash
                      ? 'Cash in hand'
                      : 'Opening balance',
                  isDefault: _makeDefault,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- Type ----------------
            const _SectionLabel(label: 'Account type'),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                for (final AccountType value in AccountType.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: value == AccountType.values.last ? 0 : 8,
                      ),
                      child: _TypeTile(
                        type: value,
                        selected: _type == value,
                        onTap: () => _setType(value),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ---------------- Fields ----------------
            const _SectionLabel(label: 'Details'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bankName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              onChanged: (_) => setState(() {}),
              validator: (String? value) => (value ?? '').trim().isEmpty
                  ? _type == AccountType.cash
                      ? 'Give the wallet a name'
                      : 'Add the bank name'
                  : null,
              decoration: InputDecoration(
                labelText: _type == AccountType.cash
                    ? 'Wallet name'
                    : _type == AccountType.card
                        ? 'Card name'
                        : 'Bank name',
                hintText: _type == AccountType.cash
                    ? 'e.g. Cash in hand'
                    : _type == AccountType.card
                        ? 'e.g. HDFC Regalia'
                        : 'e.g. HDFC Savings',
                prefixIcon: Icon(_type.icon),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _holderName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Account holder',
                hintText: 'Name printed on the card',
                prefixIcon: Icon(Icons.person_outline_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _opening,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (String? value) {
                      final String raw = (value ?? '').trim();
                      if (raw.isEmpty) return null;
                      final double? parsed = formatter.parse(raw);
                      if (parsed == null) return 'Enter a valid amount';
                      if (parsed.abs() > 999999999) return 'Too large';
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Opening balance',
                      hintText: '0',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _last4,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (_) => setState(() {}),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (String? value) {
                      final String raw = (value ?? '').trim();
                      if (raw.isNotEmpty && raw.length < 4) {
                        return '4 digits';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Last 4',
                      hintText: '4821',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'The opening balance is the money already in this account today. '
              'Every transaction after that is added on top.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- Colour ----------------
            const _SectionLabel(label: 'Card colour'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final AccountStyle style in AccountStyle.palette)
                  _StyleSwatch(
                    style: style,
                    selected: style.id == _style.id,
                    onTap: () => setState(() => _style = style),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _makeDefault,
              onChanged: (bool value) => setState(() => _makeDefault = value),
              title: const Text('Use as default account'),
              subtitle: const Text(
                'Pre-selected whenever you add a transaction',
              ),
              secondary: Icon(
                Icons.bookmark_outline_rounded,
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
                        widget.isEditing ? 'Save changes' : 'Add account',
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
                    'Delete account',
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

/// Opens the account editor (create when [existing] is null).
Future<AccountModel?> openAddAccountScreen(
  BuildContext context, {
  AccountModel? existing,
  AccountType? initialType,
}) {
  return Navigator.of(context).push<AccountModel>(
    MaterialPageRoute<AccountModel>(
      builder: (BuildContext context) => AddAccountScreen(
        existing: existing,
        initialType: initialType,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AccountType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              type.icon,
              size: 22,
              color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              type.label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleSwatch extends StatelessWidget {
  const _StyleSwatch({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AccountStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Tooltip(
      message: style.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[style.start, style.end],
            ),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}
