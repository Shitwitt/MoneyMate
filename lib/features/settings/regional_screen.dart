import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/currency_rebase.dart';
import '../../core/data/providers.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';

const languageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'pa': 'ਪੰਜਾਬੀ',
  'mr': 'मराठी',
  'gu': 'ગુજરાતી',
  'bn': 'বাংলা',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'ar': 'العربية',
  'pt': 'Português',
};

class RegionalScreen extends ConsumerWidget {
  const RegionalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    final profile = ref.watch(profileProvider)!;
    final controller = ref.read(appProvider.notifier);
    return FeaturePage(
      title: 'A familiar way to see money',
      child: ListView(
        children: [
          const SectionHeader('Language'),
          formSelect(
            'App language',
            settings.locale,
            languageNames.keys.toList(),
            (value) => runSafe(
              context,
              () => controller.settings((s) => s.copyWith(locale: value)),
            ),
            display: (id) => languageNames[id]!,
          ),
          const SizedBox(height: 12),
          const Text(
            '13 starter translations cover navigation and primary actions. Detailed finance explanations and some forms remain in English. Arabic automatically uses right-to-left layout.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Currency & format'),
          formSelect(
            'Profile / reporting currency',
            profile.profile.currency,
            currencySymbols.keys.toList(),
            (value) async {
              if (value == profile.profile.currency) return;
              if (await confirm(
                    context,
                    'Convert your plans to $value?',
                    'Account currencies and transactions are kept as entered. Budgets, goals, loans, assets and bill shares are converted using your reference rates and rounded to $value precision. Export a backup before changing this.',
                    confirmLabel: 'Convert',
                  ) &&
                  context.mounted)
                await runSafe(
                  context,
                  () => controller.updateProfile(
                    (data, app) => rebaseProfile(data, value),
                  ),
                );
            },
          ),
          const SizedBox(height: 16),
          formSelect(
            'Number format',
            settings.numberFormat,
            ['international', 'indian'],
            (value) => runSafe(
              context,
              () => controller.settings((s) => s.copyWith(numberFormat: value)),
            ),
          ),
          const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: AmountText(
                  toMinor(1234567.89, profile.profile.currency),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader('Your financial calendar'),
            formSelect(
              'First day of week',
              '${settings.weekStart}',
              [for (var i = 1; i <= 7; i++) '$i'],
              (value) => runSafe(
                context,
                () => controller.settings(
                  (s) => s.copyWith(weekStart: int.parse(value)),
                ),
              ),
              display: (id) => [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ][int.parse(id) - 1],
            ),
            const SizedBox(height: 16),
            formSelect(
              'Financial month starts on day',
              '${settings.monthStart}',
              [for (var i = 1; i <= 31; i++) '$i'],
              (value) => runSafe(
                context,
                () => controller.settings(
                  (s) => s.copyWith(monthStart: int.parse(value)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Days 29–31 clamp to the last day of shorter months. Existing budgets keep their own renewal dates; this changes dashboard and report periods.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 100),
        ],
      ),
    );
  }
}
