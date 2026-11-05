import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/utils/constants.dart';
import 'package:paisaclone/core/utils/dates.dart';
import 'package:paisaclone/shared/daily_spend_chart.dart';

import 'support.dart';

void main() {
  test(
    'Old default layout migrates once; custom order, visibility and settings survive',
    () {
      final migrated = AppSettings.fromJson({
        'homeCards': [
          'balance',
          'cashflow',
          'accounts',
          'trend',
          'budgets',
          'goals',
          'recent',
          'templates',
          'recurring',
          'assets',
          'loans',
          'reports',
          'achievements',
          'premium',
        ],
        'navTabs': ['home', 'accounts', 'transactions', 'plans', 'more'],
        'hiddenCards': ['balance'],
        'locale': 'fa',
        'theme': 'black',
      });
      expect(migrated.homeCards, defaultHomeCards);
      expect(migrated.navTabs, ['home', 'accounts', 'reports', 'search']);
      expect(migrated.hiddenCards, ['balance']);
      expect(migrated.locale, 'fa');
      expect(migrated.theme, 'black');
      final custom = AppSettings.fromJson({
        'homeCards': ['templates', 'goals', 'accounts'],
        'navTabs': ['home', 'more', 'accounts'],
      });
      expect(custom.homeCards.take(3), ['templates', 'goals', 'accounts']);
      expect(custom.homeCards.toSet().length, custom.homeCards.length);
      expect(custom.navTabs, ['home', 'more', 'accounts']);
      final reordered = migrated.copyWith(
        homeCards: ['templates', 'accounts', 'recent', 'goals'],
      );
      expect(
        AppSettings.fromJson(reordered.toJson()).homeCards,
        reordered.homeCards,
      );
    },
  );
  test(
    'Daily/cumulative chart data uses real expenses, excludes future records and preserves unknown future days',
    () {
      final profile = fixture();
      final account = profile.accounts.first.id;
      final expense = profile.categories
          .firstWhere((c) => c.type == 'expense')
          .id;
      final income = profile.categories
          .firstWhere((c) => c.type == 'income')
          .id;
      final now = DateTime(2026, 11, 4, 12);
      MoneyTransaction entry(
        String id,
        String type,
        int day,
        int amount, {
        int hour = 9,
      }) => MoneyTransaction(
        id: id,
        type: type,
        amountMinor: amount,
        accountId: account,
        categoryId: type == 'expense' ? expense : income,
        date: DateTime(2026, 11, day, hour),
      );
      final ledger = Ledger(
        profile.copyWith(
          transactions: [
            entry('one', 'expense', 2, 120),
            entry('two', 'expense', 2, 80),
            entry('three', 'income', 3, 2000),
            entry('today', 'expense', 4, 50),
            entry('later', 'expense', 4, 999, hour: 18),
            entry('tomorrow', 'expense', 5, 500),
          ],
        ),
        const AppSettings(),
      );
      expect(
        dailyExpenses(
          ledger,
          DateWindow(DateTime(2026, 11, 2), DateTime(2026, 11, 9)),
          now,
        ),
        [200, 0, 50, null, null, null, null],
      );
    },
  );
}
