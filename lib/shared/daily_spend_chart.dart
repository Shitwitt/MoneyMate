import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/data/ledger.dart';
import '../core/utils/dates.dart';
import 'reference_components.dart';

/// Null future days stay unknown. Every non-null point sums real expense rows.
List<int?> dailyExpenses(Ledger ledger, DateWindow window, DateTime now) {
  final values = List<int?>.generate(
    window.days,
    (index) =>
        DateTime(
          window.start.year,
          window.start.month,
          window.start.day + index,
        ).isAfter(dayOnly(now))
        ? null
        : 0,
  );
  for (final entry in ledger.data.transactions.where(
    (e) =>
        e.type == 'expense' &&
        !ledger.account(e.accountId).excluded &&
        window.contains(e.date) &&
        !e.date.isAfter(now),
  )) {
    final index = calendarDaysBetween(window.start, entry.date);
    if (index >= 0 && index < values.length && values[index] != null)
      values[index] = values[index]! + ledger.entryValue(entry);
  }
  return values;
}

class DailySpendChart extends StatelessWidget {
  final Ledger ledger;
  final DateWindow window;
  final DateTime now;
  final bool cumulative;
  final Color color;
  const DailySpendChart({
    super.key,
    required this.ledger,
    required this.window,
    required this.now,
    required this.color,
    this.cumulative = false,
  });
  @override
  Widget build(BuildContext context) {
    if (ledger.settings.hideAmounts)
      return const SizedBox(
        height: 94,
        child: Center(child: Icon(Icons.visibility_off_outlined)),
      );
    final values = dailyExpenses(ledger, window, now);
    if (cumulative) {
      var total = 0;
      final running = values.map((v) {
        if (v == null) return null;
        total += v;
        return total;
      }).toList();
      return Semantics(
        label:
            'Cumulative recorded expenses over ${window.days} calendar days. Future dates are not plotted.',
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: referenceMotion(context, 500),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => SizedBox(
            height: 94,
            child: CustomPaint(
              painter: _CumulativePainter(running, color, progress),
              size: Size.infinite,
            ),
          ),
        ),
      );
    }
    final maximum = values.whereType<int>().fold<int>(1, math.max);
    return Semantics(
      label: 'Daily recorded expenses. Empty outlines are future days, not a prediction.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 88,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: referenceMotion(context, 500),
                        curve: Curves.easeOutCubic,
                        height: values[i] == null || values[i] == 0
                            ? 8
                            : 12 + values[i]! / maximum * 76,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: values[i] == null ? Colors.transparent : color,
                          border: values[i] == null
                              ? Border.all(color: color.withValues(alpha: .25))
                              : null,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat.E()
                        .format(
                          DateTime(
                            window.start.year,
                            window.start.month,
                            window.start.day + i,
                          ),
                        )
                        .substring(0, 1),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CumulativePainter extends CustomPainter {
  final List<int?> values;
  final Color color;
  final double progress;
  _CumulativePainter(this.values, this.color, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    final maximum = values.whereType<int>().fold<int>(1, math.max);
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) break;
      points.add(
        Offset(
          i / math.max(1, values.length - 1) * size.width,
          size.height - 3 - v / maximum * (size.height - 8) * progress,
        ),
      );
    }
    if (points.isEmpty) return;
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: .18));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CumulativePainter old) =>
      old.values != values || old.color != color || old.progress != progress;
}
