import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// A single, finite foil sweep. Never loops or intercepts content gestures.
class ShineSurface extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final Color? color;
  final double radius;
  final Color? glow;
  final Object? shineKey;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const ShineSurface({
    super.key,
    required this.child,
    this.colors,
    this.color,
    this.radius = 28,
    this.glow,
    this.shineKey,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  State<ShineSurface> createState() => _ShineSurfaceState();
}

class _ShineSurfaceState extends State<ShineSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      sweep.value = 1;
    } else if (!started) {
      started = true;
      sweep.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ShineSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shineKey != widget.shineKey &&
        !MediaQuery.disableAnimationsOf(context)) {
      sweep.forward(from: 0);
    }
  }

  @override
  void dispose() {
    sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = widget.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: (widget.glow ?? Colors.black).withValues(
              alpha: widget.glow == null ? (dark ? .10 : .055) : .18,
            ),
            blurRadius: widget.glow == null ? 24 : 30,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Material(
          color: widget.color ?? Theme.of(context).colorScheme.surface,
          child: Ink(
            decoration: BoxDecoration(
              gradient: colors == null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? .09 : .60),
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Padding(padding: widget.padding, child: widget.child),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: sweep,
                        builder: (_, _) => CustomPaint(
                          painter: _FoilPainter(sweep.value, dark ? .09 : .20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoilPainter extends CustomPainter {
  final double progress, opacity;
  _FoilPainter(this.progress, this.opacity);
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final x = -size.width + progress * size.width * 3;
    final rect = Rect.fromLTWH(
      x - size.width * .25,
      0,
      size.width * .5,
      size.height,
    );
    canvas.save();
    canvas.transform(Matrix4.skewX(-.3).storage);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FoilPainter old) =>
      old.progress != progress || old.opacity != opacity;
}

class LuxuryWordmark extends StatelessWidget {
  final double size;
  const LuxuryWordmark({super.key, this.size = 42});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tink',
    header: true,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/branding/mark.png',
                width: size,
                height: size,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Tink',
            style: AppTextStyles.display(
              size + 5,
              Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Customizable destinations are kept intact; only their presentation changes.
class GlassNavigationDock extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final Map<String, String> labels;
  final Map<String, IconData> icons;
  final bool showLabels;
  final ValueChanged<String> onSelect;
  const GlassNavigationDock({
    super.key,
    required this.tabs,
    required this.selected,
    required this.labels,
    required this.icons,
    required this.onSelect,
    this.showLabels = true,
  });
  @override
  Widget build(BuildContext context) {
    final main = tabs.where((id) => id != 'more').toList();
    final hasMore = tabs.contains('more');
    final dark = AppColors.dark(context);
    final surface = dark ? const Color(0xff2B2B32) : const Color(0xffE7E6EA);
    Widget item(String id, {bool more = false}) {
      final active = id == selected;
      final ink = active
          ? Colors.white
          : Theme.of(context).colorScheme.onSurface;
      return Semantics(
        button: true,
        selected: active,
        label: labels[id],
        onTap: () => onSelect(id),
        child: ExcludeSemantics(
          child: Tooltip(
            message: labels[id]!,
            child: AnimatedScale(
              scale: active ? 1 : .96,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              child: ShineSurface(
                shineKey: active,
                radius: 100,
                padding: EdgeInsets.zero,
                glow: active ? const Color(0xffFF7F45) : null,
                colors: active
                    ? const [
                        Color(0xffB5421C),
                        Color(0xff932811),
                        Color(0xffAA3518),
                      ]
                    : [
                        surface.withValues(alpha: .35),
                        surface.withValues(alpha: .12),
                      ],
                onTap: () => onSelect(id),
                child: SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          more ? Icons.more_vert_rounded : icons[id],
                          color: ink,
                          size: more ? 29 : 24,
                        ),
                        if (showLabels) ...[
                          const SizedBox(height: 3),
                          Text(
                            labels[id]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.data(
                              12,
                              active ? FontWeight.w700 : FontWeight.w500,
                              ink,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: surface.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: dark ? .2 : .85),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final id in main) Expanded(child: item(id)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (hasMore) ...[
              const SizedBox(width: 8),
              SizedBox(width: 68, child: item('more', more: true)),
            ],
          ],
        ),
      ),
    );
  }
}

class SegmentedDistribution extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  const SegmentedDistribution({
    super.key,
    required this.values,
    required this.colors,
  });
  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + math.max(0, b));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 28,
        child: total <= 0
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              )
            : Row(
                children: [
                  for (var i = 0; i < values.length; i++)
                    if (values[i] > 0)
                      Expanded(
                        flex: math.max(1, (values[i] / total * 10000).round()),
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(end: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.lerp(
                                  colors[i % colors.length],
                                  Colors.white,
                                  .25,
                                )!,
                                colors[i % colors.length],
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
