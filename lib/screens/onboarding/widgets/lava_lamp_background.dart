import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The animated "lava lamp" backdrop used on the welcome page.
///
/// Three large tonal blobs drift on independent paths, blend with
/// [BlendMode.plus] and are drawn behind a subtle noise-free gradient. Colours
/// come from the active Material 3 scheme (`primaryContainer`,
/// `secondaryContainer`, `tertiaryContainer`), so it re-tints itself with
/// dynamic colour and never fights the theme.
///
/// The animation is a single [AnimationController] + [CustomPainter] — no image
/// assets, no third-party packages — and it honours `MediaQuery.disableAnimations`
/// (and therefore the OS "remove animations" accessibility setting) by painting
/// a static frame.
class LavaLampBackground extends StatefulWidget {
  const LavaLampBackground({
    super.key,
    required this.child,
    this.blobCount = 3,
    this.speed = 1.0,
    this.opacity = 0.85,
  });

  final Widget child;

  /// How many drifting blobs to paint (2–5 looks best).
  final int blobCount;

  /// Multiplier on the drift speed. `1.0` ≈ 18 s per full cycle.
  final double speed;

  /// Overall strength of the blobs against the surface colour.
  final double opacity;

  @override
  State<LavaLampBackground> createState() => _LavaLampBackgroundState();
}

class _LavaLampBackgroundState extends State<LavaLampBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (18000 / (widget.speed <= 0 ? 1 : widget.speed)).round(),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final List<Color> colors = <Color>[
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
      scheme.primary,
      scheme.tertiary,
    ];

    final Widget painted = reduceMotion
        ? CustomPaint(
            painter: _LavaPainter(
              progress: 0.25,
              colors: colors,
              blobCount: widget.blobCount,
              opacity: widget.opacity,
            ),
            child: const SizedBox.expand(),
          )
        : AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                painter: _LavaPainter(
                  progress: _controller.value,
                  colors: colors,
                  blobCount: widget.blobCount,
                  opacity: widget.opacity,
                ),
                child: child,
              );
            },
            child: const SizedBox.expand(),
          );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: scheme.surface),
        RepaintBoundary(child: painted),
        // A gentle vertical scrim keeps body text legible over the blobs.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                scheme.surface.withAlpha(30),
                scheme.surface.withAlpha(150),
                scheme.surface.withAlpha(235),
              ],
              stops: const <double>[0.0, 0.55, 1.0],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _LavaPainter extends CustomPainter {
  const _LavaPainter({
    required this.progress,
    required this.colors,
    required this.blobCount,
    required this.opacity,
  });

  final double progress;
  final List<Color> colors;
  final int blobCount;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress * 2 * math.pi;
    final Paint paint = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);

    for (int i = 0; i < blobCount; i++) {
      final double phase = i * (2 * math.pi / blobCount);
      final double orbitX = size.width * 0.30;
      final double orbitY = size.height * 0.22;

      final double x = size.width / 2 +
          math.sin(t + phase) * orbitX +
          math.cos(t * 0.5 + phase) * size.width * 0.08;
      final double y = size.height * 0.42 +
          math.cos(t * 0.85 + phase * 1.7) * orbitY +
          math.sin(t * 0.4 + phase) * size.height * 0.06;

      final double radius =
          size.shortestSide * (0.30 + 0.07 * math.sin(t * 0.6 + phase * 2));

      final Color color = colors[i % colors.length]
          .withAlpha((70 * opacity).round().clamp(0, 255));
      paint.color = color;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // A soft highlight in the top-left corner anchors the composition.
    final Paint highlight = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)
      ..color = colors.first.withAlpha((40 * opacity).round().clamp(0, 255));
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.12),
      size.shortestSide * 0.32,
      highlight,
    );
  }

  @override
  bool shouldRepaint(_LavaPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colors != colors ||
      oldDelegate.blobCount != blobCount ||
      oldDelegate.opacity != opacity;
}

/// The MoneyMate wordmark: a rounded "coin" glyph plus the app name.
class PaisaLogo extends StatelessWidget {
  const PaisaLogo({
    super.key,
    this.size = 88,
    this.showWordmark = true,
  });

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget coin = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.alphaBlend(scheme.tertiary.withAlpha(150), scheme.primary),
          ],
        ),
      ),
      child: Icon(
        Icons.currency_rupee_rounded,
        size: size * 0.52,
        color: scheme.onPrimary,
      ),
    );

    if (!showWordmark) return coin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        coin,
        SizedBox(height: size * 0.18),
        Text(
          'MoneyMate',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
