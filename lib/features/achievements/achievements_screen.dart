import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/data/achievements.dart';
import '../../core/data/providers.dart';
import '../../shared/widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider)!;
    final progress = achievementProgress(profile, ref.watch(appProvider).settings, DateTime.now());
    return FeaturePage(title: 'Little wins add up', subtitle: 'Progress, not perfection', child: ListView(padding: const EdgeInsets.only(bottom: 110), children: [Row(children: [Expanded(child: StatCard(title: 'Entries', value: Text('${profile.transactions.length}'), icon: Icons.receipt_long_rounded)), const SizedBox(width: 12), Expanded(child: StatCard(title: 'Best streak', value: Text('${longestStreak(profile)} days'), icon: Icons.local_fire_department_rounded))]), const SizedBox(height: 24), Text('${profile.achievements.length} / ${badges.length} little wins collected', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 16), for (final badge in badges) Padding(padding: const EdgeInsets.only(bottom: 14), child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Stack(alignment: Alignment.center, children: [SizedBox.square(dimension: 58, child: CircularProgressIndicator(value: ((progress[badge.id] ?? 0) / badge.target).clamp(0, 1), strokeWidth: 3, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest)), Icon(profile.achievements.any((item) => item.id == badge.id) ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.primary)]), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(badge.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 5), Text(badge.detail, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 7), Text('${badge.rarity} · ${profile.achievements.any((item) => item.id == badge.id) ? 'Unlocked ${DateFormat.yMMMd().format(profile.achievements.firstWhere((item) => item.id == badge.id).unlockedAt)}' : '${(progress[badge.id] ?? 0).clamp(0, badge.target)} / ${badge.target}'}', style: Theme.of(context).textTheme.labelSmall)]))]))))]));
  }
}
