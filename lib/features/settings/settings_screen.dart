import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/utils/constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets.dart';
import 'appearance_screen.dart';
import 'backup_screen.dart';
import 'exchange_rates_screen.dart';
import 'help_screen.dart';
import 'layout_screen.dart';
import 'notifications_screen.dart';
import 'page_shortcuts_screen.dart';
import 'premium_screen.dart';
import 'profiles_screen.dart';
import 'regional_screen.dart';
import 'security_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(appProvider).settings;
    return FeaturePage(
      title: l.settings,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          ShineSurface(
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xff30263F), Color(0xff1B1B23)]
                : const [Color(0xffEDE7FF), Color(0xffF9F8FC)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LuxuryWordmark(size: 34),
                const SizedBox(height: 20),
                Text(
                  'A space that feels\nlike you.',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Every preference. Entirely yours. Always on this device.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader('Make it personal'),
          for (final item in [
            (
              l.appearance,
              'Themes, Material You & text size',
              Icons.palette_outlined,
              const AppearanceScreen(),
            ),
            (
              'Home & navigation',
              'Reorder cards, hide sections, make it yours',
              Icons.dashboard_customize_outlined,
              const LayoutScreen(),
            ),
            (
              l.language,
              'Currency, formats & your financial calendar',
              Icons.translate_rounded,
              const RegionalScreen(),
            ),
            (
              l.security,
              'Biometrics, PIN & hidden amounts',
              Icons.shield_outlined,
              const SecurityScreen(),
            ),
            (
              'Notifications',
              'Local reminders, on your terms',
              Icons.notifications_none_rounded,
              const NotificationsScreen(),
            ),
            (
              l.backup,
              'ZIP, JSON, CSV import & exports',
              Icons.backup_outlined,
              const BackupScreen(),
            ),
            (
              'Profiles',
              'Separate spaces for separate lives',
              Icons.people_outline_rounded,
              const ProfilesScreen(),
            ),
            (
              'Exchange rates',
              'Manual, offline reference rates',
              Icons.currency_exchange_rounded,
              const ExchangeRatesScreen(),
            ),
            (
              'Page shortcuts',
              'Copy safe links to specific Tink pages',
              Icons.link_rounded,
              const PageShortcutsScreen(),
            ),
            (
              'Widgets, automation & FAQ',
              'Home-screen widgets, links, help',
              Icons.help_outline_rounded,
              const HelpScreen(),
            ),
            (
              settings.isPro ? 'Manage Pro' : l.unlockPlus,
              'Simulated premium · no real payments',
              Icons.auto_awesome_rounded,
              const PremiumScreen(),
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CategoryIcon(icon: item.$3, size: 46),
                  title: Text(item.$1),
                  subtitle: Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => openPage(context, item.$4),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Image.asset(
                    'assets/branding/mark.png',
                    width: 30,
                    height: 30,
                  ),
                  title: const Text('About Tink'),
                  subtitle: const Text('v$appVersion · Private by design'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: appName,
                    applicationVersion: appVersion,
                    applicationIcon: Image.asset(
                      'assets/branding/mark.png',
                      width: 56,
                      height: 56,
                    ),
                    children: const [
                      Text(
                        'An independent offline finance app inspired by the privacy-first approach of Paisa. Independent Tink implementation and branding, with a GPL-licensed Paisa 6.3.6 backup compatibility adaptation. Not affiliated with Hemanth Savarala or paisa-tracker.app. See Open-source licenses for source, copyright and modification notices.\n\nNo analytics. No ads. No cloud. Your data is yours.',
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open-source licenses'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: appName,
                    applicationVersion: appVersion,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline_rounded),
                  title: const Text('Enjoying your little finance space?'),
                  subtitle: const Text(
                    'This sideload project has no store listing. Share the source, not your private data.',
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Thank you for being here'),
                      content: const Text(
                        'You can share the repository with a friend or open an issue with feedback. A public app-store rating link can be added after you publish your own listing.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Sounds good'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
