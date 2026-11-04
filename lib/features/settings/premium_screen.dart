import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(appProvider.select((data) => data.settings.isPro));
    Future<void> unlock() async {
      final done = await runSafe(
        context,
        () => ref
            .read(appProvider.notifier)
            .settings((settings) => settings.copyWith(isPro: true)),
        success:
            'Plus unlocked forever on this installation. No payment, ever.',
      );
      if (done && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    return FeaturePage(
      title: 'A little more possibility',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.tertiaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface
                        .withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'PAISACLONE PLUS',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Icon(Icons.auto_awesome_rounded, size: 46),
                const SizedBox(height: 20),
                Text(
                  'Your dreams.\nWithout limits.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Same privacy. A little more room to grow.',
                  style: TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final feature in [
            ('Budgets & goals', '3 each', 'Unlimited'),
            ('Labels, people & places', '10 each', 'Unlimited'),
            ('Split bills', '3 bills', 'Unlimited'),
            ('Reports', 'Core charts + CSV', 'Velocity, comparisons, heatmap'),
            ('PDF reports', '—', 'Export & print'),
            ('Themes', 'System, light & dark', 'Just Black + extra accents'),
          ])
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        feature.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        feature.$2,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        feature.$3,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: pro ? null : unlock,
            icon: Icon(pro ? Icons.verified_rounded : Icons.lock_open_rounded),
            label: Text(pro ? 'You’re already Plus' : 'Unlock Premium Forever'),
          ),
          const SizedBox(height: 12),
          const Text(
            'SIMULATED PREMIUM · FREE\nNo payment SDK, subscriptions, account, or purchase tracking. This button only saves a local flag.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.7),
          ),
          TextButton(
            onPressed: unlock,
            child: const Text('Restore simulated unlock'),
          ),
          if (pro)
            TextButton(
              onPressed: () => runSafe(
                context,
                () => ref
                    .read(appProvider.notifier)
                    .settings(
                      (settings) => settings.copyWith(
                        isPro: false,
                        theme: settings.theme == 'black'
                            ? 'dark'
                            : settings.theme,
                      ),
                    ),
                success: 'Free mode enabled. Existing data is kept.',
              ),
              child: const Text('Test free mode (keep all data)'),
            ),
        ],
      ),
    );
  }
}
