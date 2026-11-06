import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/reporting.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/reference_charts.dart';
import '../../shared/widgets.dart';
import '../budgets/budgets_screen.dart';
import '../recurring/recurring_detail_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/transaction_tile.dart';
import '../transactions/transactions_screen.dart';

class HomeCalendarHeatmap extends StatefulWidget {
  final Ledger ledger;
  const HomeCalendarHeatmap(this.ledger, {super.key});
  @override
  State<HomeCalendarHeatmap> createState() => _HomeCalendarHeatmapState();
}

class _HomeCalendarHeatmapState extends State<HomeCalendarHeatmap> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger, today = dayOnly(DateTime.now());
    final start = DateTime(month.year, month.month),
        end = DateTime(month.year, month.month + 1);
    final days = calendarDaysBetween(start, end),
        offset = (start.weekday - ledger.settings.weekStart + 7) % 7;
    final counts = <int, int>{};
    for (final e in ledger.data.transactions.where(
      (e) => !e.date.isBefore(start) && e.date.isBefore(end),
    ))
      counts.update(e.date.day, (n) => n + 1, ifAbsent: () => 1);
    final max = counts.values.fold<int>(1, math.max),
        accent = Theme.of(context).colorScheme.primary;
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return TonalCard(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Calendar heatmap',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'All calendar transactions',
                onPressed: () => openPage(
                  context,
                  TransactionsScreen(
                    title: DateFormat.yMMM().format(month),
                    initialFilter: TransactionFilter(
                      dates: DateWindow(start, end),
                    ),
                  ),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous activity month',
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMM(ledger.settings.locale).format(month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Next activity month',
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(348.0, box.maxWidth),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ((days + offset) / 7).ceil() * 7,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: large ? .85 : 1,
                  ),
                  itemBuilder: (context, index) {
                    final day = index - offset + 1;
                    if (day < 1 || day > days) return const SizedBox.shrink();
                    final date = DateTime(month.year, month.month, day),
                        count = counts[day] ?? 0;
                    final future = date.isAfter(today);
                    final cellColor = count == 0
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: future ? .3 : .65)
                        : accent.withValues(alpha: .2 + .65 * count / max);
                    final cellInk =
                        Color.alphaBlend(
                              cellColor,
                              Theme.of(context).colorScheme.surface,
                            ).computeLuminance() >
                            .179
                        ? Colors.black
                        : Colors.white;
                    return Semantics(
                      button: true,
                      label:
                          '${DateFormat.yMMMMd().format(date)}, $count recorded transactions${future ? ', future date' : ''}',
                      child: Tooltip(
                        message: '$count transactions',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () => openPage(
                            context,
                            TransactionsScreen(
                              title: DateFormat.MMMd().format(date),
                              initialFilter: TransactionFilter(
                                dates: DateWindow(date, nextDay(date)),
                              ),
                            ),
                          ),
                          child: AnimatedContainer(
                            duration: referenceMotion(context, 180),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(5),
                              border: date == today
                                  ? Border.all(color: accent, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: count > 0 || date == today
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: cellInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Recorded activity · brighter means more records; future dates are scheduled',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class HomeCashflowTrend extends StatelessWidget {
  final Ledger ledger;
  const HomeCashflowTrend(this.ledger, {super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(),
        current = financialMonth(DateTime.now(), ledger.settings.monthStart),
        previous = previousMonth(DateTime.now(), ledger.settings.monthStart);
    final actual = ReportSnapshot(ledger, current, now: now).daily,
        past = ReportSnapshot(ledger, previous, now: now).daily;
    var running = 0.0, pastRunning = 0.0;
    final today = actual.map((d) {
      if (d.future) return null;
      running += d.net;
      return running;
    }).toList();
    final old = List<double?>.generate(actual.length, (i) {
      if (i >= past.length) return null;
      pastRunning += past[i].net;
      return pastRunning;
    });
    final pending = upcomingRecords(ledger, now)
        .where(
          (u) => u.type != 'transfer' && !ledger.account(u.accountId).excluded,
        )
        .toList();
    final todayIndex = actual.where((d) => !d.future).length - 1;
    final future = List<double?>.generate(actual.length, (i) {
      if (i < todayIndex) return null;
      for (final item in pending.where(
        (u) => dayOnly(u.date) == actual[i].date,
      )) {
        running +=
            ledger.inBase(
              item.amountMinor,
              ledger.account(item.accountId).currency,
            ) *
            (item.type == 'income' ? 1 : -1);
      }
      return running;
    });
    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Cash flow reports',
                onPressed: () => openPage(context, const ReportsScreen()),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReferenceLineChart(
            ledger: ledger,
            start: current.start,
            series: [
              ReferenceSeries(
                DateFormat.MMM().format(previous.start),
                old,
                const Color(0xffD6B8A9),
                dashed: true,
              ),
              ReferenceSeries(
                'This month',
                today,
                Theme.of(context).colorScheme.primary,
              ),
              ReferenceSeries(
                'Upcoming',
                future,
                const Color(0xffD0C58A),
                dashed: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Net recorded cash flow. Upcoming uses only scheduled entries/rules at your manual rates; it is not a forecast or a bank balance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class HomeTrackedBudgets extends StatefulWidget {
  final Ledger ledger;
  const HomeTrackedBudgets(this.ledger, {super.key});
  @override
  State<HomeTrackedBudgets> createState() => _HomeTrackedBudgetsState();
}

class _HomeTrackedBudgetsState extends State<HomeTrackedBudgets> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger,
        budgets = widget.ledger.data.budgets
            .where((b) => b.showOnHome)
            .toList();
    if (budgets.isEmpty)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Track budgets'),
          TonalCard(
            onTap: () => openPage(context, const BudgetsScreen()),
            child: const Text(
              'Choose Show Budget in a budget’s details to track it here.',
            ),
          ),
        ],
      );
    final large =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Track budgets'),
        SizedBox(
          height: large
              ? 340.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6)
              : 244,
          child: PageView.builder(
            itemCount: budgets.length,
            onPageChanged: (p) => setState(() => page = p),
            itemBuilder: (context, index) {
              final budget = budgets[index],
                  status = ledger.budgetStatus(budget, DateTime.now()),
                  color = readableTint(context, Color(budget.color));
              final ringScale = MediaQuery.textScalerOf(context)
                  .scale(1)
                  .clamp(1.0, 1.6);
              final ring = WavyRing(
                status.progress,
                size: 94 * ringScale,
                strokeWidth: 7 * ringScale,
                color: budget.income
                    ? status.progress >= 1
                          ? AppColors.income
                          : color
                    : status.remaining < 0
                    ? AppColors.expense
                    : status.progress >= .8
                    ? AppColors.warning
                    : const Color(0xff74B85B),
                child: SizedBox.square(
                  dimension: 72 * ringScale,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(status.progress * 100).round()}%',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          budget.income ? 'reached' : 'used',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
              final metrics = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in [
                    ('Budget', status.limit),
                    (budget.income ? 'Received' : 'Spent', status.spent),
                    ('Remaining', status.remaining),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.$1,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: AmountText(
                              row.$2,
                              style: TextStyle(
                                color: row.$1 == 'Remaining' ? color : null,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: TonalCard(
                  color: Color.alphaBlend(
                    Color(budget.color).withValues(alpha: .12),
                    Theme.of(context).colorScheme.surface,
                  ),
                  onTap: () => openPage(context, BudgetDetailScreen(budget.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ColorIcon(budget.icon, budget.color, size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  budget.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${titleCase(budget.period)} · ${budgetStatusLabel(budget, status)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (large) ...[
                        Center(child: ring),
                        const SizedBox(height: 14),
                        metrics,
                      ] else
                        Row(
                          children: [
                            ring,
                            const SizedBox(width: 20),
                            Expanded(child: metrics),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < budgets.length; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: i == page ? 1 : .25),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class UpcomingTransactionsSection extends StatelessWidget {
  final Ledger ledger;
  final bool all;
  const UpcomingTransactionsSection(this.ledger, {super.key, this.all = false});
  @override
  Widget build(BuildContext context) {
    final upcoming = upcomingRecords(ledger, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!all)
          SectionHeader(
            'Upcoming transactions',
            action: 'See all',
            onTap: () => openPage(context, const UpcomingTransactionsScreen()),
          ),
        if (upcoming.isEmpty)
          const TonalCard(
            child: Text('No scheduled transactions in the next 60 days.'),
          ),
        for (final item in upcoming.take(all ? 500 : 10))
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: TonalCard(
              radius: 14,
              padding: EdgeInsets.zero,
              child: item.entry != null
                  ? TransactionTile(item.entry!)
                  : _UpcomingRuleTile(item, ledger),
            ),
          ),
      ],
    );
  }
}

class _UpcomingRuleTile extends StatelessWidget {
  final UpcomingRecord item;
  final Ledger ledger;
  const _UpcomingRuleTile(this.item, this.ledger);
  @override
  Widget build(BuildContext context) {
    final rule = item.rule!, account = ledger.account(item.accountId);
    final budget = ledger.data.budgets
        .where((b) => b.id == rule.budgetId)
        .firstOrNull;
    final tags = ledger.data.entities.where(
      (e) =>
          rule.labelIds.contains(e.id) ||
          rule.personIds.contains(e.id) ||
          rule.placeId == e.id,
    );
    return InkWell(
      onTap: () => openPage(context, RecurringDetailScreen(rule.id)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ColorIcon(
              ledger.category(rule.categoryId)?.icon ?? 'bills',
              ledger.category(rule.categoryId)?.color ?? 0xffFFB59A,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat.MMMd().add_jm().format(item.date)} · ${account.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (budget != null)
                        TransactionMetadataTag(
                          budget.name,
                          Color(budget.color),
                          Icons.savings_outlined,
                        ),
                      for (final tag in tags)
                        TransactionMetadataTag(
                          tag.name,
                          Color(tag.color),
                          tag.kind == 'place'
                              ? Icons.place_outlined
                              : tag.kind == 'person'
                              ? Icons.person_outline_rounded
                              : Icons.label_outline_rounded,
                        ),
                      const TransactionMetadataTag(
                        'Scheduled · not posted',
                        Color(0xffB7C9E5),
                        Icons.schedule_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    rule.amountMinor,
                    currency: account.currency,
                    style: TextStyle(
                      color: AppColors.semantic(context, rule.type),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (account.currency != ledger.currency)
                    AmountText(
                      ledger.inBase(rule.amountMinor, account.currency),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpcomingTransactionsScreen extends ConsumerWidget {
  const UpcomingTransactionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FeaturePage(
    title: 'Upcoming transactions',
    child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: UpcomingTransactionsSection(ref.watch(ledgerProvider)!, all: true),
    ),
  );
}
