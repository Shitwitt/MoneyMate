import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/analytics.dart';
import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../shared/analytics_chart.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/widgets.dart';
import '../transactions/transaction_detail.dart';
import '../transactions/transactions_screen.dart';

const weekdayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
Future<void> showAnalyticsHelp(BuildContext context) => showHowItWorks(
  context,
  title: 'How Analytics Work',
  introduction: 'Transparent calculations from records on this device. Not AI advice, fraud detection or a prediction of unrecorded spending.',
  sections: const [
    (
      Icons.receipt_long_outlined,
      'Records and currency',
      'Posted expenses only: future records, transfers, opening balances and excluded accounts are omitted. All amounts are converted with your current saved manual rates. Editing records or rates recalculates everything.',
    ),
    (
      Icons.lightbulb_outline,
      'Smart Insights',
      'Compare spending so far this financial month with the previous whole financial month, not equal-length periods. No prior amount means no percentage baseline, never a made-up 100 percent increase. Swipe cards or use their arrows; tap to open matching records.',
    ),
    (
      Icons.speed_outlined,
      'Spending Velocity',
      'Daily rate is month-to-date spending divided by elapsed calendar days including today. Remaining days exclude today. Weekly burn is that unrounded daily rate times seven; month projection uses the actual financial-month length. Faster/Slower compares this pace with the previous full-month daily rate, using a 20 percent band.',
    ),
    (
      Icons.show_chart,
      'Monthly Overview',
      'Six financial-month expense totals ending this month. The last point is partial. Top categories and weekday bars use all posted history, with the scope printed on each card. No invented chart points.',
    ),
    (
      Icons.trending_up,
      'Spending Predictions',
      'Average means the six completed financial months before this one; months with no recorded expenses count as zero, not verified zero spending. Each category forecast blends that average and its current-month pace equally, with a floor at already posted category spending. Without a category baseline, it is pace-only. Overall prediction sums these category forecasts. These are low-confidence estimates, not promises.',
    ),
    (
      Icons.warning_amber,
      'Unusual Spending',
      'Per exact category, at least four expenses are needed. Records above the upper quartile plus 1.5 times the interquartile range are flagged using linearly interpolated quartiles. A flag is not fraud. Tap any record for details.',
    ),
    (
      Icons.category_outlined,
      'Category Trends',
      'Current financial month versus the previous whole month. Sparklines show the same six monthly buckets as the overview. A zero prior amount is New spending, not a defined percentage.',
    ),
    (
      Icons.calendar_view_week,
      'Spending by Day of Week',
      'Totals across all posted history, Sunday through Saturday. Zero-record weekdays are included. Ties choose the first weekday in that order. Without recorded expenses, peak and lowest are unavailable.',
    ),
  ],
);

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final pager = PageController(viewportFraction: .92);
  int insight = 0, unusualLimit = 10;
  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final data = AnalyticsSnapshot(ledger, DateTime.now());
    final hidden = ledger.settings.hideAmounts;
    void showInsight(int page) {
      final duration = referenceMotion(context, 260);
      if (duration == Duration.zero) {
        pager.jumpToPage(page);
      } else {
        pager.animateToPage(
          page,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
      }
    }

    final insights = data.insights.take(8).toList(),
        trends = data.trends,
        unusual = data.unusual;
    String change(double? n) => hidden
        ? '•••%'
        : n == null
        ? 'No prior baseline'
        : '${n >= 0 ? '+' : ''}${n.toStringAsFixed(1)}%';
    void category(AnalyticsCategory c, {bool all = false}) => openPage(
      context,
      TransactionsScreen(
        title: c.name,
        initialFilter: TransactionFilter(
          categories: {c.id},
          type: 'expense',
          dates: all ? null : data.current,
        ),
      ),
    );
    Widget panel(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TonalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: readableTint(
                  context,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
    Widget scope(String text) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
    return FeaturePage(
      title: 'Analytics',
      actions: [
        IconButton(
          tooltip: 'Analytics methods',
          onPressed: () => showAnalyticsHelp(context),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const SectionHeader('Smart Insights'),
          if (insights.isEmpty)
            const TonalCard(
              child: Text(
                'No category increases to compare yet. Add expenses to see local, record-based insights.',
              ),
            )
          else ...[
            SizedBox(
              height:
                  185 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
              child: PageView.builder(
                key: const PageStorageKey('analytics-smart-insights'),
                controller: pager,
                itemCount: insights.length,
                onPageChanged: (i) => setState(() => insight = i),
                itemBuilder: (context, i) {
                  final c = insights[i];
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: TonalCard(
                      color: Color.alphaBlend(
                        const Color(0xffffb300).withValues(alpha: .10),
                        Theme.of(context).colorScheme.surface,
                      ),
                      onTap: () => category(c),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${c.previous == 0 ? 'New Spending' : 'High Spending'} in ${c.name}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              c.previous == 0
                                  ? 'No recorded expense in the previous month, so a percentage increase is undefined.'
                                  : 'Spending so far is ${change(c.change)} versus the previous full month.',
                            ),
                            const SizedBox(height: 14),
                            AmountText(
                              c.current - c.previous,
                              prefix: 'Increase: ',
                              style: TextStyle(
                                color: AppColors.semantic(context, 'expense'),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous smart insight',
                  onPressed: insight == 0
                      ? null
                      : () => showInsight(insight - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${insight.clamp(0, insights.length - 1) + 1} / ${insights.length}',
                ),
                IconButton(
                  tooltip: 'Next smart insight',
                  onPressed: insight >= insights.length - 1
                      ? null
                      : () => showInsight(insight + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          panel('Spending Velocity', [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SmallTag(data.velocityStatus),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                AmountText(
                  data.daily,
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const Text('/daily'),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('${data.elapsed} days elapsed'),
                Text('${data.remaining} days remaining'),
              ],
            ),
            const SizedBox(height: 14),
            WavyProgress(data.elapsed / data.current.days),
            const SizedBox(height: 20),
            const Text('Last 7 Days'),
            const SizedBox(height: 10),
            AnalyticsChart(
              values: data.lastSeven,
              labels: List.generate(
                7,
                (i) => DateFormat.MMMd().format(
                  DateTime(data.now.year, data.now.month, data.now.day - 6 + i),
                ),
              ),
              ledger: ledger,
            ),
            const SizedBox(height: 12),
            SummaryColumns(
              labels: const ['Weekly Burn Rate', 'Projected Monthly'],
              values: [AmountText(data.weeklyBurn), AmountText(data.projected)],
            ),
            scope(
              'Pace estimates · ${DateFormat.MMMd().format(data.current.start)} – ${DateFormat.MMMd().format(DateTime(data.current.end.year, data.current.end.month, data.current.end.day - 1))} · today included',
            ),
          ]),
          const SectionHeader('Overall Spending'),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth > 650
                  ? 3
                  : box.maxWidth >= 340 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.3
                  ? 3
                  : 1;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final stat in [
                    (
                      'Current Spending',
                      data.spending,
                      '${change(data.change)} vs last full month',
                    ),
                    (
                      'Monthly Average',
                      data.average ?? 0,
                      data.average == null
                          ? 'No completed-month baseline'
                          : '6 completed months',
                    ),
                    (
                      'Predicted',
                      data.predicted,
                      '${data.average == null ? 'Pace-only' : 'Blended'} estimate',
                    ),
                  ])
                    SizedBox(
                      width: (box.maxWidth - (columns - 1) * 10) / columns,
                      child: TonalCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.$1,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 12),
                            if (stat.$1 == 'Monthly Average' &&
                                data.average == null)
                              const Text('Unavailable')
                            else
                              AmountText(
                                stat.$2,
                                compact: false,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.semantic(
                                    context,
                                    stat.$1 == 'Monthly Average'
                                        ? 'transfer'
                                        : 'expense',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              stat.$3,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          panel('Top categories', [
            if (data.categories.isEmpty) const Text('No posted expenses yet.'),
            for (final c in data.categories.take(5))
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: ColorIcon(c.icon, c.color, size: 48),
                title: Text(c.name),
                subtitle: Text(
                  hidden
                      ? '•••% of total'
                      : data.total == 0
                      ? 'Below base-currency precision'
                      : '${(c.total / data.total * 100).toStringAsFixed(1)}% of total',
                ),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: AmountText(c.total, compact: true),
                ),
                onTap: () => category(c, all: true),
              ),
            scope(
              'All posted history · share of total recorded expenses · ${ledger.currency}',
            ),
          ]),
          panel('Monthly Overview', [
            AnalyticsChart(
              values: data.monthly,
              labels: data.months
                  .map((m) => DateFormat('MM/yy').format(m.start))
                  .toList(),
              ledger: ledger,
              curved: true,
            ),
            scope(
              'Six financial months · final month is partial. Tap points or use arrows for exact amounts.',
            ),
          ]),
          panel('Spending Predictions', [
            if (data.categories
                .where((c) => c.current > 0 || c.average > 0)
                .isEmpty)
              const Text('Not enough recorded spending for an estimate.'),
            for (final c in data.categories.where(
              (c) => c.current > 0 || c.average > 0,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: InkWell(
                  onTap: () => category(c),
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: readableTint(
                                        context,
                                        Color(c.color),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              AmountText(
                                c.average,
                                prefix: 'Average Spending: ',
                              ),
                              AmountText(
                                data.prediction(c),
                                prefix: 'Predicted: ',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: hidden
                              ? 'Estimate hidden'
                              : data.prediction(c) > c.average
                              ? 'Estimate above historical average'
                              : data.prediction(c) < c.average
                              ? 'Estimate below historical average'
                              : 'Estimate unchanged',
                          child: Icon(
                            hidden
                                ? Icons.visibility_off_outlined
                                : data.prediction(c) > c.average
                                ? Icons.arrow_upward
                                : data.prediction(c) < c.average
                                ? Icons.arrow_downward
                                : Icons.horizontal_rule,
                            color: hidden
                                ? null
                                : AppColors.semantic(
                                    context,
                                    data.prediction(c) > c.average
                                        ? 'expense'
                                        : 'income',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            scope(
              'Low-confidence monthly estimates. Six completed months averaged with current pace; no baseline uses pace only. Never below already posted spending.',
            ),
          ]),
          panel('Unusual Spending', [
            if (unusual.isEmpty)
              const Text(
                'No unusually high expenses found. Each category needs at least four posted expenses for the quartile comparison.',
              ),
            for (final e in unusual.take(unusualLimit))
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                leading: ColorIcon(
                  ledger.category(e.categoryId)?.icon ?? 'category',
                  ledger.category(e.categoryId)?.color ?? 0xffffb59a,
                  size: 48,
                ),
                title: Text(
                  e.name,
                  style: TextStyle(
                    color: readableTint(
                      context,
                      Color(ledger.category(e.categoryId)?.color ?? 0xffffb59a),
                    ),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AmountText(ledger.entryValue(e), prefix: 'Amount: '),
                    Text(DateFormat.yMMMd().format(e.date)),
                  ],
                ),
                onTap: () => showTransactionDetail(context, ref, e.id),
              ),
            if (unusual.length > unusualLimit)
              TextButton(
                onPressed: () => setState(() => unusualLimit += 10),
                child: Text(
                  'Show more · ${unusual.length - unusualLimit} remaining',
                ),
              ),
            scope(
              'All posted history · per-category upper-quartile rule, not fraud detection',
            ),
          ]),
          panel('Category Trends', [
            if (trends.isEmpty)
              const Text('No posted expenses this financial month.'),
            for (final c in trends.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: InkWell(
                  onTap: () => category(c),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ColorIcon(c.icon, c.color, size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  '${c.currentCount} transactions this period',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: AnalyticsChart(
                              values: c.monthly,
                              labels: data.months
                                  .map((m) => DateFormat.yMMM().format(m.start))
                                  .toList(),
                              ledger: ledger,
                              small: true,
                              color: AppColors.semantic(
                                context,
                                c.current >= c.previous ? 'expense' : 'income',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AmountText(c.current),
                                Text(
                                  c.previous == 0
                                      ? (hidden
                                            ? '•••'
                                            : c.current == 0
                                            ? 'No baseline'
                                            : 'New spending')
                                      : change(c.change),
                                  style: TextStyle(
                                    color: AppColors.semantic(
                                      context,
                                      c.current >= c.previous
                                          ? 'expense'
                                          : 'income',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            scope(
              'So far this financial month vs previous whole month; zero prior spending has no percentage baseline.',
            ),
          ]),
          panel('Spending by Day of Week', [
            AnalyticsChart(
              values: data.weekdays,
              labels: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
              ledger: ledger,
              bars: true,
            ),
            const SizedBox(height: 16),
            SummaryColumns(
              labels: const ['Peak Spending Day', 'Lowest Spending Day'],
              values: [
                Text(
                  data.peakWeekday == null
                      ? 'Unavailable'
                      : weekdayNames[data.peakWeekday!],
                ),
                Text(
                  data.lowestWeekday == null
                      ? 'Unavailable'
                      : weekdayNames[data.lowestWeekday!],
                ),
              ],
            ),
            scope(
              'All posted history · totals, not per-occurrence averages · tied days choose the first weekday',
            ),
          ]),
        ],
      ),
    );
  }
}
