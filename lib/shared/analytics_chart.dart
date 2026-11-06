import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data/ledger.dart';
import '../core/utils/money.dart';
import 'widgets.dart';

/// Six-month, seven-day, weekday and category-sparkline renderer. All points are
/// supplied ledger values; bounded midpoint Beziers cannot invent negative dips.
class AnalyticsChart extends StatefulWidget {
  final List<int> values;
  final List<String> labels;
  final Ledger ledger;
  final bool bars, curved, small;
  final Color? color;
  const AnalyticsChart({
    super.key,
    required this.values,
    required this.labels,
    required this.ledger,
    this.bars = false,
    this.curved = false,
    this.small = false,
    this.color,
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
    final ink = chartInk(
      widget.color ?? Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.surface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) => Semantics(
            label: widget.bars
                ? 'Recorded spending bar chart'
                : 'Recorded spending line chart',
            value: index == null
                ? widget.values
                      .asMap()
                      .entries
                      .map((e) => '${widget.labels[e.key]}: ${amount(e.value)}')
                      .join('. ')
                : '${widget.labels[index]}: ${amount(widget.values[index])}',
            onIncrease: () => setState(
              () => selected = ((index ?? -1) + 1)
                  .clamp(0, widget.values.length - 1)
                  .toInt(),
            ),
            onDecrease: () => setState(
              () => selected = ((index ?? 1) - 1)
                  .clamp(0, widget.values.length - 1)
                  .toInt(),
            ),
            child: GestureDetector(
              onTapDown: (event) => setState(
                () => selected =
                    ((event.localPosition.dx - (widget.small ? 0 : 42)) /
                            math.max(
                              1,
                              box.maxWidth - (widget.small ? 0 : 48),
                            ) *
                            (widget.values.length - 1))
                        .round()
                        .clamp(0, widget.values.length - 1)
                        .toInt(),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: referenceMotion(context, 600),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => SizedBox(
                  height: widget.small ? 36 : 220,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!widget.small)
          Row(
            children: [
              IconButton(
                tooltip: 'Previous chart point',
                onPressed: index == 0
                    ? null
                    : () => setState(
                        () => selected = ((index ?? 1) - 1)
                            .clamp(0, widget.values.length - 1)
                            .toInt(),
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: index == null
                    ? const Text(
                        'Tap a point or use arrows',
                        textAlign: TextAlign.center,
                      )
                    : Column(
                        children: [
                          Text(
                            widget.labels[index],
                            textAlign: TextAlign.center,
                          ),
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
                    : () => setState(
                        () => selected = ((index ?? -1) + 1)
                            .clamp(0, widget.values.length - 1)
                            .toInt(),
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class _AnalyticsPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final Color color, grid;
  final TextStyle textStyle;
  final double progress;
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
  );
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      small ? 2 : 42,
      small ? 2 : 12,
      size.width - 6,
      size.height - (small ? 2 : 28),
    );
    if (rect.width <= 0 || rect.height <= 0) return;
    final high = values.fold<int>(1, math.max) * 1.12;
    Offset point(int i) => Offset(
      rect.left +
          (bars
                  ? (i + .5) / values.length
                  : i / math.max(1, values.length - 1)) *
              rect.width,
      rect.bottom - values[i] / high * rect.height * progress,
    );
    void label(String text, Offset at, {bool center = false}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: textStyle.copyWith(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 42);
      painter.paint(
        canvas,
        at - Offset(center ? painter.width / 2 : painter.width, 0),
      );
    }

    if (!small) {
      for (var i = 0; i < 5; i++) {
        final y = rect.bottom - i / 4 * rect.height;
        canvas.drawLine(
          Offset(rect.left, y),
          Offset(rect.right, y),
          Paint()
            ..color = grid.withValues(alpha: .35)
            ..strokeWidth = .7,
        );
        if (!bars) label(format(high * i / 4), Offset(rect.left - 6, y - 6));
      }
      for (var i = 0; i < labels.length; i++)
        label(labels[i], Offset(point(i).dx, rect.bottom + 10), center: true);
    }
    canvas.save();
    canvas.clipRect(rect.inflate(3));
    if (bars) {
      for (var i = 0; i < values.length; i++) {
        final p = point(i), width = rect.width / values.length * .6;
        if (values[i] == 0) {
          canvas.drawCircle(
            Offset(p.dx, rect.bottom),
            2,
            Paint()..color = color.withValues(alpha: .4),
          );
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              p.dx - width / 2,
              p.dy,
              p.dx + width / 2,
              rect.bottom,
            ),
            Radius.circular(width / 2),
          ),
          Paint()
            ..color = color.withValues(
              alpha: selected == null || selected == i ? 1 : .55,
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
          ..lineTo(point(values.length - 1).dx, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
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
      for (var i = 0; i < values.length; i++)
        if (curved || selected == i) {
          canvas.drawCircle(
            point(i),
            selected == i ? 5 : 3.5,
            Paint()..color = color,
          );
          canvas.drawCircle(point(i), 2, Paint()..color = Colors.white);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnalyticsPainter old) => true;
}
