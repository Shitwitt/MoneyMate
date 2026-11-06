import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/csv_service.dart';
import '../../core/services/file_service.dart';
import '../../core/utils/dates.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import 'filter_sheet.dart';
import 'transaction_form.dart';
import 'transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final TransactionFilter initialFilter;
  final String? title;
  const TransactionsScreen({
    super.key,
    this.initialFilter = const TransactionFilter(),
    this.title,
  });
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late TransactionFilter filter = widget.initialFilter;
  final query = TextEditingController();
  final selected = <String>{};
  int limit = 80;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  TransactionFilter get current => TransactionFilter(
    query: query.text,
    exactName: filter.exactName,
    postedOnly: filter.postedOnly,
    includedOnly: filter.includedOnly,
    cashFlowOnly: filter.cashFlowOnly,
    lastWeekOfMonth: filter.lastWeekOfMonth,
    weekday: filter.weekday,
    dates: filter.dates,
    accounts: filter.accounts,
    categories: filter.categories,
    labels: filter.labels,
    people: filter.people,
    places: filter.places,
    type: filter.type,
    minMinor: filter.minMinor,
    maxMinor: filter.maxMinor,
    sort: filter.sort,
  );
  Future<void> filters() async {
    final result = await showTransactionFilters(
      context,
      ref.read(profileProvider)!,
      current,
    );
    if (result != null && mounted) {
      setState(() {
        filter = result;
        limit = 80;
      });
    }
  }

  Future<void> delete(Set<String> ids) async {
    if (await confirm(
          context,
          'Delete ${ids.length == 1 ? 'transaction' : '${ids.length} transactions'}?',
          'This also reverses every affected account balance. Export a backup first if you might need these entries.',
        ) &&
        mounted) {
      final saved = await runSafe(
        context,
        () => ref.read(appProvider.notifier).deleteTransactions(ids),
        success: 'Deleted from your device',
      );
      if (saved && mounted) setState(() => selected.removeAll(ids));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final entries = current.apply(ledger);
    final income = entries
        .where((entry) => entry.type == 'income')
        .fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final expense = entries
        .where((entry) => entry.type == 'expense')
        .fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final byAmount = ['largest', 'smallest'].contains(filter.sort);
    final groups = <DateTime, List<MoneyTransaction>>{};
    for (final entry in entries.take(limit)) {
      groups
          .putIfAbsent(
            byAmount ? DateTime(1970) : dayOnly(entry.date),
            () => [],
          )
          .add(entry);
    }
    final dailyTotals = <DateTime, int>{};
    for (final entry in entries) {
      final day = dayOnly(entry.date);
      dailyTotals[day] =
          (dailyTotals[day] ?? 0) +
          (entry.type == 'transfer'
              ? 0
              : ledger.entryValue(entry) * (entry.type == 'income' ? 1 : -1));
    }
    final l = AppLocalizations.of(context);
    return FeaturePage(
      title: selected.isEmpty
          ? widget.title ?? l.activity
          : '${selected.length} selected',
      padded: false,
      actions: [
        if (selected.isNotEmpty) ...[
          IconButton(
            tooltip: 'Cancel selection',
            onPressed: () => setState(selected.clear),
            icon: const Icon(Icons.close_rounded),
          ),
          IconButton(
            tooltip: 'Delete selected',
            onPressed: () => delete({...selected}),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ] else ...[
          IconButton(
            tooltip: 'Export filtered CSV',
            onPressed: entries.isEmpty
                ? null
                : () => runSafe(
                    context,
                    () => FileService.save(
                      CsvService.export(ledger, entries),
                      'Tink-transactions.csv',
                      mime: 'text/csv',
                    ),
                  ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Filters',
            onPressed: filters,
            icon: Badge(
              isLabelVisible: filter.active,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ],
      child: RefreshIndicator(
        onRefresh: () => runSafe(
          context,
          () => ref.read(appProvider.notifier).processRecurring(),
        ).then((_) {}),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 250 &&
                limit < entries.length) {
              setState(() => limit += 80);
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      TextField(
                        controller: query,
                        onChanged: (_) => setState(() => limit = 80),
                        decoration: InputDecoration(
                          hintText: l.searchActivity,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () => setState(query.clear),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _summary(
                              context,
                              l.income,
                              income,
                              AppColors.semantic(context, 'income'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summary(
                              context,
                              l.expenses,
                              expense,
                              AppColors.semantic(context, 'expense'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${entries.length} entries',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          if (filter.active || query.text.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() {
                                filter = const TransactionFilter();
                                query.clear();
                              }),
                              child: const Text('Clear all'),
                            ),
                        ],
                      ),
                      if (filter.active)
                        Wrap(
                          spacing: 6,
                          children: [
                            if (filter.dates != null)
                              ActionChip(
                                label: const Text('Date range'),
                                onPressed: filters,
                              ),
                            for (final pair in [
                              ('Accounts', filter.accounts.length),
                              ('Categories', filter.categories.length),
                              ('Labels', filter.labels.length),
                              ('People', filter.people.length),
                              ('Places', filter.places.length),
                            ])
                              if (pair.$2 > 0)
                                ActionChip(
                                  label: Text('${pair.$1}: ${pair.$2}'),
                                  onPressed: filters,
                                ),
                            if (filter.type != 'all')
                              ActionChip(
                                label: Text(filter.type),
                                onPressed: filters,
                              ),
                            if (filter.minMinor != null ||
                                filter.maxMinor != null)
                              ActionChip(
                                label: const Text('Amount range'),
                                onPressed: filters,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: query.text.isEmpty && !filter.active
                        ? 'Every little entry counts'
                        : 'Nothing here just yet',
                    message: query.text.isEmpty && !filter.active
                        ? 'Your first transaction is the start of a better relationship with money.'
                        : 'Try another search or clear your filters.',
                    icon: Icons.receipt_long_rounded,
                    action: 'Add transaction',
                    onAction: () => openPage(context, const TransactionForm()),
                  ),
                ),
              for (final group in groups.entries) ...[
                if (!byAmount)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DayHeader(
                      group.key,
                      dailyTotals[group.key] ?? 0,
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  sliver: SliverList.builder(
                    itemCount: group.value.length,
                    itemBuilder: (context, index) {
                      final entry = group.value[index];
                      return Dismissible(
                        key: ValueKey(entry.id),
                        background: _swipe(
                          context,
                          Icons.edit_rounded,
                          Alignment.centerLeft,
                        ),
                        secondaryBackground: _swipe(
                          context,
                          Icons.delete_outline_rounded,
                          Alignment.centerRight,
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            await openPage(
                              context,
                              TransactionForm(initial: entry),
                            );
                          } else {
                            await delete({entry.id});
                          }
                          return false;
                        },
                        child: TransactionTile(
                          entry,
                          selecting: selected.isNotEmpty,
                          selected: selected.contains(entry.id),
                          onSelect: () => setState(() {
                            if (!selected.add(entry.id)) {
                              selected.remove(entry.id);
                            }
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (limit < entries.length)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: OutlinedButton(
                      onPressed: () => setState(() => limit += 80),
                      child: const Text('Load more'),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    String label,
    int amount,
    Color color,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          AmountText(
            amount,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
  Widget _swipe(BuildContext context, IconData icon, Alignment alignment) =>
      Container(
        alignment: alignment,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon),
      );
}

class _DayHeader extends SliverPersistentHeaderDelegate {
  final DateTime date;
  final int total;
  _DayHeader(this.date, this.total);
  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(
    color: Theme.of(context).scaffoldBackgroundColor,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    alignment: Alignment.center,
    child: Row(
      children: [
        Expanded(
          child: Text(
            date == dayOnly(DateTime.now())
                ? 'Today'
                : DateFormat('EEE, d MMM yyyy').format(date),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        AmountText(total, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
  @override
  bool shouldRebuild(_DayHeader old) => old.date != date || old.total != total;
}
