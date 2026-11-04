import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../data/ledger.dart';
import '../models/models.dart';
import '../utils/money.dart';

class WidgetService {
  String? lastError;
  Future<void> sync(AppData app) async {
    if (kIsWeb || app.profiles.isEmpty) return;
    try {
      final profile = app.profiles.firstWhere((item) => item.profile.id == app.activeProfileId);
      final ledger = Ledger(profile, app.settings);
      final hidden = app.settings.hideAmounts || app.settings.lockMode != 'none';
      await HomeWidget.setAppGroupId('group.com.example.paisaclone');
      await HomeWidget.saveWidgetData<String>('balance', money(ledger.netWorth, profile.profile.currency, hidden: hidden, indian: app.settings.numberFormat == 'indian'));
      await HomeWidget.saveWidgetData<String>('profile', profile.profile.name);
      final status = profile.budgets.isEmpty ? null : ledger.budgetStatus(profile.budgets.first, DateTime.now());
      await HomeWidget.saveWidgetData<String>('budget', status == null ? 'Create a budget' : hidden ? '••••' : '${(status.progress * 100).round()}% used');
      await HomeWidget.saveWidgetData<int>('budgetPercent', hidden ? 0 : ((status?.progress ?? 0) * 100).round().clamp(0, 100));
      await HomeWidget.saveWidgetData<String>('budgetName', profile.budgets.firstOrNull?.name ?? 'Your next good habit');
      await HomeWidget.updateWidget(androidName: 'BalanceWidget', iOSName: 'BalanceWidget');
      await HomeWidget.updateWidget(androidName: 'BudgetWidget', iOSName: 'BudgetWidget');
      await HomeWidget.updateWidget(androidName: 'QuickAddWidget', iOSName: 'QuickAddWidget');
      lastError = null;
    } catch (error) { lastError = 'Widgets need platform setup: $error'; }
  }
}
