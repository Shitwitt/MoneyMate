import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/enum/filter_enums.dart';
import '../../../core/theme/paisa_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// The big, tappable amount display at the top of the entry form.
///
/// The [TextField] handles ordinary typing; tapping the calculator icon opens
/// the keypad sheet so several bill items can be added up before saving.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.formatter,
    required this.type,
    required this.onOpenCalculator,
    this.focusNode,
    this.errorText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final CurrencyFormatter formatter;
  final TransactionType type;
  final VoidCallback onOpenCalculator;
  final FocusNode? focusNode;
  final String? errorText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    final Color accent = switch (type) {
      TransactionType.expense => colors.expense,
      TransactionType.income => colors.income,
      TransactionType.transfer => colors.transfer,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: errorText == null ? scheme.outlineVariant : scheme.error,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              formatter.symbol,
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: accent,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: accent.withValues(alpha: 0.35),
                ),
                errorText: errorText,
                errorStyle: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            onPressed: onOpenCalculator,
            tooltip: 'Open calculator',
            icon: const Icon(Icons.calculate_outlined),
          ),
        ],
      ),
    );
  }
}
