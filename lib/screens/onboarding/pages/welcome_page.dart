import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../widgets/lava_lamp_background.dart';

/// Page 1 — welcome, feature highlights and the language selector.
class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.languageCode,
    required this.onLanguageChanged,
    required this.onContinue,
    required this.onSkip,
  });

  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      body: LavaLampBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: onSkip,
                              child: Text(context.tr('onboardingSkip')),
                            ),
                          ),
                          const Spacer(),
                          const Center(child: PaisaLogo(size: 92)),
                          const SizedBox(height: 36),
                          Text(
                            context.tr('welcomeTitle'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('welcomeSubtitle'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _FeatureRow(
                            icon: Icons.cloud_off_rounded,
                            label: context.tr('featureOffline'),
                            tint: scheme.primaryContainer,
                            onTint: scheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 10),
                          _FeatureRow(
                            icon: Icons.lock_outline_rounded,
                            label: context.tr('featurePrivate'),
                            tint: scheme.secondaryContainer,
                            onTint: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(height: 10),
                          _FeatureRow(
                            icon: Icons.insights_rounded,
                            label: context.tr('featureInsights'),
                            tint: scheme.tertiaryContainer,
                            onTint: scheme.onTertiaryContainer,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            context.tr('chooseLanguage'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LanguageSelector(
                            selectedCode: languageCode,
                            onChanged: onLanguageChanged,
                          ),
                          const Spacer(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: onContinue,
                              child: Text(context.tr('onboardingNext')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A tonal pill: icon in a coloured bubble, label beside it.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTint,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final Color onTint;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: onTint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrollable language pills with a wrap fallback on wide screens.
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.selectedCode,
    required this.onChanged,
  });

  final String selectedCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final AppLanguage language in AppLanguage.all)
          Semantics(
            button: true,
            selected: language.code == selectedCode,
            label: language.englishName,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChanged(language.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: language.code == selectedCode
                      ? scheme.secondaryContainer
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: language.code == selectedCode
                        ? scheme.secondary
                        : scheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(language.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      language.nativeName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: language.code == selectedCode
                            ? scheme.onSecondaryContainer
                            : scheme.onSurface,
                        fontWeight: language.code == selectedCode
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
