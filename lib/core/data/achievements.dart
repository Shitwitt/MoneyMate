import '../models/models.dart';
import '../utils/dates.dart';
import 'ledger.dart';

class BadgeDefinition {
  final String id, name, detail, rarity;
  final int target;
  const BadgeDefinition(
    this.id,
    this.name,
    this.detail,
    this.rarity,
    this.target,
  );
}

const badges = [
  BadgeDefinition(
    'first',
    'A fresh start',
    'Record your first transaction',
    'Common',
    1,
  ),
  BadgeDefinition(
    'seven',
    'A little every day',
    'Track on 7 consecutive days',
    'Uncommon',
    7,
  ),
  BadgeDefinition(
    'thirty',
    'In your rhythm',
    'Track on 30 consecutive days',
    'Rare',
    30,
  ),
  BadgeDefinition(
    'hundred',
    'Money mindful',
    'Record 100 transactions',
    'Uncommon',
    100,
  ),
  BadgeDefinition(
    'goal',
    'Dream, meet reality',
    'Complete a savings goal',
    'Epic',
    1,
  ),
  BadgeDefinition(
    'budget',
    'Perfectly balanced',
    'Finish a budget period within its limit',
    'Rare',
    1,
  ),
];
int longestStreak(ProfileData data) {
  final days =
      data.transactions.map((entry) => dayOnly(entry.date)).toSet().toList()
        ..sort();
  var longest = 0, current = 0;
  DateTime? previous;
  for (final day in days) {
    current =
        previous != null &&
            DateTime(
                  day.year,
                  day.month,
                  day.day,
                ).difference(previous).inHours >=
                23 &&
            day.difference(previous).inHours <= 25
        ? current + 1
        : 1;
    if (current > longest) longest = current;
    previous = day;
  }
  return longest;
}

Map<String, int> achievementProgress(
  ProfileData data,
  AppSettings settings,
  DateTime now,
) {
  final ledger = Ledger(data, settings);
  final streak = longestStreak(data);
  final completedBudget = data.budgets.any((budget) {
    if (budget.start.isAfter(now) || budget.income) return false;
    final previous = budgetWindow(
      budget,
      budgetWindow(
        budget,
        now,
        settings.weekStart,
      ).start.subtract(const Duration(days: 1)),
      settings.weekStart,
    );
    return !previous.end.isAfter(now) &&
        !previous.start.isBefore(dayOnly(budget.start)) &&
        ledger.spentFor(budget, previous) > 0 &&
        ledger.spentFor(budget, previous) <= budget.limitMinor;
  });
  return {
    'first': data.transactions.isEmpty ? 0 : 1,
    'seven': streak,
    'thirty': streak,
    'hundred': data.transactions.length,
    'goal': data.goals.any((goal) => ledger.goalSaved(goal) >= goal.targetMinor)
        ? 1
        : 0,
    'budget': completedBudget ? 1 : 0,
  };
}

ProfileData unlockAchievements(ProfileData data, AppSettings settings) {
  final now = DateTime.now();
  final progress = achievementProgress(data, settings, now);
  final unlocked = data.achievements.map((item) => item.id).toSet();
  final additions = badges
      .where(
        (badge) =>
            !unlocked.contains(badge.id) &&
            (progress[badge.id] ?? 0) >= badge.target,
      )
      .map((badge) => Achievement(id: badge.id, unlockedAt: now))
      .toList();
  return additions.isEmpty
      ? data
      : data.copyWith(achievements: [...data.achievements, ...additions]);
}
