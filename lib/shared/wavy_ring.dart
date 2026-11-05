import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'reference_components.dart';

class WavyRing extends StatelessWidget {
  final double value, size;
  final Color? color;
  final Widget? child;
  const WavyRing(
    this.value, {
    super.key,
    this.size = 60,
    this.color,
    this.child,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value.clamp(0, 1) * 100).round()} percent',
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
          ),
          child: Center(child: child),
        ),
      ),
    ),
  );
}

class _WavyRingPainter extends CustomPainter {
  final double value;
  final Color color;
  _WavyRingPainter(this.value, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        radius = size.shortestSide / 2 - 4;
    final paint = Paint()
      ..color = color.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    if (value <= 0) return;
    final path = Path();
    final samples = math.max(2, (value * 180).ceil());
    for (var i = 0; i <= samples; i++) {
      final angle = i / samples * value * math.pi * 2 - math.pi / 2;
      final wave = radius + math.sin((angle + math.pi / 2) * 12) * 1.2;
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
      oldDelegate.value != value || oldDelegate.color != color;
}
