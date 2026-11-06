import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/data/providers.dart';
import '../../core/services/service_providers.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import '../onboarding/introduction_screen.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    const example =
        'tink://silent_add?amount=180&type=expense&name=Coffee&account=Everyday&category=Food%20%26%20Dining';
    return FeaturePage(
      title: 'Help & a little clarity',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const TinkLogo(size: 44),
              title: const Text('Meet Tink again'),
              subtitle: const Text('Replay the six-page introduction'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => openPage(
                context,
                IntroductionScreen(onFinish: () => Navigator.pop(context)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Your home-screen companions'),
          const Text(
            'Android: long-press your launcher → Widgets → Tink, or request a widget below. iOS: long-press the Home Screen → + → Tink, after configuring the App Group with your signing team (see README). Widgets refresh after saved changes and use the active profile.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 16),
          for (final widget in [
            (
              'BalanceWidget',
              'Net worth / balance',
              Icons.account_balance_wallet_outlined,
            ),
            ('BudgetWidget', 'Budget progress', Icons.donut_large_rounded),
            ('QuickAddWidget', 'Quick add', Icons.add_circle_outline_rounded),
          ])
            Card(
              child: ListTile(
                leading: Icon(widget.$3),
                title: Text(widget.$2),
                trailing: const Icon(Icons.add_rounded),
                onTap: () => runSafe(context, () async {
                  if (kIsWeb ||
                      defaultTargetPlatform != TargetPlatform.android) {
                    throw const FormatException(
                      'Add this widget from your mobile device’s home-screen widget gallery.',
                    );
                  }
                  final supported =
                      await HomeWidget.isRequestPinWidgetSupported() ?? false;
                  if (!supported) {
                    throw const FormatException(
                      'Your launcher does not support pin requests. Add it from the launcher’s widget gallery.',
                    );
                  }
                  await HomeWidget.requestPinWidget(androidName: widget.$1);
                }),
              ),
            ),
          const SizedBox(height: 24),
          const SectionHeader('Quick links & automation'),
          const Text(
            'Use Tasker, shortcuts, or an Android VIEW intent to open a prefilled transaction. The app validates account, category, type, amount and date. By default you always review and confirm it. A silent_add request posts only after app unlock AND after explicitly enabling the toggle below.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SelectableText(
                    example,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: example),
                      );
                      if (context.mounted) toast(context, 'Example copied');
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy example'),
                  ),
                ],
              ),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow silent_add automation after unlock'),
            subtitle: const Text(
              'Any installed app can invoke custom URI schemes. Enable only if you trust your device’s apps.',
            ),
            value: settings.allowSilentAdds,
            onChanged: (value) async {
              if (value &&
                  !await confirm(
                    context,
                    'Allow automated entries?',
                    'Links will be able to add income or expenses without a second confirmation when Tink is unlocked. Do not enable on shared devices.',
                    confirmLabel: 'Allow',
                  )) {
                return;
              }
              if (context.mounted) {
                await runSafe(
                  context,
                  () => ref
                      .read(appProvider.notifier)
                      .settings((s) => s.copyWith(allowSilentAdds: value)),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          const SelectableText(
            'adb shell am start -a android.intent.action.VIEW -d "tink://quick_add" com.example.paisaclone',
            style: TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
          const SizedBox(height: 14),
          const Text(
            'HTTPS fallback: https://paisaclone.example/add?... is a deliberately unverified placeholder, not a hosted website. Replace it with a domain you own, host a fallback page and assetlinks.json / apple-app-site-association, and configure App Links / Associated Domains before distributing. Custom tink:// links work without a server. Existing paisa:// links remain supported for compatibility, but may also be handled by the original app if it is installed. The optional description parameter is accepted as an alias for notes.',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Good questions'),
          for (final faq in [
            (
              'Where does my data live?',
              'In a local Hive database, separately for each profile. No analytics, sign-in, financial APIs or remote backend are included. Native device sandboxing and device encryption are your first line of protection.',
            ),
            (
              'Will recurring entries post while the app is closed?',
              'No. Reminder notifications are native, but ledger catch-up happens on launch/resume. Each occurrence has a deterministic ID to avoid duplicates. A maximum of 1,000 overdue entries per rule is caught up per pass; reopen to continue an unusually old rule.',
            ),
            (
              'Does a goal move real money?',
              'No. Manual contributions are planning allocations. Tagged income can also increase manual-goal progress. A linked-account goal tracks that account balance instead. Loans and assets affect net worth; enter actual account movements too when appropriate.',
            ),
            (
              'Are exchange rates live?',
              'No. They are illustrative offline reference rates, expressed as units per USD. Update them manually. Reports use current reference rates; transfers retain the receiving amounts recorded when you saved them.',
            ),
            (
              'How does rollover work?',
              'Each completed recurring budget period contributes its allowance minus its spending to the next period. Both underspending and overspending carry forward. Custom one-off budgets do not roll over.',
            ),
            (
              'What happens after clearing browser storage?',
              'Web data is deleted along with this origin’s site storage. Export a ZIP/JSON backup, and restore it in the new browser. Installable PWA caching is an offline convenience, not a backup.',
            ),
            (
              'What does Pro cost?',
              'Nothing in this project. Unlocking Pro only saves a local flag. There is no real purchase or subscription to cancel.',
            ),
            (
              'Can I change the PIN if I forget it?',
              'There is no server recovery. Preserve and verify an export, reinstall or clear app data, restore your backup, and choose a new PIN. Backups intentionally exclude PIN hashes.',
            ),
          ])
            Card(
              child: ExpansionTile(
                title: Text(
                  faq.$1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                children: [Text(faq.$2, style: const TextStyle(height: 1.7))],
              ),
            ),
          if (ref.read(widgetServiceProvider).lastError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(ref.read(widgetServiceProvider).lastError!),
            ),
        ],
      ),
    );
  }
}
