import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'reference_components.dart';

/// Finite, reduced-motion-aware progress drawn as a wave, not a gradient bar.
class WavyProgress extends StatelessWidget {
  final double value;
  final Color? color;
  const WavyProgress(this.value, {super.key, this.color});
  @override
  Widget build(BuildContext context) {
    final progress = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final ink = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Progress',
      value: '${(progress * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: referenceMotion(context, 500),
        curve: Curves.easeOutCubic,
        builder: (context, amount, _) => SizedBox(
          height: 12,
          width: double.infinity,
          child: CustomPaint(
            painter: _WavePainter(
              amount,
              ink,
              Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool rtl;
  _WavePainter(this.progress, this.color, this.rtl);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final path = Path();
    final steps = math.max(1, (size.width / 2).ceil());
    for (var i = 0; i <= steps; i++) {
      final x = i / steps * size.width;
      final y = size.height / 2 + math.sin(x / 14 * math.pi * 2) * 1.7;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..color = color.withValues(alpha: .18);
    canvas.drawPath(path, paint);
    if (progress <= 0) return;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        rtl ? size.width * (1 - progress) : 0,
        0,
        size.width * progress,
        size.height,
      ),
    );
    canvas.drawPath(path, paint..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.color != color || old.rtl != rtl;
}
