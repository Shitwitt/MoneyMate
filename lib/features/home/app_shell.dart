import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../shared/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/layout_screen.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String selected = 'home';
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appProvider).settings;
    final tabs = settings.navTabs;
    final active = tabs.contains(selected) ? selected : tabs.first;
    final index = tabs.indexOf(active);
    final l = AppLocalizations.of(context);
    final labels = {
      'home': l.home,
      'accounts': l.accounts,
      'transactions': l.activity,
      'plans': l.plans,
      'reports': l.reports,
      'more': l.more,
      'search': l.search,
    };
    Widget page(String id) => switch (id) {
      'home' => const HomeScreen(),
      'accounts' => const AccountsScreen(),
      'transactions' => const TransactionsScreen(),
      'search' => const TransactionsScreen(title: 'Search'),
      'plans' => const PlansScreen(),
      'reports' => const ReportsScreen(),
      _ => const MoreScreen(),
    };
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final extended = MediaQuery.sizeOf(context).width >= 1250;
    return Scaffold(
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              extended: extended,
              minExtendedWidth: 205,
              labelType: extended
                  ? null
                  : settings.navLabels
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.none,
              selectedIndex: index,
              onDestinationSelected: (index) =>
                  setState(() => selected = tabs[index]),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (extended)
                      const LuxuryWordmark(size: 36)
                    else
                      Image.asset(
                        'assets/branding/mark.png',
                        width: 40,
                        height: 40,
                      ),
                  ],
                ),
              ),
              destinations: [
                for (final id in tabs)
                  NavigationRailDestination(
                    icon: AnimatedScale(
                      scale: active == id ? 1.08 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(tabIcons[id]),
                    ),
                    label: Text(labels[id]!),
                  ),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: index,
              children: [
                for (final id in tabs)
                  KeyedSubtree(key: ValueKey(id), child: page(id)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : ReferenceNavigationDock(
              tabs: tabs,
              selected: active,
              labels: labels,
              icons: tabIcons,
              showLabels: settings.navLabels,
              onSelect: (id) => setState(() => selected = id),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openTransactionSheet(context),
        tooltip: l.addTransaction,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}
