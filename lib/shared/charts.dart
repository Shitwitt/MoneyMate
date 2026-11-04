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
              gridData: const FlGridData(show: false),
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
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: titles,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, index, rod, rodIndex) => BarTooltipItem(
                    '${rodIndex == 0 ? 'Income' : 'Expense'}\n${money(toMinor(rod.toY, ledger.currency), ledger.currency, indian: ledger.settings.numberFormat == 'indian')}',
                    const TextStyle(color: Colors.white, fontSize: 12),
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
                      color: primary,
                      width: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    BarChartRodData(
                      toY: expense[index] * progress,
                      color: secondary,
                      width: 12,
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
  @override
  Widget build(BuildContext context) {
    if (widget.ledger.settings.hideAmounts) {
      return const SizedBox(
        height: 220,
        child: Center(child: Icon(Icons.visibility_off_rounded)),
      );
    }
    final breakdown = widget.ledger
        .breakdown(widget.entries, 'category')
        .entries
        .toList();
    if (breakdown.isEmpty) {
      return const EmptyState(
        title: 'Your story starts here',
        message: 'Add some transactions to see the bigger picture.',
        icon: Icons.donut_large_rounded,
      );
    }
    final total = breakdown.fold<int>(0, (sum, entry) => sum + entry.value);
    final values = breakdown.take(6).toList();
    if (breakdown.length > 6) {
      values.add(
        MapEntry(
          'Other categories',
          breakdown.skip(6).fold(0, (sum, entry) => sum + entry.value),
        ),
      );
    }
    const colors = AppColors.chart;
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => ChartReveal(
                  progress: progress,
                  circular: true,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 66,
                      sectionsSpace: 4,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) => setState(
                          () => touched = event.isInterestedForInteractions
                              ? response?.touchedSection?.touchedSectionIndex ??
                                    -1
                              : -1,
                        ),
                      ),
                      sections: [
                        for (var i = 0; i < values.length; i++)
                          PieChartSectionData(
                            value: values[i].value.toDouble(),
                            color: colors[i],
                            radius: touched == i ? 34.0 : 26.0,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 125,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touched >= 0 && touched < values.length
                          ? values[touched].key
                          : 'Total',
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    AmountText(
                      touched >= 0 && touched < values.length
                          ? values[touched].value
                          : total,
                      compact: true,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < values.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(values[i].key)),
                Text(
                  '${(values[i].value / total * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(width: 14),
                AmountText(
                  values[i].value,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
