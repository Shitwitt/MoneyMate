import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/expression_calculator.dart';

/// The bottom-sheet calculator for building up an amount from several bill
/// items (`120 + 35.50 × 2`).
///
/// Two ways in:
/// * the system keyboard (`TextField` focus) for quick typing,
/// * the built-in keypad below it, which never covers the expression.
///
/// Returns the confirmed total, or `null` when dismissed.
Future<double?> showCalculatorSheet(
  BuildContext context, {
  required CurrencyFormatter formatter,
  double initialValue = 0,
  String title = 'Amount',
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return CalculatorSheet(
        formatter: formatter,
        initialValue: initialValue,
        title: title,
      );
    },
  );
}

class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({
    super.key,
    required this.formatter,
    required this.initialValue,
    required this.title,
  });

  final CurrencyFormatter formatter;
  final double initialValue;
  final String title;

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  late String _expression = widget.initialValue == 0
      ? ''
      : widget.formatter.forInput(widget.initialValue);
  late final TextEditingController _controller =
      TextEditingController(text: _expression);
  final FocusNode _focusNode = FocusNode();
  double? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Keeps the text field and the internal expression in lock-step without
  /// fighting the cursor while the user types.
  void _syncController() {
    if (_controller.text == _expression) return;
    _controller.value = TextEditingValue(
      text: _expression,
      selection: TextSelection.collapsed(offset: _expression.length),
    );
  }

  void _recalculate() {
    final double? result = ExpressionCalculator.evaluate(_expression);
    setState(() {
      _preview = result;
      _error = _expression.isEmpty ? null : (result == null ? 'Invalid' : null);
    });
  }

  void _append(String token) {
    setState(() {
      if (ExpressionCalculator.isOperator(token)) {
        if (_expression.isEmpty) {
          // Starting with a minus is legitimate ("-50" is a refund-less charge);
          // any other operator restarts the expression.
          if (token == '-') _expression = '-';
          return;
        }
        final String last = _expression[_expression.length - 1];
        if (ExpressionCalculator.isOperator(last)) {
          _expression =
              '${_expression.substring(0, _expression.length - 1)}$token';
          return;
        }
        _expression = '$_expression$token';
        return;
      }
      // Digits and the decimal point.
      if (token == '.') {
        // Only one decimal point per number.
        final String tail = _expression.split(RegExp(r'[+\-×÷]')).last;
        if (tail.contains('.')) return;
        _expression = _expression.isEmpty ? '0.' : '$_expression.';
        return;
      }
      if (token == '00') {
        if (_expression.isEmpty) return;
        _expression = '${_expression}00';
        return;
      }
      // Avoid leading zeros like "007".
      if (token == '0') {
        final String tail = _expression.split(RegExp(r'[+\-×÷]')).last;
        if (tail == '0') return;
      }
      _expression = '$_expression$token';
    });
    _syncController();
    _recalculate();
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
    });
    _syncController();
    _recalculate();
  }

  void _clear() {
    setState(() {
      _expression = '';
      _error = null;
    });
    _syncController();
    _recalculate();
  }

  void _confirm() {
    final double? result =
        _preview ?? ExpressionCalculator.evaluate(_expression);
    if (result == null || result <= 0) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    Navigator.of(context).pop(double.parse(result.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),

          // ---------------- Expression display ----------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (String value) {
                    _expression = value;
                    _recalculate();
                  },
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-×÷*/. ]')),
                  ],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error ??
                      '= ${widget.formatter.format(_preview ?? 0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _error != null
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_expression.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    ExpressionCalculator.prettify(_expression),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---------------- Keypad ----------------
          _Keypad(
            onDigit: _append,
            onOperator: _append,
            onClear: _clear,
            onBackspace: _backspace,
            onEquals: _confirm,
          ),
          const SizedBox(height: 12),

          FilledButton(
            onPressed: _confirm,
            child: Text(
              _preview == null
                  ? 'Use amount'
                  : 'Use ${widget.formatter.formatWhole(_preview!)}',
            ),
          ),
        ],
      ),
    );
  }
}

/// A 4×5 keypad: digits, operators, AC, backspace and equals.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onOperator,
    required this.onClear,
    required this.onBackspace,
    required this.onEquals,
  });

  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onEquals;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Widget key(
      String label, {
      required VoidCallback onTap,
      Color? background,
      Color? foreground,
      IconData? icon,
      int flex = 1,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 54,
            child: Material(
              color: background ?? scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Center(
                  child: icon != null
                      ? Icon(icon, size: 20, color: foreground)
                      : Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Color accent = scheme.primary;
    final Color onAccent = scheme.onPrimary;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            key('AC', onTap: onClear, foreground: scheme.error),
            key('⌫', onTap: onBackspace, icon: Icons.backspace_outlined),
            key('00', onTap: () => onDigit('00')),
            key(
              '÷',
              onTap: () => onOperator('÷'),
              background: scheme.secondaryContainer,
              foreground: scheme.onSecondaryContainer,
            ),
          ],
        ),
        Row(
          children: <Widget>[
            key('7', onTap: () => onDigit('7')),
            key('8', onTap: () => onDigit('8')),
            key('9', onTap: () => onDigit('9')),
            key(
              '×',
              onTap: () => onOperator('×'),
              background: scheme.secondaryContainer,
              foreground: scheme.onSecondaryContainer,
            ),
          ],
        ),
        Row(
          children: <Widget>[
            key('4', onTap: () => onDigit('4')),
            key('5', onTap: () => onDigit('5')),
            key('6', onTap: () => onDigit('6')),
            key(
              '-',
              onTap: () => onOperator('-'),
              background: scheme.secondaryContainer,
              foreground: scheme.onSecondaryContainer,
            ),
          ],
        ),
        Row(
          children: <Widget>[
            key('1', onTap: () => onDigit('1')),
            key('2', onTap: () => onDigit('2')),
            key('3', onTap: () => onDigit('3')),
            key(
              '+',
              onTap: () => onOperator('+'),
              background: scheme.secondaryContainer,
              foreground: scheme.onSecondaryContainer,
            ),
          ],
        ),
        Row(
          children: <Widget>[
            key('0', onTap: () => onDigit('0'), flex: 2),
            key('.', onTap: () => onDigit('.')),
            key(
              '=',
              onTap: onEquals,
              background: accent,
              foreground: onAccent,
            ),
          ],
        ),
      ],
    );
  }
}
