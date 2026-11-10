import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/money.dart';

void main() {
  group('Money.parse', () {
    test('parses whole amounts', () {
      expect(Money.parse('50', 'INR'), Money.fromMinor(5000, 'INR'));
      expect(Money.parse('0', 'INR'), Money.fromMinor(0, 'INR'));
    });

    test('parses fractional amounts', () {
      expect(Money.parse('50.25', 'INR'), Money.fromMinor(5025, 'INR'));
      expect(Money.parse('0.01', 'INR'), Money.fromMinor(1, 'INR'));
      expect(Money.parse('12.3', 'INR'), Money.fromMinor(1230, 'INR'));
    });

    test('strips symbols, spaces and thousands separators', () {
      expect(Money.parse('₹1,234.56', 'INR'), Money.fromMinor(123456, 'INR'));
      expect(Money.parse('  \$50.00  ', 'USD'), Money.fromMinor(5000, 'USD'));
      expect(Money.parse('1,000,000', 'USD'), Money.fromMinor(100000000, 'USD'));
    });

    test('parses negatives', () {
      expect(Money.parse('-50.00', 'INR'), Money.fromMinor(-5000, 'INR'));
      expect(Money.parse('(50.00)', 'INR'), Money.fromMinor(-5000, 'INR'));
      expect(Money.parse('50-', 'INR'), Money.fromMinor(-5000, 'INR'));
    });

    test('respects zero-decimal currencies', () {
      expect(Money.parse('1200', 'JPY'), Money.fromMinor(1200, 'JPY'));
      expect(() => Money.parse('12.5', 'JPY'), throwsFormatException);
    });

    test('respects three-decimal currencies', () {
      expect(Money.parse('1.234', 'KWD'), Money.fromMinor(1234, 'KWD'));
      expect(() => Money.parse('1.2345', 'KWD'), throwsFormatException);
    });

    test('rejects excess precision instead of rounding', () {
      expect(() => Money.parse('10.999', 'INR'), throwsFormatException);
    });

    test('rejects empty and invalid input', () {
      expect(() => Money.parse('', 'INR'), throwsFormatException);
      expect(() => Money.parse('   ', 'INR'), throwsFormatException);
      expect(() => Money.parse('..', 'INR'), throwsFormatException);
      expect(() => Money.parse('1.2.3', 'INR'), throwsFormatException);
    });
  });

  group('Money arithmetic', () {
    test('adds and subtracts in minor units', () {
      final Money a = Money.fromMinor(1000, 'INR');
      final Money b = Money.fromMinor(250, 'INR');
      expect(a + b, Money.fromMinor(1250, 'INR'));
      expect(a - b, Money.fromMinor(750, 'INR'));
    });

    test('scales by an integer factor exactly', () {
      expect(
        Money.fromMinor(333, 'INR') * 3,
        Money.fromMinor(999, 'INR'),
      );
    });

    test('rejects mixed currencies', () {
      final Money inr = Money.fromMinor(100, 'INR');
      final Money usd = Money.fromMinor(100, 'USD');
      expect(() => inr + usd, throwsArgumentError);
      expect(() => inr.compareTo(usd), throwsArgumentError);
    });

    test('compares and checks sign', () {
      expect(Money.fromMinor(100, 'INR').compareTo(Money.fromMinor(50, 'INR')), 1);
      expect(Money.zero('INR').isZero, isTrue);
      expect(Money.fromMinor(1, 'INR').isPositive, isTrue);
      expect(Money.fromMinor(-1, 'INR').isNegative, isTrue);
      expect(Money.fromMinor(-5, 'INR').abs(), Money.fromMinor(5, 'INR'));
      expect(-Money.fromMinor(5, 'INR'), Money.fromMinor(-5, 'INR'));
    });

    test('equality and hash code', () {
      expect(Money.fromMinor(100, 'INR'), Money.fromMinor(100, 'INR'));
      expect(
        Money.fromMinor(100, 'INR').hashCode,
        Money.fromMinor(100, 'INR').hashCode,
      );
      expect(Money.fromMinor(100, 'INR') == Money.fromMinor(100, 'USD'), isFalse);
    });
  });

  group('Money.format', () {
    test('formats with symbol and two decimals', () {
      expect(Money.fromMinor(123456, 'INR').format(), '₹1,234.56');
      expect(Money.fromMinor(5000, 'USD').format(), r'$50.00');
    });

    test('formats negatives with a leading minus', () {
      expect(Money.fromMinor(-5000, 'INR').format(), '-₹50.00');
    });

    test('formats zero-decimal currencies without fraction', () {
      expect(Money.fromMinor(1200, 'JPY').format(), '¥1,200');
    });

    test('formats three-decimal currencies', () {
      expect(Money.fromMinor(1234, 'KWD').format(), 'KD1.234');
    });

    test('formats zero', () {
      expect(Money.zero('INR').format(), '₹0.00');
    });
  });
}
