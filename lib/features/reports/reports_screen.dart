import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/reporting.dart';
import '../../core/models/models.dart';
import '../../core/services/csv_service.dart';
import '../../core/services/file_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/reference_charts.dart';
import '../../shared/widgets.dart';
import '../budgets/budgets_screen.dart';
import '../goals/goals_screen.dart';
import '../home/home_screen.dart';
import '../transactions/filter_sheet.dart';
import '../transactions/transaction_tile.dart';
import 'advanced_reports_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateWindow window;
  TransactionFilter filter = const TransactionFilter();
  bool bars = true, descending = true;
  String chartType = 'expense', dimension = 'category';
  @override
  void initState() {
    super.initState();
    window = financialMonth(
      DateTime.now(),
      ref.read(appProvider).settings.monthStart,
    );
  }

  Future<void> filters() async {
    final result = await showTransactionFilters(
      context,
      ref.read(profileProvider)!,
      filterDates(filter, window),
    );
    if (result != null && mounted)
      setState(() {
        filter = result;
        if (result.dates != null) window = result.dates!;
      });
  }

  Future<void> export(String kind) => runSafe(context, () async {
    final ledger = ref.read(ledgerProvider)!,
        snapshot = ReportSnapshot(
          ref.read(ledgerProvider)!,
          window,
          selection: filterDates(
            filter,
            window,
          ).apply(ref.read(ledgerProvider)!),
        );
    if (kind == 'csv') {
      await FileService.save(
        CsvService.export(ledger, snapshot.entries),
        'Tink-report.csv',
        mime: 'text/csv',
      );
      return;
    }
    if (!ledger.settings.isPro) throw const PremiumRequired('PDF reports');
    final bytes = await PdfService.report(
      ledger,
      snapshot.entries,
      'Month Summary',
    );
    if (kind == 'print') {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Tink-report.pdf',
      );
    } else {
      await FileService.save(bytes, 'Tink-report.pdf', mime: 'application/pdf');
    }
  }).then((_) {});
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final snapshot = ReportSnapshot(
      ledger,
      window,
      selection: filterDates(filter, window).apply(ledger),
    );
    final months = monthlyWindows(
      DateTime.now(),
      ledger.settings.monthStart,
      12,
    ).reversed.toList();
    final regular = financialMonth(window.start, ledger.settings.monthStart);
    final previousWindow =
        regular.start == window.start && regular.end == window.end
        ? previousMonth(window.start, ledger.settings.monthStart)
        : DateWindow(
            DateTime(
              window.start.year,
              window.start.month,
              window.start.day - window.days,
            ),
            window.start,
          );
    final previous = ReportSnapshot(
      ledger,
      previousWindow,
      selection: filterDates(filter, previousWindow).apply(ledger),
    );
    final groups = snapshot.groups(type: chartType, dimension: dimension);
    final rows = descending ? groups : groups.reversed.toList();
    final total = chartType == 'expense' ? snapshot.expense : snapshot.income;
    return FeaturePage(
      title: 'Reports',
      actions: [
        IconButton(
          tooltip: 'Filter reports',
          onPressed: filters,
          icon: Badge(
            isLabelVisible: filter.active,
            child: const Icon(Icons.tune_rounded),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Report actions',
          onSelected: (v) {
            if (v == 'advanced')
              openPage(context, const AdvancedReportsScreen());
            else
              export(v);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'advanced',
              child: Text('Advanced reports & comparisons'),
            ),
            PopupMenuItem(
              value: 'csv',
              child: Text('Export matching CSV · full amounts'),
            ),
            PopupMenuItem(value: 'pdf', child: Text('Save PDF · Pro')),
            PopupMenuItem(value: 'print', child: Text('Print report · Pro')),
          ],
        ),
        IconButton(
          tooltip: 'Profiles & settings',
          onPressed: () => showProfileMenu(context, ref),
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: months.length,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (context, i) {
                final month = months[i],
                    selected =
                        month.start == window.start && month.end == window.end;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ChoiceChip(
                    label: Text(
                      DateFormat(
                        "MMM yy",
                        ledger.settings.locale,
                      ).format(month.start),
                    ),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: AppColors.dark(context)
                        ? const Color(0xff494314)
                        : const Color(0xffEEE6BC),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.ink
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(selected ? 40 : 6),
                    ),
                    onSelected: (_) => setState(() => window = month),
                  ),
                );
              },
            ),
          ),
          if (ledger.settings.monthStart != 1 || window.days > 31)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${DateFormat.yMMMd().format(window.start)} – ${DateFormat.yMMMd().format(window.end.subtract(const Duration(days: 1)))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: AmountText(
                  snapshot.net,
                  animate: true,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReportTotal(
                  'Income',
                  snapshot.income,
                  previous.income,
                  income: true,
                  ledger: ledger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportTotal(
                  'Expense',
                  snapshot.expense,
                  previous.expense,
                  income: false,
                  ledger: ledger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          QuickInsights(snapshot),
          const SizedBox(height: 22),
          TonalCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reports',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Daily bar chart',
                      isSelected: bars,
                      onPressed: () => setState(() => bars = true),
                      icon: const Icon(Icons.bar_chart_rounded),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: 'Daily line chart',
                      isSelected: !bars,
                      onPressed: () => setState(() => bars = false),
                      icon: const Icon(Icons.show_chart_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ReportDailyChart(snapshot, bars: bars),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: chartType,
                  decoration: const InputDecoration(
                    labelText: 'Transaction type',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                  ],
                  onChanged: (v) => setState(() => chartType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: dimension,
                  decoration: const InputDecoration(labelText: 'Group by'),
                  items: const [
                    DropdownMenuItem(
                      value: 'category',
                      child: Text('Category'),
                    ),
                    DropdownMenuItem(value: 'account', child: Text('Account')),
                    DropdownMenuItem(value: 'label', child: Text('Label')),
                    DropdownMenuItem(value: 'person', child: Text('Person')),
                    DropdownMenuItem(value: 'place', child: Text('Place')),
                  ],
                  onChanged: (v) => setState(() => dimension = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ReferenceDonut(groups, ledger),
          if (dimension == 'label' || dimension == 'person')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Multiple tags can include the same record. Donut percentages use the sum of group totals, not distinct cash flow.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  chartType == 'expense' ? 'Expense' : 'Income',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Reverse breakdown order',
                onPressed: () => setState(() => descending = !descending),
                icon: const Icon(Icons.unfold_more_rounded),
              ),
              Flexible(
                child: AmountText(
                  total,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final group in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TonalCard(
                color: Color.alphaBlend(
                  Color(group.color).withValues(alpha: .2),
                  Theme.of(context).colorScheme.surface,
                ),
                onTap: () => openPage(
                  context,
                  ReportRecordsScreen(
                    title: group.name,
                    window: window,
                    recordIds: group.entries.map((e) => e.id).toSet(),
                  ),
                ),
                child: Row(
                  children: [
                    ColorIcon(group.icon, group.color, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${group.name} (${total > 0 ? (group.amount / total * 100).toStringAsFixed(1) : '0'}%)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${group.entries.length} ${group.entries.length == 1 ? 'transaction' : 'transactions'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (dimension == 'category' &&
                              ledger.data.categories.any(
                                (c) => c.parentId == group.id,
                              ))
                            const Text(
                              'Includes sub-categories',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          SectionHeader('Financial Reports'),
          for (final item in financialReports)
            TonalCard(
              radius: 12,
              padding: EdgeInsets.zero,
              onTap: () => openPage(
                context,
                FinancialReportScreen(item.$1, window: window, filter: filter),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(item.$4),
                ),
                title: Text(
                  item.$2,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(item.$3),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          const SizedBox(height: 26),
          Text('*Note', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Overview details show posted income and expense transactions from included accounts. Excluded accounts, transfers, future-dated records and opening balances are not counted. Initial account balances remain visible in Accounts. Values use your manual reference rates.',
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => openPage(
              context,
              ReportRecordsScreen(
                title: 'Report transactions',
                window: window,
                recordIds: snapshot.entries.map((e) => e.id).toSet(),
              ),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(
              'Explore ${snapshot.entries.length} matching transactions',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTotal extends StatelessWidget {
  final String title;
  final int amount, previous;
  final bool income;
  final Ledger ledger;
  const _ReportTotal(
    this.title,
    this.amount,
    this.previous, {
    required this.income,
    required this.ledger,
  });
  @override
  Widget build(BuildContext context) {
    final change = previous == 0 ? null : (amount - previous) / previous * 100;
    final color = AppColors.semantic(context, income ? 'income' : 'expense');
    return TonalCard(
      color: Color.alphaBlend(
        color.withValues(alpha: .09),
        Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(title)),
              if (change != null && !ledger.settings.hideAmounts)
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AmountText(
            amount,
            animate: true,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          AmountText(
            previous,
            prefix: 'was ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class QuickInsights extends StatelessWidget {
  final ReportSnapshot snapshot;
  const QuickInsights(this.snapshot, {super.key});
  @override
  Widget build(BuildContext context) {
    final top = snapshot.groups().firstOrNull,
        largest = snapshot.largestExpense,
        peak = snapshot.peakDay;
    final hidden = snapshot.ledger.settings.hideAmounts;
    final rate = snapshot.savingsRate;
    final cells = <Widget>[
      _Insight(
        'Savings Rate',
        Icons.savings_outlined,
        Text(
          hidden
              ? '••••'
              : rate == null
              ? '—'
              : '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.semantic(
              context,
              rate != null && rate < 0 ? 'expense' : 'income',
            ),
          ),
        ),
        rate == null ? 'No income baseline' : 'Net income after expenses',
      ),
      _Insight(
        'Avg. Daily',
        Icons.calendar_today_outlined,
        AmountText(
          snapshot.dailyAverage,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        '${(snapshot.entries.length / snapshot.window.days).toStringAsFixed(1)} / day · full period',
      ),
      _Insight(
        'Average Transaction',
        Icons.receipt_long_outlined,
        AmountText(
          snapshot.averageTransaction,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        '${snapshot.expenses.length} expenses',
      ),
      _Insight(
        'Peak Spending Day',
        Icons.trending_up_rounded,
        Text(
          peak == null ? '—' : DateFormat('EEE, MMM d').format(peak),
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        peak == null
            ? 'No expense records'
            : hidden
            ? 'Amount hidden'
            : money(
                snapshot.dailyExpenses[peak] ?? 0,
                snapshot.ledger.currency,
                locale: snapshot.ledger.settings.locale,
              ),
      ),
    ];
    return TonalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final heading = Row(
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Insights',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              );
              final count = SmallTag('${snapshot.entries.length} Transactions');
              if (box.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 8), count],
                );
              return Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 8),
                  count,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              final one =
                  box.maxWidth < 310 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              return Column(
                children: [
                  for (var i = 0; i < cells.length; i += one ? 1 : 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: one
                          ? cells[i]
                          : IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: cells[i]),
                                  const SizedBox(width: 10),
                                  Expanded(child: cells[i + 1]),
                                ],
                              ),
                            ),
                    ),
                ],
              );
            },
          ),
          if (top != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TonalCard(
                color: Color.alphaBlend(
                  Color(top.color).withValues(alpha: .16),
                  Theme.of(context).colorScheme.surface,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ColorIcon(top.icon, top.color, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Category',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            top.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: AmountText(
                        top.amount,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (largest != null)
            TonalCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ColorIcon(
                    snapshot.ledger.category(largest.categoryId)?.icon ??
                        'expense',
                    snapshot.ledger.category(largest.categoryId)?.color ??
                        0xffEEB5B8,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Largest Expense',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          largest.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          DateFormat.yMMMd().format(largest.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: AmountText(snapshot.ledger.entryValue(largest)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  final String title, caption;
  final IconData icon;
  final Widget value;
  const _Insight(this.title, this.icon, this.value, this.caption);
  @override
  Widget build(BuildContext context) => TonalCard(
    color: Theme.of(context).scaffoldBackgroundColor,
    padding: const EdgeInsets.all(12),
    radius: 18,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 7),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
        const SizedBox(height: 14),
        value,
        const SizedBox(height: 7),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

const financialReports = <(String, String, String, IconData)>[
  (
    'month',
    'Month Summary',
    'Quick overview of income, expenses, and net balance for the selected month',
    Icons.bar_chart_rounded,
  ),
  (
    'category',
    'Category Breakdown',
    'Detailed spending analysis by category with visual charts',
    Icons.pie_chart_outline_rounded,
  ),
  (
    'budget',
    'Budget Performance',
    'Track budget vs actual spending with performance indicators',
    Icons.track_changes_rounded,
  ),
  (
    'cashflow',
    'Cash Flow Analysis',
    'Money flow trends and patterns over time',
    Icons.payments_outlined,
  ),
  (
    'goal',
    'Goal Progress',
    'Financial goals tracking with milestone progress',
    Icons.emoji_events_outlined,
  ),
];

class ReportRecordsScreen extends ConsumerWidget {
  final String title;
  final DateWindow window;
  final Set<String>? recordIds;
  const ReportRecordsScreen({
    super.key,
    required this.title,
    required this.window,
    this.recordIds,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final entries =
        ReportSnapshot(ledger, window).entries
            .where((e) => recordIds == null || recordIds!.contains(e.id))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return FeaturePage(
      title: title,
      child: entries.isEmpty
          ? const EmptyState(
              title: 'No matching posted records',
              message: 'Transfers, excluded accounts and future dates are not included.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [for (final entry in entries) TransactionTile(entry)],
            ),
    );
  }
}

class FinancialReportScreen extends ConsumerWidget {
  final String kind;
  final DateWindow window;
  final TransactionFilter filter;
  const FinancialReportScreen(
    this.kind, {
    super.key,
    required this.window,
    this.filter = const TransactionFilter(),
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!,
        snapshot = ReportSnapshot(
          ref.watch(ledgerProvider)!,
          window,
          selection: filterDates(filter, window).apply(ledger),
        );
    final budgetReport = kind == 'budget'
        ? BudgetPerformanceSnapshot(ledger, window, filter: filter)
        : null;
    final title = financialReports.where((r) => r.$1 == kind).first.$2;
    return FeaturePage(
      title: title,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Text(
            '${DateFormat.yMMMd().format(window.start)} – ${DateFormat.yMMMd().format(window.end.subtract(const Duration(days: 1)))}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          if (kind == 'month') ...[
            QuickInsights(snapshot),
            const SizedBox(height: 20),
            ReportDailyChart(snapshot),
            const SizedBox(height: 20),
            SummaryColumns(
              labels: const ['Income', 'Expense', 'Net'],
              values: [
                AmountText(snapshot.income),
                AmountText(snapshot.expense),
                AmountText(snapshot.net),
              ],
            ),
          ],
          if (kind == 'category') ...[
            ReferenceDonut(snapshot.groups(), ledger),
            const SizedBox(height: 18),
            for (final group in snapshot.groups())
              ListTile(
                leading: ColorIcon(group.icon, group.color, size: 36),
                title: Text(group.name),
                subtitle: Text('${group.entries.length} transactions'),
                trailing: AmountText(group.amount),
                onTap: () => openPage(
                  context,
                  ReportRecordsScreen(
                    title: group.name,
                    window: window,
                    recordIds: group.entries.map((e) => e.id).toSet(),
                  ),
                ),
              ),
          ],
          if (kind == 'cashflow') ...[
            ReportDailyChart(snapshot, bars: false),
            const SizedBox(height: 20),
            SummaryColumns(
              labels: const ['Income', 'Outgoings', 'Net cash flow'],
              values: [
                AmountText(snapshot.income),
                AmountText(snapshot.expense),
                AmountText(snapshot.net),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Posted income minus expense, excluding transfers, opening balances and excluded accounts. No bank feeds or predictions.',
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => openPage(context, const AdvancedReportsScreen()),
              child: const Text('Longer-term patterns & comparisons'),
            ),
          ],
          if (kind == 'budget' && budgetReport != null) ...[
            Text(
              'Budget cycles as of ${DateFormat.yMMMd().format(budgetReport.asOf)}. Posted activity only; transfers, excluded accounts and future entries do not count. Transaction filters also scope rollover history. Historical edits to limits are not reconstructed.',
            ),
            const SizedBox(height: 16),
            if (!budgetReport.periodStarted)
              const Text(
                'This period has not started; no posted performance yet.',
              ),
            if (budgetReport.periodStarted && ledger.data.budgets.isEmpty)
              const Text(
                'Create a budget to compare its allowance and recorded spending.',
              ),
            for (final b
                in budgetReport.periodStarted
                    ? ledger.data.budgets
                    : <Budget>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Builder(
                  builder: (context) {
                    if (dayOnly(b.start).isAfter(dayOnly(budgetReport.asOf)))
                      return TonalCard(
                        onTap: () =>
                            openPage(context, BudgetDetailScreen(b.id)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Not started as of this date · starts ${DateFormat.yMMMd().format(b.start)}',
                            ),
                          ],
                        ),
                      );
                    final status = budgetReport.status(b);
                    return TonalCard(
                      onTap: () => openPage(context, BudgetDetailScreen(b.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${DateFormat.yMMMd().format(status.window.start)} – ${DateFormat.yMMMd().format(status.window.end.subtract(const Duration(microseconds: 1)))}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          WavyProgress(status.progress),
                          const SizedBox(height: 14),
                          SummaryColumns(
                            labels: const [
                              'Recorded',
                              'Allowance',
                              'Remaining',
                            ],
                            values: [
                              AmountText(status.spent),
                              AmountText(status.limit),
                              AmountText(status.remaining),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
          if (kind == 'goal') ...[
            const Text(
              'Current progress across all goals, not reconstructed historical balances. Transaction filters and the selected period do not change saved goal contributions.',
            ),
            const SizedBox(height: 16),
            if (ledger.data.goals.isEmpty)
              const Text(
                'Create a goal and record contributions to see progress.',
              ),
            for (final goal in ledger.data.goals)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TonalCard(
                  onTap: () => openPage(context, const GoalsScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      WavyProgress(ledger.goalSaved(goal) / goal.targetMinor),
                      const SizedBox(height: 12),
                      SummaryColumns(
                        labels: const ['Saved', 'Target'],
                        values: [
                          AmountText(ledger.goalSaved(goal)),
                          AmountText(goal.targetMinor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => openPage(
              context,
              ReportRecordsScreen(
                title: 'Matching records',
                window: window,
                recordIds: snapshot.entries.map((e) => e.id).toSet(),
              ),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Explore posted transactions'),
          ),
        ],
      ),
    );
  }
}
