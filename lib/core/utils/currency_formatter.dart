import 'package:intl/intl.dart';

import '../constants/currencies.dart';

/// Multi-currency money formatting.
///
/// `INR` formats with the Indian numbering system (`en_IN`): `₹1,25,450.00`.
/// Every other currency formats with its own market locale, so `USD` gives
/// `$125,450.00`, `EUR` gives `125.450,00 €`, `JPY` gives `¥125,450` (no
/// decimals), and so on.
///
/// Instances are cheap — they are created once by `PaisaProvider` whenever the
/// user changes currency, and `NumberFormat`s are cached behind the scenes.
class CurrencyFormatter {
  CurrencyFormatter({
    required this.currency,
    bool hideAmounts = false,
  }) : _hideAmounts = hideAmounts;

  /// Builds a formatter from a stored ISO code (unknown codes fall back to INR).
  factory CurrencyFormatter.fromCode(
    String? code, {
    bool hideAmounts = false,
  }) {
    return CurrencyFormatter(
      currency: CurrencyTable.byCode(code),
      hideAmounts: hideAmounts,
    );
  }

  final CurrencyDefinition currency;
  final bool _hideAmounts;

  static final Map<String, NumberFormat> _currencyCache =
      <String, NumberFormat>{};
  static final Map<String, NumberFormat> _decimalCache =
      <String, NumberFormat>{};
  static final Map<String, NumberFormat> _compactCache =
      <String, NumberFormat>{};

  /// Mask shown when "hide amounts" (shoulder-surfing mode) is on.
  static const String maskedAmount = '••••••';

  CurrencyFormatter copyWith({CurrencyDefinition? currency, bool? hideAmounts}) {
    return CurrencyFormatter(
      currency: currency ?? this.currency,
      hideAmounts: hideAmounts ?? _hideAmounts,
    );
  }

  String get symbol => currency.symbol;
  String get code => currency.code;

  NumberFormat get _currencyFormat => _currencyCache.putIfAbsent(
        '${currency.locale}|${currency.symbol}|${currency.decimalDigits}',
        () => NumberFormat.currency(
          locale: currency.locale,
          symbol: currency.symbol,
          decimalDigits: currency.decimalDigits,
        ),
      );

  NumberFormat get _decimalFormat => _decimalCache.putIfAbsent(
        '${currency.locale}|${currency.decimalDigits}',
        () => NumberFormat.decimalPatternDigits(
          locale: currency.locale,
          decimalDigits: currency.decimalDigits,
        ),
      );

  NumberFormat get _compactFormat => _compactCache.putIfAbsent(
        currency.locale,
        () => NumberFormat.compactCurrency(
          locale: currency.locale,
          symbol: currency.symbol,
        ),
      );

  /// `₹1,25,450.00` — the canonical amount, with the market's own grouping.
  ///
  /// Pass `withDecimals: false` for the dense variant (`₹1,25,450`).
  String format(double value, {bool withDecimals = true}) {
    if (_hideAmounts) return maskedAmount;
    if (!value.isFinite) return '—';
    return withDecimals ? _currencyFormat.format(value) : formatWhole(value);
  }

  /// `₹1,25,450` — drops the decimal part for dense lists and hero cards.
  String formatWhole(double value) {
    if (_hideAmounts) return maskedAmount;
    if (!value.isFinite) return '—';
    return '${currency.symbol}${_wholePattern.format(value)}';
  }

  /// Grouped digits with no currency symbol and no decimals: `1,25,450`.
  String formatNumber(double value) {
    if (_hideAmounts) return maskedAmount;
    return _wholePattern.format(value);
  }

  /// Signed amount: `+₹500` for money in, `-₹500` for money out.
  String formatSigned(double value, {bool withDecimals = false}) {
    if (_hideAmounts) return maskedAmount;
    final String body =
        withDecimals ? format(value.abs()) : formatWhole(value.abs());
    if (value > 0) return '+$body';
    if (value < 0) return '-$body';
    return body;
  }

  /// Compact form for chart axes and tight tiles.
  ///
  /// Indian system: `₹850`, `₹1.2K`, `₹12.5K`, `₹1.5L`, `₹1.2Cr`.
  /// Western system: `₹850`, `₹1.2K`, `₹1.2M`, `₹1.2B` (via ICU compaction).
  String compact(double value) {
    if (_hideAmounts) return '••••';
    if (!value.isFinite) return '—';
    final double magnitude = value.abs();
    final String sign = value < 0 ? '-' : '';

    if (currency.isIndian) {
      if (magnitude >= 10000000) {
        return '$sign${currency.symbol}${_trim(magnitude / 10000000)}Cr';
      }
      if (magnitude >= 100000) {
        return '$sign${currency.symbol}${_trim(magnitude / 100000)}L';
      }
      if (magnitude >= 1000) {
        return '$sign${currency.symbol}${_trim(magnitude / 1000)}K';
      }
      return '$sign${currency.symbol}${magnitude.round()}';
    }

    return '${sign.isEmpty ? '' : sign}${_compactFormat.format(magnitude)}';
  }

  /// Compact axis label with zero padding: `₹0` instead of an empty string.
  static String _trim(double value) {
    if (value >= 100) return value.round().toString();
    final String text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  /// Whole-number pattern re-created whenever the locale changes.
  NumberFormat get _wholePattern => _wholeCache.putIfAbsent(
        currency.locale,
        () => NumberFormat.decimalPattern(currency.locale),
      );

  static final Map<String, NumberFormat> _wholeCache =
      <String, NumberFormat>{};

  /// `62%` — budget usage and progress labels.
  ///
  /// Fractions above 1 are *not* clamped here (the budget UI shows `128%` when
  /// a category is over budget); use [percentOf] for clamped display.
  String percent(double fraction, {int decimals = 0}) {
    final double safe = fraction.isFinite ? fraction : 0;
    final double asPercent = safe * 100;
    if (decimals <= 0) return '${asPercent.round()}%';
    return '${asPercent.toStringAsFixed(decimals)}%';
  }

  /// Percentage from a raw `spent / budget` ratio, clamped for display.
  String percentOf(double part, double whole) {
    if (whole <= 0) return '0%';
    return percent((part / whole).clamp(0.0, 1.0));
  }

  /// Parses user input in any of the supported formats.
  ///
  /// Strips the currency symbol, grouping separators and spaces, understands
  /// both `1,25,450.50` and `125.450,50` (European decimal comma), and returns
  /// `null` for anything unparseable.
  double? parse(String raw) {
    String text = raw
        .replaceAll(currency.symbol, '')
        .replaceAll(RegExp(r'[A-Za-z]'), '')
        .replaceAll('\u00A0', '')
        .replaceAll(' ', '')
        .trim();
    if (text.isEmpty) return null;

    final bool hasComma = text.contains(',');
    final bool hasDot = text.contains('.');
    if (hasComma && hasDot) {
      // Whichever separator appears last is the decimal separator.
      if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (hasComma) {
      // A single comma with exactly two trailing digits is a decimal comma.
      final int commaIndex = text.lastIndexOf(',');
      final int trailing = text.length - commaIndex - 1;
      text = trailing == 2 && commaIndex > 0
          ? text.replaceAll(',', '.')
          : text.replaceAll(',', '');
    }

    return double.tryParse(text);
  }

  /// Value pre-filled into an amount text field: `125450.5` → `125450.5`.
  String forInput(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is CurrencyFormatter &&
      other.currency == currency &&
      other._hideAmounts == _hideAmounts;

  @override
  int get hashCode => Object.hash(currency, _hideAmounts);

  @override
  String toString() => 'CurrencyFormatter(${currency.code})';
}
