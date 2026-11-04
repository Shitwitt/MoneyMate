import 'package:flutter/material.dart';

import '../core/data/providers.dart';
import '../features/settings/premium_screen.dart';

void toast(
  BuildContext context,
  String text, {
  bool error = false,
  bool success = false,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : success
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: error
                ? const Color(0xffF87171)
                : success
                ? const Color(0xff34D399)
                : const Color(0xffC4B5FD),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

Future<bool> runSafe(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null)
      toast(context, success, success: true);
    return true;
  } on PremiumRequired {
    if (context.mounted) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
    }
    return false;
  } catch (error) {
    if (context.mounted) {
      toast(
        context,
        error.toString().replaceFirst('FormatException: ', ''),
        error: true,
      );
    }
    return false;
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String confirmLabel = 'Delete',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                [
                  'Delete',
                  'Remove',
                  'Reset',
                ].any((word) => confirmLabel.startsWith(word))
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
