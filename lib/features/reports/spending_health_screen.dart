import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/data/ledger.dart';
import '../../core/data/seed.dart';
import '../../core/data/spending_review.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/analytics_chart.dart';
import '../../shared/how_it_works_sheet.dart';
import '../../shared/wavy_ring.dart';
import '../../shared/widgets.dart';
import '../catalog/category_detail_screen.dart';
import '../recurring/recurring_editor.dart';
import '../transactions/transactions_screen.dart';

Future<void> showSpendingMethods(
  BuildContext context,
  SpendingReview data,
) => showHowItWorks(
  context,
  title: 'How Spending Review Works',
  introduction: 'A local record review, not a credit score, bank assessment, financial-health verdict or financial advice. Missing records are unknown. Cash-flow calculations use saved manual reference rates and posted records from included accounts. The index also uses saved opening balances, allocations and current tracker status.',
  sections: [
    (
      Icons.donut_large,
      'Recorded-data index',
      'The ring is the equal mean of available planning indicators, requiring at least two. Each indicator is bounded to 0–100. ${data.pulse.metrics.map((m) => '${m.label}: ${m.explanation}').join(' ')}',
    ),
    (
      Icons.local_fire_department_outlined,
      'Expense-record streak',
      'Consecutive calendar days with expense records below the unrounded daily expense mean of the six completed financial months. The displayed threshold is rounded. Gaps and days without expense records break the streak. Best covers those six months and this month so far. Without a positive expense baseline it is unavailable, not zero.',
    ),
    (
      Icons.flag_outlined,
      'Optional monthly challenge',
      'An unsaved illustration: 15% below the largest category in the previous financial month, rounded to the base currency minor unit with a minimum of one. It is not a budget or a recommendation; tap to review records. The current month is partial.',
    ),
    (
      Icons.receipt_long_outlined,
      'Monthly comparisons',
      'Current financial-month expenses so far versus the previous full month. No prior recorded amount means an undefined percentage, not a fabricated increase or grade. Periods differ in elapsed length. Category amounts are not a judgment about need or value.',
    ),
    (
      Icons.swipe_outlined,
      'Habits',
      'Weekday totals use all recorded expense history. Last-week share means the final seven calendar days of each month, across recorded history. Neither is an average verified spending day. Tap a card to see its exact record selection.',
    ),
    (
      Icons.calendar_month_outlined,
      'Calendar',
      'Calendar-month posted income and expense; transfers omitted. Color reflects recorded daily net, not an inferred no-spend day. Tap a day for records. Hold it for exact income, expense and net. Empty days mean no records.',
    ),
    (
      Icons.savings_outlined,
      'Recorded surplus projection',
      'Six displayed financial-month surpluses, including the partial current month. Mean uses the six completed financial months, including empty months as recorded zero, not verified zero. Year-end estimate is posted calendar-year surplus plus the completed-period daily surplus mean multiplied by calendar days after today. It can be negative. Opening balances, debt principal, investments and unrecorded activity are not forecast; this is not a bank-balance or return prediction.',
    ),
    (
      Icons.repeat,
      'Possible monthly repeats',
      'Candidates only: at least two consecutive completed calendar months, ending last month; one expense per month with the same normalized name, account and category; days within three and amounts within 20% of the median. Saved recurring links/rules and archived accounts are omitted. Native median is rounded, then converted. Daily cost annualizes the monthly total over this calendar year. No detection confirms a subscription, charge or future debit. Creating a reminder requires reviewing and saving its draft; auto-processing starts off.',
    ),
  ],
);

class SpendingHealthScreen extends ConsumerStatefulWidget {
  const SpendingHealthScreen({super.key});
  @override
  ConsumerState<SpendingHealthScreen> createState() =>
      _SpendingHealthScreenState();
}

class _SpendingHealthScreenState extends ConsumerState<SpendingHealthScreen> {
  final pager = PageController(viewportFraction: .92);
  int habit = 0;
  bool allCategories = false;
  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!, now = DateTime.now();
    final data = SpendingReview(ledger, now),
        hidden = ledger.settings.hideAmounts;
    final scheme = Theme.of(context).colorScheme;
    final green = AppColors.semantic(context, 'income'),
        red = AppColors.semantic(context, 'expense');
    String amount(int value) => hidden
        ? '•••'
        : money(
            value,
            ledger.currency,
            locale: ledger.settings.locale,
            indian: ledger.settings.numberFormat == 'indian',
          );
    String percentage(double? value) => hidden
        ? '•••%'
        : value == null
        ? 'No prior baseline'
        : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%';
    Widget panel(String title, List<Widget> children, {Color? color}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: TonalCard(
            color: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: readableTint(context, scheme.primary)),
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        );
    void transactions({
      int? weekday,
      bool lastWeek = false,
      String? category,
      DateWindow? dates,
    }) => openPage(
      context,
      TransactionsScreen(
        title: 'Spending review records',
        initialFilter: TransactionFilter(
          type: 'expense',
          categories: category == null ? const {} : {category},
          weekday: weekday,
          lastWeekOfMonth: lastWeek,
          dates: dates,
          postedOnly: true,
          includedOnly: true,
        ),
      ),
    );
    final score = data.pulse.score,
        streak = data.streak,
        challenge = data.challenge;
    final target = data.challengeTarget;
    final trends =
        data.analytics.categories
            .where((c) => c.currentCount > 0 || c.previous > 0)
            .toList()
          ..sort((a, b) => b.current.compareTo(a.current));
    final shown = allCategories ? trends : trends.take(8).toList();
    final top = [...data.analytics.categories]
      ..sort((a, b) => b.total.compareTo(a.total));
    final peak = data.analytics.peakWeekday;
    final habitData = <(String, String, IconData, VoidCallback?)>[
      (
        'Weekday pattern',
        hidden
            ? 'Amounts are hidden'
            : peak == null
            ? 'Add posted expenses to compare weekdays.'
            : '${weekdayNamesForReview[peak]} has the largest recorded total, ${amount(data.analytics.weekdays[peak])}.',
        Icons.calendar_view_week_outlined,
        peak == null ? null : () => transactions(weekday: peak),
      ),
      (
        'End-of-month pattern',
        hidden
            ? 'Amounts are hidden'
            : data.lastWeekShare == null
            ? 'No recorded expense to compare.'
            : '${(data.lastWeekShare! * 100).toStringAsFixed(1)}% of all recorded expenses fall in the final seven calendar days of a month.',
        Icons.date_range_outlined,
        data.lastWeekShare == null ? null : () => transactions(lastWeek: true),
      ),
      (
        'Largest recorded category',
        top.isEmpty
            ? 'Your category pattern is still unknown.'
            : '${top.first.name} · ${amount(top.first.total)} across posted history.',
        Icons.category_outlined,
        top.isEmpty ? null : () => transactions(category: top.first.id),
      ),
    ];
    final candidates = data.candidates;
    return FeaturePage(
      title: 'Spending Health',
      actions: [
        IconButton(
          tooltip: 'Spending review methods',
          onPressed: () => showSpendingMethods(context, data),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          panel('Recorded-data index', [
            Center(
              child: GestureDetector(
                onLongPress: () => showSpendingMethods(context, data),
                child: WavyRing(
                  hidden ? 0 : (score ?? 0) / 100,
                  size: 190,
                  strokeWidth: 12,
                  color: green,
                  semanticsLabel: hidden
                      ? 'Recorded-data index hidden'
                      : score == null
                      ? 'Recorded-data index unavailable'
                      : 'Recorded-data planning index $score out of 100; not a financial-health assessment',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hidden
                            ? '•••'
                            : score == null
                            ? '—'
                            : '$score',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(color: green),
                      ),
                      Text(
                        hidden ? 'Amounts are hidden' : data.pulse.status,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'A lens, not a verdict. Local planning indicators; not a real financial-health or credit score.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SummaryColumns(
              labels: const ['Buffer', 'Spending', 'Debt'],
              values: [
                for (final label in ['Buffer', 'Spending', 'Debt'])
                  Builder(
                    builder: (context) {
                      final m = data.pulse.metrics.firstWhere(
                        (m) => m.label == label,
                      );
                      return InkWell(
                        onTap: () => showFeatureInfo(
                          context,
                          m.label,
                          '${hidden
                              ? 'Hidden'
                              : m.value == null
                              ? 'Unavailable'
                              : '${m.value!.toStringAsFixed(1)} / 100'}\n\n${m.explanation}',
                        ),
                        onLongPress: () => showFeatureInfo(
                          context,
                          m.label,
                          '${hidden
                              ? 'Hidden'
                              : m.value == null
                              ? 'Unavailable'
                              : '${m.value!.toStringAsFixed(1)} / 100'}\n\n${m.explanation}',
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                hidden
                                    ? '•••'
                                    : m.value == null
                                    ? '—'
                                    : '${m.value!.round()} / 100',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              if (!hidden)
                                WavyProgress((m.value ?? 0) / 100, color: green)
                              else
                                const Icon(Icons.visibility_off_outlined),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => showSpendingMethods(context, data),
              child: const Text('All five indicators and calculations'),
            ),
          ]),
          panel('Expense-record streak', [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ColorIcon('fire', 0xffffb7a9),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hidden
                            ? 'Hidden'
                            : streak == null
                            ? 'Baseline unavailable'
                            : '${streak.$1} consecutive days',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hidden
                            ? 'Hidden'
                            : streak == null
                            ? 'Add prior-period expense records.'
                            : 'Best in review window · ${streak.$2} days',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data.baselineDailyExpense == null
                  ? 'A positive completed-period expense baseline is needed.'
                  : 'Expense-record days below ${amount(data.baselineDailyExpense!.round())}/day. Unlogged days break the streak, not assumed zero-spend days.',
            ),
          ]),
          panel(
            'Monthly Challenge',
            [
              const Text('Optional example · not a saved budget'),
              const SizedBox(height: 12),
              if (challenge == null || target == null)
                const Text(
                  'No previous financial-month category baseline is available.',
                )
              else ...[
                Text(
                  'Review ${challenge.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'An example target 15% below the previous financial month.',
                ),
                const SizedBox(height: 18),
                SummaryColumns(
                  labels: const ['Recorded so far', 'Example target'],
                  values: [AmountText(challenge.current), AmountText(target)],
                ),
                const SizedBox(height: 18),
                if (!hidden)
                  WavyProgress(
                    challenge.current / target,
                    color: challenge.current > target ? red : green,
                  )
                else
                  const Icon(Icons.visibility_off_outlined),
                const SizedBox(height: 14),
                Text(
                  hidden
                      ? 'Progress hidden'
                      : challenge.current <= target
                      ? '${amount(target - challenge.current)} below the example target'
                      : '${amount(challenge.current - target)} above the example target',
                ),
                TextButton.icon(
                  onPressed: () =>
                      openPage(context, CategoryDetailScreen(challenge.id)),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Review category records'),
                ),
              ],
            ],
            color: Color.alphaBlend(
              scheme.primary.withValues(alpha: .06),
              scheme.surface,
            ),
          ),
          panel('Monthly Report Card', [
            Text(
              '${DateFormat.yMMMd().format(data.analytics.current.start)} – ${DateFormat.yMMMd().format(DateTime(data.analytics.current.end.year, data.analytics.current.end.month, data.analytics.current.end.day - 1))}',
            ),
            const SizedBox(height: 12),
            const Text(
              'Partial current financial month versus previous full month. Comparisons, not grades.',
            ),
            const SizedBox(height: 16),
            if (trends.isEmpty)
              const Text('No category expenses in either period.'),
            for (final c in shown)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ColorIcon(c.icon, c.color, size: 40),
                title: Text(c.name),
                subtitle: Text(
                  '${percentage(c.change)} · ${amount(c.current)} so far',
                ),
                trailing: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : c.change == null
                      ? Icons.remove
                      : c.change! > 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: hidden
                      ? scheme.onSurfaceVariant
                      : c.change != null && c.change! <= 0
                      ? green
                      : red,
                ),
                onTap: () => openPage(context, CategoryDetailScreen(c.id)),
              ),
            if (trends.length > 8)
              TextButton(
                onPressed: () => setState(() => allCategories = !allCategories),
                child: Text(
                  allCategories
                      ? 'Show fewer categories'
                      : 'Show all ${trends.length} categories',
                ),
              ),
          ]),
          const SectionHeader('Spending Habits'),
          SizedBox(
            height:
                230 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
            child: PageView.builder(
              controller: pager,
              itemCount: habitData.length,
              onPageChanged: (v) => setState(() => habit = v),
              itemBuilder: (context, i) {
                final h = habitData[i];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: TonalCard(
                    onTap: h.$4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            h.$3,
                            color: readableTint(context, scheme.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            h.$1,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          Text(h.$2),
                          if (h.$4 != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 14),
                              child: Text('Tap to review matching records'),
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
                tooltip: 'Previous spending habit',
                onPressed: habit == 0
                    ? null
                    : () => pager.animateToPage(
                        habit - 1,
                        duration: referenceMotion(context, 260),
                        curve: Curves.easeOutCubic,
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${habit + 1} / ${habitData.length}'),
              IconButton(
                tooltip: 'Next spending habit',
                onPressed: habit == habitData.length - 1
                    ? null
                    : () => pager.animateToPage(
                        habit + 1,
                        duration: referenceMotion(context, 260),
                        curve: Curves.easeOutCubic,
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 18),
          panel('Spending Heatmap', [ReviewCalendar(data)]),
          panel('Category Review', [
            const Text(
              'Recorded changes, not category-health ratings. Sparklines show six financial months; the final point is partial.',
            ),
            const SizedBox(height: 16),
            for (final c in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ColorIcon(c.icon, c.color, size: 40),
                      title: Text(c.name),
                      subtitle: Text(
                        '${percentage(c.change)} versus the previous full financial month',
                      ),
                      onTap: () =>
                          openPage(context, CategoryDetailScreen(c.id)),
                    ),
                    AnalyticsChart(
                      values: c.monthly,
                      labels: const [],
                      ledger: ledger,
                      small: true,
                      color: c.change != null && c.change! <= 0 ? green : red,
                    ),
                  ],
                ),
              ),
          ]),
          panel('Savings Projection', [
            const Text(
              'Recorded income minus expense, not a bank balance or investment return.',
            ),
            const SizedBox(height: 18),
            SummaryColumns(
              labels: const [
                'Year-end surplus estimate',
                'Six-period mean surplus',
              ],
              values: [
                data.yearEndSurplus == null
                    ? const Text('Unavailable')
                    : AmountText(
                        data.yearEndSurplus!,
                        style: TextStyle(
                          color: data.yearEndSurplus! < 0 ? red : green,
                        ),
                      ),
                data.monthlySurplusMean == null
                    ? const Text('Unavailable')
                    : AmountText(data.monthlySurplusMean!),
              ],
            ),
            const SizedBox(height: 18),
            AnalyticsChart(
              values: data.monthlySurplus,
              labels: [
                for (final w in data.analytics.months)
                  DateFormat.MMM().format(w.start),
              ],
              pointLabels: [
                for (final w in data.analytics.months)
                  DateFormat.yMMMd().format(w.start),
              ],
              ledger: ledger,
              color: green,
              label: 'Recorded surplus',
            ),
            Text(
              data.hasSurplusBaseline
                  ? 'Estimate uses completed-period daily surplus × days after today plus posted year-to-date surplus. Can be negative; unrecorded activity is unknown.'
                  : 'No completed-period income/expense baseline. No estimate has been invented.',
            ),
          ]),
          panel('Possible Monthly Repeats', [
            const Text(
              'Unconfirmed candidates, not detected charges or auto-debits.',
            ),
            const SizedBox(height: 18),
            SummaryColumns(
              labels: const [
                'Estimated monthly total',
                'Annualized daily cost',
              ],
              values: [
                AmountText(data.possibleMonthlyTotal),
                AmountText(data.possibleDailyCost),
              ],
            ),
            const SizedBox(height: 18),
            if (candidates.isEmpty)
              const Text(
                'No current, sufficiently consistent monthly pattern found in the last six completed calendar months.',
              ),
            for (final c in candidates)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.repeat),
                    title: Text(c.name),
                    subtitle: Text(
                      '${c.months} consecutive completed months · ${amount(c.baseMinor)}/month estimate',
                    ),
                    onTap: () => openPage(
                      context,
                      TransactionsScreen(
                        title: c.name,
                        initialFilter: TransactionFilter(
                          type: 'expense',
                          accounts: {c.accountId},
                          categories: {c.categoryId},
                          exactName: c.name,
                          dates: DateWindow(
                            DateTime(now.year, now.month - 6),
                            DateTime(now.year, now.month),
                          ),
                          postedOnly: true,
                          includedOnly: true,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await reviewRecurringDraft(
                        context,
                        ref,
                        Recurring(
                          id: uuid.v4(),
                          name: c.name,
                          type: 'expense',
                          amountMinor: c.nativeMinor,
                          accountId: c.accountId,
                          categoryId: c.categoryId,
                          frequency: 'monthly',
                          start: c.first,
                          nextDue: c.next,
                          autoPost: false,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_alarm),
                    label: const Text('Review a monthly reminder draft'),
                  ),
                  const Divider(),
                ],
              ),
          ]),
        ],
      ),
    );
  }
}

const weekdayNamesForReview = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

class ReviewCalendar extends StatefulWidget {
  final SpendingReview data;
  const ReviewCalendar(this.data, {super.key});
  @override
  State<ReviewCalendar> createState() => _ReviewCalendarState();
}

class _ReviewCalendarState extends State<ReviewCalendar> {
  late DateTime month;
  @override
  void initState() {
    super.initState();
    month = DateTime(widget.data.now.year, widget.data.now.month);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data,
        ledger = data.ledger,
        hidden = ledger.settings.hideAmounts;
    final days = DateTime(month.year, month.month + 1, 0).day,
        offset = (month.weekday - ledger.settings.weekStart + 7) % 7;
    final flows = data.dailyCashFlow;
    final positive = AppColors.semantic(context, 'income'),
        negative = AppColors.semantic(context, 'expense');
    String amount(int n) => hidden
        ? '•••'
        : money(
            n,
            ledger.currency,
            locale: ledger.settings.locale,
            indian: ledger.settings.numberFormat == 'indian',
          );
    final count = <DateTime, int>{};
    for (final e in data.posted) {
      final day = dayOnly(e.date.toLocal());
      count.update(day, (v) => v + 1, ifAbsent: () => 1);
    }
    void move(int amount) =>
        setState(() => month = DateTime(month.year, month.month + amount));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous review month',
              onPressed: () => move(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM().format(month),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Next review month',
              onPressed: () => move(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: box.maxWidth < 348 ? 348 : box.maxWidth,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Text(
                            weekdayNamesForReview[(ledger.settings.weekStart +
                                        i) %
                                    7]
                                .substring(0, 1),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var row = 0; row < (offset + days + 6) ~/ 7; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final number = row * 7 + col - offset + 1;
                                if (number < 1 || number > days)
                                  return const SizedBox(height: 52);
                                final date = DateTime(
                                      month.year,
                                      month.month,
                                      number,
                                    ),
                                    flow = flows[date] ?? (0, 0),
                                    n = count[date] ?? 0;
                                final net = flow.$1 - flow.$2;
                                return Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Semantics(
                                    label:
                                        '${DateFormat.yMMMMd().format(date)}. $n records. ${hidden ? 'Amounts hidden' : 'Income ${amount(flow.$1)}; expense ${amount(flow.$2)}; net ${amount(net)}'}',
                                    child: Material(
                                      color: hidden || n == 0
                                          ? Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest
                                          : Color.alphaBlend(
                                              (net >= 0 ? positive : negative)
                                                  .withValues(alpha: .22),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => openPage(
                                          context,
                                          TransactionsScreen(
                                            title: DateFormat.yMMMMd().format(
                                              date,
                                            ),
                                            initialFilter: TransactionFilter(
                                              dates: DateWindow(
                                                date,
                                                nextDay(date),
                                              ),
                                              postedOnly: true,
                                              includedOnly: true,
                                              cashFlowOnly: true,
                                            ),
                                          ),
                                        ),
                                        onLongPress: () => showFeatureInfo(
                                          context,
                                          DateFormat.yMMMMd().format(date),
                                          '$n posted records\nIncome: ${amount(flow.$1)}\nExpense: ${amount(flow.$2)}\nNet: ${amount(net)}\n\n${n == 0 ? 'No records, not verified zero activity.' : 'Transfers and excluded accounts omitted.'}',
                                        ),
                                        child: SizedBox(
                                          height: 48,
                                          child: Center(child: Text('$number')),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Green: recorded net ≥ 0 · red: net < 0 · empty: no records. Tap for records; hold for exact values. Transfers omitted.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
