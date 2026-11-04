import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/csv_service.dart';
import '../../core/services/file_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/actions.dart';
import '../../shared/charts.dart';
import '../../shared/widgets.dart';
import '../settings/premium_screen.dart';
import '../transactions/filter_sheet.dart';
import '../transactions/transactions_screen.dart';

TransactionFilter filterDates(TransactionFilter filter, DateWindow? dates) => TransactionFilter(query: filter.query, dates: dates, accounts: filter.accounts, categories: filter.categories, labels: filter.labels, people: filter.people, places: filter.places, type: filter.type, minMinor: filter.minMinor, maxMinor: filter.maxMinor, sort: filter.sort);
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}
class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  TransactionFilter filter = const TransactionFilter();
  bool line = false;
  String chartType = 'expense';
  @override
  void initState() {
    super.initState();
    final settings = ref.read(appProvider).settings;
    final now = DateTime.now();
    filter = TransactionFilter(dates: DateWindow(safeMonth(now.year, now.month - 5, settings.monthStart), financialMonth(now, settings.monthStart).end));
  }
  Future<void> _filters() async {
    final result = await showTransactionFilters(context, ref.read(profileProvider)!, filter);
    if (mounted && result != null) setState(() => filter = result);
  }
  Future<void> _export(String kind) async {
    await runSafe(context, () async {
      final ledger = ref.read(ledgerProvider)!;
      final entries = filter.apply(ledger);
      if (kind == 'csv') { await FileService.save(CsvService.export(ledger, entries), 'PaisaClone-report.csv', mime: 'text/csv'); return; }
      if (!ref.read(appProvider).settings.isPro) throw const PremiumRequired('PDF reports');
      final bytes = await PdfService.report(ledger, entries, 'Your money, a little clearer');
      if (kind == 'print') { await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'PaisaClone-report.pdf'); } else { await FileService.save(bytes, 'PaisaClone-report.pdf', mime: 'application/pdf'); }
    });
  }
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final entries = filter.apply(ledger);
    final expenses = entries.where((entry) => entry.type == 'expense').toList();
    final income = entries.where((entry) => entry.type == 'income').fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final expense = expenses.fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final window = filter.dates ?? DateWindow(DateTime(1970), DateTime.now().add(const Duration(days: 1)));
    final end = window.end.subtract(const Duration(days: 1));
    final chartMonths = math.max(1, math.min(12, (end.year - window.start.year) * 12 + end.month - window.start.month + 1));
    final chartLedger = Ledger(ledger.data.copyWith(transactions: entries), ledger.settings);
    return FeaturePage(title: 'Your money, a little clearer', actions: [IconButton(tooltip: 'Filter reports', onPressed: _filters, icon: Badge(isLabelVisible: filter.active, child: const Icon(Icons.tune_rounded))), PopupMenuButton<String>(tooltip: 'Export report (contains full amounts)', onSelected: _export, itemBuilder: (_) => const [PopupMenuItem(value: 'csv', child: Text('Export filtered CSV')), PopupMenuItem(value: 'pdf', child: Text('Save PDF · Plus')), PopupMenuItem(value: 'print', child: Text('Print report · Plus'))])], child: ListView(padding: const EdgeInsets.only(bottom: 110), children: [
      Wrap(spacing: 8, runSpacing: 6, children: [ActionChip(avatar: const Icon(Icons.date_range_rounded, size: 16), label: Text(filter.dates == null ? 'All dates' : '${DateFormat.yMMMd().format(window.start)} — ${DateFormat.yMMMd().format(end)}'), onPressed: _filters), for (final months in [1, 6, 12]) ActionChip(label: Text(months == 1 ? 'This month' : '$months months'), onPressed: () { final now = DateTime.now(); final current = financialMonth(now, ledger.settings.monthStart); setState(() => filter = filterDates(filter, DateWindow(safeMonth(current.start.year, current.start.month - months + 1, ledger.settings.monthStart), current.end))); }), if (filter.active) ActionChip(label: const Text('All data / clear'), onPressed: () => setState(() => filter = const TransactionFilter()))]), const SizedBox(height: 20),
      LayoutBuilder(builder: (context, constraints) => Wrap(spacing: 12, runSpacing: 12, children: [for (final stat in [('Income', income, Icons.south_west_rounded), ('Expenses', expense, Icons.north_east_rounded), ('Net cash flow', income - expense, Icons.waves_rounded)]) SizedBox(width: constraints.maxWidth > 650 ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2, child: StatCard(title: stat.$1, value: AmountText(stat.$2, compact: constraints.maxWidth < 650), icon: stat.$3, caption: stat.$1 == 'Net cash flow' ? '${income > 0 ? ((income - expense) / income * 100).toStringAsFixed(1) : '0'}% savings rate' : '${entries.where((entry) => entry.type == (stat.$1 == 'Income' ? 'income' : 'expense')).length} entries'))])),
      const SizedBox(height: 24), SectionHeader('The bigger picture', trailing: SegmentedButton<bool>(segments: const [ButtonSegment(value: false, icon: Icon(Icons.bar_chart_rounded)), ButtonSegment(value: true, icon: Icon(Icons.show_chart_rounded))], selected: {line}, showSelectedIcon: false, onSelectionChanged: (value) => setState(() => line = value.first))),
      Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [TrendChart(chartLedger, line: line, months: chartMonths, anchor: end), const SizedBox(height: 10), const Text('Monthly buckets for this selection · transfers excluded', style: TextStyle(fontSize: 11))]))),
      const SizedBox(height: 24), SectionHeader('Where it all goes', trailing: DropdownButton<String>(value: chartType, underline: const SizedBox.shrink(), items: const [DropdownMenuItem(value: 'expense', child: Text('Expenses')), DropdownMenuItem(value: 'income', child: Text('Income'))], onChanged: (value) => setState(() => chartType = value!))),
      Card(child: Padding(padding: const EdgeInsets.all(22), child: CategoryChart(ledger, entries.where((entry) => entry.type == chartType).toList()))),
      const SizedBox(height: 24), const SectionHeader('By account'), _breakdown(context, ledger.breakdown(expenses, 'account'), expense),
      const SizedBox(height: 24), const SectionHeader('Your regular favourites'), _breakdown(context, ledger.breakdown(expenses, 'name'), expense, limit: 8),
      for (final kind in ['label', 'person', 'place']) if (ledger.data.entities.any((entity) => entity.kind == kind)) ...[const SizedBox(height: 24), SectionHeader('Spending by ${kind == 'person' ? 'person' : kind}'), _breakdown(context, {for (final entity in ledger.data.entities.where((entity) => entity.kind == kind)) entity.name: expenses.where((entry) => kind == 'label' ? entry.labelIds.contains(entity.id) : kind == 'person' ? entry.personIds.contains(entity.id) : entry.placeId == entity.id).fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry))}, expense), if (kind != 'place') const Padding(padding: EdgeInsets.all(8), child: Text('Multi-tagged entries appear in each matching group.', style: TextStyle(fontSize: 10)))],
      const SizedBox(height: 24), if (ledger.settings.isPro) ..._advanced(context, ledger, entries, window, expense) else Card(color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: .5), child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.auto_awesome_rounded), const SizedBox(height: 12), Text('A little more perspective', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), const Text('Spending velocity, period comparisons, seasonal patterns, and beautiful PDF reports.'), const SizedBox(height: 18), FilledButton.tonal(onPressed: () => openPage(context, const PremiumScreen()), child: const Text('Explore PaisaClone Plus'))]))),
      const SizedBox(height: 20), OutlinedButton.icon(onPressed: () => openPage(context, TransactionsScreen(title: 'Report transactions', initialFilter: filter)), icon: const Icon(Icons.receipt_long_outlined), label: Text('Explore ${entries.length} matching transactions')),
    ]));
  }
  Widget _breakdown(BuildContext context, Map<String, int> values, int total, {int limit = 10}) {
    final sorted = values.entries.where((entry) => entry.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No matching activity in this selection.')));
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [for (final entry in sorted.take(limit)) Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(children: [Row(children: [Expanded(child: Text(entry.key)), AmountText(entry.value, style: const TextStyle(fontWeight: FontWeight.w600))]), const SizedBox(height: 8), LinearProgressIndicator(value: total > 0 ? (entry.value / total).clamp(0, 1) : 0, minHeight: 4, borderRadius: BorderRadius.circular(4))]))])));
  }
  List<Widget> _advanced(BuildContext context, Ledger ledger, List<MoneyTransaction> entries, DateWindow window, int expense) {
    final now = DateTime.now();
    final elapsed = math.max(1, math.min(window.days, now.difference(window.start).inDays + 1));
    final pace = (expense / elapsed).round();
    final previous = DateWindow(window.start.subtract(window.end.difference(window.start)), window.start);
    final pastEntries = filterDates(filter, previous).apply(ledger);
    final past = pastEntries.where((entry) => entry.type == 'expense').fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final yearly = DateWindow(safeMonth(window.start.year - 1, window.start.month, window.start.day), safeMonth(window.end.year - 1, window.end.month, window.end.day));
    final lastYear = filterDates(filter, yearly).apply(ledger).where((entry) => entry.type == 'expense').fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final week = <String, int>{for (var i = 0; i < 7; i++) DateFormat.EEEE().format(DateTime(2024, 1, 1 + (ledger.settings.weekStart - 1 + i) % 7)): entries.where((entry) => entry.type == 'expense' && entry.date.weekday == (ledger.settings.weekStart - 1 + i) % 7 + 1).fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry))};
    return [const SectionHeader('Your spending velocity'), Row(children: [Expanded(child: StatCard(title: 'Daily pace', value: AmountText(pace, compact: true), icon: Icons.speed_rounded, caption: '$elapsed elapsed days')), const SizedBox(width: 12), Expanded(child: StatCard(title: 'Projected period', value: AmountText(pace * window.days, compact: true), icon: Icons.timeline_rounded, caption: 'At this pace · not a prediction'))]), const SizedBox(height: 24), const SectionHeader('A little perspective'), Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [Row(children: [const Expanded(child: Text('Previous equal-length period')), AmountText(past)]), const SizedBox(height: 12), Row(children: [const Expanded(child: Text('Same window, last year')), AmountText(lastYear)]), const SizedBox(height: 12), Text(past == 0 ? 'Your next chapter starts with this data.' : '${((expense - past) / past * 100).abs().toStringAsFixed(1)}% ${expense > past ? 'more' : 'less'} spending than the previous period', style: Theme.of(context).textTheme.titleMedium)]))), const SizedBox(height: 24), const SectionHeader('The shape of your week'), _breakdown(context, week, expense), const SizedBox(height: 24), const SectionHeader('Daily spending heatmap'), _heatmap(context, ledger, entries, window.end.subtract(const Duration(days: 1)))];
  }
  Widget _heatmap(BuildContext context, Ledger ledger, List<MoneyTransaction> entries, DateTime month) {
    final first = DateTime(month.year, month.month), days = DateTime(month.year, month.month + 1, 0).day;
    final offset = (first.weekday - ledger.settings.weekStart + 7) % 7;
    final values = List.generate(days, (i) => entries.where((entry) => entry.type == 'expense' && dayOnly(entry.date) == DateTime(month.year, month.month, i + 1)).fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry)));
    final max = values.fold<int>(1, math.max);
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Text(DateFormat.yMMMM().format(first)), const SizedBox(height: 14), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1.6), itemCount: days + offset, itemBuilder: (context, index) { if (index < offset) return const SizedBox.shrink(); final day = index - offset; return Tooltip(message: money(values[day], ledger.currency, hidden: ledger.settings.hideAmounts), child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: ledger.settings.hideAmounts ? .08 : .06 + values[day] / max * .6), borderRadius: BorderRadius.circular(8)), child: Text('${day + 1}', style: const TextStyle(fontSize: 12)))); })])));
  }
}
