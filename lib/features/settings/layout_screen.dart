import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/utils/constants.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';

const tabLabels = {
  'home': 'Home',
  'accounts': 'Accounts',
  'transactions': 'Activity',
  'plans': 'Plans',
  'reports': 'Reports',
  'more': 'More',
};
const tabIcons = {
  'home': Icons.space_dashboard_rounded,
  'accounts': Icons.account_balance_wallet_rounded,
  'transactions': Icons.receipt_long_rounded,
  'plans': Icons.donut_large_rounded,
  'reports': Icons.insert_chart_outlined_rounded,
  'more': Icons.grid_view_rounded,
};

class LayoutScreen extends ConsumerWidget {
  const LayoutScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    final controller = ref.read(appProvider.notifier);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('A home that feels like yours'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Home cards'),
              Tab(text: 'Navigation'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReorderableListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: settings.homeCards.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final cards = [...settings.homeCards];
                cards.insert(newIndex, cards.removeAt(oldIndex));
                runSafe(
                  context,
                  () =>
                      controller.settings((s) => s.copyWith(homeCards: cards)),
                );
              },
              itemBuilder: (context, index) {
                final id = settings.homeCards[index];
                return Padding(
                  key: ValueKey(id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.fromLTRB(18, 8, 48, 8),
                      title: Text(homeCardNames[id]!),
                      subtitle: const Text('Drag the handle to move this card'),
                      value: !settings.hiddenCards.contains(id),
                      onChanged: (value) => runSafe(
                        context,
                        () => controller.settings(
                          (s) => s.copyWith(
                            hiddenCards: value
                                ? s.hiddenCards
                                      .where((item) => item != id)
                                      .toList()
                                : {...s.hiddenCards, id}.toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SectionHeader('Live preview'),
                Card(
                  child: NavigationBar(
                    labelBehavior: settings.navLabels
                        ? NavigationDestinationLabelBehavior.alwaysShow
                        : NavigationDestinationLabelBehavior.alwaysHide,
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    destinations: [
                      for (final id in settings.navTabs)
                        NavigationDestination(
                          icon: Icon(tabIcons[id]),
                          label: tabLabels[id]!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: SwitchListTile.adaptive(
                    title: const Text('Show labels'),
                    value: settings.navLabels,
                    onChanged: (value) => runSafe(
                      context,
                      () => controller.settings(
                        (s) => s.copyWith(navLabels: value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Keep 3–5 tabs, including More. Everything is still available from More.',
                ),
                const SizedBox(height: 12),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: settings.navTabs.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    final tabs = [...settings.navTabs];
                    tabs.insert(newIndex, tabs.removeAt(oldIndex));
                    runSafe(
                      context,
                      () =>
                          controller.settings((s) => s.copyWith(navTabs: tabs)),
                    );
                  },
                  itemBuilder: (context, index) {
                    final id = settings.navTabs[index];
                    return ListTile(
                      key: ValueKey(id),
                      leading: Icon(tabIcons[id]),
                      title: Text(tabLabels[id]!),
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: 25),
                        child: IconButton(
                          tooltip: 'Hide ${tabLabels[id]} tab',
                          onPressed:
                              id == 'more' || settings.navTabs.length <= 3
                              ? null
                              : () => runSafe(
                                  context,
                                  () => controller.settings(
                                    (s) => s.copyWith(
                                      navTabs: s.navTabs
                                          .where((tab) => tab != id)
                                          .toList(),
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                      ),
                    );
                  },
                ),
                for (final id in tabLabels.keys.where(
                  (id) => !settings.navTabs.contains(id),
                ))
                  ListTile(
                    leading: Icon(tabIcons[id]),
                    title: Text(tabLabels[id]!),
                    trailing: IconButton(
                      tooltip: 'Add tab',
                      onPressed: settings.navTabs.length >= 5
                          ? null
                          : () => runSafe(
                              context,
                              () => controller.settings(
                                (s) => s.copyWith(navTabs: [...s.navTabs, id]),
                              ),
                            ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
