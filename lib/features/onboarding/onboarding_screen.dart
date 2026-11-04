import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/utils/money.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../settings/backup_screen.dart';

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
  final pageController = PageController();
  final form = GlobalKey<FormState>();
  int step = 0;
  String currency = 'INR';
  bool demo = false, busy = false;
  @override
  void dispose() {
    name.dispose();
    account.dispose();
    opening.dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (step == 1 && !form.currentState!.validate()) return;
    if (step < 2) {
      setState(() => step++);
      await pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    setState(() => busy = true);
    final done = await runSafe(context, () async {
      final initial = num.tryParse(opening.text.replaceAll(',', ''));
      if (initial == null || !initial.isFinite) {
        throw const FormatException('Enter a valid starting balance');
      }
      await ref
          .read(appProvider.notifier)
          .createProfile(
            name: name.text,
            currency: currency,
            accountName: account.text,
            openingMinor: toMinor(initial, currency),
            demo: demo,
          );
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (done && widget.addingProfile) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: step > 0
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() => step--);
                  pageController.animateToPage(
                    step,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : widget.addingProfile
            ? const BackButton()
            : null,
        title: Row(
          children: [
            Image.asset('assets/branding/mark.png', width: 32, height: 32),
            const SizedBox(width: 10),
            const Text(
              'PaisaClone',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Chip(
              label: Text('${step + 1} / 3'),
              avatar: const Icon(Icons.spa_outlined, size: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/branding/welcome.png',
                                height: 220,
                                semanticLabel: 'A growing plant and coins, a fresh start for your finances',
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              widget.addingProfile
                                  ? 'A new space.\nA fresh perspective.'
                                  : 'A little clarity.\nA lot more freedom.',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Make room for what matters. Track your spending, build better habits, and bring your dreams a little closer.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    height: 1.7,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                Chip(
                                  avatar: Icon(
                                    Icons.wifi_off_rounded,
                                    size: 16,
                                  ),
                                  label: Text('Offline, always'),
                                ),
                                Chip(
                                  avatar: Icon(Icons.shield_outlined, size: 16),
                                  label: Text('Private by design'),
                                ),
                                Chip(
                                  avatar: Icon(
                                    Icons.favorite_outline_rounded,
                                    size: 16,
                                  ),
                                  label: Text('Made for everyday'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Let’s make it yours.',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No sign-up. Just a name for your private space.',
                              ),
                              const SizedBox(height: 28),
                              formText(
                                name,
                                'What should we call you?',
                                required: true,
                              ),
                              const SizedBox(height: 18),
                              formSelect(
                                'Preferred currency',
                                currency,
                                currencySymbols.keys.toList(),
                                (value) => setState(() => currency = value),
                                display: (code) =>
                                    '$code · ${currencySymbols[code]}',
                              ),
                              const SizedBox(height: 18),
                              formText(
                                account,
                                'Your first account',
                                required: true,
                                hint: 'Everyday, Cash, My bank…',
                              ),
                              const SizedBox(height: 18),
                              formText(
                                opening,
                                'Starting balance ($currency)',
                                numeric: true,
                                required: true,
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'You can add more accounts and currencies later. Starting balances can be negative for debt.',
                                style: TextStyle(fontSize: 12, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.spa_outlined, size: 52),
                            const SizedBox(height: 24),
                            Text(
                              'Your money.\nYour device.',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l.privacyPromise,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 28),
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.lock_outline_rounded),
                              title: Text('100% local storage'),
                              subtitle: Text(
                                'Nothing leaves unless you export or share it.',
                              ),
                            ),
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.backup_outlined),
                              title: Text('You’re in control of backups'),
                              subtitle: Text(
                                'Keep a copy before changing devices or clearing browser data.',
                              ),
                            ),
                            const SizedBox(height: 18),
                            Card(
                              child: SwitchListTile.adaptive(
                                title: const Text(
                                  'Show me around with sample data',
                                ),
                                subtitle: const Text(
                                  'Six months of fictional activity in this new profile',
                                ),
                                value: demo,
                                onChanged: (value) =>
                                    setState(() => demo = value),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'An independent, original open-source implementation inspired by offline finance apps. Not affiliated with Paisa or its developer.',
                              style: TextStyle(fontSize: 11, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : next,
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                step == 2
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                        label: Text(
                          busy
                              ? 'Making room for you…'
                              : step == 2
                              ? l.getStarted
                              : l.continueLabel,
                        ),
                      ),
                      if (!widget.addingProfile && step == 0)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => restoreBackup(
                                  context,
                                  (preview) => ref
                                      .read(appProvider.notifier)
                                      .restore(preview.data),
                                ),
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
