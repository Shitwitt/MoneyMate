import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/data/ledger.dart';
import '../core/models/models.dart';
import '../core/utils/dates.dart';
import '../core/utils/money.dart';
import 'widgets.dart';

class TrendChart extends StatelessWidget {
  final Ledger ledger;
  final bool line;
  final int months;
  final DateTime? anchor;
  const TrendChart(
    this.ledger, {
    super.key,
    this.line = false,
    this.months = 6,
    this.anchor,
  });
  @override
  Widget build(BuildContext context) {
    if (ledger.settings.hideAmounts) {
      return const SizedBox(
        height: 210,
        child: Center(child: Icon(Icons.visibility_off_rounded)),
      );
    }
    final now = anchor ?? DateTime.now();
    final windows = monthlyWindows(now, ledger.settings.monthStart, months);
    final income = windows
        .map(
          (window) =>
              fromMinor(ledger.total('income', window), ledger.currency),
        )
        .toList();
    final expense = windows
        .map(
          (window) =>
              fromMinor(ledger.total('expense', window), ledger.currency),
        )
        .toList();
    final maxValue = [...income, ...expense].fold<double>(0, math.max);
    final primary = AppColors.semantic(context, 'income');
    final secondary = AppColors.semantic(context, 'expense');
    final titles = FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) =>
              value.toInt() >= 0 && value.toInt() < windows.length
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    DateFormat.MMM(ledger.settings.locale)
                        .format(windows[value.toInt()].start),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
    Widget chart(double progress) => line
        ? LineChart(
            LineChartData(
              minY: 0,
              maxY: math.max(1, maxValue * 1.2),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: .55),
                  strokeWidth: .8,
                  dashArray: [3, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: titles,
              lineBarsData: [
                for (var series = 0; series < 2; series++)
                  LineChartBarData(
                    spots: List.generate(
                      months,
                      (index) => FlSpot(
                        index.toDouble(),
                        (series == 0 ? income : expense)[index] * progress,
                      ),
                    ),
                    isCurved: true,
                    color: series == 0 ? primary : secondary,
                    barWidth: 3,
                    shadow: Shadow(
                      color: (series == 0 ? primary : secondary).withValues(
                        alpha: .3,
                      ),
                      blurRadius: 10,
                    ),
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (series == 0 ? primary : secondary).withValues(
                        alpha: .07,
                      ),
                    ),
                  ),
              ],
            ),
          )
        : BarChart(
            BarChartData(
              maxY: math.max(1, maxValue * 1.2),
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: .55),
                  strokeWidth: .8,
                  dashArray: [3, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: titles,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, index, rod, rodIndex) => BarTooltipItem(
                    '${rodIndex == 0 ? 'Income' : 'Expense'}\n${money(toMinor(rod.toY, ledger.currency), ledger.currency, indian: ledger.settings.numberFormat == 'indian')}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'SourceSerif4',
                    ),
                  ),
                ),
              ),
              barGroups: List.generate(
                months,
                (index) => BarChartGroupData(
                  x: index,
                  barsSpace: 5,
                  barRods: [
                    BarChartRodData(
                      toY: income[index] * progress,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(primary, Colors.white, .22)!,
                          primary.withValues(alpha: .65),
                        ],
                      ),
                      width: 13,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    BarChartRodData(
                      toY: expense[index] * progress,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(secondary, Colors.white, .18)!,
                          secondary.withValues(alpha: .65),
                        ],
                      ),
                      width: 13,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
            ),
          );
    return Column(
      children: [
        Semantics(
          label:
              'Income and expense chart, $months financial months. Income ${money(windows.fold<int>(0, (sum, w) => sum + ledger.total('income', w)), ledger.currency)}. Expenses ${money(windows.fold<int>(0, (sum, w) => sum + ledger.total('expense', w)), ledger.currency)}.',
          child: ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => SizedBox(
                height: 200,
                child: line
                    ? ChartReveal(progress: value, child: chart(1))
                    : chart(value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(context, primary, 'Income'),
            const SizedBox(width: 24),
            _legend(context, secondary, 'Expenses'),
          ],
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class CategoryChart extends StatefulWidget {
  final Ledger ledger;
  final List<MoneyTransaction> entries;
  const CategoryChart(this.ledger, this.entries, {super.key});
  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  int touched = -1;
  bool petals = true;
  final plotKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    if (widget.ledger.settings.hideAmounts)
      return const SizedBox(
        height: 180,
        child: Center(child: Icon(Icons.visibility_off_rounded)),
      );
    final breakdown = widget.ledger
        .breakdown(widget.entries, 'category')
        .entries
        .toList();
    if (breakdown.isEmpty)
      return const EmptyState(
        title: 'Your story starts here',
        message: 'Add some transactions to see the bigger picture.',
        icon: Icons.filter_vintage_outlined,
      );
    final total = breakdown.fold<int>(0, (sum, e) => sum + e.value);
    final values = breakdown.take(6).toList();
    if (breakdown.length > 6)
      values.add(
        MapEntry(
          'Other categories',
          breakdown.skip(6).fold(0, (s, e) => s + e.value),
        ),
      );
    const colors = [
      Color(0xffA78BFA),
      Color(0xffC6D860),
      Color(0xff7ABED4),
      Color(0xffE1AB83),
      Color(0xffD693BF),
      Color(0xff8EAC91),
      Color(0xff9595B5),
    ];
    final active = touched >= 0 && touched < values.length ? touched : -1;
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Petals'),
              selected: petals,
              onSelected: (_) => setState(() => petals = true),
            ),
            ChoiceChip(
              label: const Text('Allocation'),
              selected: !petals,
              onSelected: (_) => setState(() => petals = false),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (petals)
          Semantics(
            label: 'Category flower. Petals compare relative category sizes; exact amounts and percentages follow below.',
            child: ExcludeSemantics(
              child: GestureDetector(
                onTapUp: (details) {
                  final box =
                      plotKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final delta =
                      details.localPosition -
                      Offset(box.size.width / 2, box.size.height / 2);
                  final angle =
                      (math.atan2(delta.dy, delta.dx) +
                          math.pi / 2 +
                          math.pi * 2) %
                      (math.pi * 2);
                  setState(
                    () => touched =
                        ((angle + math.pi / values.length) /
                                (math.pi * 2) *
                                values.length)
                            .floor() %
                        values.length,
                  );
                },
                child: SizedBox.square(
                  key: plotKey,
                  dimension: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => CustomPaint(
                          size: const Size(280, 280),
                          painter: _PetalPainter(
                            [for (final e in values) e.value.toDouble()],
                            colors,
                            value,
                            active,
                            Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: const [
                            BoxShadow(color: Color(0x09000000), blurRadius: 18),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  active < 0 ? 'Total' : values[active].key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                AmountText(
                                  active < 0 ? total : values[active].value,
                                  compact: true,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          SegmentedDistribution(
            values: [for (final e in values) e.value.toDouble()],
            colors: colors,
          ),
          const SizedBox(height: 20),
          AmountText(total, style: Theme.of(context).textTheme.headlineLarge),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < values.length; i++)
          InkWell(
            onTap: () => setState(() => touched = touched == i ? -1 : i),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: active == i
                    ? colors[i].withValues(alpha: .12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      values[i].key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmountText(
                        values[i].value,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        '${(values[i].value / total * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PetalPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;
  final int active;
  final Color surface;
  _PetalPainter(
    this.values,
    this.colors,
    this.progress,
    this.active,
    this.surface,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxValue = values.fold<double>(1, math.max);
    final base = size.shortestSide * .47;
    final sector = math.pi * 2 / values.length;
    Offset point(double a, double r) =>
        center + Offset(math.cos(a), math.sin(a)) * r;
    for (var i = 0; i < values.length; i++) {
      final a = -math.pi / 2 + i * sector;
      final r = base * math.sqrt(values[i] / maxValue) * progress;
      final left = point(a - sector * .43, 22),
          right = point(a + sector * .43, 22);
      final tip = point(a, r),
          c1 = point(a - sector * .48, r),
          c2 = point(a + sector * .48, r);
      final p = Path()
        ..moveTo(left.dx, left.dy)
        ..cubicTo(c1.dx, c1.dy, c1.dx, c1.dy, tip.dx, tip.dy)
        ..cubicTo(c2.dx, c2.dy, c2.dx, c2.dy, right.dx, right.dy)
        ..close();
      final color = colors[i];
      if (active == i)
        canvas.drawPath(
          p,
          Paint()
            ..color = color.withValues(alpha: .35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, .30)!, color],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) =>
      old.values != values ||
      old.progress != progress ||
      old.active != active ||
      old.surface != surface;
}
