import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/data/financial_pulse.dart';
import '../core/data/ledger.dart';
import '../core/models/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/dates.dart';
import 'luxury_components.dart';

class FinancialPulsePanel extends StatefulWidget {
  final Ledger ledger;
  final bool expanded;
  const FinancialPulsePanel(this.ledger, {super.key, this.expanded = false});
  @override
  State<FinancialPulsePanel> createState() => _FinancialPulsePanelState();
}

class _FinancialPulsePanelState extends State<FinancialPulsePanel> {
  bool? open;
  @override
  Widget build(BuildContext context) {
    final pulse = FinancialPulse.fromLedger(widget.ledger, DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    final expanded = open ?? widget.expanded;
    if (widget.ledger.settings.hideAmounts) {
      return const ShineSurface(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Icon(Icons.visibility_off_outlined),
          ),
        ),
      );
    }
    return ShineSurface(
      glow: scheme.primary,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your financial pulse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'How financial pulse is calculated',
                icon: const Icon(Icons.info_outline_rounded, size: 21),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A lens, not a verdict.',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'A local planning estimate from your own records. Not a credit score, financial advice, a bank assessment or an evaluation of insurance or retirement readiness. Unrecorded finances are unknown. The overall value is the equal mean of available indicators, requiring at least two.',
                        ),
                        for (final m in pulse.metrics) ...[
                          const SizedBox(height: 20),
                          Text(
                            m.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(m.explanation),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Semantics(
            label: pulse.score == null
                ? 'Financial pulse unavailable. Add more records.'
                : 'Financial pulse ${pulse.score} out of 100. ${pulse.status}. Local estimate.',
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (pulse.score ?? 0) / 100),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  height: 165,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value,
                      scheme.primary,
                      scheme.outlineVariant,
                    ),
                    child: Align(
                      alignment: const Alignment(0, .65),
                      child: Text(
                        pulse.score == null ? '—' : '${(value * 100).round()}',
                        style: AppTextStyles.display(64, scheme.onSurface),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            pulse.status,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'Your records. A little perspective.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => open = !expanded),
            icon: Icon(expanded ? Icons.expand_less : Icons.radar_rounded),
            label: Text(
              expanded ? 'A quieter view' : 'Explore the five indicators',
            ),
          ),
          if (expanded) ...[
            Semantics(
              label: pulse.metrics
                  .map(
                    (m) => '${m.label}: ${m.value?.round() ?? 'unavailable'}',
                  )
                  .join('. '),
              child: ExcludeSemantics(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => SizedBox(
                    height:
                        320 *
                        MediaQuery.textScalerOf(context)
                            .scale(1)
                            .clamp(1.0, 1.4),
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _RadarPainter(
                        pulse.metrics,
                        progress,
                        scheme.onSurface,
                        scheme.outlineVariant,
                        MediaQuery.textScalerOf(context).scale(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final m in pulse.metrics)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Expanded(child: Text(m.label)),
                    Text(
                      m.value == null
                          ? 'Not enough records'
                          : '${m.value!.round()} / 100',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Available indicators only · Planning estimate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color, track;
  _GaugePainter(this.value, this.color, this.track);
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width * .43, size.height * .82);
    final center = Offset(size.width / 2, size.height * .88);
    final rect = Rect.fromCircle(center: center, radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      p..color = track.withValues(alpha: .3),
    );
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * value,
      false,
      p
        ..color = color.withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
    p.maskFilter = null;
    p.shader = SweepGradient(
      startAngle: math.pi,
      endAngle: math.pi * 2,
      colors: [color.withValues(alpha: .18), color, const Color(0xffD6C9FF)],
      transform: const GradientRotation(0),
    ).createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi * value, false, p);
    p.shader = null;
    for (var i = 0; i <= 20; i++) {
      final angle = math.pi + math.pi * i / 20;
      final a = center + Offset(math.cos(angle), math.sin(angle)) * (r - 12);
      final b =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (r - (i % 5 == 0 ? 23 : 18));
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = track
          ..strokeWidth = 1.2,
      );
    }
    if (value > 0) {
      final angle = math.pi + math.pi * value;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * (r - 29),
        center + Offset(math.cos(angle), math.sin(angle)) * (r + 8),
        Paint()
          ..color = color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color || old.track != track;
}

class _RadarPainter extends CustomPainter {
  final List<PulseMetric> metrics;
  final double progress, fontSize;
  final Color ink, divider;
  _RadarPainter(
    this.metrics,
    this.progress,
    this.ink,
    this.divider,
    this.fontSize,
  );
  static const colors = [
    Color(0xff34C984),
    Color(0xffE4CC34),
    Color(0xffA58BFF),
    Color(0xff3DC9DC),
    Color(0xff5A8FFF),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width * .31, size.height * .31);
    Offset point(int i, double ratio) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      return center + Offset(math.cos(a), math.sin(a)) * r * ratio;
    }

    for (final level in [.25, .5, .75, 1.0]) {
      final path = Path();
      for (var i = 0; i < 5; i++) {
        final p = point(i, level);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path..close(),
        Paint()
          ..color = divider.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    final points = [
      for (var i = 0; i < 5; i++)
        point(i, (metrics[i].value ?? 0) / 100 * progress),
    ];
    final shape = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < 5; i++) {
      final a = Offset.lerp(points[i], center, .25)!,
          b = Offset.lerp(points[(i + 1) % 5], center, .25)!,
          end = points[(i + 1) % 5];
      shape.cubicTo(a.dx, a.dy, b.dx, b.dy, end.dx, end.dy);
    }
    shape.close();
    final shader = const SweepGradient(
      colors: [
        Color(0xffD4EB48),
        Color(0xff9C7BFF),
        Color(0xff36CCE2),
        Color(0xff23C897),
        Color(0xffD4EB48),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawPath(
      shape,
      Paint()
        ..color = const Color(0xff916CFF).withValues(alpha: .25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 17),
    );
    canvas.drawPath(shape, Paint()..shader = shader);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        center,
        point(i, 1),
        Paint()..color = divider.withValues(alpha: .3),
      );
      if (metrics[i].value != null)
        canvas.drawCircle(points[i], 5, Paint()..color = colors[i]);
      final text = TextPainter(
        text: TextSpan(
          text: '${metrics[i].label}\n${metrics[i].value?.round() ?? '—'}',
          style: AppTextStyles.data(fontSize, FontWeight.w500, ink),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 95);
      final pos = point(i, 1.36);
      text.paint(
        canvas,
        Offset(
          (pos.dx - text.width / 2).clamp(0.0, size.width - text.width),
          (pos.dy - text.height / 2).clamp(0.0, size.height - text.height),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress ||
      old.metrics != metrics ||
      old.ink != ink ||
      old.fontSize != fontSize;
}

class ActivityHeatmap extends StatefulWidget {
  final List<MoneyTransaction> entries;
  final DateTime? anchor;
  const ActivityHeatmap(this.entries, {super.key, this.anchor});
  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  DateTime? selected;
  @override
  Widget build(BuildContext context) {
    final today = dayOnly(widget.anchor ?? DateTime.now());
    final end = DateTime(
      today.year,
      today.month,
      today.day + 7 - today.weekday,
    );
    final start = DateTime(end.year, end.month, end.day - 90);
    final counts = <DateTime, int>{};
    for (final entry in widget.entries.where(
      (e) => !dayOnly(e.date).isAfter(today),
    )) {
      final day = dayOnly(entry.date);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    final maximum = counts.values.fold<int>(1, math.max);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xffFE6C90) : const Color(0xff8E3160);
    final focus = selected ?? today;
    return ShineSurface(
      colors: dark
          ? const [Color(0xff361A26), Color(0xff1E1B24)]
          : const [Color(0xffFBEDF2), Color(0xffF6F1F7)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A little, often.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Your entry rhythm · 13 weeks',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 18,
                  child: Column(
                    children: [
                      for (final name in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                        SizedBox(
                          height: (constraints.maxWidth - 22) / 13,
                          child: Center(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var week = 0; week < 13; week++)
                        Expanded(
                          child: Column(
                            children: [
                              for (var day = 0; day < 7; day++)
                                Builder(
                                  builder: (context) {
                                    final date = DateTime(
                                      start.year,
                                      start.month,
                                      start.day + week * 7 + day,
                                    );
                                    final value = counts[date] ?? 0;
                                    final future = date.isAfter(today);
                                    return AspectRatio(
                                      aspectRatio: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(1.8),
                                        child: Tooltip(
                                          message:
                                              '${DateFormat.yMMMd().format(date)} · $value entries',
                                          child: InkWell(
                                            onTap: future
                                                ? null
                                                : () => setState(
                                                    () => selected = date,
                                                  ),
                                            child: AnimatedContainer(
                                              duration:
                                                  MediaQuery.disableAnimationsOf(
                                                    context,
                                                  )
                                                  ? Duration.zero
                                                  : const Duration(
                                                      milliseconds: 180,
                                                    ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color: future
                                                    ? Colors.transparent
                                                    : value == 0
                                                    ? accent.withValues(
                                                        alpha: .07,
                                                      )
                                                    : accent.withValues(
                                                        alpha:
                                                            .25 +
                                                            .75 *
                                                                value /
                                                                maximum,
                                                      ),
                                                border: date == selected
                                                    ? Border.all(
                                                        color: accent,
                                                        width: 2,
                                                      )
                                                    : null,
                                                boxShadow: value == maximum
                                                    ? [
                                                        BoxShadow(
                                                          color: accent
                                                              .withValues(
                                                                alpha: .18,
                                                              ),
                                                          blurRadius: 7,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${DateFormat.yMMMd().format(focus)} · ${counts[focus] ?? 0} entries',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous day',
                onPressed: () => setState(
                  () => selected = DateTime(
                    focus.year,
                    focus.month,
                    focus.day - 1,
                  ),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${DateFormat.MMMd().format(start)} — ${DateFormat.MMMd().format(today)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: focus.isBefore(today)
                    ? () => setState(
                        () => selected = DateTime(
                          focus.year,
                          focus.month,
                          focus.day + 1,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
