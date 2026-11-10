import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/currency.dart';
import '../../../core/money.dart';
import '../application/home_providers.dart';

/// Phase 0 placeholder home screen (themed "Hello" screen).
///
/// Later phases replace this with the dashboard (balance card, trend chart,
/// reorderable cards). Kept animation-free so `disableAnimations` is
/// trivially respected; layout uses flexible/wrapping widgets so text
/// scales to 200% without clipping.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = ref.watch(appTitleProvider);
    final Money zero = Money.zero(kDefaultCurrencyCode);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Hello',
                  style: context.text.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your offline-first expense manager',
                  style: context.text.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  label: 'Total balance ${zero.format()}',
                  child: Text(
                    zero.format(),
                    style: context.text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Get started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
