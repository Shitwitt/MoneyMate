import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/constants.dart';
import '../../core/utils/money.dart';
import '../../shared/widgets.dart';
import '../settings/language_picker.dart';
import 'feature_phone_preview.dart';

/// Only supplied pages are reference reconstructions. Pages 9, 11, 12 and the
/// final two setup forms are original, working continuations pending references.
const introductionPages = [
  (
    'Set up Tink',
    'Start fresh, bring back an existing backup, or explore Tink with sample data.',
    'setup',
  ),
  (
    'Welcome to Tink',
    'Effortlessly track your expenses, simply and securely.',
    'home',
  ),
  (
    'Manage Your Budgets',
    'Set and track budgets to stay on top of your finances.',
    'budgets',
  ),
  ('Track Your Loans', 'Keep track of your loans and repayments.', 'loans'),
  (
    'Set Financial Goals',
    'Achieve your financial goals with personalized plans.',
    'goals',
  ),
  (
    'Recurring Transactions',
    'Manage subscriptions and repeat payments without missing a beat.',
    'recurring',
  ),
  (
    'Categories',
    'Organize your expenses with unlimited custom categories.',
    'categories',
  ),
  (
    'Support for 35+ Languages',
    'Choose from 36 offline languages for core navigation and actions. Detailed finance tools currently use English.',
    'languages',
  ),
  (
    'Make Tink Your Own',
    'Choose light, coffee-dark, or Just Black. Your appearance preferences stay on this device.',
    'appearance',
  ),
  (
    'Reminders & Notifications',
    'Set up private local reminders to stay on top of your finances.',
    'notifications',
  ),
  (
    'Private by Design',
    'No account, no server, no tracking. Your app lock is not database encryption, and exported backups are unencrypted.',
    'privacy',
  ),
  (
    'Money in Your Currency',
    'Choose your reporting currency. Accounts can use different currencies with manual, offline exchange rates.',
    'currency',
  ),
];

class IntroductionScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback? onRestore, onDemo;
  final Future<void> Function(String)? onLanguage;
  final ValueChanged<String>? onTheme, onCurrency;
  final Future<void> Function()? onNotifications;
  final String language, currency;
  const IntroductionScreen({
    super.key,
    required this.onFinish,
    this.onRestore,
    this.onDemo,
    this.onLanguage,
    this.onTheme,
    this.onCurrency,
    this.onNotifications,
    this.language = 'en',
    this.currency = 'INR',
  });
  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final controller = PageController();
  int current = 0;
  late String language = widget.language, currency = widget.currency;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void next() {
    if (current == introductionPages.length - 1) {
      widget.onFinish();
      return;
    }
    controller.nextPage(
      duration: referenceMotion(context, 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> chooseLanguage() =>
      showLanguagePicker(context, language, (value) async {
        await widget.onLanguage?.call(value);
        if (mounted) setState(() => language = value);
      });
  @override
  Widget build(BuildContext context) {
    final coffeeTheme = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkSurface,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryInk,
        surface: AppColors.darkCard,
        onSurface: const Color(0xffEAD2C6),
        onSurfaceVariant: AppColors.darkSecondary,
        primaryContainer: const Color(0xff4B2B1E),
      ),
      textTheme: AppTextStyles.theme(
        const Color(0xffEAD2C6),
        AppColors.darkSecondary,
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: coffeeTheme,
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: AppColors.darkSurface,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                        child: Row(
                          children: [
                            OutlinedButton(
                              onPressed: chooseLanguage,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(72, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                foregroundColor: const Color(0xffEAD2C6),
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(
                                  color: Color(0xff63412E),
                                ),
                              ),
                              child: Text(
                                language.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${current + 1}/14',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            SizedBox(
                              width: 72,
                              child: current == 0
                                  ? const SizedBox.shrink()
                                  : TextButton(
                                      onPressed: widget.onFinish,
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            AppColors.darkSecondary,
                                      ),
                                      child: const Text('Skip'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: controller,
                          itemCount: introductionPages.length,
                          onPageChanged: (index) =>
                              setState(() => current = index),
                          itemBuilder: (context, index) {
                            final page = introductionPages[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: switch (page.$3) {
                                      'setup' => _SetupChoices(
                                        onRestore: widget.onRestore,
                                        onDemo: widget.onDemo,
                                      ),
                                      'languages' => _LanguagesArt(
                                        selected: language,
                                        onMore: chooseLanguage,
                                        onSelected: (value) async {
                                          await widget.onLanguage?.call(value);
                                          if (mounted)
                                            setState(() => language = value);
                                        },
                                      ),
                                      'privacy' => const _PrivacyArt(),
                                      'currency' => Center(
                                        child: TonalCard(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.currency_exchange_rounded,
                                                size: 70,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(height: 24),
                                              DropdownButtonFormField<String>(
                                                initialValue: currency,
                                                isExpanded: true,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Reporting currency',
                                                    ),
                                                items: [
                                                  for (final code
                                                      in currencySymbols.keys)
                                                    DropdownMenuItem(
                                                      value: code,
                                                      child: Text(
                                                        '$code · ${currencySymbols[code]}',
                                                      ),
                                                    ),
                                                ],
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(
                                                      () => currency = value,
                                                    );
                                                    widget.onCurrency?.call(
                                                      value,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      'notifications' => Stack(
                                        children: [
                                          const FeaturePhonePreview(
                                            feature: 'notifications',
                                          ),
                                          Positioned(
                                            bottom: 12,
                                            left: 0,
                                            right: 0,
                                            child: Center(
                                              child: FilledButton.icon(
                                                onPressed:
                                                    widget.onNotifications,
                                                icon: const Icon(
                                                  Icons
                                                      .notifications_none_rounded,
                                                ),
                                                label: const Text(
                                                  'Enable notifications',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      _ => FeaturePhonePreview(
                                        feature: page.$3,
                                      ),
                                    },
                                  ),
                                  if (page.$3 == 'appearance')
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        for (final mode in [
                                          'light',
                                          'dark',
                                          'black',
                                        ])
                                          OutlinedButton(
                                            onPressed: () =>
                                                widget.onTheme?.call(mode),
                                            child: Text(
                                              mode == 'black'
                                                  ? 'Just Black'
                                                  : titleCase(mode),
                                            ),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 14),
                                  Text(
                                    page.$1,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    page.$2,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: AppColors.darkSecondary,
                                          height: 1.45,
                                        ),
                                  ),
                                  const SizedBox(height: 18),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(36, 0, 36, 20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 230,
                            maxWidth: 330,
                          ),
                          child: FilledButton(
                            onPressed: next,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.primaryInk,
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            child: Text(
                              current == 0
                                  ? 'Start fresh'
                                  : current == 1
                                  ? 'Get started'
                                  : current == introductionPages.length - 1
                                  ? 'Continue'
                                  : 'Next',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupChoices extends StatelessWidget {
  final VoidCallback? onRestore, onDemo;
  const _SetupChoices({this.onRestore, this.onDemo});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: TinkLogo(size: 126),
            ),
            Column(
              children: [
                _Choice(
                  Icons.cloud_download_outlined,
                  'Restore a provider backup',
                  onRestore,
                ),
                const SizedBox(height: 12),
                _Choice(
                  Icons.restore_rounded,
                  'Restore Local Backup',
                  onRestore,
                ),
                const SizedBox(height: 12),
                _Choice(Icons.science_outlined, 'Try Demo Mode', onDemo),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  const _Choice(this.icon, this.title, this.onTap);
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xffEAD2C6),
      side: const BorderSide(color: Color(0xff77655C)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: const Color(0xff4B2B1E),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 22),
      ],
    ),
  );
}

class _LanguagesArt extends StatelessWidget {
  final String selected;
  final Future<void> Function(String) onSelected;
  final VoidCallback onMore;
  const _LanguagesArt({
    required this.selected,
    required this.onSelected,
    required this.onMore,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        SizedBox(
          height: math.min(100, MediaQuery.sizeOf(context).height * .08),
        ),
        const CircleAvatar(
          radius: 62,
          backgroundColor: Color(0xff371E12),
          child: Icon(
            Icons.language_rounded,
            size: 76,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final code in [
              'en',
              'es',
              'fr',
              'de',
              'zh',
              'ja',
              'hi',
              'ar',
              'pt',
              'ru',
              'it',
            ])
              ChoiceChip(
                label: Text(languageNames[code]!),
                selected: code == selected,
                backgroundColor: const Color(0xff322826),
                selectedColor: const Color(0xff66402C),
                labelStyle: const TextStyle(color: Color(0xffEAD2C6)),
                onSelected: (_) => onSelected(code),
              ),
            ActionChip(
              label: Text('+${languageNames.length - 11} more'),
              onPressed: onMore,
              labelStyle: const TextStyle(color: Color(0xffEAD2C6)),
              backgroundColor: const Color(0xff322826),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PrivacyArt extends StatelessWidget {
  const _PrivacyArt();
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 106,
            color: AppColors.primary,
          ),
          const SizedBox(height: 32),
          for (final item in [
            (Icons.phone_android_rounded, '100% on your device'),
            (Icons.no_accounts_outlined, 'No sign-up or tracking'),
            (
              Icons.lock_outline_rounded,
              'An app lock, not database encryption',
            ),
            (Icons.backup_outlined, 'Private, unencrypted backup files'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TonalCard(
                child: Row(
                  children: [
                    Icon(item.$1, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.$2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
