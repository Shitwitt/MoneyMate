import 'package:flutter/material.dart';

/// An app-owned demo control, not an imitation OS status bar or chat overlay.
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
      child: Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
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
          ),
        ],
      ),
    );
  }
}
