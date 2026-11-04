import 'package:flutter/material.dart';
import '../core/data/providers.dart';
import '../features/settings/premium_screen.dart';

void toast(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> runSafe(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) toast(context, success);
    return true;
  } on PremiumRequired {
    if (context.mounted)
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
    return false;
  } catch (error) {
    if (context.mounted)
      toast(context, error.toString().replaceFirst('FormatException: ', ''));
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
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
