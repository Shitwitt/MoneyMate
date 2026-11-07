import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';

/// Shared chrome for the five onboarding pages.
///
/// Responsibilities:
///  * the step progress bar + "Step n of 5" label,
///  * the Back / Skip row,
///  * the pinned primary action (safe-area aware, never covers the content),
///  * an optional lava-lamp background for the welcome page.
///
/// Each page supplies its own scrollable [body]; the scaffold owns the keyboard
/// insets so text fields on page 2 stay visible.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.onBack,
    this.onSkip,
    this.primaryEnabled = true,
    this.primaryBusy = false,
    this.showProgress = true,
    this.background,
    this.secondaryAction,
    this.header,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool primaryEnabled;
  final bool primaryBusy;
  final bool showProgress;

  /// Optional full-bleed backdrop (the welcome page passes a lava lamp).
  final Widget? background;

  /// Optional secondary text button shown beside the primary action.
  final Widget? secondaryAction;

  /// Optional widget rendered above the title (the logo on page 1).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double progress = totalSteps <= 0 ? 0 : (step / totalSteps).clamp(0.0, 1.0);

    final Widget content = SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: <Widget>[
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  )
                else
                  const SizedBox(width: 48),
                const Spacer(),
                if (showProgress)
                  Text(
                    '$step / $totalSteps',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(width: 8),
                if (onSkip != null)
                  TextButton(
                    onPressed: onSkip,
                    child: Text(context.tr('onboardingSkip')),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          if (showProgress)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: SingleChildScrollView(
                key: ValueKey<int>(step),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (header != null) ...<Widget>[
                      Center(child: header!),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      title,
                      textAlign: header != null ? TextAlign.center : TextAlign.start,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign:
                            header != null ? TextAlign.center : TextAlign.start,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    body,
                  ],
                ),
              ),
            ),
          ),
          // The scroll view above already absorbs the keyboard inset, so the
          // action bar only needs the bottom safe-area padding.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: <Widget>[
                if (secondaryAction != null) ...<Widget>[
                  secondaryAction!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed:
                        primaryEnabled && !primaryBusy ? onPrimary : null,
                    child: primaryBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(primaryLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: background == null
          ? content
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                background!,
                content,
              ],
            ),
    );
  }
}
