import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'reference_components.dart';

class WavyRing extends StatelessWidget {
  final double value, size, strokeWidth;
  final Color? color;
  final String? semanticsLabel;
  final Widget? child;
  const WavyRing(
    this.value, {
    super.key,
    this.size = 60,
    this.strokeWidth = 3.5,
    this.color,
    this.semanticsLabel,
    this.child,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    value: semanticsLabel ?? '${(value * 100).round()} percent of target',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: referenceMotion(context, 500),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _WavyRingPainter(
            progress,
            color ?? Theme.of(context).colorScheme.primary,
            strokeWidth,
          ),
          child: Center(child: child),
        ),
      ),
    ),
  );
}

class _WavyRingPainter extends CustomPainter {
  final double value, strokeWidth;
  final Color color;
  _WavyRingPainter(this.value, this.color, this.strokeWidth);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        waveSize = strokeWidth * .28,
        radius = size.shortestSide / 2 - strokeWidth / 2 - waveSize - 1;
    final paint = Paint()
      ..color = color.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    if (value <= 0) return;
    final path = Path();
    final samples = math.max(2, (value * 180).ceil());
    for (var i = 0; i <= samples; i++) {
      final angle = i / samples * value * math.pi * 2 - math.pi / 2;
      final wave =
          radius +
          math.sin((angle + math.pi / 2) * 12 + value * math.pi * 2) * waveSize;
      final point =
          center + Offset(math.cos(angle) * wave, math.sin(angle) * wave);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint..color = color);
  }

  @override
  bool shouldRepaint(_WavyRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
