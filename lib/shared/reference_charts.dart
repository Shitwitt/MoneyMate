import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/data/ledger.dart';
import '../core/data/reporting.dart';
import '../core/utils/money.dart';
import 'widgets.dart';

class ReferenceSeries {
  final String name;
  final List<double?> values;
  final Color color;
  final bool dashed, fill;
  const ReferenceSeries(
    this.name,
    this.values,
    this.color, {
    this.dashed = false,
    this.fill = false,
  });
}

/// Actual calendar-day points, not decorative/random paths. Touch selects a
/// day and exposes exact values; the same summary is readable without color.
class ReferenceLineChart extends StatefulWidget {
  final List<ReferenceSeries> series;
  final DateTime start;
  final Ledger ledger;
  final double height;
  final bool bars;
  const ReferenceLineChart({
    super.key,
    required this.series,
    required this.start,
    required this.ledger,
    this.height = 230,
    this.bars = false,
  });
  @override
  State<ReferenceLineChart> createState() => _ReferenceLineChartState();
}

class _ReferenceLineChartState extends State<ReferenceLineChart> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    if (widget.ledger.settings.hideAmounts)
      return SizedBox(
        height: widget.height,
        child: const Center(child: Icon(Icons.visibility_off_outlined)),
      );
    final count = widget.series.fold<int>(
      0,
      (n, s) => math.max(n, s.values.length),
    );
    final all = widget.series
        .expand((s) => s.values.whereType<double>())
        .toList();
    final maximum = all.fold<double>(1, math.max);
    final minimum = math.min(0.0, all.fold<double>(0, math.min));
    final high = maximum + (maximum - minimum) * .12;
    final low = minimum < 0 ? minimum - (maximum - minimum) * .06 : 0.0;
    final index = selected?.clamp(0, math.max(0, count - 1)).toInt();
    String amount(double value) => money(
      value.round(),
      widget.ledger.currency,
      compact: true,
      locale: widget.ledger.settings.locale,
      indian: widget.ledger.settings.numberFormat == 'indian',
    );
    String pointSummary(int point) =>
        '${DateFormat.yMMMd().format(DateTime(widget.start.year, widget.start.month, widget.start.day + point))}. ${widget.series.map((series) => '${series.name}: ${point < series.values.length && series.values[point] != null ? money(series.values[point]!.round(), widget.ledger.currency, locale: widget.ledger.settings.locale) : 'not recorded'}').join('. ')}';
    final nextPoint = ((index ?? -1) + 1)
        .clamp(0, math.max(0, count - 1))
        .toInt();
    final previousPoint = ((index ?? 1) - 1)
        .clamp(0, math.max(0, count - 1))
        .toInt();
    final painted = [
      for (final series in widget.series)
        ReferenceSeries(
          series.name,
          series.values,
          chartInk(series.color, Theme.of(context).colorScheme.surface),
          dashed: series.dashed,
          fill: series.fill,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (index != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${DateFormat.MMMd().format(DateTime(widget.start.year, widget.start.month, widget.start.day + index))} · ${widget.series.map((s) => '${s.name}: ${index < s.values.length && s.values[index] != null ? money(s.values[index]!.round(), widget.ledger.currency, locale: widget.ledger.settings.locale) : 'not recorded'}').join(' · ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        LayoutBuilder(
          builder: (context, box) => Semantics(
            onIncrease: count == 0 || index == count - 1
                ? null
                : () => setState(() => selected = nextPoint),
            onDecrease: count == 0 || index == 0
                ? null
                : () => setState(() => selected = previousPoint),
            value: index == null ? 'No day selected' : pointSummary(index),
            increasedValue: count == 0 ? '' : pointSummary(nextPoint),
            decreasedValue: count == 0 ? '' : pointSummary(previousPoint),
            label:
                '${widget.bars ? 'Bar' : 'Line'} chart. ${widget.series.map((s) => s.name).join(', ')}. Tap a day to inspect recorded values.',
            child: GestureDetector(
              onTapDown: (event) => setState(
                () => selected =
                    (((event.localPosition.dx - 44) /
                                math.max(1, box.maxWidth - 52)) *
                            math.max(0, count - 1))
                        .round()
                        .clamp(0, math.max(0, count - 1)),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: referenceMotion(context, 600),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => SizedBox(
                  height: widget.height,
                  child: CustomPaint(
                    painter: _ReferenceChartPainter(
                      painted,
                      low,
                      high,
                      progress,
                      Theme.of(context).colorScheme.outlineVariant
                          .withValues(alpha: .45),
                      Theme.of(context).textTheme.labelSmall!,
                      widget.start,
                      amount,
                      selected: index,
                      bars: widget.bars,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            for (final s in painted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 15,
                    height: widget.bars ? 9 : 3,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(s.name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _ReferenceChartPainter extends CustomPainter {
  final List<ReferenceSeries> series;
  final double low, high, progress;
  final Color grid;
  final TextStyle labelStyle;
  final DateTime start;
  final String Function(double) format;
  final int? selected;
  final bool bars;
  _ReferenceChartPainter(
    this.series,
    this.low,
    this.high,
    this.progress,
    this.grid,
    this.labelStyle,
    this.start,
    this.format, {
    this.selected,
    required this.bars,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTRB(44, 8, size.width - 8, size.height - 27);
    final count = series.fold<int>(1, (n, s) => math.max(n, s.values.length));
    double x(int i) => bounds.left + i / math.max(1, count - 1) * bounds.width;
    double y(double value) =>
        bounds.bottom - (value - low) / (high - low) * bounds.height;
    void text(String value, Offset point, {bool centered = false}) {
      final p = TextPainter(
        text: TextSpan(text: value, style: labelStyle.copyWith(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 42);
      p.paint(canvas, point - Offset(centered ? p.width / 2 : p.width, 0));
    }

    for (var i = 0; i <= 5; i++) {
      final value = low + (high - low) * i / 5;
      final dy = y(value);
      canvas.drawLine(
        Offset(bounds.left, dy),
        Offset(bounds.right, dy),
        Paint()
          ..color = grid
          ..strokeWidth = .7,
      );
      text(format(value), Offset(bounds.left - 6, dy - 6));
    }
    for (var i = 0; i < count; i++) {
      if (i % math.max(1, (count / 6).ceil()) == 0 || i == count - 1) {
        final day = DateTime(start.year, start.month, start.day + i).day;
        text('$day', Offset(x(i), bounds.bottom + 9), centered: true);
      }
    }
    canvas.save();
    canvas.clipRect(bounds.inflate(2));
    if (selected != null) {
      canvas.drawLine(
        Offset(x(selected!), bounds.top),
        Offset(x(selected!), bounds.bottom),
        Paint()
          ..color = grid
          ..strokeWidth = 1.5,
      );
    }
    for (var s = 0; s < series.length; s++) {
      final data = series[s];
      final path = Path();
      var started = false;
      Offset? first, last;
      for (var i = 0; i < data.values.length; i++) {
        final value = data.values[i];
        if (value == null) {
          started = false;
          continue;
        }
        final point = Offset(x(i), y(value * progress));
        if (bars) {
          final width = math.min(
            10.0,
            bounds.width / count / math.max(1, series.length) * .7,
          );
          final offset = (s - (series.length - 1) / 2) * (width + 1);
          final rect = Rect.fromLTRB(
            point.dx + offset - width / 2,
            math.min(point.dy, y(0)),
            point.dx + offset + width / 2,
            math.max(point.dy, y(0)),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()..color = data.color,
          );
        } else {
          if (!started) {
            path.moveTo(point.dx, point.dy);
            first ??= point;
          } else {
            path.lineTo(point.dx, point.dy);
          }
          started = true;
          last = point;
        }
      }
      if (!bars) {
        if (data.fill && first != null && last != null) {
          final fill = Path.from(path)
            ..lineTo(last.dx, y(0))
            ..lineTo(first.dx, y(0))
            ..close();
          canvas.drawPath(
            fill,
            Paint()..color = data.color.withValues(alpha: .14),
          );
        }
        final paint = Paint()
          ..color = data.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        if (data.dashed) {
          for (final metric in path.computeMetrics()) {
            for (var at = 0.0; at < metric.length; at += 10)
              canvas.drawPath(
                metric.extractPath(at, math.min(at + 5, metric.length)),
                paint,
              );
          }
        } else {
          canvas.drawPath(path, paint);
        }
        if (selected != null &&
            selected! < data.values.length &&
            data.values[selected!] != null) {
          canvas.drawCircle(
            Offset(x(selected!), y(data.values[selected!]! * progress)),
            4,
            Paint()..color = data.color,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ReferenceChartPainter old) => true;
}

class ReportDailyChart extends StatelessWidget {
  final ReportSnapshot snapshot;
  final bool bars;
  const ReportDailyChart(this.snapshot, {super.key, this.bars = true});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReferenceLineChart(
        ledger: snapshot.ledger,
        start: snapshot.window.start,
        bars: bars,
        series: [
          ReferenceSeries(
            'Expense',
            snapshot.daily
                .map((d) => d.future ? null : d.expense.toDouble())
                .toList(),
            const Color(0xffF45B52),
          ),
          ReferenceSeries(
            'Income',
            snapshot.daily
                .map((d) => d.future ? null : d.income.toDouble())
                .toList(),
            const Color(0xff69BD75),
          ),
        ],
      ),
      if (snapshot.window.days > 366)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Daily chart shows the first 366 days. Totals cover the full selected range.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}

class ReferenceDonut extends StatefulWidget {
  final List<ReportGroup> groups;
  final Ledger ledger;
  const ReferenceDonut(this.groups, this.ledger, {super.key});
  @override
  State<ReferenceDonut> createState() => _ReferenceDonutState();
}

class _ReferenceDonutState extends State<ReferenceDonut> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.ledger.settings.hideAmounts)
      return const SizedBox(
        height: 260,
        child: Center(child: Icon(Icons.visibility_off_outlined)),
      );
    final total = widget.groups.fold<int>(0, (s, g) => s + g.amount);
    if (total <= 0)
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Text(
          'No matching records in this selection.',
          textAlign: TextAlign.center,
        ),
      );
    final index = selected.clamp(0, widget.groups.length - 1),
        group = widget.groups[selected.clamp(0, widget.groups.length - 1)];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) => GestureDetector(
            onTapDown: (tap) {
              final center = Offset(box.maxWidth / 2, 135),
                  delta = tap.localPosition - center;
              final radius = math.min(106.0, box.maxWidth / 2 - 30);
              if (delta.distance < radius - 24 || delta.distance > radius + 24)
                return;
              final angle =
                  (math.atan2(delta.dy, delta.dx) + math.pi / 2 + math.pi * 2) %
                  (math.pi * 2);
              var cursor = 0.0;
              for (var i = 0; i < widget.groups.length; i++) {
                cursor += widget.groups[i].amount / total * math.pi * 2;
                if (angle <= cursor) {
                  setState(() => selected = i);
                  break;
                }
              }
            },
            child: Semantics(
              onIncrease: () =>
                  setState(() => selected = (index + 1) % widget.groups.length),
              onDecrease: () => setState(
                () => selected =
                    (index + widget.groups.length - 1) % widget.groups.length,
              ),
              label:
                  '${group.name}, ${(group.amount / total * 100).toStringAsFixed(1)} percent. ${money(group.amount, widget.ledger.currency)}.',
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: referenceMotion(context, 650),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => SizedBox(
                  height: 270,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      widget.groups,
                      total,
                      progress,
                      index,
                      [
                        for (final group in widget.groups)
                          chartInk(
                            Color(group.color),
                            Theme.of(context).colorScheme.surface,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${group.name} · ${(group.amount / total * 100).toStringAsFixed(1)}%',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AmountText(group.amount),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ReportGroup> groups;
  final int total, selected;
  final double progress;
  final List<Color> colors;
  _DonutPainter(
    this.groups,
    this.total,
    this.progress,
    this.selected,
    this.colors,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        radius = math.min(106.0, size.width / 2 - 30);
    var angle = -math.pi / 2;
    for (var i = 0; i < groups.length; i++) {
      final sweep = groups[i].amount / total * math.pi * 2 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        math.max(0, sweep - .012),
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == selected ? 45 : 39,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

class BudgetProgressChart extends StatelessWidget {
  final Ledger ledger;
  final BudgetStatus status;
  final List<DailyFlow> flows;
  final bool income;
  const BudgetProgressChart({
    super.key,
    required this.ledger,
    required this.status,
    required this.flows,
    required this.income,
  });
  @override
  Widget build(BuildContext context) {
    var accumulated = 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReferenceLineChart(
          ledger: ledger,
          start: status.window.start,
          series: [
            ReferenceSeries(
              income ? 'Income' : 'Expense',
              flows.map((d) {
                if (d.future) return null;
                accumulated += income ? d.income : d.expense;
                return accumulated;
              }).toList(),
              const Color(0xff32B5A5),
              fill: true,
            ),
            ReferenceSeries(
              'Ideal pace',
              List.generate(
                flows.length,
                (i) => status.limit * (i + 1) / math.max(1, status.window.days),
              ),
              const Color(0xffA49D96),
              dashed: true,
            ),
            ReferenceSeries(
              income ? 'Target' : 'Limit',
              List.filled(flows.length, status.limit.toDouble()),
              const Color(0xffFFB7A9),
              dashed: true,
            ),
          ],
        ),
        if (flows.length < status.window.days)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Daily chart shows the first 366 days. Budget totals cover the full period.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
