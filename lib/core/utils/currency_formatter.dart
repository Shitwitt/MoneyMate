import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Metadata for one presentation currency.
///
/// [inrRate] is the offline reference rate expressed as "INR per one unit of
/// this currency". It mirrors the existing MoneyMate catalog so UI values can
/// be converted without a network request.
@immutable
class CurrencyMeta {
  const CurrencyMeta({
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
    required this.inrRate,
    this.compactIndian = false,
    this.aliases = const <String>[],
  });

  final String code;
  final String name;
  final String symbol;
  final String locale;
  final int decimalDigits;
  final double inrRate;
  final bool compactIndian;
  final List<String> aliases;

  String get displayLabel => '$symbol $code';

  String get searchLabel => '$symbol $code $name ${aliases.join(' ')}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is CurrencyMeta && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CurrencyMeta($code, $symbol, $name)';
}

/// Offline currency formatting and conversion utilities.
///
/// INR always uses `NumberFormat.currency(locale: 'en_IN', symbol: '₹')`,
/// producing Indian grouping such as `₹1,25,450.00`. Compact chart labels use
/// Indian K/L/Cr units for INR and K/M/B for other currencies.
abstract final class CurrencyFormatter {
  static const CurrencyMeta indianRupee = CurrencyMeta(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 2,
    inrRate: 1,
    compactIndian: true,
    aliases: <String>['rupee', 'rupees', 'india', 'indian', 'भारत', 'रुपये'],
  );

  /// The complete searchable catalog. Indian Rupee is intentionally first so
  /// it can be pinned at the top of the onboarding currency picker.
  static const List<CurrencyMeta> currencies = <CurrencyMeta>[
    indianRupee,
    CurrencyMeta(code: 'USD', name: 'US Dollar', symbol: '\$', locale: 'en_US', decimalDigits: 2, inrRate: 83.15, aliases: <String>['dollar', 'america', 'usa']),
    CurrencyMeta(code: 'EUR', name: 'Euro', symbol: '€', locale: 'en_IE', decimalDigits: 2, inrRate: 90.2, aliases: <String>['europe', 'eurozone']),
    CurrencyMeta(code: 'GBP', name: 'British Pound', symbol: '£', locale: 'en_GB', decimalDigits: 2, inrRate: 105.4, aliases: <String>['pound', 'sterling', 'uk']),
    CurrencyMeta(code: 'JPY', name: 'Japanese Yen', symbol: '¥', locale: 'ja_JP', decimalDigits: 0, inrRate: 0.56, aliases: <String>['yen', 'japan']),
    CurrencyMeta(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', locale: 'en_AU', decimalDigits: 2, inrRate: 54.6, aliases: <String>['australia', 'aussie']),
    CurrencyMeta(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', locale: 'en_CA', decimalDigits: 2, inrRate: 60.5, aliases: <String>['canada', 'canadian']),
    CurrencyMeta(code: 'AED', name: 'UAE Dirham', symbol: 'AED', locale: 'en_AE', decimalDigits: 2, inrRate: 22.64, aliases: <String>['dirham', 'uae', 'emirates', 'د.إ']),
    CurrencyMeta(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', locale: 'de_CH', decimalDigits: 2, inrRate: 94.6, aliases: <String>['franc', 'switzerland']),
    CurrencyMeta(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', locale: 'zh_CN', decimalDigits: 2, inrRate: 11.5, aliases: <String>['yuan', 'renminbi', 'china']),
    CurrencyMeta(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', locale: 'en_SG', decimalDigits: 2, inrRate: 61.8, aliases: <String>['singapore']),
    CurrencyMeta(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', locale: 'zh_HK', decimalDigits: 2, inrRate: 10.65, aliases: <String>['hong kong']),
    CurrencyMeta(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$', locale: 'en_NZ', decimalDigits: 2, inrRate: 50.4, aliases: <String>['new zealand', 'kiwi']),
    CurrencyMeta(code: 'ZAR', name: 'South African Rand', symbol: 'R', locale: 'en_ZA', decimalDigits: 2, inrRate: 4.55, aliases: <String>['rand', 'south africa']),
    CurrencyMeta(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', locale: 'sv_SE', decimalDigits: 2, inrRate: 7.9, aliases: <String>['krona', 'sweden']),
    CurrencyMeta(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', locale: 'nb_NO', decimalDigits: 2, inrRate: 7.6, aliases: <String>['krone', 'norway']),
    CurrencyMeta(code: 'DKK', name: 'Danish Krone', symbol: 'kr', locale: 'da_DK', decimalDigits: 2, inrRate: 12.1, aliases: <String>['denmark']),
    CurrencyMeta(code: 'PLN', name: 'Polish Zloty', symbol: 'zł', locale: 'pl_PL', decimalDigits: 2, inrRate: 20.8, aliases: <String>['zloty', 'poland']),
    CurrencyMeta(code: 'THB', name: 'Thai Baht', symbol: '฿', locale: 'th_TH', decimalDigits: 2, inrRate: 2.35, aliases: <String>['baht', 'thailand']),
    CurrencyMeta(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', locale: 'ms_MY', decimalDigits: 2, inrRate: 17.8, aliases: <String>['ringgit', 'malaysia']),
    CurrencyMeta(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', locale: 'id_ID', decimalDigits: 0, inrRate: 0.0053, aliases: <String>['rupiah', 'indonesia']),
    CurrencyMeta(code: 'PHP', name: 'Philippine Peso', symbol: '₱', locale: 'en_PH', decimalDigits: 2, inrRate: 1.44, aliases: <String>['peso', 'philippines']),
    CurrencyMeta(code: 'KRW', name: 'South Korean Won', symbol: '₩', locale: 'ko_KR', decimalDigits: 0, inrRate: 0.061, aliases: <String>['won', 'korea']),
    CurrencyMeta(code: 'TRY', name: 'Turkish Lira', symbol: '₺', locale: 'tr_TR', decimalDigits: 2, inrRate: 2.45, aliases: <String>['lira', 'turkey']),
    CurrencyMeta(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', locale: 'pt_BR', decimalDigits: 2, inrRate: 15.2, aliases: <String>['real', 'brazil']),
    CurrencyMeta(code: 'MXN', name: 'Mexican Peso', symbol: 'Mex\$', locale: 'es_MX', decimalDigits: 2, inrRate: 4.65, aliases: <String>['peso', 'mexico']),
    CurrencyMeta(code: 'RUB', name: 'Russian Ruble', symbol: '₽', locale: 'ru_RU', decimalDigits: 2, inrRate: 0.9, aliases: <String>['ruble', 'russia']),
    CurrencyMeta(code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR', locale: 'ar_SA', decimalDigits: 2, inrRate: 22.17, aliases: <String>['riyal', 'saudi']),
    CurrencyMeta(code: 'QAR', name: 'Qatari Riyal', symbol: 'QAR', locale: 'ar_QA', decimalDigits: 2, inrRate: 22.85, aliases: <String>['riyal', 'qatar']),
    CurrencyMeta(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'KWD', locale: 'ar_KW', decimalDigits: 3, inrRate: 270.5, aliases: <String>['dinar', 'kuwait']),
    CurrencyMeta(code: 'BHD', name: 'Bahraini Dinar', symbol: 'BHD', locale: 'ar_BH', decimalDigits: 3, inrRate: 220.6, aliases: <String>['dinar', 'bahrain']),
    CurrencyMeta(code: 'OMR', name: 'Omani Rial', symbol: 'OMR', locale: 'ar_OM', decimalDigits: 3, inrRate: 216.1, aliases: <String>['rial', 'oman']),
    CurrencyMeta(code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs', locale: 'si_LK', decimalDigits: 2, inrRate: 0.28, aliases: <String>['rupee', 'sri lanka']),
    CurrencyMeta(code: 'NPR', name: 'Nepalese Rupee', symbol: 'रू', locale: 'ne_NP', decimalDigits: 2, inrRate: 0.625, aliases: <String>['rupee', 'nepal']),
    CurrencyMeta(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳', locale: 'bn_BD', decimalDigits: 2, inrRate: 0.76, aliases: <String>['taka', 'bangladesh']),
    CurrencyMeta(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', locale: 'ur_PK', decimalDigits: 2, inrRate: 0.30, aliases: <String>['rupee', 'pakistan']),
    CurrencyMeta(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', locale: 'en_NG', decimalDigits: 2, inrRate: 0.055, aliases: <String>['naira', 'nigeria']),
    CurrencyMeta(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', locale: 'sw_KE', decimalDigits: 2, inrRate: 0.64, aliases: <String>['shilling', 'kenya']),
    CurrencyMeta(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£', locale: 'ar_EG', decimalDigits: 2, inrRate: 1.7, aliases: <String>['pound', 'egypt']),
    CurrencyMeta(code: 'ARS', name: 'Argentine Peso', symbol: 'AR\$', locale: 'es_AR', decimalDigits: 2, inrRate: 0.095, aliases: <String>['peso', 'argentina']),
    CurrencyMeta(code: 'CLP', name: 'Chilean Peso', symbol: 'CLP\$', locale: 'es_CL', decimalDigits: 0, inrRate: 0.088, aliases: <String>['peso', 'chile']),
    CurrencyMeta(code: 'COP', name: 'Colombian Peso', symbol: 'COL\$', locale: 'es_CO', decimalDigits: 0, inrRate: 0.021, aliases: <String>['peso', 'colombia']),
    CurrencyMeta(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', locale: 'es_PE', decimalDigits: 2, inrRate: 22.1, aliases: <String>['sol', 'peru']),
    CurrencyMeta(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', locale: 'vi_VN', decimalDigits: 0, inrRate: 0.0033, aliases: <String>['dong', 'vietnam']),
    CurrencyMeta(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč', locale: 'cs_CZ', decimalDigits: 2, inrRate: 3.6, aliases: <String>['koruna', 'czech']),
    CurrencyMeta(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft', locale: 'hu_HU', decimalDigits: 0, inrRate: 0.23, aliases: <String>['forint', 'hungary']),
    CurrencyMeta(code: 'RON', name: 'Romanian Leu', symbol: 'lei', locale: 'ro_RO', decimalDigits: 2, inrRate: 18.1, aliases: <String>['leu', 'romania']),
    CurrencyMeta(code: 'ILS', name: 'Israeli New Shekel', symbol: '₪', locale: 'he_IL', decimalDigits: 2, inrRate: 22.4, aliases: <String>['shekel', 'israel']),
    CurrencyMeta(code: 'TWD', name: 'New Taiwan Dollar', symbol: 'NT\$', locale: 'zh_TW', decimalDigits: 2, inrRate: 2.58, aliases: <String>['taiwan']),
  ];

  static CurrencyMeta meta(String code) {
    final String normalized = code.toUpperCase().trim();
    for (final CurrencyMeta item in currencies) {
      if (item.code == normalized) return item;
    }
    return indianRupee;
  }

  static String symbol(String code) => meta(code).symbol;

  static String locale(String code) => meta(code).locale;

  static int decimalDigits(String code) => meta(code).decimalDigits;

  static double inrRate(String code) => meta(code).inrRate;

  /// Converts an amount in [code] into the INR base unit.
  static double toInr(double amount, String code) {
    return amount * inrRate(code);
  }

  /// Converts an INR base amount into [code].
  static double fromInr(double inrAmount, String code) {
    final double rate = inrRate(code);
    return rate == 0 ? inrAmount : inrAmount / rate;
  }

  static double convert(
    double amount, {
    required String from,
    required String to,
  }) {
    return fromInr(toInr(amount, from), to);
  }

  static NumberFormat _fullFormatter(CurrencyMeta meta) {
    try {
      return NumberFormat.currency(
        locale: meta.locale,
        symbol: meta.symbol,
        decimalDigits: meta.decimalDigits,
      );
    } catch (_) {
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: meta.symbol,
        decimalDigits: meta.decimalDigits,
      );
    }
  }

  /// Full currency amount, e.g. `₹1,25,450.00`, `$1,234.56`, `¥1,234`.
  static String format(
    double amount, {
    String code = 'INR',
    bool showPlusSign = false,
  }) {
    final CurrencyMeta item = meta(code);
    final double safeAmount = amount.isFinite ? amount : 0;
    final String body = _fullFormatter(item).format(safeAmount.abs());
    final String sign = safeAmount < 0
        ? '-'
        : showPlusSign && safeAmount > 0
            ? '+'
            : '';
    return '$sign$body';
  }

  /// Formats an amount stored in INR into the currently selected display code.
  static String formatBaseInr(
    double inrAmount, {
    String code = 'INR',
    bool showPlusSign = false,
  }) {
    return format(
      fromInr(inrAmount, code),
      code: code,
      showPlusSign: showPlusSign,
    );
  }

  static String _trimCompact(double value, int maxFractionDigits) {
    final int clamped = maxFractionDigits.clamp(0, 2).toInt();
    String text = value.toStringAsFixed(clamped);
    if (text.contains('.')) {
      text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return text;
  }

  /// Compact chart-axis amount, e.g. `₹1.2K`, `₹1.5L`, `₹2.1Cr`, `$1.5M`.
  static String compact(
    double amount, {
    String code = 'INR',
    int maxFractionDigits = 1,
    bool showPlusSign = false,
  }) {
    final CurrencyMeta item = meta(code);
    final double safeAmount = amount.isFinite ? amount : 0;
    final double absolute = safeAmount.abs();
    final String body;

    if (item.compactIndian) {
      if (absolute >= 10000000) {
        body = '${_trimCompact(absolute / 10000000, maxFractionDigits)}Cr';
      } else if (absolute >= 100000) {
        body = '${_trimCompact(absolute / 100000, maxFractionDigits)}L';
      } else if (absolute >= 1000) {
        body = '${_trimCompact(absolute / 1000, maxFractionDigits)}K';
      } else {
        body = _trimCompact(absolute, maxFractionDigits);
      }
    } else {
      if (absolute >= 1000000000) {
        body = '${_trimCompact(absolute / 1000000000, maxFractionDigits)}B';
      } else if (absolute >= 1000000) {
        body = '${_trimCompact(absolute / 1000000, maxFractionDigits)}M';
      } else if (absolute >= 1000) {
        body = '${_trimCompact(absolute / 1000, maxFractionDigits)}K';
      } else {
        body = _trimCompact(absolute, maxFractionDigits);
      }
    }

    final String sign = safeAmount < 0
        ? '-'
        : showPlusSign && safeAmount > 0
            ? '+'
            : '';
    return '$sign${item.symbol}$body';
  }

  /// Alias used by chart axis builders.
  static String axis(
    double amount, {
    String code = 'INR',
    int maxFractionDigits = 1,
  }) {
    return compact(amount, code: code, maxFractionDigits: maxFractionDigits);
  }

  /// Short KPI label with one decimal by default.
  static String short(
    double amount, {
    String code = 'INR',
    int maxFractionDigits = 1,
  }) {
    return compact(amount, code: code, maxFractionDigits: maxFractionDigits);
  }

  static String signed(
    double amount, {
    String code = 'INR',
    bool compactValue = false,
  }) {
    return compactValue
        ? compact(amount, code: code, showPlusSign: true)
        : format(amount, code: code, showPlusSign: true);
  }

  static String masked(String code) {
    return '${symbol(code)}••••••';
  }

  static String percent(double ratio, {int decimalDigits = 0}) {
    final double safe = ratio.isFinite ? ratio : 0;
    final int digits = decimalDigits.clamp(0, 2).toInt();
    return '${(safe * 100).toStringAsFixed(digits)}%';
  }

  /// Searchable currency list with Indian Rupee pinned at the top.
  static List<CurrencyMeta> search(
    String query, {
    bool pinIndianRupee = true,
  }) {
    final String needle = query.trim().toLowerCase();
    final List<CurrencyMeta> matches = <CurrencyMeta>[];
    for (final CurrencyMeta item in currencies) {
      if (needle.isEmpty || item.searchLabel.toLowerCase().contains(needle)) {
        matches.add(item);
      }
    }
    if (pinIndianRupee) {
      matches.removeWhere((CurrencyMeta item) => item.code == 'INR');
      matches.insert(0, indianRupee);
    }
    return matches;
  }
}
