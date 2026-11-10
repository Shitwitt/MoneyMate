/// Supported currencies and their minor-unit precision.
///
/// Amounts are always stored as integer minor units (paise/cents). The
/// [decimalDigits] value tells [Money] how many minor units make one major
/// unit: 2 for most currencies (100 paise = 1 rupee), 0 for JPY/KRW/VND
/// (no minor unit), 3 for KWD/BHD/OMR (1000 fils = 1 dinar).
class Currency {
  /// ISO 4217 code, e.g. `INR`.
  final String code;

  /// Display symbol, e.g. `₹` for INR.
  final String symbol;

  /// English display name, e.g. `Indian rupee`.
  final String name;

  /// Number of minor-unit digits after the decimal point.
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
  });
}

/// Default base currency (blueprint section 1: default INR, switchable).
const String kDefaultCurrencyCode = 'INR';

/// Currencies shipped in v1. Extend as needed; unknown codes fall back to
/// 2 decimal digits and the code itself as the symbol.
const List<Currency> kCurrencies = <Currency>[
  Currency(code: 'INR', symbol: '₹', name: 'Indian rupee', decimalDigits: 2),
  Currency(code: 'USD', symbol: r'$', name: 'US dollar', decimalDigits: 2),
  Currency(code: 'EUR', symbol: '€', name: 'Euro', decimalDigits: 2),
  Currency(code: 'GBP', symbol: '£', name: 'Pound sterling', decimalDigits: 2),
  Currency(code: 'JPY', symbol: '¥', name: 'Japanese yen', decimalDigits: 0),
  Currency(code: 'AUD', symbol: 'A\$', name: 'Australian dollar', decimalDigits: 2),
  Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian dollar', decimalDigits: 2),
  Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss franc', decimalDigits: 2),
  Currency(code: 'CNY', symbol: '¥', name: 'Chinese yuan', decimalDigits: 2),
  Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong dollar', decimalDigits: 2),
  Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore dollar', decimalDigits: 2),
  Currency(code: 'AED', symbol: 'د.إ', name: 'UAE dirham', decimalDigits: 2),
  Currency(code: 'SAR', symbol: '﷼', name: 'Saudi riyal', decimalDigits: 2),
  Currency(code: 'KWD', symbol: 'KD', name: 'Kuwaiti dinar', decimalDigits: 3),
  Currency(code: 'BHD', symbol: 'BD', name: 'Bahraini dinar', decimalDigits: 3),
  Currency(code: 'OMR', symbol: '﷼', name: 'Omani rial', decimalDigits: 3),
  Currency(code: 'ZAR', symbol: 'R', name: 'South African rand', decimalDigits: 2),
  Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian real', decimalDigits: 2),
  Currency(code: 'MXN', symbol: r'$', name: 'Mexican peso', decimalDigits: 2),
  Currency(code: 'RUB', symbol: '₽', name: 'Russian ruble', decimalDigits: 2),
  Currency(code: 'KRW', symbol: '₩', name: 'South Korean won', decimalDigits: 0),
  Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian rupiah', decimalDigits: 2),
  Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian ringgit', decimalDigits: 2),
  Currency(code: 'THB', symbol: '฿', name: 'Thai baht', decimalDigits: 2),
  Currency(code: 'PHP', symbol: '₱', name: 'Philippine peso', decimalDigits: 2),
  Currency(code: 'VND', symbol: '₫', name: 'Vietnamese dong', decimalDigits: 0),
  Currency(code: 'TRY', symbol: '₺', name: 'Turkish lira', decimalDigits: 2),
  Currency(code: 'PLN', symbol: 'zł', name: 'Polish zloty', decimalDigits: 2),
  Currency(code: 'SEK', symbol: 'kr', name: 'Swedish krona', decimalDigits: 2),
  Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian krone', decimalDigits: 2),
  Currency(code: 'DKK', symbol: 'kr', name: 'Danish krone', decimalDigits: 2),
  Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand dollar', decimalDigits: 2),
  Currency(code: 'NGN', symbol: '₦', name: 'Nigerian naira', decimalDigits: 2),
  Currency(code: 'KES', symbol: 'KSh', name: 'Kenyan shilling', decimalDigits: 2),
  Currency(code: 'EGP', symbol: 'E£', name: 'Egyptian pound', decimalDigits: 2),
  Currency(code: 'ILS', symbol: '₪', name: 'Israeli shekel', decimalDigits: 2),
];

/// Returns the [Currency] for an ISO [code], or null if unknown.
Currency? currencyByCode(String code) {
  final String normalized = code.trim().toUpperCase();
  for (final Currency currency in kCurrencies) {
    if (currency.code == normalized) {
      return currency;
    }
  }
  return null;
}

/// Returns the display symbol for [code], falling back to the code itself.
String symbolFor(String code) => currencyByCode(code)?.symbol ?? code;

/// Returns the minor-unit digits for [code], defaulting to 2.
int decimalDigitsFor(String code) => currencyByCode(code)?.decimalDigits ?? 2;
