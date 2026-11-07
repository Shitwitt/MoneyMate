import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/transaction_model.dart';
import '../providers/paisa_provider.dart';
import '../widgets/avatar_view.dart';
import 'accounts/accounts_screen.dart';
import 'budgets/budgets_screen.dart';
import 'debts/debts_screen.dart';
import 'home/home_screen.dart';
import 'overview/overview_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/add_transaction_screen.dart';

/// Root scaffold: sticky app bar, five destinations and the container-transform
/// FAB that opens [AddTransactionScreen].
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const Duration _fabTransition = Duration(milliseconds: 420);

  int _index = 0;

  // Kept alive across tab switches so scroll offsets and in-progress filters
  // survive; the pages themselves are cheap, the providers hold the data.
  final List<Widget> _pages = const <Widget>[
    HomeScreen(),
    AccountsScreen(),
    OverviewScreen(),
    DebtsScreen(),
    BudgetsScreen(),
  ];

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _push(context, const SettingsScreen()),
              child: PaisaAvatarView(
                avatarIndex: provider.userAvatarIndex,
                imagePath: provider.customImagePath,
                size: 42,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _greeting(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Welcome back, ${provider.greetingName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            onPressed: () => _push(context, const SearchScreen()),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Profile & settings',
            onPressed: () => _push(context, const SettingsScreen()),
            icon: Icon(
              provider.hasCustomAvatar
                  ? Icons.manage_accounts_outlined
                  : Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          for (int i = 0; i < _pages.length; i++)
            KeyedSubtree(
              key: PageStorageKey<String>('tab-$i'),
              child: _pages[i],
            ),
        ],
      ),
      floatingActionButton: OpenContainer<Object?>(
        transitionDuration: _fabTransition,
        closedElevation: 6,
        closedShape: const StadiumBorder(),
        closedColor: scheme.primary,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return SizedBox(
            width: 60,
            height: 60,
            child: Icon(
              Icons.add_rounded,
              color: scheme.onPrimary,
              size: 30,
            ),
          );
        },
        // The scrim lets the container grow into a full page while the shell
        // stays visible behind the transition.
        openColor: scheme.surface,
        middleColor: scheme.primaryContainer,
        openShape: const RoundedRectangleBorder(),
        // The typed contract is `Widget Function(BuildContext,
        // CloseContainerActionCallback<Object?>)`. The route is popped by the
        // form itself (`Navigator.pop(draft)`), so the action is not used here
        // beyond satisfying the signature.
        openBuilder: (
          BuildContext context,
          CloseContainerActionCallback<Object?> closeContainer,
        ) {
          return const AddTransactionScreen();
        },
        onClosed: (Object? result) {
          // `AddTransactionScreen` pops with the saved model, or `null` when the
          // user backs out; only the former deserves a confirmation.
          if (result is TransactionModel && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('“${result.name}” saved'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: const Icon(Icons.donut_large_outlined),
            selectedIcon: const Icon(Icons.donut_large_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: const Icon(Icons.handshake_outlined),
            selectedIcon: const Icon(Icons.handshake_rounded),
            label: 'Debts',
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: const Icon(Icons.pie_chart_rounded),
            label: 'Budgets',
          ),
        ],
      ),
    );
  }

  /// Mirrors `Paisa`'s time-of-day greeting above the user's name.
  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (BuildContext _) => page),
    );
  }
}
