import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

import '../models/models.dart';

const currencySymbols = <String, String>{
  'INR': '₹',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'AUD': 'A\$',
  'CAD': 'C\$',
  'CHF': 'Fr',
  'CNY': '¥',
  'SGD': 'S\$',
  'AED': 'د.إ',
  'SAR': '﷼',
  'BDT': '৳',
  'PKR': '₨',
  'NPR': 'रू',
  'LKR': 'Rs',
  'KRW': '₩',
  'KWD': 'د.ك',
  'BHD': '.د.ب',
  'OMR': 'ر.ع.',
};
int decimalsFor(String code) => switch (code) {
  'JPY' || 'KRW' => 0,
  'KWD' || 'BHD' || 'OMR' => 3,
  _ => 2,
};
int toMinor(num amount, String code) {
  if (!amount.isFinite || amount.abs() > 1000000000000) {
    throw const FormatException('Amount is out of range');
  }
  return (amount * math.pow(10, decimalsFor(code))).round();
}

double fromMinor(int amount, String code) =>
    amount / math.pow(10, decimalsFor(code));
String money(
  int minor,
  String currency, {
  bool hidden = false,
  bool indian = false,
  bool compact = false,
  String locale = 'en',
}) {
  if (hidden) return '••••';
  final value = fromMinor(minor, currency);
  final symbol = currencySymbols[currency] ?? '$currency ';
  if (compact && value.abs() >= 100000) {
    if (indian) {
      final crore = value.abs() >= 10000000;
      return '$symbol${(value / (crore ? 10000000 : 100000)).toStringAsFixed(1)}${crore ? 'Cr' : 'L'}';
    }
    return '$symbol${NumberFormat.compact(locale: locale).format(value)}';
  }
  return NumberFormat.currency(
    locale: indian ? 'en_IN' : locale,
    symbol: symbol,
    decimalDigits: decimalsFor(currency),
  ).format(value);
}

/// Rates are explicit user-maintained reference values, expressed as units per USD.
/// Transfers lock in their receiving amount; future rate edits never rewrite a ledger.
int convertMinor(int amount, String from, String to, List<ExchangeRate> rates) {
  if (from == to) return amount;
  double rate(String code) {
    if (code == 'USD') return 1;
    final matches = rates.where((rate) => rate.code == code);
    if (matches.isEmpty ||
        matches.first.perUsd <= 0 ||
        !matches.first.perUsd.isFinite) {
      throw FormatException('Set an exchange rate for $code first');
    }
    return matches.first.perUsd;
  }

  return toMinor(fromMinor(amount, from) / rate(from) * rate(to), to);
}

/// A deliberately small grammar: no variables, functions, or executable input.
/// This evaluates arithmetic only; it is not Dart eval or a JavaScript bridge.
num evaluateAmount(String expression) {
  final text = expression
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll(',', '')
      .trim();
  if (text.isEmpty ||
      text.length > 120 ||
      !RegExp(r'^[0-9.\s+\-*/()%]+$').hasMatch(text)) {
    throw const FormatException(
      'Enter an amount or an expression such as 120 + 45 / 2',
    );
  }
  // Percent is an explicit /100 suffix, so 200*10% evaluates to 20.
  final normalized = text.replaceAllMapped(
    RegExp(r'(\d+(?:\.\d+)?)%'),
    (m) => '(${m[1]}/100)',
  );
  final result =
      Parser().parse(normalized).evaluate(EvaluationType.REAL, ContextModel())
          as num;
  if (!result.isFinite || result <= 0 || result > 1000000000000) {
    throw const FormatException('Amount must be positive and finite');
  }
  return result;
}

String titleCase(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
