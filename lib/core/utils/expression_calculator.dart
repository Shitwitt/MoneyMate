/// A tiny, dependency-free arithmetic engine for the amount calculator.
///
/// Supports the four operators the calculator exposes (`+`, `-`, `×`, `÷`),
/// decimals, unary minus and operator precedence (`× ÷` bind tighter than
/// `+ -`). It is deliberately *not* a general expression parser: no
/// parentheses, no functions, no variables — just enough to total up a bill.
///
/// ```dart
/// ExpressionCalculator.evaluate('120+35.50*2') // 191.0
/// ExpressionCalculator.evaluate('100/0')       // null (division by zero)
/// ```
class ExpressionCalculator {
  const ExpressionCalculator._();

  /// Operators the keypad can produce, in display order.
  static const List<String> operators = <String>['+', '-', '×', '÷'];

  /// True when [value] is one of [operators].
  static bool isOperator(String value) => operators.contains(value);

  /// Evaluates [expression] or returns `null` when it is incomplete or invalid.
  ///
  /// A trailing operator is tolerated (`12+` evaluates to `12`) because that is
  /// how a calculator feels while it is being typed into.
  static double? evaluate(String expression) {
    final String normalized = _normalize(expression);
    if (normalized.isEmpty) return null;

    final List<String> tokens = _tokenize(normalized);
    if (tokens.isEmpty) return null;

    // Pass 1 — × and ÷ (left to right).
    final List<String> reduced = <String>[];
    int index = 0;
    while (index < tokens.length) {
      final String token = tokens[index];
      if (token == '×' || token == '÷') {
        final double? left = reduced.isEmpty ? null : _toNumber(reduced.last);
        final double? right =
            index + 1 < tokens.length ? _toNumber(tokens[index + 1]) : null;
        if (left == null) return null;
        // `5×` means "5 for now" so the running total keeps updating.
        if (right == null) {
          reduced.removeLast();
          reduced.add(_format(left));
          index += 1;
          continue;
        }
        final double computed = token == '×' ? left * right : left / right;
        if (!computed.isFinite) return null;
        reduced.removeLast();
        reduced.add(_format(computed));
        index += 2;
        continue;
      }
      reduced.add(token);
      index += 1;
    }

    // Pass 2 — + and - (left to right).
    double? total;
    String pendingOperator = '+';
    for (final String token in reduced) {
      if (isOperator(token)) {
        pendingOperator = token;
        continue;
      }
      final double? value = _toNumber(token);
      if (value == null) return null;
      switch (pendingOperator) {
        case '-':
          total = (total ?? 0) - value;
        case '×':
          total = (total ?? 0) * value;
        case '÷':
          if (value == 0) return null;
          total = (total ?? 0) / value;
        case '+':
        default:
          total = (total ?? 0) + value;
      }
    }

    if (total == null || !total.isFinite) return null;
    // Money is rounded to paise to avoid 0.30000000000000004 style artefacts.
    return double.parse(total.toStringAsFixed(2));
  }

  /// Splits a raw expression into numbers and operators, merging unary minus
  /// into the number it belongs to.
  static List<String> _tokenize(String input) {
    final List<String> tokens = <String>[];
    final StringBuffer buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) return;
      tokens.add(buffer.toString());
      buffer.clear();
    }

    for (int i = 0; i < input.length; i++) {
      final String char = input[i];
      if (isOperator(char)) {
        // A leading `-` or a `-` straight after another operator is a sign.
        final bool unary = char == '-' &&
            (buffer.isEmpty) &&
            (tokens.isEmpty || isOperator(tokens.last));
        if (unary) {
          buffer.write(char);
          continue;
        }
        flush();
        tokens.add(char);
        continue;
      }
      buffer.write(char);
    }
    flush();
    return tokens;
  }

  static String _normalize(String input) {
    return input
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('x', '×')
        .replaceAll('X', '×')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
  }

  static double? _toNumber(String raw) {
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  /// Formats a computed value back into an expression token.
  static String _format(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.round().toString();
    }
    return value.toStringAsFixed(4);
  }

  /// True when the trailing character is an operator (so the UI can keep the
  /// "equals" preview hidden instead of showing a half-finished sum).
  static bool endsWithOperator(String expression) {
    final String trimmed = expression.trim();
    if (trimmed.isEmpty) return false;
    return isOperator(trimmed[trimmed.length - 1]);
  }

  /// Splits an expression into a readable preview: `120 + 35 × 2`.
  ///
  /// Normalisation runs first, so `*` and `/` typed on a hardware keyboard are
  /// displayed with the same `×` / `÷` glyphs the keypad produces.
  static String prettify(String expression) {
    final StringBuffer out = StringBuffer();
    final String input = _normalize(expression);
    for (int i = 0; i < input.length; i++) {
      final String char = input[i];
      if (isOperator(char) && i > 0) {
        out.write(' $char ');
      } else {
        out.write(char);
      }
    }
    return out.toString();
  }
}

/// The button layout of the calculator keypad, shared by the widget and tests.
enum CalculatorKey {
  seven('7'),
  eight('8'),
  nine('9'),
  divide('÷'),
  four('4'),
  five('5'),
  six('6'),
  multiply('×'),
  one('1'),
  two('2'),
  three('3'),
  subtract('-'),
  zero('0'),
  decimal('.'),
  equals('='),
  add('+'),
  clear('AC'),
  backspace('⌫'),
  doubleZero('00');

  const CalculatorKey(this.label);

  final String label;

  bool get isDigit =>
      this == seven ||
      this == eight ||
      this == nine ||
      this == four ||
      this == five ||
      this == six ||
      this == one ||
      this == two ||
      this == three ||
      this == zero ||
      this == doubleZero;

  bool get isOperator => ExpressionCalculator.isOperator(label);
}
