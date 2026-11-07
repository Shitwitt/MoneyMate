import 'package:flutter/foundation.dart';

/// How a currency groups its thousands.
enum NumberGrouping {
  /// 1,25,450 — 3 digits, then pairs (lakh / crore).
  indian,

  /// 125,450 — 3 digits, then triplets (thousand / million / billion).
  western,
}

/// A supported currency.
///
/// [locale] is the ICU locale handed to `intl`, so the _symbol_, _grouping_ and
/// _decimal separator_ all follow that market's conventions.
@immutable
class CurrencyDefinition {
  const CurrencyDefinition({
    required this.code,
    required this.symbol,
    required this.name,
    required this.locale,
    this.decimalDigits = 2,
    this.grouping = NumberGrouping.western,
  });

  /// ISO-4217 code, e.g. `INR`.
  final String code;

  /// Display symbol, e.g. `₹`.
  final String symbol;

  /// English name shown in the picker, e.g. `Indian Rupee`.
  final String name;

  /// ICU locale used for formatting, e.g. `en_IN`.
  final String locale;

  /// Digits after the decimal separator. JPY/Yen use 0.
  final int decimalDigits;

  /// Grouping style — [NumberGrouping.indian] only for INR.
  final NumberGrouping grouping;

  bool get isIndian => grouping == NumberGrouping.indian;

  /// `Indian Rupee (₹ - INR)` — the exact row label used by the picker.
  String get pickerLabel => '$name ($symbol - $code)';

  /// `₹ INR` — the compact badge used in settings.
  String get badge => '$symbol $code';

  /// `₹1,25,450.00` style sample, used to preview a currency in the picker.
  String get sampleAmount =>
      isIndian ? '${symbol}1,25,450' : '${symbol}125,450';

  @override
  bool operator ==(Object other) => other is CurrencyDefinition && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CurrencyDefinition($code)';
}

/// The currency catalogue.
///
/// `INR` is pinned first because Paisa is an Indian-first app; the rest follow
/// in a stable, predictable order (by English name) so the searchable picker
/// never reshuffles between launches.
class CurrencyTable {
  const CurrencyTable._();

  static const CurrencyDefinition inr = CurrencyDefinition(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    locale: 'en_IN',
    grouping: NumberGrouping.indian,
  );

  static const CurrencyDefinition usd = CurrencyDefinition(
    code: 'USD',
    symbol: r'$',
    name: 'US Dollar',
    locale: 'en_US',
  );

  static const CurrencyDefinition eur = CurrencyDefinition(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    locale: 'de_DE',
  );

  static const CurrencyDefinition gbp = CurrencyDefinition(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    locale: 'en_GB',
  );

  static const CurrencyDefinition jpy = CurrencyDefinition(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    locale: 'ja_JP',
    decimalDigits: 0,
  );

  static const CurrencyDefinition aud = CurrencyDefinition(
    code: 'AUD',
    symbol: r'A$',
    name: 'Australian Dollar',
    locale: 'en_AU',
  );

  static const CurrencyDefinition cad = CurrencyDefinition(
    code: 'CAD',
    symbol: r'C$',
    name: 'Canadian Dollar',
    locale: 'en_CA',
  );

  static const CurrencyDefinition aed = CurrencyDefinition(
    code: 'AED',
    symbol: 'AED',
    name: 'UAE Dirham',
    locale: 'en_AE',
  );

  /// The eight currencies the spec calls out, in that order.
  static const List<CurrencyDefinition> primary = <CurrencyDefinition>[
    inr,
    usd,
    eur,
    gbp,
    jpy,
    aud,
    cad,
    aed,
  ];

  /// Every currency the picker offers. INR is always the first element so the
  /// "pinned at the top" row is guaranteed without extra UI logic.
  static const List<CurrencyDefinition> all = <CurrencyDefinition>[
    inr,
    usd,
    eur,
    gbp,
    jpy,
    aud,
    cad,
    aed,
    CurrencyDefinition(
      code: 'AFN',
      symbol: '؋',
      name: 'Afghan Afghani',
      locale: 'en_US',
    ),
    CurrencyDefinition(
      code: 'ARS',
      symbol: r'AR$',
      name: 'Argentine Peso',
      locale: 'es_AR',
    ),
    CurrencyDefinition(
      code: 'BDT',
      symbol: '৳',
      name: 'Bangladeshi Taka',
      locale: 'bn_BD',
    ),
    CurrencyDefinition(
      code: 'BHD',
      symbol: 'BHD',
      name: 'Bahraini Dinar',
      locale: 'en_US',
      decimalDigits: 3,
    ),
    CurrencyDefinition(
      code: 'BRL',
      symbol: r'R$',
      name: 'Brazilian Real',
      locale: 'pt_BR',
    ),
    CurrencyDefinition(
      code: 'CHF',
      symbol: 'CHF',
      name: 'Swiss Franc',
      locale: 'de_CH',
    ),
    CurrencyDefinition(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan',
      locale: 'zh_CN',
    ),
    CurrencyDefinition(
      code: 'CZK',
      symbol: 'Kč',
      name: 'Czech Koruna',
      locale: 'cs_CZ',
    ),
    CurrencyDefinition(
      code: 'DKK',
      symbol: 'kr',
      name: 'Danish Krone',
      locale: 'da_DK',
    ),
    CurrencyDefinition(
      code: 'EGP',
      symbol: 'E£',
      name: 'Egyptian Pound',
      locale: 'ar_EG',
    ),
    CurrencyDefinition(
      code: 'HKD',
      symbol: r'HK$',
      name: 'Hong Kong Dollar',
      locale: 'en_HK',
    ),
    CurrencyDefinition(
      code: 'HUF',
      symbol: 'Ft',
      name: 'Hungarian Forint',
      locale: 'hu_HU',
      decimalDigits: 0,
    ),
    CurrencyDefinition(
      code: 'IDR',
      symbol: 'Rp',
      name: 'Indonesian Rupiah',
      locale: 'id_ID',
      decimalDigits: 0,
    ),
    CurrencyDefinition(
      code: 'ILS',
      symbol: '₪',
      name: 'Israeli Shekel',
      locale: 'he_IL',
    ),
    CurrencyDefinition(
      code: 'KRW',
      symbol: '₩',
      name: 'South Korean Won',
      locale: 'ko_KR',
      decimalDigits: 0,
    ),
    CurrencyDefinition(
      code: 'KWD',
      symbol: 'KWD',
      name: 'Kuwaiti Dinar',
      locale: 'en_US',
      decimalDigits: 3,
    ),
    CurrencyDefinition(
      code: 'LKR',
      symbol: 'Rs',
      name: 'Sri Lankan Rupee',
      locale: 'en_LK',
    ),
    CurrencyDefinition(
      code: 'MXN',
      symbol: r'MX$',
      name: 'Mexican Peso',
      locale: 'es_MX',
    ),
    CurrencyDefinition(
      code: 'MYR',
      symbol: 'RM',
      name: 'Malaysian Ringgit',
      locale: 'ms_MY',
    ),
    CurrencyDefinition(
      code: 'NOK',
      symbol: 'kr',
      name: 'Norwegian Krone',
      locale: 'nb_NO',
    ),
    CurrencyDefinition(
      code: 'NPR',
      symbol: 'रू',
      name: 'Nepalese Rupee',
      locale: 'ne_NP',
    ),
    CurrencyDefinition(
      code: 'NZD',
      symbol: r'NZ$',
      name: 'New Zealand Dollar',
      locale: 'en_NZ',
    ),
    CurrencyDefinition(
      code: 'OMR',
      symbol: 'OMR',
      name: 'Omani Rial',
      locale: 'en_US',
      decimalDigits: 3,
    ),
    CurrencyDefinition(
      code: 'PHP',
      symbol: '₱',
      name: 'Philippine Peso',
      locale: 'en_PH',
    ),
    CurrencyDefinition(
      code: 'PKR',
      symbol: 'Rs',
      name: 'Pakistani Rupee',
      locale: 'en_PK',
    ),
    CurrencyDefinition(
      code: 'PLN',
      symbol: 'zł',
      name: 'Polish Zloty',
      locale: 'pl_PL',
    ),
    CurrencyDefinition(
      code: 'QAR',
      symbol: 'QAR',
      name: 'Qatari Riyal',
      locale: 'en_US',
    ),
    CurrencyDefinition(
      code: 'RON',
      symbol: 'lei',
      name: 'Romanian Leu',
      locale: 'ro_RO',
    ),
    CurrencyDefinition(
      code: 'RUB',
      symbol: '₽',
      name: 'Russian Ruble',
      locale: 'ru_RU',
    ),
    CurrencyDefinition(
      code: 'SAR',
      symbol: 'SAR',
      name: 'Saudi Riyal',
      locale: 'en_US',
    ),
    CurrencyDefinition(
      code: 'SEK',
      symbol: 'kr',
      name: 'Swedish Krona',
      locale: 'sv_SE',
    ),
    CurrencyDefinition(
      code: 'SGD',
      symbol: r'S$',
      name: 'Singapore Dollar',
      locale: 'en_SG',
    ),
    CurrencyDefinition(
      code: 'THB',
      symbol: '฿',
      name: 'Thai Baht',
      locale: 'th_TH',
    ),
    CurrencyDefinition(
      code: 'TRY',
      symbol: '₺',
      name: 'Turkish Lira',
      locale: 'tr_TR',
    ),
    CurrencyDefinition(
      code: 'TWD',
      symbol: r'NT$',
      name: 'New Taiwan Dollar',
      locale: 'zh_TW',
    ),
    CurrencyDefinition(
      code: 'VND',
      symbol: '₫',
      name: 'Vietnamese Dong',
      locale: 'vi_VN',
      decimalDigits: 0,
    ),
    CurrencyDefinition(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
      locale: 'en_ZA',
    ),
  ];

  static final Map<String, CurrencyDefinition> _byCode =
      <String, CurrencyDefinition>{
    for (final CurrencyDefinition currency in all) currency.code: currency,
  };

  /// Resolves a stored code, falling back to INR.
  static CurrencyDefinition byCode(String? code) {
    if (code == null) return inr;
    return _byCode[code.toUpperCase()] ?? inr;
  }

  /// Case-insensitive search over code, name and symbol.
  ///
  /// The result keeps INR pinned first, then the spec's eight primary
  /// currencies, then everything else alphabetically.
  static List<CurrencyDefinition> search(String query) {
    final String needle = query.trim().toLowerCase();
    final List<CurrencyDefinition> matches = needle.isEmpty
        ? List<CurrencyDefinition>.of(all)
        : all
            .where((CurrencyDefinition currency) =>
                currency.code.toLowerCase().contains(needle) ||
                currency.name.toLowerCase().contains(needle) ||
                currency.symbol.toLowerCase().contains(needle))
            .toList(growable: true);

    matches.sort((CurrencyDefinition a, CurrencyDefinition b) {
      if (a.code == inr.code) return -1;
      if (b.code == inr.code) return 1;
      final int aRank = primary.indexOf(a);
      final int bRank = primary.indexOf(b);
      if (aRank != -1 && bRank != -1) return aRank.compareTo(bRank);
      if (aRank != -1) return -1;
      if (bRank != -1) return 1;
      return a.name.compareTo(b.name);
    });
    return matches;
  }
}
