import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/icons.dart';
import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_format.dart';
import '../../data/models/category_budget_stat.dart';
import '../../data/models/category_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/period_summary.dart';

/// Overview — analytics for the selected period.
///
/// Charts are drawn with plain `CustomPainter`s (donut + bars) so the tab is
/// fully interactive and needs no extra charting setup; Step 6 swaps the
/// sparkline for `fl_chart` once historical ranges land.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final CurrencyFormatter formatter = provider.formatter;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    final FilterExpense filter = provider.selectedTimeFilter;
    final Map<String, double> spendByCategory =
        provider.spendByCategoryForPeriod(filter);
    final List<CategoryBudgetStat> breakdown = <CategoryBudgetStat>[];
    double totalSpend = 0;
    spendByCategory.forEach((String id, double value) {
      final CategoryModel? category = provider.categoryById(id);
      if (category == null || value <= 0) return;
      totalSpend += value;
      breakdown.add(
        CategoryBudgetStat(
          category: category,
          spent: value,
          daysLeftInPeriod: provider.daysLeftInMonth,
        ),
      );
    });
    breakdown.sort((CategoryBudgetStat a, CategoryBudgetStat b) =>
        b.spent.compareTo(a.spent));

    final List<DailyTotal> daily = provider.dailyTotals(filter);

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        PeriodFilterChips(
          selected: filter,
          onSelected: provider.setSelectedTimeFilter,
        ),
        const SizedBox(height: 12),

        // ---------------- Income vs expense ----------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _AnalyticsCard(
                  label: 'Income',
                  value: formatter.formatWhole(provider.periodIncome),
                  color: colors.income,
                  background: colors.incomeContainer,
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalyticsCard(
                  label: 'Expense',
                  value: formatter.formatWhole(provider.periodExpense),
                  color: colors.expense,
                  background: colors.expenseContainer,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _AnalyticsCard(
            label: 'Net savings this period',
            value: formatter.formatSigned(provider.periodNet, withDecimals: false),
            color: provider.periodNet >= 0 ? colors.income : colors.expense,
            background: scheme.surfaceContainerHighest,
            icon: Icons.savings_outlined,
            trailing:
                'Savings rate ${formatter.percentOf(math.max(0, provider.periodNet), provider.periodIncome)}',
          ),
        ),
        const SizedBox(height: 24),

        // ---------------- Donut ----------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Where the money went',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: breakdown.isEmpty
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'No spending in this period yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: <Widget>[
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: _DonutChart(
                          slices: <_DonutSlice>[
                            for (int i = 0; i < breakdown.length; i++)
                              _DonutSlice(
                                value: breakdown[i].spent,
                                color: Color(breakdown[i].category.color),
                              ),
                          ],
                          total: totalSpend,
                          label: formatter.compact(totalSpend),
                          subLabel: 'spent',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            for (final CategoryBudgetStat stat
                                in breakdown.take(5))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Color(stat.category.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        stat.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                    Text(
                                      formatter.percentOf(stat.spent, totalSpend),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant,
                                      ),
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
        ),
        const SizedBox(height: 24),

        // ---------------- Daily bars ----------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Daily flow',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _DailyBarCard(totals: daily, formatter: formatter),
        ),
        const SizedBox(height: 24),

        // ---------------- Category breakdown ----------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Category breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (breakdown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Log an expense to unlock the breakdown.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (final CategoryBudgetStat stat in breakdown)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(stat.category.color).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        ICONS.byCodePoint(stat.category.icon),
                        size: 18,
                        color: Color(stat.category.color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            stat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: totalSpend <= 0
                                  ? 0
                                  : (stat.spent / totalSpend).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: scheme.surfaceContainerHighest,
                              color: Color(stat.category.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          formatter.formatWhole(stat.spent),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatter.percentOf(stat.spent, totalSpend),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Average ${formatter.formatWhole(provider.averageDailySpend)}/day · '
            'projected ${formatter.formatWhole(provider.projectedPeriodExpense)} for the period',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    required this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;
  final IconData icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DonutSlice {
  const _DonutSlice({required this.value, required this.color});

  final double value;
  final Color color;
}

/// A donut with a hole label, drawn with a [CustomPainter].
class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.slices,
    required this.total,
    required this.label,
    required this.subLabel,
  });

  final List<_DonutSlice> slices;
  final double total;
  final String label;
  final String subLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        CustomPaint(
          size: const Size.square(132),
          painter: _DonutPainter(
            slices: slices,
            total: total,
            trackColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.trackColor,
  });

  final List<_DonutSlice> slices;
  final double total;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double stroke = size.shortestSide * 0.20;
    final double radius = (size.shortestSide - stroke) / 2;

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (total <= 0) return;

    double start = -1.5707963267948966; // -90°
    for (final _DonutSlice slice in slices) {
      final double sweep = (slice.value / total) * 6.283185307179586;
      if (sweep <= 0) continue;
      // A tiny gap between slices keeps adjacent hues readable.
      final double gap = slices.length > 1 ? 0.035 : 0;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + gap / 2,
        (sweep - gap).clamp(0.0, 6.283185307179586),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.slices.length != slices.length ||
      !_sameColors(oldDelegate.slices, slices);

  static bool _sameColors(List<_DonutSlice> a, List<_DonutSlice> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].color != b[i].color || a[i].value != b[i].value) return false;
    }
    return true;
  }
}

/// Income/expense bars for each day of the period.
class _DailyBarCard extends StatelessWidget {
  const _DailyBarCard({required this.totals, required this.formatter});

  final List<DailyTotal> totals;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    // > 31 days is unreadable as bars; aggregate by week for longer periods.
    final bool weekly = totals.length > 31;

    double maxValue = 0;
    for (final DailyTotal total in totals) {
      maxValue = [maxValue, total.income, total.expense].reduce((a, b) => a > b ? a : b);
    }
    if (maxValue <= 0) maxValue = 1;

    final int bucketCount = weekly ? (totals.length / 7).ceil() : totals.length;
    final List<double> incomeBuckets = List<double>.filled(bucketCount, 0);
    final List<double> expenseBuckets = List<double>.filled(bucketCount, 0);
    final List<String> labels = List<String>.filled(bucketCount, '');

    for (int i = 0; i < totals.length; i++) {
      final int index = weekly ? i ~/ 7 : i;
      if (index >= bucketCount) continue;
      incomeBuckets[index] += totals[i].income;
      expenseBuckets[index] += totals[i].expense;
      if (labels[index].isEmpty) {
        labels[index] = weekly
            ? DateTimeFormat.shortDate(totals[i].date)
            : totals[i].date.day.toString();
      }
    }

    for (int i = 0; i < bucketCount; i++) {
      maxValue = [maxValue, incomeBuckets[i], expenseBuckets[i]]
          .reduce((a, b) => a > b ? a : b);
    }

    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: SizedBox(
                    width: math.max(
                      constraints.maxWidth,
                      bucketCount * 26.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        for (int i = 0; i < bucketCount; i++)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  _Bar(
                                    fraction: incomeBuckets[i] / maxValue,
                                    color: colors.income,
                                  ),
                                  const SizedBox(height: 2),
                                  _Bar(
                                    fraction: expenseBuckets[i] / maxValue,
                                    color: colors.expense,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    labels[i],
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _LegendDot(color: colors.income, label: 'Income'),
              const SizedBox(width: 16),
              _LegendDot(color: colors.expense, label: 'Expense'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double height = (fraction.clamp(0.0, 1.0)) * 90;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      height: height < 2 ? 2 : height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
