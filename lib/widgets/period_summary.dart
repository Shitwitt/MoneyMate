import 'package:flutter/material.dart';

import '../core/enum/filter_enums.dart';
import '../core/theme/paisa_colors.dart';
import '../core/utils/currency_formatter.dart';

/// The home hero card: total net balance plus the period's income and expense.
///
/// * 28dp rounded, `primaryContainer` gradient body.
/// * The balance animates with a [TweenAnimationBuilder] every time it changes
///   (never on first paint, so cold start does not "count up from zero").
/// * Two tonal sub-cards at the bottom carry income and expense with their
///   transaction counts.
class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({
    super.key,
    required this.totalBalance,
    required this.periodIncome,
    required this.periodExpense,
    required this.incomeCount,
    required this.expenseCount,
    required this.formatter,
    this.periodLabel,
    this.onTogglePrivacy,
    this.hideAmounts = false,
    this.footer,
  });

  final double totalBalance;
  final double periodIncome;
  final double periodExpense;
  final int incomeCount;
  final int expenseCount;
  final CurrencyFormatter formatter;

  /// e.g. `This Month` — shown above the two sub-cards.
  final String? periodLabel;

  final VoidCallback? onTogglePrivacy;
  final bool hideAmounts;

  /// Optional extra content below the sub-cards (the home screen uses it for the
  /// "left to spend" hint).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.surfaceContainerHighest.withAlpha(120),
              scheme.primaryContainer,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Net Balance',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onTogglePrivacy != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: hideAmounts ? 'Show amounts' : 'Hide amounts',
                  onPressed: onTogglePrivacy,
                  icon: Icon(
                    hideAmounts
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          AnimatedAmount(
            value: totalBalance,
            formatter: formatter,
            hide: hideAmounts,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
              color: scheme.onPrimaryContainer,
            ),
          ),
          if (periodLabel != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              periodLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer.withAlpha(190),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _PeriodSubCard(
                  icon: Icons.south_west_rounded,
                  label: 'Income',
                  amount: formatter.formatWhole(periodIncome),
                  count: incomeCount,
                  accent: colors.income,
                  container: colors.incomeContainer,
                  hideAmounts: hideAmounts,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PeriodSubCard(
                  icon: Icons.north_east_rounded,
                  label: 'Expense',
                  amount: formatter.formatWhole(periodExpense),
                  count: expenseCount,
                  accent: colors.expense,
                  container: colors.expenseContainer,
                  hideAmounts: hideAmounts,
                ),
              ),
            ],
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// One of the two tonal sub-cards inside the hero card.
class _PeriodSubCard extends StatelessWidget {
  const _PeriodSubCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.count,
    required this.accent,
    required this.container,
    required this.hideAmounts,
  });

  final IconData icon;
  final String label;
  final String amount;
  final int count;
  final Color accent;
  final Color container;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count == 1 ? '1 transaction' : '$count transactions',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A money value that counts to its new value instead of snapping.
///
/// The first build renders the final value immediately (no "0 → total" flash on
/// launch); subsequent changes animate over 450 ms.
class AnimatedAmount extends StatefulWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.hide = false,
  });

  final double value;
  final CurrencyFormatter formatter;
  final TextStyle? style;
  final bool hide;

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount> {
  double _previous = 0;
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    _previous = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previous = oldWidget.value;
    _firstBuild = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hide) {
      return Text(CurrencyFormatter.maskedAmount, style: widget.style);
    }
    if (_firstBuild) {
      return Text(
        widget.formatter.format(widget.value),
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previous, end: widget.value),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, _) {
        return Text(
          widget.formatter.format(value),
          style: widget.style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// The horizontal `Daily / Weekly / Monthly / Yearly / All` filter row.
class PeriodFilterChips extends StatelessWidget {
  const PeriodFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.labels,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final FilterExpense selected;
  final ValueChanged<FilterExpense> onSelected;

  /// Optional override for the chip labels (localized strings).
  final String Function(FilterExpense filter)? labels;

  final EdgeInsets padding;

  static String defaultLabel(FilterExpense filter) {
    switch (filter) {
      case FilterExpense.daily:
        return 'Daily';
      case FilterExpense.weekly:
        return 'Weekly';
      case FilterExpense.monthly:
        return 'Monthly';
      case FilterExpense.yearly:
        return 'Yearly';
      case FilterExpense.all:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: FilterExpense.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final FilterExpense filter = FilterExpense.values[index];
          final bool isSelected = filter == selected;
          return ChoiceChip(
            label: Text(
              labels?.call(filter) ?? defaultLabel(filter),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

/// Human label for a period, e.g. `This Month`, `Today`, `All Time`.
String periodLabelFor(FilterExpense filter) {
  switch (filter) {
    case FilterExpense.daily:
      return 'Today';
    case FilterExpense.weekly:
      return 'This Week';
    case FilterExpense.monthly:
      return 'This Month';
    case FilterExpense.yearly:
      return 'This Year';
    case FilterExpense.all:
      return 'All Time';
  }
}
