import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';

/// Declarative routes (blueprint section 3).
///
/// Phase 0 ships the root route only; later phases add the full tree
/// (`/onboarding`, `/lock`, `/transactions`, `/analytics`, `/budgets`,
/// `/more`, `/settings`, ...). Deep links use the `moneymanager://`
/// scheme declared in the Android manifest, e.g.
/// `moneymanager://add?amount=50&category=food`.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
  ],
);
