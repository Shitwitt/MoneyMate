import 'package:flutter/material.dart';

import '../accounts/accounts_screen.dart';
import '../achievements/achievements_screen.dart';
import '../assets/assets_screen.dart';
import '../bills/bills_screen.dart';
import '../budgets/budgets_screen.dart';
import '../catalog/catalog_screen.dart';
import '../goals/goals_screen.dart';
import '../loans/loans_screen.dart';
import '../recurring/recurring_screen.dart';
import '../reports/analytics_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/spending_health_screen.dart';
import '../settings/backup_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/templates_screen.dart';
import '../transactions/transactions_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'net_worth_screen.dart';

/// Only allowlisted, local screens. No URL, executable route or monetary write.
Widget pageDestination(String destination) => switch (destination) {
  'home' => const HomeScreen(standalone: true),
  'accounts' => const AccountsScreen(),
  'activity' => const TransactionsScreen(),
  'search' => const TransactionsScreen(title: 'Search'),
  'plans' => const PlansScreen(),
  'reports' => const ReportsScreen(),
  'analytics' => const AnalyticsScreen(),
  'health' => const SpendingHealthScreen(),
  'budgets' => const BudgetsScreen(),
  'goals' => const GoalsScreen(),
  'loans' => const LoansScreen(),
  'recurring' => const RecurringScreen(),
  'categories' => const CatalogScreen('category'),
  'labels' => const CatalogScreen('label'),
  'people' => const CatalogScreen('person'),
  'places' => const CatalogScreen('place'),
  'assets' => const AssetsScreen(),
  'net-worth' => const NetWorthScreen(),
  'templates' => const TemplatesScreen(),
  'splitter' => const BillsScreen(),
  'achievements' => const AchievementsScreen(),
  'settings' => const SettingsScreen(),
  'backup' => const BackupScreen(),
  'more' => const MoreScreen(),
  _ => throw const FormatException('Unknown page shortcut'),
};
