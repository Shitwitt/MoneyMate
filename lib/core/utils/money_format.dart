import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';

/// Money formatting for the Indian number system (lakh / crore grouping).
///
/// `en_IN` gives `₹1,23,456.00` instead of the western `₹123,456.00`, which is
/// what Paisa shows everywhere.
class MoneyFormat {
  const MoneyFormat._();

  static final Map<String, NumberFormat> _cache = <String, NumberFormat>{};

  static NumberFormat _currency({
    required String locale,
    required String symbol,
    required int decimals,
  }) {
    final String key = '$locale|$symbol|$decimals';
    return _cache.putIfAbsent(
      key,
      () => NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: decimals,
      ),
    );
  }

  /// `₹1,23,456` — the default amount format (no decimals).
  static String amount(
    double value, {
    String symbol = '₹',
    String locale = 'en_IN',
    int decimals = 0,
    bool showSign = false,
    bool hide = false,
  }) {
    if (hide) return '••••••';
    final String formatted = _currency(
      locale: locale,
      symbol: symbol,
      decimals: decimals,
    ).format(value.abs());
    if (!showSign) return value < 0 ? '-$formatted' : formatted;
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }

  /// `₹1.2L` style compact amount for chart axes and tight tiles.
  static String compact(
    double value, {
    String symbol = '₹',
    String locale = 'en_IN',
    bool hide = false,
  }) {
    if (hide) return '••••';
    final NumberFormat formatter = _cache.putIfAbsent(
      'compact|$locale',
      () => NumberFormat.compactCurrency(
        locale: locale,
        symbol: symbol,
        decimalDigits: 1,
      ),
    );
    final String formatted = formatter.format(value.abs());
    return value < 0 ? '-$formatted' : formatted;
  }

  /// Amount with the sign of a [TransactionType] prefix: expenses get `-`,
  /// income gets `+`, transfers get nothing.
  static String forTransaction(
    TransactionModel transaction, {
    String symbol = '₹',
    String locale = 'en_IN',
    bool hide = false,
  }) {
    final String base = amount(
      transaction.amount,
      symbol: symbol,
      locale: locale,
      hide: hide,
    );
    if (transaction.type == TransactionType.expense) return '-$base';
    if (transaction.type == TransactionType.income) return '+$base';
    return base;
  }

  /// `₹0.00`-free editing value: `1234.5` → `1234.5`.
  static String forInput(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  /// Parses user input (`1,250.50`, `₹ 1250`, `-30`) into a number, or `null`.
  static double? parse(String raw) {
    final String cleaned = raw
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .replaceAll('\u00A0', '')
        .replaceAll(' ', '')
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Percentage as a whole number, e.g. `62%`.
  static String percent(double fraction) =>
      '${(fraction * 100).clamp(0, 999).round()}%';
}
