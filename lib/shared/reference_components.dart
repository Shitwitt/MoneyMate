import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

Duration referenceMotion(BuildContext context, [int milliseconds = 240]) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// Flat, tactile cards, not gradients or screenshot backgrounds.
class TonalCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  const TonalCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(radius),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final List<IconData>? icons;
  const PillTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.icons,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(100),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final longest = labels.fold<int>(
          0,
          (n, s) => s.length > n ? s.length : n,
        );
        final tabWidth =
            (longest * 8.0 * MediaQuery.textScalerOf(context).scale(1) + 24)
                .clamp(48.0, 400.0);
        final desired = tabWidth * labels.length;
        final width = desired > box.maxWidth ? desired : box.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == selected,
                      button: true,
                      child: AnimatedContainer(
                        duration: referenceMotion(context, 160),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: i == selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () => onSelected(i),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (icons != null) ...[
                                    Icon(icons![i], size: 19),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      labels[i],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: i == selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class SmallTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const SmallTag(this.text, {super.key, this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color?.withValues(alpha: .13) ?? scheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? scheme.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color ?? scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monday-first calendars and sheet rows use full-size, labeled touch targets.
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  const DetailRow(this.icon, this.label, this.value, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    leading: Icon(icon, size: 22),
    title: Text(label, style: Theme.of(context).textTheme.bodySmall),
    subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
  );
}

class ReferenceNavigationDock extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final Map<String, String> labels;
  final Map<String, IconData> icons;
  final bool showLabels;
  final ValueChanged<String> onSelect;
  const ReferenceNavigationDock({
    super.key,
    required this.tabs,
    required this.selected,
    required this.labels,
    required this.icons,
    required this.showLabels,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: [
            for (final id in tabs)
              Expanded(
                child: Semantics(
                  selected: selected == id,
                  button: true,
                  label: labels[id],
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onSelect(id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: referenceMotion(context, 160),
                            width: 64,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: selected == id
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              icons[id],
                              size: 23,
                              color: selected == id
                                  ? (AppColors.dark(context)
                                        ? AppColors.primary
                                        : AppColors.primaryInk)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (showLabels) ...[
                            const SizedBox(height: 5),
                            Text(
                              labels[id]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 12,
                                    letterSpacing: 0,
                                    fontWeight: selected == id
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Color readableTint(BuildContext context, Color tint) {
  final background = Theme.of(context).colorScheme.surface;
  final a = tint.computeLuminance(), b = background.computeLuminance();
  if ((a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05)) >= 4.5)
    return tint;
  return Theme.of(context).colorScheme.onSurface;
}

/// Keep plotted strokes/segments distinguishable on light, coffee, black and
/// custom surfaces. Preserve the original hue instead of replacing every pale
/// series with the same body-text color. Filled areas can remain translucent.
Color chartInk(Color color, Color background) {
  final base = Color.alphaBlend(color, background);
  final bg = background.computeLuminance();
  double contrast(Color value) {
    final luminance = value.computeLuminance();
    return luminance > bg
        ? (luminance + .05) / (bg + .05)
        : (bg + .05) / (luminance + .05);
  }

  if (contrast(base) >= 3) return base;
  final hsl = HSLColor.fromColor(base);
  final direction = bg < .179 ? 1.0 : -1.0;
  for (var step = 1; step <= 100; step++) {
    final adjusted = hsl
        .withLightness(
          (hsl.lightness + direction * step / 100).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
    if (contrast(adjusted) >= 3) return adjusted;
  }
  return bg < .179 ? Colors.white : Colors.black;
}

class SummaryColumns extends StatelessWidget {
  final List<String> labels;
  final List<Widget> values;
  const SummaryColumns({super.key, required this.labels, required this.values});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < labels.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labels[i], style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              DefaultTextStyle.merge(
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: values[i],
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

Future<void> showFeatureInfo(
  BuildContext context,
  String title,
  String body,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              tooltip: 'Close information',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  ),
);
