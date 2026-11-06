import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data/ledger.dart';
import '../core/utils/money.dart';
import 'widgets.dart';

/// Uses exactly the painter's geometry. Bars occupy equal-width bins, while
/// line points include both endpoints. This also supports very narrow charts.
int chartPointIndex(
  double x,
  double width,
  int count, {
  bool bars = false,
  bool small = false,
}) {
  if (count <= 1) return 0;
  final left = small ? 2.0 : 42.0, right = width - 6;
  final f = ((x - left) / math.max(1, right - left)).clamp(0.0, 1.0);
  return (bars ? (f * count).floor() : (f * (count - 1)).round())
      .clamp(0, count - 1)
      .toInt();
}

/// Actual ledger points with signed bounds and a zero baseline. Hold and drag,
/// tap, screen-reader adjustment or the arrows reveal the same exact values.
class AnalyticsChart extends StatefulWidget {
  final List<int> values;
  final List<String> labels, pointLabels;
  final Ledger ledger;
  final bool bars, curved, small;
  final Color? color;
  final String label;
  final ValueChanged<int>? onOpenPoint;
  const AnalyticsChart({
    super.key,
    required this.values,
    required this.labels,
    required this.ledger,
    this.bars = false,
    this.curved = false,
    this.small = false,
    this.color,
    this.pointLabels = const [],
    this.label = 'Recorded spending',
    this.onOpenPoint,
  });
  @override
  State<AnalyticsChart> createState() => _AnalyticsChartState();
}

class _AnalyticsChartState extends State<AnalyticsChart> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    if (widget.ledger.settings.hideAmounts)
      return SizedBox(
        height: widget.small ? 36 : 150,
        child: const Center(child: Icon(Icons.visibility_off_outlined)),
      );
    if (widget.values.isEmpty)
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No recorded points')),
      );
    final index = selected?.clamp(0, widget.values.length - 1).toInt();
    String amount(int value) => money(
      value,
      widget.ledger.currency,
      locale: widget.ledger.settings.locale,
      indian: widget.ledger.settings.numberFormat == 'indian',
    );
    String label(int i) => i < widget.pointLabels.length
        ? widget.pointLabels[i]
        : i < widget.labels.length
        ? widget.labels[i]
        : 'Point ${i + 1}';
    String summary(int i) => '${label(i)}: ${amount(widget.values[i])}';
    String change(int i) {
      if (i == 0) return 'First recorded point; no previous-point comparison.';
      final prior = widget.values[i - 1], delta = widget.values[i] - prior;
      return 'Change versus previous point: ${amount(delta)}. ${prior <= 0 ? 'Percentage unavailable for a zero or negative baseline.' : '${delta >= 0 ? '+' : ''}${(delta / prior * 100).toStringAsFixed(1)}%.'}';
    }

    final next = ((index ?? -1) + 1).clamp(0, widget.values.length - 1).toInt();
    final previous = ((index ?? 1) - 1)
        .clamp(0, widget.values.length - 1)
        .toInt();
    final ink = chartInk(
      widget.color ?? Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.surface,
    );
    final scale = MediaQuery.textScalerOf(context)
        .scale(1)
        .clamp(1.0, 1.6)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            void select(Offset point) => setState(
              () => selected = chartPointIndex(
                point.dx,
                box.maxWidth,
                widget.values.length,
                bars: widget.bars,
                small: widget.small,
              ),
            );
            return Semantics(
              label: '${widget.label} ${widget.bars ? 'bar' : 'line'} chart',
              value: index == null
                  ? List.generate(widget.values.length, summary).join('. ')
                  : summary(index),
              increasedValue: summary(next),
              decreasedValue: summary(previous),
              onIncrease: index == widget.values.length - 1
                  ? null
                  : () => setState(() => selected = next),
              onDecrease: index == 0
                  ? null
                  : () => setState(() => selected = previous),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (e) => select(e.localPosition),
                onLongPressStart: (e) => select(e.localPosition),
                onLongPressMoveUpdate: (e) => select(e.localPosition),
                onHorizontalDragUpdate: (e) => select(e.localPosition),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(
                    '${widget.values.join(",")}/${widget.bars}/${widget.curved}',
                  ),
                  tween: Tween(begin: 0, end: 1),
                  duration: referenceMotion(context, 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => SizedBox(
                    height: widget.small ? 36 : 220 * scale,
                    child: CustomPaint(
                      painter: _AnalyticsPainter(
                        widget.values,
                        widget.labels,
                        ink,
                        Theme.of(context).colorScheme.outlineVariant,
                        Theme.of(context).textTheme.labelSmall!,
                        progress,
                        widget.bars,
                        widget.curved,
                        widget.small,
                        index,
                        (v) => money(
                          v.round(),
                          widget.ledger.currency,
                          compact: true,
                          locale: widget.ledger.settings.locale,
                          indian:
                              widget.ledger.settings.numberFormat == 'indian',
                        ),
                        scale,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (!widget.small)
          Row(
            children: [
              IconButton(
                tooltip: 'Previous chart point',
                onPressed: index == 0
                    ? null
                    : () => setState(() => selected = previous),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: index == null
                    ? const Text(
                        'Hold and drag, tap, or use arrows',
                        textAlign: TextAlign.center,
                      )
                    : Column(
                        children: [
                          Text(label(index), textAlign: TextAlign.center),
                          AmountText(
                            widget.values[index],
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
              IconButton(
                tooltip: 'Next chart point',
                onPressed: index == widget.values.length - 1
                    ? null
                    : () => setState(() => selected = next),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        if (index != null) ...[
          if (widget.small)
            Text(summary(index), style: Theme.of(context).textTheme.labelSmall),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              change(index),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (widget.onOpenPoint != null)
            TextButton.icon(
              onPressed: () => widget.onOpenPoint!(index),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('See matching records'),
            ),
        ],
      ],
    );
  }
}

class _AnalyticsPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final Color color, grid;
  final TextStyle textStyle;
  final double progress, scale;
  final bool bars, curved, small;
  final int? selected;
  final String Function(double) format;
  _AnalyticsPainter(
    this.values,
    this.labels,
    this.color,
    this.grid,
    this.textStyle,
    this.progress,
    this.bars,
    this.curved,
    this.small,
    this.selected,
    this.format,
    this.scale,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      small ? 2 : 42,
      small ? 2 : 12,
      size.width - 6,
      size.height - (small ? 2 : 32 * scale),
    );
    if (rect.width <= 0 || rect.height <= 0) return;
    var low = math.min(0, values.reduce(math.min)).toDouble(),
        high = math.max(0, values.reduce(math.max)).toDouble();
    final span = math.max(1.0, high - low);
    if (low < 0) low -= span * .08;
    if (high > 0) high += span * .12;
    if (high == low) high = low + 1;
    double y(double value) =>
        rect.bottom - (value - low) / (high - low) * rect.height;
    final zero = y(0);
    Offset point(int i) => Offset(
      rect.left +
          (bars
                  ? (i + .5) / values.length
                  : i / math.max(1, values.length - 1)) *
              rect.width,
      zero + (y(values[i].toDouble()) - zero) * progress,
    );
    void label(
      String text,
      Offset at, {
      bool center = false,
      double width = 42,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(fontSize: 10 * scale),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: width);
      final dx = (at.dx - (center ? painter.width / 2 : painter.width))
          .clamp(0.0, math.max(0.0, size.width - painter.width))
          .toDouble();
      painter.paint(canvas, Offset(dx, at.dy));
    }

    if (!small) {
      for (var i = 0; i < 5; i++) {
        final value = low + (high - low) * i / 4, position = y(value);
        canvas.drawLine(
          Offset(rect.left, position),
          Offset(rect.right, position),
          Paint()
            ..color = grid.withValues(alpha: .35)
            ..strokeWidth = .7,
        );
        label(format(value), Offset(rect.left - 5, position - 6 * scale));
      }
      canvas.drawLine(
        Offset(rect.left, zero),
        Offset(rect.right, zero),
        Paint()
          ..color = grid
          ..strokeWidth = 1.2,
      );
      final maxLabels = math.max(2, (rect.width / (48 * scale)).floor());
      final stride = math.max(1, (values.length / maxLabels).ceil());
      var last = -stride;
      for (var i = 0; i < math.min(labels.length, values.length); i++) {
        if (i % stride != 0 && i != values.length - 1) continue;
        if (i == values.length - 1 && i - last < stride * .65) continue;
        label(
          labels[i],
          Offset(point(i).dx, rect.bottom + 10),
          center: true,
          width: 48 * scale,
        );
        last = i;
      }
    }
    canvas.save();
    canvas.clipRect(rect.inflate(3));
    if (selected != null)
      canvas.drawLine(
        Offset(point(selected!).dx, rect.top),
        Offset(point(selected!).dx, rect.bottom),
        Paint()
          ..color = color.withValues(alpha: .4)
          ..strokeWidth = 1,
      );
    if (bars) {
      for (var i = 0; i < values.length; i++) {
        final p = point(i), width = rect.width / values.length * .6;
        if (values[i] == 0) {
          canvas.drawCircle(
            Offset(p.dx, zero),
            2,
            Paint()..color = color.withValues(alpha: .4),
          );
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              p.dx - width / 2,
              math.min(p.dy, zero),
              p.dx + width / 2,
              math.max(p.dy, zero),
            ),
            Radius.circular(width / 2),
          ),
          Paint()
            ..color = color.withValues(
              alpha: selected == null || selected == i ? 1 : .5,
            ),
        );
      }
    } else {
      final path = Path()..moveTo(point(0).dx, point(0).dy);
      for (var i = 1; i < values.length; i++) {
        final a = point(i - 1), b = point(i);
        if (curved) {
          final middle = (a.dx + b.dx) / 2;
          path.cubicTo(middle, a.dy, middle, b.dy, b.dx, b.dy);
        } else {
          path.lineTo(b.dx, b.dy);
        }
      }
      if (!small) {
        final area = Path.from(path)
          ..lineTo(point(values.length - 1).dx, zero)
          ..lineTo(rect.left, zero)
          ..close();
        canvas.drawPath(area, Paint()..color = color.withValues(alpha: .12));
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = small ? 2 : 2.5
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      for (var i = 0; i < values.length; i++) {
        if (curved || selected == i) {
          canvas.drawCircle(
            point(i),
            selected == i ? 5 : 3.5,
            Paint()..color = color,
          );
          canvas.drawCircle(point(i), 2, Paint()..color = Colors.white);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnalyticsPainter old) => true;
}
