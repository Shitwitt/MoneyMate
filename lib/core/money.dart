import 'currency.dart';

/// An amount of money as integer minor units plus a currency code.
///
/// This is the ONLY way money crosses layers (UI, providers, repositories,
/// DAOs). Amounts are never stored or computed as [double]; parsing never
/// uses `double.parse`. All arithmetic is integer arithmetic on
/// [amountMinor], so values are exact.
class Money implements Comparable<Money> {
  /// Amount in minor units (paise/cents/fils). May be negative for balances.
  final int amountMinor;

  /// ISO 4217 currency code, e.g. `INR`.
  final String currencyCode;

  const Money({required this.amountMinor, required this.currencyCode});

  /// Creates money from minor units directly.
  factory Money.fromMinor(int amountMinor, String currencyCode) {
    return Money(amountMinor: amountMinor, currencyCode: currencyCode);
  }

  /// Zero amount in the given currency.
  factory Money.zero(String currencyCode) {
    return Money(amountMinor: 0, currencyCode: currencyCode);
  }

  /// Parses a user-typed amount (e.g. `1,234.56`, `₹50`, `-12.30`) into
  /// integer minor units for [currencyCode].
  ///
  /// Accepted forms: optional leading/trailing `-`, optional surrounding
  /// parentheses for negatives, optional currency symbols/spaces, comma
  /// thousands separators, and a `.` decimal separator. The fractional part
  /// must not have more digits than the currency supports (e.g. more than
  /// 2 digits for INR); excess precision throws [FormatException] rather
  /// than silently rounding money.
  ///
  /// Throws [FormatException] if the input is empty or invalid.
  factory Money.parse(String input, String currencyCode) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Amount is empty', input);
    }

    bool negative = false;
    String text = trimmed;

    // Parenthesised negatives, e.g. (50.00).
    if (text.startsWith('(') && text.endsWith(')')) {
      negative = true;
      text = text.substring(1, text.length - 1).trim();
    }
    // Trailing minus, e.g. 50-.
    if (text.endsWith('-')) {
      negative = true;
      text = text.substring(0, text.length - 1).trim();
    }
    // Leading minus, e.g. -50.00.
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1).trim();
    }
    // Leading plus is accepted and ignored.
    if (text.startsWith('+')) {
      text = text.substring(1).trim();
    }

    // Strip currency symbols, spaces and thousands separators. Only digits
    // and at most one decimal point may remain.
    final StringBuffer cleaned = StringBuffer();
    int dotCount = 0;
    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      if (ch == '.') {
        dotCount++;
        if (dotCount > 1) {
          throw FormatException('Invalid amount', input);
        }
        cleaned.write(ch);
      } else if (ch == ',' || ch == ' ' || ch == '\u00A0') {
        // Thousands separator / whitespace: skip.
      } else if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        cleaned.write(ch);
      } else {
        // Any other character is treated as a currency symbol and skipped,
        // e.g. ₹, $, €, £, ¥, letters in "Rs 50".
        continue;
      }
    }

    final String digits = cleaned.toString();
    if (digits.isEmpty || digits == '.') {
      throw FormatException('Invalid amount', input);
    }

    final int digitsCount = decimalDigitsFor(currencyCode);
    final int dotIndex = digits.indexOf('.');
    final String intPart = dotIndex == -1 ? digits : digits.substring(0, dotIndex);
    final String fracPart = dotIndex == -1 ? '' : digits.substring(dotIndex + 1);

    if (fracPart.length > digitsCount) {
      throw FormatException(
        'Too many decimal places for $currencyCode',
        input,
      );
    }

    final int major = intPart.isEmpty ? 0 : int.parse(intPart);
    final String paddedFrac = fracPart.padRight(digitsCount, '0');
    final int minor = paddedFrac.isEmpty ? 0 : int.parse(paddedFrac);
    final int scale = _pow10(digitsCount);
    int total = major * scale + minor;
    if (negative) {
      total = -total;
    }
    return Money(amountMinor: total, currencyCode: currencyCode);
  }

  static int _pow10(int exponent) {
    int result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  /// Number of minor-unit digits for this currency.
  int get decimalDigits => decimalDigitsFor(currencyCode);

  bool get isZero => amountMinor == 0;
  bool get isPositive => amountMinor > 0;
  bool get isNegative => amountMinor < 0;

  Money abs() {
    return Money(amountMinor: amountMinor.abs(), currencyCode: currencyCode);
  }

  Money operator -() {
    return Money(amountMinor: -amountMinor, currencyCode: currencyCode);
  }

  Money operator +(Money other) {
    _checkSameCurrency(other);
    return Money(
      amountMinor: amountMinor + other.amountMinor,
      currencyCode: currencyCode,
    );
  }

  Money operator -(Money other) {
    _checkSameCurrency(other);
    return Money(
      amountMinor: amountMinor - other.amountMinor,
      currencyCode: currencyCode,
    );
  }

  /// Scales by an integer factor (exact, no rounding).
  Money operator *(int factor) {
    return Money(amountMinor: amountMinor * factor, currencyCode: currencyCode);
  }

  void _checkSameCurrency(Money other) {
    if (other.currencyCode != currencyCode) {
      throw ArgumentError(
        'Cannot combine $currencyCode with ${other.currencyCode}',
      );
    }
  }

  @override
  int compareTo(Money other) {
    _checkSameCurrency(other);
    return amountMinor.compareTo(other.amountMinor);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Money &&
            other.amountMinor == amountMinor &&
            other.currencyCode == currencyCode;
  }

  @override
  int get hashCode => Object.hash(amountMinor, currencyCode);

  /// Formats as `₹1,234.56` (integer-only formatting, no floating point).
  ///
  /// Negative amounts render as `-₹50.00`. Zero-decimal currencies render
  /// without a fractional part (e.g. `¥1,200`).
  String format() {
    final String symbol = symbolFor(currencyCode);
    final int digits = decimalDigits;
    final int scale = _pow10(digits);
    final int absMinor = amountMinor.abs();
    final int major = absMinor ~/ scale;
    final int minor = absMinor % scale;
    final String groupedMajor = _groupThousands(major.toString());
    final String sign = amountMinor < 0 ? '-' : '';
    if (digits == 0) {
      return '$sign$symbol$groupedMajor';
    }
    final String frac = minor.toString().padLeft(digits, '0');
    return '$sign$symbol$groupedMajor.$frac';
  }

  static String _groupThousands(String digits) {
    if (digits.length <= 3) {
      return digits;
    }
    final StringBuffer buffer = StringBuffer();
    final int lead = digits.length % 3;
    int index = 0;
    if (lead > 0) {
      buffer.write(digits.substring(0, lead));
      index = lead;
    }
    while (index < digits.length) {
      if (buffer.isNotEmpty) {
        buffer.write(',');
      }
      buffer.write(digits.substring(index, index + 3));
      index += 3;
    }
    return buffer.toString();
  }

  @override
  String toString() => 'Money($amountMinor, $currencyCode)';
}
