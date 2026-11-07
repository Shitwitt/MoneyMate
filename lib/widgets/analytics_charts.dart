import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/enum/filter_enums.dart';
import '../core/theme/paisa_colors.dart';
import '../core/theme/paisa_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_time_format.dart';
import '../data/models/analytics_models.dart';

/// Shared chrome for the four analytics charts: a titled card with an optional
/// caption and a fixed-height plot area.
class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Small colour key used under the line and bar charts.
class ChartLegendDot extends StatelessWidget {
  const ChartLegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The "nothing to plot yet" panel used by every chart, so an empty ledger
/// still looks intentional instead of showing four blank axes.
class ChartEmptyState extends StatelessWidget {
  const ChartEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.height = 150,
  });

  final IconData icon;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: scheme.onSurfaceVariant, size: 24),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CHART 1 — Income vs expense, curved lines with gradient area fill
// ---------------------------------------------------------------------------

/// Interactive income/expense [LineChart].
///
/// * Two curved series (`isCurved` + `preventCurveOverShooting`) so a single
///   big day never balloons the curve past the axis.
/// * A vertical gradient fill under each line anchors the series to the
///   baseline without hiding the grid.
/// * Tooltips list the bucket's date and both formatted amounts; the touched
///   spot grows a ring so the finger never covers the value it is reading.
class IncomeExpenseLineChart extends StatelessWidget {
  const IncomeExpenseLineChart({
    super.key,
    required this.points,
    required this.formatter,
    required this.showIncome,
    required this.showExpense,
  });

  /// Buckets from the provider — days for short windows, months for long ones.
  final List<FlowPoint> points;

  final CurrencyFormatter formatter;

  /// Whether the type filter wants each series drawn.
  final bool showIncome;
  final bool showExpense;

  /// How many x-axis labels are printed at most, so a 30-day month does not
  /// turn its axis into a smear.
  static const int _maxAxisLabels = 7;

  @override
  Widget build(BuildContext context) {
    final PaisaColors colors = PaisaColors.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    double maxY = 0;
    for (final FlowPoint point in points) {
      if (showIncome) maxY = math.max(maxY, point.income);
      if (showExpense) maxY = math.max(maxY, point.expense);
    }
    // Headroom so the peak never touches the top edge of the plot.
    final double topY = maxY <= 0 ? 100 : maxY * 1.18;
    final double labelInterval = _axisInterval(topY);

    return SizedBox(
      height: 224,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, points.length - 1).toDouble(),
          minY: 0,
          maxY: topY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: labelInterval,
            getDrawingHorizontalLine: (double value) => FlLine(
              color: colors.chartGrid,
              strokeWidth: 1,
              dashArray: const <int>[4, 6],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: labelInterval,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(
                      formatter.compact(value),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: _bottomInterval(),
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Only print every nth label on dense windows.
                  if (_bottomInterval() > 1 && index % _bottomInterval() != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      points[index].label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchSpotThreshold: 24,
            getTouchedSpotIndicator: (
              LineChartBarData barData,
              List<int> spotIndexes,
            ) {
              return spotIndexes.map((int index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: barData.color?.withOpacity(0.45) ?? colors.neutral,
                    strokeWidth: 1.4,
                    dashArray: const <int>[4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (
                      FlSpot spot,
                      double percent,
                      LineChartBarData data,
                      int i,
                    ) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: data.color ?? colors.neutral,
                        strokeWidth: 2.5,
                        strokeColor: scheme.surfaceContainerLow,
                      );
                    },
                  ),
                );
              }).toList(growable: false);
            },
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 200,
              tooltipRoundedRadius: 14,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              getTooltipColor: (LineBarSpot spot) => scheme.inverseSurface,
              getTooltipItems: (List<LineBarSpot> touched) {
                return touched.map((LineBarSpot spot) {
                  final int index = spot.x.round();
                  final FlowPoint? point =
                      index >= 0 && index < points.length
                          ? points[index]
                          : null;
                  // The expense series is always appended after the income
                  // series, so the bar index alone decides which it is.
                  final bool isIncome = showIncome && spot.barIndex == 0;
                  final Color accent =
                      isIncome ? colors.income : colors.expense;
                  final String when = point == null
                      ? ''
                      : point.monthBucket
                          ? DateTimeFormat.monthYear(point.date)
                          : DateTimeFormat.weekdayDate(point.date);
                  final String amount = formatter.format(spot.y);
                  return LineTooltipItem(
                    '$when\n',
                    TextStyle(
                      color: scheme.onInverseSurface.withOpacity(0.82),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: isIncome ? 'Received ' : 'Spent ',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: amount,
                        style: TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false);
              },
            ),
          ),
          lineBarsData: <LineChartBarData>[
            if (showIncome)
              _series(
                values: <double>[
                  for (final FlowPoint point in points) point.income,
                ],
                color: colors.income,
                surface: scheme.surfaceContainerLow,
              ),
            if (showExpense)
              _series(
                values: <double>[
                  for (final FlowPoint point in points) point.expense,
                ],
                color: colors.expense,
                surface: scheme.surfaceContainerLow,
              ),
          ],
        ),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  LineChartBarData _series({
    required List<double> values,
    required Color color,
    required Color surface,
  }) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.22,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.6,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (FlSpot spot, LineChartBarData bar) {
          // One dot per point is noise on a month; mark the peaks instead.
          final double peak = values.isEmpty
              ? 0
              : values.reduce((double a, double b) => a > b ? a : b);
          return values.length <= 7 || (spot.y > 0 && spot.y >= peak);
        },
        getDotPainter: (
          FlSpot spot,
          double percent,
          LineChartBarData bar,
          int index,
        ) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 2,
            strokeColor: surface,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withOpacity(0.28),
            color.withOpacity(0.03),
          ],
        ),
      ),
    );
  }

  /// Round y-axis grid interval that keeps 3–5 lines on screen.
  double _axisInterval(double topY) {
    if (topY <= 0) return 100;
    final double raw = topY / 4;
    final double magnitude = math.pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final double normalized = raw / magnitude;
    final double step = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return math.max(1, step * magnitude);
  }

  /// Prints at most [_maxAxisLabels] labels across the window.
  int _bottomInterval() =>
      points.length <= _maxAxisLabels
          ? 1
          : (points.length / _maxAxisLabels).ceil();
}

// ---------------------------------------------------------------------------
// CHART 2 — Category donut with a tappable, expanding slice
// ---------------------------------------------------------------------------

/// The interactive category donut.
///
/// Tapping a slice grows it (`radius: isTouched ? 70 : 58`) and swaps the hole
/// label to that category's name and share; tapping the hole again clears the
/// selection. The centre label is a real widget (not painter text) so it can
/// animate and respect `hideAmounts`.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.slices,
    required this.formatter,
    required this.touchedIndex,
    required this.onTouch,
  });

  final List<CategorySlice> slices;

  final CurrencyFormatter formatter;

  /// Index of the expanded slice, `-1` when the chart is at rest.
  final int touchedIndex;

  /// Reports the newly touched index (or `-1` to clear).
  final ValueChanged<int> onTouch;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double total = slices.fold<double>(
      0,
      (double sum, CategorySlice slice) => sum + slice.amount,
    );
    final bool hasSelection =
        touchedIndex >= 0 && touchedIndex < slices.length;
    final CategorySlice? selected = hasSelection ? slices[touchedIndex] : null;

    return SizedBox(
      height: 216,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 62,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                  final int index =
                      response?.touchedSection?.touchedSectionIndex ?? -1;
                  if (event is FlTapUpEvent || event is FlPointerHoverEvent) {
                    onTouch(index);
                  } else if (event is FlPointerExitEvent) {
                    onTouch(-1);
                  }
                },
              ),
              sections: <PieChartSectionData>[
                for (int i = 0; i < slices.length; i++)
                  _section(
                    slice: slices[i],
                    color: _sliceColor(slices[i], i),
                    isTouched: i == touchedIndex,
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (selected == null) ...<Widget>[
                  Text(
                    'Total',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatter.compact(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ] else ...<Widget>[
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Color(selected.colorValue).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      IconData(
                        selected.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                      size: 15,
                      color: Color(selected.colorValue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 88,
                    child: Text(
                      selected.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatter.percent(selected.share),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Color(selected.colorValue),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section({
    required CategorySlice slice,
    required Color color,
    required bool isTouched,
  }) {
    return PieChartSectionData(
      value: math.max(slice.amount, 0),
      color: color,
      radius: isTouched ? 70 : 58,
      showTitle: slice.share >= 0.07,
      title: formatter.percent(slice.share),
      titleStyle: TextStyle(
        fontSize: isTouched ? 12 : 10.5,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.2,
        shadows: const <Shadow>[
          Shadow(color: Color(0x33000000), blurRadius: 3),
        ],
      ),
      badgePositionPercentageOffset: 1.25,
    );
  }

  /// Category colours are user-editable, so two categories can share a hue.
  /// Slight lightness shifts keep adjacent slices distinguishable.
  Color _sliceColor(CategorySlice slice, int index) {
    final Color base = Color(slice.colorValue);
    if (index == 0) return base;
    final double shift = (index % 3) * 0.06;
    final HSLColor hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + (index.isEven ? shift : -shift))
            .clamp(0.24, 0.74))
        .toColor();
  }
}

// ---------------------------------------------------------------------------
// CHART 3 — Grouped monthly income vs expense bars
// ---------------------------------------------------------------------------

/// Grouped bar chart of the last 6 or 12 months.
///
/// Each group holds an income rod and an expense rod side by side, both
/// gradient-filled, with rounded tops and a full-width tooltip that states the
/// month and both amounts.
class MonthlyFlowBarChart extends StatelessWidget {
  const MonthlyFlowBarChart({
    super.key,
    required this.flows,
    required this.formatter,
    required this.showIncome,
    required this.showExpense,
    required this.touchedGroup,
    required this.onTouchGroup,
  });

  final List<MonthlyFlow> flows;
  final CurrencyFormatter formatter;
  final bool showIncome;
  final bool showExpense;

  /// Currently highlighted group index, `-1` for none.
  final int touchedGroup;

  final ValueChanged<int> onTouchGroup;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    double maxY = 0;
    for (final MonthlyFlow flow in flows) {
      if (showIncome) maxY = math.max(maxY, flow.income);
      if (showExpense) maxY = math.max(maxY, flow.expense);
    }
    final double topY = maxY <= 0 ? 100 : maxY * 1.15;
    final double interval = _axisInterval(topY);

    return SizedBox(
      height: 214,
      child: BarChart(
        BarChartData(
          maxY: topY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: 12,
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              final int index = response?.spot?.touchedBarGroupIndex ?? -1;
              if (event is FlTapUpEvent || event is FlPointerHoverEvent) {
                onTouchGroup(index);
              } else if (event is FlPointerExitEvent) {
                onTouchGroup(-1);
              }
            },
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 190,
              tooltipRoundedRadius: 14,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              getTooltipColor: (BarChartGroupData group) => scheme.inverseSurface,
              getTooltipItem: (
                BarChartGroupData group,
                int groupIndex,
                BarChartRodData rod,
                int rodIndex,
              ) {
                if (groupIndex < 0 || groupIndex >= flows.length) return null;
                final MonthlyFlow flow = flows[groupIndex];
                final bool incomeRod = rodIndex == 0;
                final double value = incomeRod ? flow.income : flow.expense;
                final Color accent = incomeRod ? colors.income : colors.expense;
                return BarTooltipItem(
                  '${DateTimeFormat.monthYear(flow.month)}\n',
                  TextStyle(
                    color: scheme.onInverseSurface.withOpacity(0.82),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: incomeRod ? 'Received  ' : 'Spent  ',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: formatter.format(value),
                      style: TextStyle(
                        color: scheme.onInverseSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: interval,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(
                      formatter.compact(value),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= flows.length) {
                    return const SizedBox.shrink();
                  }
                  final bool active = index == touchedGroup;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      flows[index].label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (double value) => FlLine(
              color: colors.chartGrid,
              strokeWidth: 1,
              dashArray: const <int>[4, 6],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: <BarChartGroupData>[
            for (int i = 0; i < flows.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: <BarChartRodData>[
                  if (showIncome)
                    _rod(
                      value: flows[i].income,
                      color: colors.income,
                      dimmed: touchedGroup >= 0 && touchedGroup != i,
                    ),
                  if (showExpense)
                    _rod(
                      value: flows[i].expense,
                      color: colors.expense,
                      dimmed: touchedGroup >= 0 && touchedGroup != i,
                    ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  BarChartRodData _rod({
    required double value,
    required Color color,
    required bool dimmed,
  }) {
    final Color base = dimmed ? color.withOpacity(0.35) : color;
    return BarChartRodData(
      toY: value,
      width: flows.length > 8 ? 8 : 12,
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: <Color>[base.withOpacity(0.55), base],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
    );
  }

  double _axisInterval(double topY) {
    if (topY <= 0) return 100;
    final double raw = topY / 3;
    final double magnitude = math.pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final double normalized = raw / magnitude;
    final double step = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return math.max(1, step * magnitude);
  }
}

// ---------------------------------------------------------------------------
// CHART 4 — Account distribution, one horizontal stacked bar
// ---------------------------------------------------------------------------

/// A single 100%-wide stacked bar broken into one segment per account, drawn
/// with animated flex so the segments grow into place when the filter changes.
class AccountDistributionBar extends StatelessWidget {
  const AccountDistributionBar({
    super.key,
    required this.shares,
    required this.formatter,
  });

  final List<AccountShare> shares;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    // Flex weights must be integers ≥ 1, so tiny shares still get a sliver.
    final List<int> weights = <int>[
      for (final AccountShare share in shares) math.max(1, (share.share * 1000).round()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 26,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < shares.length; i++)
                  Expanded(
                    flex: weights[i],
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == shares.length - 1 ? 0 : 2,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 260 + i * 45),
                        curve: Curves.easeOutCubic,
                        builder: (
                          BuildContext context,
                          double value,
                          Widget? child,
                        ) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: child,
                          );
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(shares[i].colorValue),
                                Color.lerp(
                                      Color(shares[i].colorValue),
                                      colors.shadow,
                                      0.22,
                                    ) ??
                                    Color(shares[i].colorValue),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Ranked breakdown list with a mini progress bar per account.
        for (int i = 0; i < shares.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(shares[i].colorValue).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    shares[i].type.icon,
                    size: 17,
                    color: Color(shares[i].colorValue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              shares[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatter.formatWhole(shares[i].amount),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: shares[i].share.clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor:
                                    scheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(shares[i].colorValue),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 38,
                            child: Text(
                              formatter.percent(shares[i].share),
                              textAlign: TextAlign.right,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The `Cash 42% · Bank 51% · Cards 7%` caption under the account bar.
class AccountTypeCaption extends StatelessWidget {
  const AccountTypeCaption({
    super.key,
    required this.shares,
    required this.formatter,
  });

  final List<AccountTypeShare> shares;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<AccountTypeShare> visible = shares
        .where((AccountTypeShare share) => share.amount > 0)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final AccountTypeShare share in visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(share.type.icon, size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${share.type.label} ${formatter.percent(share.share)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
