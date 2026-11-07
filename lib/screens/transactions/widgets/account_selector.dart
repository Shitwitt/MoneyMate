import 'package:flutter/material.dart';

import '../../../core/enum/filter_enums.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';

/// A horizontal row of account pills.
///
/// The entry form renders **two** of these for a transfer (`From` and `To`) and
/// disables the counterpart inside each, so the same account can never be
/// picked on both sides.
class AccountSelectorRow extends StatelessWidget {
  const AccountSelectorRow({
    super.key,
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
    required this.formatter,
    required this.balances,
    this.excludedId,
    this.errorText,
    this.icon,
  });

  /// `Account`, `Transfer From Account`, `Transfer To Account`.
  final String label;

  final List<AccountModel> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final CurrencyFormatter formatter;

  /// Live balance per account id, shown under each pill.
  final Map<String, double> balances;

  /// The other side's selection — rendered disabled with a "Same account" hint.
  final String? excludedId;

  final String? errorText;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (accounts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Add an account first to record transactions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final AccountModel account = accounts[index];
                final bool isSelected = account.id == selectedId;
                final bool isExcluded = account.id == excludedId;
                return _AccountPill(
                  account: account,
                  selected: isSelected,
                  disabled: isExcluded,
                  balance: formatter.formatWhole(
                    balances[account.id] ?? account.initialAmount,
                  ),
                  onTap: isExcluded ? null : () => onSelect(account.id),
                );
              },
            ),
          ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

class _AccountPill extends StatelessWidget {
  const _AccountPill({
    required this.account,
    required this.selected,
    required this.disabled,
    required this.balance,
    required this.onTap,
  });

  final AccountModel account;
  final bool selected;
  final bool disabled;
  final String balance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color tint = Color(account.color);

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: !disabled,
        label: account.title,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 148,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Color.alphaBlend(tint.withAlpha(32), scheme.surfaceContainerLow)
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? tint : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(account.cardType.icon, size: 16, color: tint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        account.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  disabled ? 'In use' : balance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: disabled ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
