import 'package:flutter/material.dart';

/// A friendly, theme-aware error state.
///
/// Used for failed writes (onboarding, transactions), corrupt backups and the
/// app-level error boundary. Never shows a raw stack trace to the user.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.secondaryLabel,
    this.onSecondary,
    this.icon = Icons.error_outline_rounded,
  });

  final String title;

  /// Short, human readable explanation (already localized by the caller).
  final String message;

  final VoidCallback? onRetry;
  final String retryLabel;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(icon, size: 40, color: scheme.onErrorContainer),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onRetry,
                      child: Text(retryLabel),
                    ),
                  ),
                if (onRetry != null && onSecondary != null)
                  const SizedBox(height: 8),
                if (onSecondary != null)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel ?? 'Cancel'),
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

/// Lightweight inline banner for recoverable problems (e.g. a failed sync of a
/// linked debt transaction) that must not take over the screen.
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.message,
    this.isError = false,
    this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color background =
        isError ? scheme.errorContainer : scheme.secondaryContainer;
    final Color foreground =
        isError ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foreground,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: foreground,
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}
