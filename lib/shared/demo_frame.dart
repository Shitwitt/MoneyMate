import 'package:flutter/material.dart';

/// An app-owned demo control, not an imitation OS status bar or chat overlay.
/// The navigator gets its own bounded region below this reserved band, so the
/// exit control cannot cover an app bar, editor, sheet, or receipt preview.
class DemoFrame extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final VoidCallback onExit;
  const DemoFrame({
    super.key,
    required this.child,
    required this.enabled,
    required this.onExit,
  });
  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Center(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: onExit,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Exit Demo'),
                ),
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
