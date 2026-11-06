import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../core/data/providers.dart';
import '../core/utils/money.dart';
import 'tink_components.dart';
export '../core/theme/app_colors.dart';
export '../core/theme/app_radius.dart';
export '../core/theme/app_spacing.dart';
export '../core/theme/app_text_styles.dart';
export 'tink_components.dart';
export 'luxury_components.dart';
export 'account_artwork.dart';
export 'reference_components.dart';
export 'wavy_ring.dart';
export 'wavy_progress.dart';

IconData iconFor(String key) => switch (key) {
  'food' => Icons.restaurant_rounded,
  'groceries' => Icons.local_grocery_store_rounded,
  'transport' => Icons.directions_transit_rounded,
  'shopping' => Icons.shopping_bag_rounded,
  'bills' => Icons.bolt_rounded,
  'entertainment' => Icons.movie_rounded,
  'health' => Icons.favorite_rounded,
  'education' => Icons.school_rounded,
  'salary' => Icons.payments_rounded,
  'work' => Icons.work_rounded,
  'gift' => Icons.redeem_rounded,
  'travel' => Icons.flight_rounded,
  'cash' => Icons.account_balance_wallet_rounded,
  'bank' => Icons.account_balance_rounded,
  'savings' => Icons.savings_rounded,
  'credit card' || 'debit card' || 'card' => Icons.credit_card_rounded,
  'wallet' => Icons.wallet_rounded,
  'investment' || 'asset' => Icons.trending_up_rounded,
  'goal' => Icons.flag_rounded,
  'home' => Icons.cottage_rounded,
  'person' => Icons.person_rounded,
  'place' => Icons.location_on_rounded,
  'label' => Icons.sell_rounded,
  'loan' => Icons.handshake_rounded,
  'transfer' => Icons.swap_horiz_rounded,
  'income' => Icons.south_west_rounded,
  'expense' => Icons.north_east_rounded,
  _ => Icons.category_rounded,
};
const iconKeys = [
  'food',
  'groceries',
  'transport',
  'shopping',
  'bills',
  'entertainment',
  'health',
  'education',
  'salary',
  'work',
  'gift',
  'travel',
  'cash',
  'bank',
  'savings',
  'card',
  'asset',
  'goal',
  'home',
  'person',
  'place',
  'label',
  'loan',
];

class AmountText extends ConsumerWidget {
  final int amount;
  final String? currency;
  final TextStyle? style;
  final bool compact;
  final String prefix;
  final bool animate;
  const AmountText(
    this.amount, {
    super.key,
    this.currency,
    this.style,
    this.compact = false,
    this.prefix = '',
    this.animate = false,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider.select((data) => data.settings));
    final code =
        currency ?? ref.watch(profileProvider)?.profile.currency ?? 'INR';
    final effectiveStyle = DefaultTextStyle.of(context).style
        .merge(style)
        .copyWith(
          fontFamily: 'TinkRounded',
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    Widget render(int value) => Text(
      '${settings.hideAmounts ? '' : prefix}${money(value, code, hidden: settings.hideAmounts, indian: settings.numberFormat == 'indian', compact: compact, locale: settings.locale)}',
      style: effectiveStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (!animate ||
        settings.hideAmounts ||
        MediaQuery.disableAnimationsOf(context))
      return render(amount);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount.toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => render(value.round()),
    );
  }
}

class ColorIcon extends StatelessWidget {
  final String icon;
  final int color;
  final double size;
  const ColorIcon(this.icon, this.color, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) =>
      CategoryIcon(icon: iconFor(icon), color: Color(color), size: size);
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  final Widget? trailing;
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.onTap,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null) trailing!,
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_rounded,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    primary: false,
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: .45),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

class FeaturePage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;
  final Widget? fab;
  final Widget? bottomBar;
  final bool padded;
  const FeaturePage({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.fab,
    this.bottomBar,
    this.padded = true,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight:
          72 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: actions,
    ),
    floatingActionButton: fab,
    bottomNavigationBar: bottomBar,
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: padded
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Entrance(child: child),
              )
            : Entrance(child: child),
      ),
    ),
  );
}

class StatCard extends StatelessWidget {
  final String title;
  final Widget value;
  final IconData icon;
  final Color? color;
  final String? caption;
  final VoidCallback? onTap;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.caption,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color:
                      color ?? Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall!
                  .copyWith(fontWeight: FontWeight.w700),
              child: value is AmountText
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: value,
                    )
                  : value,
            ),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(
                caption!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Compatibility wrapper: the premium design uses a clean, rounded track.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    enabled: !MediaQuery.disableAnimationsOf(context),
    baseColor: Colors.grey.withValues(alpha: .15),
    highlightColor: Colors.grey.withValues(alpha: .06),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            height: i == 0 ? 190 : 95,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
      ],
    ),
  );
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
