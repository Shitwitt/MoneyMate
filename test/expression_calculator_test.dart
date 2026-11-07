import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/core/utils/expression_calculator.dart';

void main() {
  group('ExpressionCalculator.evaluate', () {
    test('returns null for an empty or whitespace expression', () {
      expect(ExpressionCalculator.evaluate(''), isNull);
      expect(ExpressionCalculator.evaluate('   '), isNull);
    });

    test('evaluates simple arithmetic', () {
      expect(ExpressionCalculator.evaluate('12+8'), 20);
      expect(ExpressionCalculator.evaluate('100-45'), 55);
    });

    test('multiplication and division bind tighter than +/-', () {
      expect(ExpressionCalculator.evaluate('2+3*4'), 14);
      expect(ExpressionCalculator.evaluate('10-6/3'), 8);
      expect(ExpressionCalculator.evaluate('2+3*4-6/2'), 11);
    });

    test('supports the unicode operators the keypad writes', () {
      expect(ExpressionCalculator.evaluate('6×7'), 42);
      expect(ExpressionCalculator.evaluate('84÷2'), 42);
    });

    test('tolerates a trailing operator while the user is typing', () {
      expect(ExpressionCalculator.evaluate('12+'), 12);
      expect(ExpressionCalculator.evaluate('12+3*'), 24);
    });

    test('returns null for division by zero', () {
      expect(ExpressionCalculator.evaluate('5/0'), isNull);
      expect(ExpressionCalculator.evaluate('5÷0'), isNull);
    });

    test('rounds money to two decimals', () {
      expect(ExpressionCalculator.evaluate('10/3'), closeTo(3.33, 0.0001));
      expect(ExpressionCalculator.evaluate('0.1+0.2'), closeTo(0.3, 0.0001));
    });

    test('rejects malformed input instead of throwing', () {
      expect(ExpressionCalculator.evaluate('abc'), isNull);
      expect(ExpressionCalculator.evaluate('1..2+3'), isNull);
      expect(ExpressionCalculator.evaluate('+'), isNull);
    });

    test('handles leading decimals and grouped numbers', () {
      expect(ExpressionCalculator.evaluate('.5+.5'), 1);
      expect(ExpressionCalculator.evaluate('1,000+500'), 1500);
    });
  });

  group('ExpressionCalculator.prettify', () {
    test('spaces the operators for the amount field', () {
      expect(ExpressionCalculator.prettify('120+35*2'), '120 + 35 × 2');
      expect(ExpressionCalculator.prettify('84÷2'), '84 ÷ 2');
      expect(ExpressionCalculator.prettify(''), '');
    });
  });
}
