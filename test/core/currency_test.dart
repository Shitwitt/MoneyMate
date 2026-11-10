import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/currency.dart';

void main() {
  group('currency lookup', () {
    test('finds known currencies case-insensitively', () {
      expect(currencyByCode('INR')?.symbol, '₹');
      expect(currencyByCode('inr')?.symbol, '₹');
      expect(currencyByCode('USD')?.decimalDigits, 2);
    });

    test('returns null for unknown codes', () {
      expect(currencyByCode('XXX'), isNull);
    });

    test('falls back to code and 2 digits for unknown codes', () {
      expect(symbolFor('XXX'), 'XXX');
      expect(decimalDigitsFor('XXX'), 2);
    });

    test('default currency is INR', () {
      expect(kDefaultCurrencyCode, 'INR');
      expect(currencyByCode(kDefaultCurrencyCode), isNotNull);
    });

    test('zero-decimal currencies have no minor unit', () {
      expect(decimalDigitsFor('JPY'), 0);
      expect(decimalDigitsFor('KRW'), 0);
      expect(decimalDigitsFor('VND'), 0);
    });

    test('three-decimal currencies use fils', () {
      expect(decimalDigitsFor('KWD'), 3);
      expect(decimalDigitsFor('BHD'), 3);
      expect(decimalDigitsFor('OMR'), 3);
    });
  });
}
