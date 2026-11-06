import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/widgets.dart';
import 'transaction_tile.dart';

const transactionPeriods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
DateTime transactionGroup(DateTime date, int period, int weekStart) =>
    switch (period) {
      1 => DateTime(
        date.year,
        date.month,
        date.day - (date.weekday - weekStart + 7) % 7,
      ),
      2 => DateTime(date.year, date.month),
      3 => DateTime(date.year),
      _ => dayOnly(date),
    };

/// Bounded initial rendering with genuine load-more; no records are discarded.
/// Grouping changes presentation only, never which records/totals are selected.
class GroupedTransactions extends ConsumerStatefulWidget {
  final List<MoneyTransaction> entries;
  final int period;
  const GroupedTransactions(this.entries, {super.key, this.period = 0});
  @override
  ConsumerState<GroupedTransactions> createState() =>
      _GroupedTransactionsState();
}

class _GroupedTransactionsState extends ConsumerState<GroupedTransactions> {
  int limit = 50;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final entries = [...widget.entries]
      ..sort((a, b) => b.date.compareTo(a.date));
    final groups = <DateTime, List<MoneyTransaction>>{};
    for (final e in entries.take(limit)) {
      (groups[transactionGroup(
                e.date,
                widget.period,
                ledger.settings.weekStart,
              )] ??=
              [])
          .add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entries.isEmpty)
          const EmptyState(
            title: 'No transactions yet',
            message: 'Matching records will appear here.',
            icon: Icons.receipt_long_outlined,
          ),
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                Text(switch (widget.period) {
                  1 => 'Week of ${DateFormat.yMMMd().format(group.key)}',
                  2 => DateFormat.yMMMM().format(group.key),
                  3 => DateFormat.y().format(group.key),
                  _ => DateFormat.yMMMEd().format(group.key),
                }, style: Theme.of(context).textTheme.titleSmall),
                // A partially rendered group must not claim a truncated amount is its
                // complete total. Sum all matching entries in this bucket instead.
                AmountText(
                  entries
                      .where(
                        (e) =>
                            transactionGroup(
                              e.date,
                              widget.period,
                              ledger.settings.weekStart,
                            ) ==
                            group.key,
                      )
                      .fold<int>(
                        0,
                        (sum, e) =>
                            sum +
                            (e.type == 'income'
                                ? ledger.entryValue(e)
                                : e.type == 'expense'
                                ? -ledger.entryValue(e)
                                : 0),
                      ),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final entry in group.value) TransactionTile(entry),
              ],
            ),
          ),
        ],
        if (entries.length > limit)
          TextButton.icon(
            onPressed: () => setState(() => limit += 50),
            icon: const Icon(Icons.expand_more),
            label: Text('Show more · ${entries.length - limit} remaining'),
          ),
      ],
    );
  }
}
