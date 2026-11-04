import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/providers.dart';
import '../../core/services/service_providers.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    final controller = ref.read(appProvider.notifier);
    final service = ref.watch(notificationServiceProvider);
    return FeaturePage(
      title: 'A gentle nudge',
      child: ListView(
        children: [
          if (kIsWeb)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Local notifications are available in the Android and iOS apps, not this web build. No push server is used.',
                ),
              ),
            ),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Enable local notifications'),
              subtitle: const Text(
                'Private reminders, scheduled on this device',
              ),
              value: settings.notificationsEnabled,
              onChanged: kIsWeb
                  ? null
                  : (value) => runSafe(context, () async {
                      if (value && !await service.requestPermission())
                        throw const FormatException(
                          'Notification permission was not granted. Enable it in device Settings and try again.',
                        );
                      await controller.settings(
                        (s) => s.copyWith(notificationsEnabled: value),
                      );
                    }),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Budget check-ins'),
                  subtitle: const Text('At 50%, 80%, and 100% of each period'),
                  value: settings.budgetNotifications,
                  onChanged: (value) => runSafe(
                    context,
                    () => controller.settings(
                      (s) => s.copyWith(budgetNotifications: value),
                    ),
                  ),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Recurring payments'),
                  subtitle: const Text('Upcoming payment reminders'),
                  value: settings.recurringNotifications,
                  onChanged: (value) => runSafe(
                    context,
                    () => controller.settings(
                      (s) => s.copyWith(recurringNotifications: value),
                    ),
                  ),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Loan due dates'),
                  value: settings.loanNotifications,
                  onChanged: (value) => runSafe(
                    context,
                    () => controller.settings(
                      (s) => s.copyWith(loanNotifications: value),
                    ),
                  ),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Weekly backup reminder'),
                  value: settings.backupReminders,
                  onChanged: (value) => runSafe(
                    context,
                    () => controller.settings(
                      (s) => s.copyWith(backupReminders: value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Notification delivery can be delayed by battery optimization, Do Not Disturb, or the operating system. No exact-alarm permission is requested. Up to 60 reminders are scheduled; opening the app refreshes the next reminders. Switching profiles replaces pending reminders with those for the active profile. Lock-screen messages omit transaction amounts.',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
          if (service.lastError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                service.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
