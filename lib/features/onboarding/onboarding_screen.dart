import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/services/service_providers.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../settings/backup_screen.dart';
import 'introduction_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool addingProfile;
  const OnboardingScreen({super.key, this.addingProfile = false});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final name = TextEditingController(),
      account = TextEditingController(text: 'Everyday'),
      opening = TextEditingController(text: '0');
  final form = GlobalKey<FormState>();
  late bool introduction = !widget.addingProfile;
  int step = 0;
  String currency = 'INR';
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    account.dispose();
    opening.dispose();
    super.dispose();
  }

  Future<void> restore() => restoreBackup(
    context,
    (preview) => ref.read(appProvider.notifier).restore(preview.data),
  );
  Future<void> next() async {
    if (step == 0) {
      if (!form.currentState!.validate()) return;
      setState(() => step = 1);
      return;
    }
    setState(() => busy = true);
    final saved = await runSafe(context, () async {
      final value = num.tryParse(opening.text.replaceAll(',', ''));
      if (value == null || !value.isFinite)
        throw const FormatException('Enter a valid starting balance');
      await ref
          .read(appProvider.notifier)
          .createProfile(
            name: name.text,
            currency: currency,
            accountName: account.text,
            openingMinor: toMinor(value, currency),
            demo: false,
          );
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (saved && widget.addingProfile) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (introduction)
      return IntroductionScreen(
        onFinish: () => setState(() => introduction = false),
        onRestore: restore,
        onDemo: () =>
            runSafe(context, () => ref.read(appProvider.notifier).startDemo()),
        language: ref.watch(appProvider).settings.locale,
        currency: currency,
        onCurrency: (value) => setState(() => currency = value),
        onLanguage: (value) => ref
            .read(appProvider.notifier)
            .settings((s) => s.copyWith(locale: value)),
        onTheme: (value) => runSafe(
          context,
          () => ref
              .read(appProvider.notifier)
              .settings((s) => s.copyWith(theme: value)),
        ),
        onNotifications: () async {
          if (kIsWeb) {
            toast(context, 'Local notifications need the Android or iOS app.');
            return;
          }
          await runSafe(context, () async {
            final granted = await ref
                .read(notificationServiceProvider)
                .requestPermission();
            if (!granted)
              throw const FormatException(
                'Notification permission was not granted. You can enable it later in Settings.',
              );
            await ref
                .read(appProvider.notifier)
                .settings((s) => s.copyWith(notificationsEnabled: true));
          }, success: 'Local reminders enabled');
        },
      );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: busy
              ? null
              : () {
                  if (step > 0) {
                    setState(() => step--);
                  } else if (widget.addingProfile) {
                    Navigator.pop(context);
                  } else {
                    setState(() => introduction = true);
                  }
                },
        ),
        title: const TinkBrand(),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                widget.addingProfile
                    ? 'Setup ${step + 1} of 2'
                    : '${step + 13}/14',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: step == 0
                          ? Form(
                              key: form,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Let’s make it yours.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No sign-up. Just a name for your private space.',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 32),
                                  formText(
                                    name,
                                    'What should we call you?',
                                    required: true,
                                  ),
                                  const SizedBox(height: 16),
                                  formSelect(
                                    'Preferred currency',
                                    currency,
                                    currencySymbols.keys.toList(),
                                    (value) => setState(() => currency = value),
                                    display: (code) =>
                                        '$code · ${currencySymbols[code]}',
                                  ),
                                  const SizedBox(height: 16),
                                  formText(
                                    account,
                                    'Your first account',
                                    required: true,
                                    hint: 'Everyday, Cash, My bank…',
                                  ),
                                  const SizedBox(height: 16),
                                  formText(
                                    opening,
                                    'Starting balance ($currency)',
                                    numeric: true,
                                    required: true,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Cash and credit, in perspective. Use a negative balance for debt. You can add more accounts later.',
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              key: const ValueKey('privacy'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: CategoryIcon(
                                    icon: Icons.shield_outlined,
                                    size: 64,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'A fresh start.\nOn your terms.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                                const SizedBox(height: 24),
                                AppCard(
                                  child: Column(
                                    children: const [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          Icons.phone_android_rounded,
                                        ),
                                        title: Text('Only on your device'),
                                        subtitle: Text(
                                          'No account, ads or automatic cloud uploads.',
                                        ),
                                      ),
                                      Divider(),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.backup_outlined),
                                        title: Text('Back up when you choose'),
                                        subtitle: Text(
                                          'Export a verified copy before changing devices.',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: const Icon(Icons.science_outlined),
                                    title: const Text(
                                      'Try a separate demo first',
                                    ),
                                    subtitle: const Text(
                                      'Sample records stay in memory, never in this profile.',
                                    ),
                                    onTap: () => runSafe(
                                      context,
                                      () => ref
                                          .read(appProvider.notifier)
                                          .startDemo(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Your device sandbox protects local storage. Portable backups are unencrypted; keep them somewhere safe. You can enable an app PIN in Settings.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        label: step == 0 ? 'Continue' : 'Start using Tink',
                        loading: busy,
                        onPressed: next,
                        icon: step == 1 ? Icons.check_rounded : null,
                      ),
                      if (!widget.addingProfile && step == 0)
                        TextButton(
                          onPressed: busy ? null : restore,
                          child: const Text(
                            'Already have a backup? Restore it',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
