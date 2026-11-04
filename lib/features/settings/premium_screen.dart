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
        success: 'Pro unlocked on this installation. No payment, ever.',
      );
      if (done && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    return FeaturePage(
      title: 'Tink Pro',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          AppCard(
            color: AppColors.darkSurface,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tink',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const PremiumBadge(),
                    const Spacer(),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.darkAccent,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'A little more\nroom to grow.',
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Same privacy. More possibilities.\nNo checkout, subscription or real payment.',
                  style: TextStyle(color: AppColors.darkSecondary, height: 1.5),
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
            ('Themes', 'System, light & dark', 'Midnight + extra accents'),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
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
            label: Text(pro ? 'Pro is enabled' : 'Unlock Pro for free'),
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
