import 'package:flutter/material.dart';

import '../core/constants/icons.dart';
import '../core/enum/filter_enums.dart';
import '../core/theme/paisa_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_time_format.dart';
import '../data/models/account_model.dart';
import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';

/// One row in the ledger.
///
/// Layout: a 48×48 tinted squircle holding the category icon, the title, a
/// `Category • Account • 07:30 PM` subtitle, and a right-aligned signed amount
/// coloured by direction (red expense / green income / blue transfer).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.formatter,
    this.category,
    this.account,
    this.toAccount,
    this.onTap,
    this.onDelete,
    this.showDate = false,
    this.hideAmounts = false,
  });

  final TransactionModel transaction;
  final CurrencyFormatter formatter;

  /// Resolved category (null for transfers or deleted categories).
  final CategoryModel? category;

  /// Source account.
  final AccountModel? account;

  /// Destination account, for transfers only.
  final AccountModel? toAccount;

  final VoidCallback? onTap;

  /// Invoked by the swipe-to-delete gesture.
  final VoidCallback? onDelete;

  /// Appends the calendar date to the subtitle (used by search results, where
  /// rows are not grouped by day).
  final bool showDate;

  /// Respects the app-wide "hide amounts" privacy mode.
  final bool hideAmounts;

  static const double _iconSize = 48;

  Color _iconColor(BuildContext context) {
    if (transaction.type == TransactionType.transfer) {
      final AccountModel? source = account;
      return source == null
          ? PaisaColors.of(context).transfer
          : Color(source.color);
    }
    final CategoryModel? model = category;
    if (model == null) return PaisaColors.of(context).neutral;
    return Color(model.color);
  }

  IconData _icon(BuildContext context) {
    if (transaction.type == TransactionType.transfer) {
      return Icons.swap_horiz_rounded;
    }
    return ICONS.byCodePoint(category?.icon);
  }

  /// `Category • Account • 07:30 PM`, skipping unknown parts so no empty `•`
  /// separators leak into the UI.
  String _subtitle(BuildContext context) {
    final List<String> parts = <String>[];
    if (transaction.type == TransactionType.transfer) {
      parts.add(account?.title ?? 'Transfer');
      parts.add(toAccount?.title ?? '—');
    } else {
      final CategoryModel? model = category;
      parts.add(model?.name ?? 'Uncategorised');
      parts.add(account?.title ?? 'Deleted account');
    }
    parts.add(
      showDate
          ? DateTimeFormat.dateTime(transaction.time)
          : DateTimeFormat.time(transaction.time),
    );
    return parts.join(' • ');
  }

  /// `-₹500`, `+₹2,000`, `⇄ ₹1,000`.
  String _amountLabel() {
    if (hideAmounts) return CurrencyFormatter.maskedAmount;
    final String value = formatter.formatWhole(transaction.amount);
    switch (transaction.type) {
      case TransactionType.expense:
        return '-$value';
      case TransactionType.income:
        return '+$value';
      case TransactionType.transfer:
        return '⇄ $value';
    }
  }

  Color _amountColor(BuildContext context) {
    final PaisaColors colors = PaisaColors.of(context);
    switch (transaction.type) {
      case TransactionType.expense:
        return colors.expense;
      case TransactionType.income:
        return colors.income;
      case TransactionType.transfer:
        return colors.transfer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color tint = _iconColor(context);

    final Widget row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: _iconSize,
                height: _iconSize,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_icon(context), size: 22, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      transaction.name.isEmpty
                          ? (transaction.type == TransactionType.transfer
                              ? 'Transfer'
                              : 'Untitled')
                          : transaction.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _amountLabel(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _amountColor(context),
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) return row;

    return Dismissible(
      key: ValueKey<String>('tx-${transaction.id}'),
      direction: DismissDirection.endToStart,
      // The delete itself is driven by the parent so it can show the Undo
      // snack bar; `confirmDismiss` returning false lets the tile spring back
      // immediately while the snack bar owns the undo window.
      confirmDismiss: (_) async {
        onDelete!();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: PaisaColors.of(context).expenseContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: PaisaColors.of(context).expense,
        ),
      ),
      child: row,
    );
  }
}

/// A date-group header: `Today` on the left, the day's net on the right.
class TransactionDayHeader extends StatelessWidget {
  const TransactionDayHeader({
    super.key,
    required this.label,
    required this.net,
    required this.formatter,
    this.transactionCount,
    this.hideAmounts = false,
  });

  final String label;
  final double net;
  final CurrencyFormatter formatter;
  final int? transactionCount;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final String netLabel = hideAmounts
        ? CurrencyFormatter.maskedAmount
        : formatter.formatSigned(net, withDecimals: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (transactionCount != null) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              '· $transactionCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          Text(
            netLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: net == 0
                  ? scheme.onSurfaceVariant
                  : (net > 0
                      ? PaisaColors.of(context).income
                      : PaisaColors.of(context).expense),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared empty state for the ledger, search results and account statements.
class LedgerEmptyState extends StatelessWidget {
  const LedgerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(icon, size: 34, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}
