import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/ledger.dart';
import '../models/models.dart';
import '../utils/dates.dart';

class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  String? lastError;
  final Set<String> _shown = {};
  Future<void> _queue = Future.value();
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      ready = true;
    } catch (error) {
      lastError = 'Notifications unavailable: $error';
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (!ready) await init();
    if (!ready) return false;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  int _id(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'paisa_reminders',
      'Private finance reminders',
      channelDescription: 'Budget, recurring, loan and backup reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      visibility: NotificationVisibility.private,
    ),
    iOS: DarwinNotificationDetails(),
  );
  Future<void> _schedule(
    String key,
    String title,
    String body,
    DateTime date,
  ) async {
    if (!date.isAfter(DateTime.now())) return;
    await plugin.zonedSchedule(
      _id(key),
      title,
      body,
      tz.TZDateTime.from(date, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> sync(AppData app, Future<void> Function(List<String>) mark) {
    final work = _queue.then((_) async {
      if (!ready) return;
      try {
        for (final request in await plugin.pendingNotificationRequests()) {
          await plugin.cancel(request.id);
        }
        final settings = app.settings;
        if (!settings.notificationsEnabled || app.profiles.isEmpty) return;
        final profile = app.profiles.firstWhere(
          (item) => item.profile.id == app.activeProfileId,
        );
        final ledger = Ledger(profile, settings);
        final now = DateTime.now();
        final marks = <String>[];
        if (settings.budgetNotifications) {
          for (final budget in profile.budgets) {
            final status = ledger.budgetStatus(budget, now);
            for (final threshold in [50, 80, 100]) {
              final key =
                  '${profile.profile.id}:${budget.id}:${status.window.start.toIso8601String()}:$threshold';
              if (status.progress * 100 >= threshold &&
                  !profile.notificationMarks.contains(key) &&
                  _shown.add(key)) {
                // Amounts and merchant names are intentionally omitted on the lock screen.
                await plugin.show(
                  _id(key),
                  'Budget check-in',
                  '${budget.name} has reached $threshold% of its allowance.',
                  details,
                );
                marks.add(key);
              }
            }
          }
        }
        var count = 0; // Stay below iOS's 64 pending-notification limit.
        if (settings.recurringNotifications) {
          for (final rule in profile.recurrings.where((rule) => rule.enabled)) {
            var date = rule.nextDue;
            if (date.isBefore(now) && !rule.autoPost) {
              date = now.add(const Duration(minutes: 1));
            }
            for (
              var i = 0;
              i < 3 &&
                  count < 45 &&
                  (rule.end == null || !date.isAfter(rule.end!));
              i++
            ) {
              await _schedule(
                '${rule.id}:$i',
                'Recurring payment',
                'A scheduled payment is due. Open Tink to review it.',
                date,
              );
              date = nextOccurrence(rule, date);
              count++;
            }
          }
        }
        if (settings.loanNotifications) {
          for (final loan in profile.loans.where(
            (loan) => ledger.loanRemaining(loan) > 0,
          )) {
            if (count++ >= 60) break;
            final due = DateTime(
              loan.due.year,
              loan.due.month,
              loan.due.day,
              9,
            );
            await _schedule(
              loan.id,
              'Loan reminder',
              'A repayment is due. Open your private loan ledger for details.',
              due,
            );
          }
        }
        if (settings.backupReminders) {
          final last = settings.lastBackup ?? now;
          final due = last.add(const Duration(days: 7));
          await _schedule(
            'backup',
            'Keep your memories safe',
            'Make a private local backup of your Tink data.',
            due.isAfter(now) ? due : now.add(const Duration(hours: 1)),
          );
        }
        if (marks.isNotEmpty) await mark(marks);
        lastError = null;
      } catch (error) {
        lastError = 'Could not schedule a reminder: $error';
      }
    });
    _queue = work.then<void>(
      (_) {},
      onError: (Object error, StackTrace trace) {},
    );
    return work;
  }
}
