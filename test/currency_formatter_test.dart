import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/constants/currencies.dart';
import 'package:moneymate/core/utils/currency_formatter.dart';

/// Verifies the multi-currency contract: Indian lakh/crore grouping for INR,
/// western grouping everywhere else, compact chart labels and input parsing.
void main() {
  group('catalogue', () {
    test('INR is pinned first and is the fallback', () {
      expect(CurrencyTable.all.first.code, 'INR');
      expect(CurrencyTable.byCode('INR').symbol, '₹');
      expect(CurrencyTable.byCode('nonsense').code, 'INR');
      expect(CurrencyTable.byCode(null).code, 'INR');
    });

    test('the eight requested currencies exist with the right symbols', () {
      const Map<String, String> expected = <String, String>{
        'INR': '₹',
        'USD': r'$',
        'EUR': '€',
        'GBP': '£',
        'JPY': '¥',
        'AUD': r'A$',
        'CAD': r'C$',
        'AED': 'AED',
      };
      expected.forEach((String code, String symbol) {
        final CurrencyDefinition currency = CurrencyTable.byCode(code);
        expect(currency.code, code);
        expect(currency.symbol, symbol);
      });
      expect(CurrencyTable.primary.length, 8);
    });

    test('search pins INR and matches code, name and symbol', () {
      expect(CurrencyTable.search('').first.code, 'INR');
      expect(CurrencyTable.search('dollar').first.code, 'USD');
      expect(CurrencyTable.search('rupee').any((c) => c.code == 'INR'), isTrue);
      expect(CurrencyTable.search('€').first.code, 'EUR');
      expect(CurrencyTable.search('zzz'), isEmpty);
    });

    test('picker label matches the spec format', () {
      expect(CurrencyTable.inr.pickerLabel, 'Indian Rupee (₹ - INR)');
    });
  });

  group('INR formatting', () {
    final CurrencyFormatter formatter =
        CurrencyFormatter(currency: CurrencyTable.inr);

    test('uses the Indian numbering system', () {
      expect(formatter.format(125450), contains('1,25,450'));
      expect(formatter.format(12545000), contains('1,25,45,000'));
      // Western grouping must never appear.
      expect(formatter.format(125450), isNot(contains('125,450')));
    });

    test('whole-number variant drops decimals', () {
      expect(formatter.formatWhole(125450), isNot(contains('.00')));
      expect(formatter.formatNumber(125450), '1,25,450');
    });

    test('signed variant prefixes correctly', () {
      expect(formatter.formatSigned(500), startsWith('+'));
      expect(formatter.formatSigned(-500), startsWith('-'));
      expect(formatter.formatSigned(0), isNot(startsWith('+')));
    });
  });

  group('other currencies', () {
    test('USD groups in thousands with a dollar sign', () {
      final CurrencyFormatter usd =
          CurrencyFormatter(currency: CurrencyTable.usd);
      expect(usd.format(125450), contains('125,450'));
      expect(usd.format(125450), contains(r'$'));
    });

    test('JPY has no decimal digits', () {
      final CurrencyFormatter jpy =
          CurrencyFormatter(currency: CurrencyTable.jpy);
      expect(jpy.format(125450), isNot(contains('.00')));
    });

    test('EUR uses the German locale it declares', () {
      final CurrencyFormatter eur =
          CurrencyFormatter(currency: CurrencyTable.eur);
      final String formatted = eur.format(125450);
      expect(formatted, contains('€'));
    });
  });

  group('compact labels', () {
    final CurrencyFormatter inr =
        CurrencyFormatter(currency: CurrencyTable.inr);

    test('Indian suffixes: K, L, Cr', () {
      expect(inr.compact(850), '₹850');
      expect(inr.compact(1200), '₹1.2K');
      expect(inr.compact(12500), '₹12.5K');
      expect(inr.compact(150000), '₹1.5L');
      expect(inr.compact(12500000), allOf(startsWith('₹'), contains('Cr')));
    });

    test('negative and zero values stay sane', () {
      expect(inr.compact(-150000), '-₹1.5L');
      expect(inr.compact(0), '₹0');
    });

    test('western compaction is used outside India', () {
      final CurrencyFormatter usd =
          CurrencyFormatter(currency: CurrencyTable.usd);
      expect(usd.compact(1500000), contains('M'));
    });
  });

  group('parsing', () {
    final CurrencyFormatter inr =
        CurrencyFormatter(currency: CurrencyTable.inr);

    test('handles Indian grouping, symbols and spaces', () {
      expect(inr.parse('1,25,450.50'), 125450.50);
      expect(inr.parse('₹ 1,250'), 1250);
      expect(inr.parse('1250'), 1250);
      expect(inr.parse(''), isNull);
      expect(inr.parse('abc'), isNull);
    });

    test('handles European decimal commas', () {
      final CurrencyFormatter eur =
          CurrencyFormatter(currency: CurrencyTable.eur);
      expect(eur.parse('1.250,50'), 1250.50);
      expect(eur.parse('1250,50'), 1250.50);
    });

    test('input round-trip', () {
      expect(inr.forInput(1250), '1250');
      expect(inr.forInput(1250.5), '1250.5');
    });
  });

  group('privacy + percentages', () {
    test('hidden amounts are masked everywhere', () {
      final CurrencyFormatter hidden = CurrencyFormatter(
        currency: CurrencyTable.inr,
        hideAmounts: true,
      );
      expect(hidden.format(125450), CurrencyFormatter.maskedAmount);
      expect(hidden.formatWhole(125450), CurrencyFormatter.maskedAmount);
      expect(hidden.compact(125450), '••••');
    });

    test('percent and percentOf', () {
      final CurrencyFormatter inr =
          CurrencyFormatter(currency: CurrencyTable.inr);
      expect(inr.percent(0.625), '63%');
      expect(inr.percent(1.28), '128%');
      expect(inr.percentOf(6000, 6000), '100%');
      expect(inr.percentOf(100, 0), '0%');
    });
  });
}
