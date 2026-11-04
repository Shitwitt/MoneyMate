import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'notification_service.dart';
import 'widget_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());
final widgetServiceProvider = Provider((ref) => WidgetService());
final unlockedProvider = StateProvider<bool>(
  (ref) =>
      ref.watch(appProvider.select((app) => app.settings.lockMode)) == 'none',
);
