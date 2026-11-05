import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/financial_pulse.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/models/models.dart';
import 'support.dart';

void main() {
  test(
    'Record coverage uses 28 calendar days across the spring DST boundary',
    () {
      final data = fixture();
      final entries = [
        expense(data, id: 'outside', date: DateTime(2026, 2, 28, 12)),
        expense(data, id: 'first-day', date: DateTime(2026, 3, 1, 12)),
        expense(data, id: 'after-clock-change', date: DateTime(2026, 3, 9, 12)),
      ];
      final pulse = FinancialPulse.fromLedger(
        Ledger(data.copyWith(transactions: entries), const AppSettings()),
        DateTime(2026, 3, 28, 18),
      );
      expect(
        pulse.metrics.firstWhere((m) => m.label == 'Record coverage').value,
        closeTo(2 / 28 * 100, .000001),
      );
    },
  );
}
