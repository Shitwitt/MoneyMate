import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_format.dart';
import '../../data/models/analytics_models.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/analytics_charts.dart';
import '../../widgets/period_summary.dart';

/// Overview — the analytics & reports tab.
///
/// Every number on this screen comes from [PaisaProvider.analyticsSnapshot],
/// which buckets the real ledger for the selected time window and transaction
/// type. There is no literal chart data in this file: flip the filter bar and
/// all four charts, the summary card and the leaderboard are recomputed from
/// the stored transactions.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  /// Index of the expanded donut slice, `-1` at rest.
  int _touchedSlice = -1;

  /// Highlighted bar group on the monthly chart, `-1` for none.
  int _touchedGroup = -1;

  /// Bar-chart span override (`6` or `12` months); `null` follows the range.
  int? _monthsOverride;

  void _resetTouchState() {
    if (_touchedSlice == -1 && _touchedGroup == -1) return;
    setState(() {
      _touchedSlice = -1;
      _touchedGroup = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = provider.formatter;

    final AnalyticsRange range = provider.analyticsRange;
    final AnalyticsTypeFilter type = provider.analyticsType;
    final AnalyticsSnapshot snapshot = provider.analyticsSnapshot(
      monthsShown: _monthsOverride,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ---------------- Sticky filter bar ----------------
        _FilterBar(
          range: range,
          type: type,
          scopeLabel: snapshot.scopeLabel,
          onRange: (AnalyticsRange next) {
            _resetTouchState();
            if (next != range) provider.setAnalyticsRange(next);
          },
          onType: (AnalyticsTypeFilter next) {
            _resetTouchState();
            if (next != type) provider.setAnalyticsType(next);
          },
        ),

        Expanded(
          child: ListView(
            key: const PageStorageKey<String>('analytics_scroll'),
            padding: const EdgeInsets.only(bottom: 128),
            children: <Widget>[
              // ---------------- Net cashflow & savings rate ----------------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _NetCashflowCard(
                  snapshot: snapshot,
                  formatter: formatter,
                  hideAmounts: provider.hideAmounts,
                  onTogglePrivacy: () => provider.setHideAmounts(
                    !provider.hideAmounts,
                  ),
                ),
              ),

              // ---------------- Chart 1 — income vs expense ----------------
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnalyticsCard(
                  title: 'Income vs expense',
                  subtitle: _flowSubtitle(snapshot),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (type != AnalyticsTypeFilter.expense)
                        ChartLegendDot(
                          color: PaisaColors.of(context).income,
                          label: 'Income',
                        ),
                      if (type != AnalyticsTypeFilter.income) ...<Widget>[
                        if (type == AnalyticsTypeFilter.all)
                          const SizedBox(height: 4),
                        ChartLegendDot(
                          color: PaisaColors.of(context).expense,
                          label: 'Expense',
                        ),
                      ],
                    ],
                  ),
                  child: !snapshot.hasFlow
                      ? const ChartEmptyState(
                          icon: Icons.show_chart_rounded,
                          message:
                              'No money moved in this window yet.\nAdd a '
                              'transaction and the trend appears here.',
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 6, top: 4),
                          child: IncomeExpenseLineChart(
                            points: snapshot.flowPoints,
                            formatter: formatter,
                            showIncome: type != AnalyticsTypeFilter.expense,
                            showExpense: type != AnalyticsTypeFilter.income,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    if (type != AnalyticsTypeFilter.expense)
                      Expanded(
                        child: _FlowTotalTile(
                          label: 'Money in',
                          value: formatter.formatWhole(snapshot.income),
                          icon: Icons.south_west_rounded,
                          color: PaisaColors.of(context).income,
                          container: PaisaColors.of(context).incomeContainer,
                        ),
                      ),
                    if (type == AnalyticsTypeFilter.all)
                      const SizedBox(width: 10),
                    if (type != AnalyticsTypeFilter.income)
                      Expanded(
                        child: _FlowTotalTile(
                          label: 'Money out',
                          value: formatter.formatWhole(snapshot.expense),
                          icon: Icons.north_east_rounded,
                          color: PaisaColors.of(context).expense,
                          container: PaisaColors.of(context).expenseContainer,
                        ),
                      ),
                  ],
                ),
              ),

              // ---------------- Chart 2 — category donut ----------------
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnalyticsCard(
                  title: type == AnalyticsTypeFilter.income
                      ? 'Where the money came from'
                      : 'Where the money went',
                  subtitle: snapshot.categorySlices.isEmpty
                      ? 'No categorised records in this window'
                      : '${snapshot.categorySlices.length} '
                          '${snapshot.categorySlices.length == 1 ? 'category' : 'categories'}'
                          ' · tap a slice',
                  trailing: snapshot.categorySlices.isEmpty
                      ? null
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            formatter.compact(snapshot.analysedTotal),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                  child: snapshot.categorySlices.isEmpty
                      ? const ChartEmptyState(
                          icon: Icons.donut_large_rounded,
                          message:
                              'Nothing to break down yet. Categorised expenses '
                              'show up here as a donut.',
                        )
                      : Column(
                          children: <Widget>[
                            CategoryDonut(
                              slices: snapshot.categorySlices,
                              formatter: formatter,
                              touchedIndex: _touchedSlice,
                              onTouch: (int index) {
                                if (index == _touchedSlice) return;
                                setState(() => _touchedSlice = index);
                              },
                            ),
                            const SizedBox(height: 6),
                            _CategoryLeaderboard(
                              slices: snapshot.categorySlices,
                              formatter: formatter,
                              highlighted: _touchedSlice,
                              onHighlight: (int index) {
                                setState(() => _touchedSlice = index);
                              },
                            ),
                          ],
                        ),
                ),
              ),

              // ---------------- Chart 3 — monthly bars ----------------
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnalyticsCard(
                  title: 'Monthly comparison',
                  subtitle:
                      'Last ${snapshot.monthsShown} months · income vs expense',
                  trailing: _SpanToggle(
                    months: snapshot.monthsShown,
                    onChanged: (int months) =>
                        setState(() => _monthsOverride = months),
                  ),
                  child: !snapshot.hasMonthlyFlow
                      ? ChartEmptyState(
                          icon: Icons.bar_chart_rounded,
                          message:
                              'No monthly history yet.\nYour first entry starts '
                              'the comparison.',
                          height: 170,
                        )
                      : Column(
                          children: <Widget>[
                            MonthlyFlowBarChart(
                              flows: snapshot.monthlyFlows,
                              formatter: formatter,
                              showIncome: type != AnalyticsTypeFilter.expense,
                              showExpense: type != AnalyticsTypeFilter.income,
                              touchedGroup: _touchedGroup,
                              onTouchGroup: (int index) {
                                if (index == _touchedGroup) return;
                                setState(() => _touchedGroup = index);
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                if (type != AnalyticsTypeFilter.expense)
                                  ChartLegendDot(
                                    color: PaisaColors.of(context).income,
                                    label: 'Income',
                                  ),
                                if (type == AnalyticsTypeFilter.all)
                                  const SizedBox(width: 18),
                                if (type != AnalyticsTypeFilter.income)
                                  ChartLegendDot(
                                    color: PaisaColors.of(context).expense,
                                    label: 'Expense',
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),

              // ---------------- Chart 4 — account distribution ----------------
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnalyticsCard(
                  title: 'Account distribution',
                  subtitle: _accountSubtitle(snapshot, type),
                  child: !snapshot.hasAccountSplit
                      ? const ChartEmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          message:
                              'No account activity in this window.\nEvery '
                              'entry is attributed to an account.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AccountDistributionBar(
                              shares: snapshot.accountShares,
                              formatter: formatter,
                            ),
                            const SizedBox(height: 4),
                            AccountTypeCaption(
                              shares: snapshot.typeShares,
                              formatter: formatter,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.insights_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Charts are rebuilt from your ledger every time the '
                        'filters change — nothing here is a sample.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
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

  String _flowSubtitle(AnalyticsSnapshot snapshot) {
    if (snapshot.flowPoints.isEmpty) return 'Nothing to plot yet';
    final bool byMonth = snapshot.flowPoints.first.monthBucket;
    final int buckets = snapshot.flowPoints.length;
    final String unit = byMonth
        ? (buckets == 1 ? 'month' : 'months')
        : (buckets == 1 ? 'day' : 'days');
    return byMonth
        ? 'Month-by-month flow · $buckets $unit'
        : 'Day-by-day flow · $buckets $unit';
  }

  String _accountSubtitle(
    AnalyticsSnapshot snapshot,
    AnalyticsTypeFilter type,
  ) {
    if (snapshot.accountShares.isEmpty) return 'Nothing to split yet';
    final int count = snapshot.accountShares.length;
    final String verb =
        type == AnalyticsTypeFilter.income ? 'Received into' : 'Paid from';
    return '$verb $count ${count == 1 ? 'account' : 'accounts'} '
        '· ${snapshot.transactionCount} '
        '${snapshot.transactionCount == 1 ? 'record' : 'records'}';
  }
}

// ---------------------------------------------------------------------------
// Sticky filter bar
// ---------------------------------------------------------------------------

/// The pinned header: title, live scope line, the four time chips and the
/// three-way type segment.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.range,
    required this.type,
    required this.scopeLabel,
    required this.onRange,
    required this.onType,
  });

  final AnalyticsRange range;
  final AnalyticsTypeFilter type;
  final String scopeLabel;
  final ValueChanged<AnalyticsRange> onRange;
  final ValueChanged<AnalyticsTypeFilter> onType;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Analytics & reports',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Icon(
                            range.icon,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              scopeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
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
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: AnalyticsRange.values.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final AnalyticsRange value = AnalyticsRange.values[index];
                return _RangeChip(
                  label: value.label,
                  selected: value == range,
                  onTap: () => onRange(value),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _TypeSegment(type: type, onChanged: onType),
          ),
        ],
      ),
    );
  }
}

/// An M3 tonal pill used for the time window filters.
class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom segmented control: full `All / Expense Only / Income Only` labels that
/// stay readable on a narrow phone, animated with a sliding tonal pill.
class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.type, required this.onChanged});

  final AnalyticsTypeFilter type;
  final ValueChanged<AnalyticsTypeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    // Narrow phones get the one-word labels so the segment never truncates.
    final bool compact = MediaQuery.sizeOf(context).width < 380;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          for (final AnalyticsTypeFilter value in AnalyticsTypeFilter.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == type,
                label: value.label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: value == type
                          ? scheme.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: value == type
                          ? <BoxShadow>[
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.16),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            compact ? value.shortLabel : value.label,
                            maxLines: 1,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: value == type
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: value == type
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small `6M / 12M` toggle on the monthly chart card.
class _SpanToggle extends StatelessWidget {
  const _SpanToggle({required this.months, required this.onChanged});

  final int months;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Widget pill(int value) {
      final bool selected = months == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${value}M',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[pill(6), pill(12)],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Net cashflow & savings rate
// ---------------------------------------------------------------------------

/// Hero summary: net cashflow, savings rate, average daily spend and the single
/// highest spending day — all four read straight from the snapshot.
class _NetCashflowCard extends StatelessWidget {
  const _NetCashflowCard({
    required this.snapshot,
    required this.formatter,
    required this.hideAmounts,
    required this.onTogglePrivacy,
  });

  final AnalyticsSnapshot snapshot;
  final CurrencyFormatter formatter;
  final bool hideAmounts;
  final VoidCallback onTogglePrivacy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final bool positive = snapshot.net >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.surfaceContainerHighest.withAlpha(140),
              scheme.primaryContainer,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 17,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 7),
              Text(
                'Net cashflow',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (snapshot.type != AnalyticsTypeFilter.expense)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    snapshot.savingsRate >= 0
                        ? 'Saved ${formatter.percent(snapshot.savingsRate)} '
                            'of income'
                        : 'Overspent '
                            '${formatter.percent(snapshot.savingsRate.abs())}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: hideAmounts ? 'Show amounts' : 'Hide amounts',
                onPressed: onTogglePrivacy,
                icon: Icon(
                  hideAmounts
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedAmount(
            value: snapshot.net,
            formatter: formatter,
            hide: hideAmounts,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: positive ? scheme.onPrimaryContainer : colors.expense,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            snapshot.type == AnalyticsTypeFilter.income
                ? 'Income minus nothing — showing money in only'
                : 'Income minus expense · transfers excluded',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricTile(
                  icon: Icons.savings_outlined,
                  label: 'Savings rate',
                  value: snapshot.income <= 0
                      ? '—'
                      : formatter.percent(snapshot.savingsRate),
                  hint: snapshot.income <= 0
                      ? 'No income in window'
                      : 'of ${formatter.compact(snapshot.income)} in',
                  accent: snapshot.savingsRate >= 0
                      ? colors.income
                      : colors.expense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Avg daily spend',
                  value: formatter.formatWhole(snapshot.averageDailySpend),
                  hint: 'over ${snapshot.elapsedDays} '
                      '${snapshot.elapsedDays == 1 ? 'day' : 'days'}',
                  accent: colors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.30 : 0.55,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.expense.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: colors.expense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Highest spending day',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        snapshot.highestSpendingDay == null
                            ? 'No spending in this window'
                            : DateTimeFormat.date(
                                snapshot.highestSpendingDay!.date,
                              ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  snapshot.highestSpendingDay == null
                      ? '—'
                      : formatter.formatWhole(
                          snapshot.highestSpendingDay!.expense,
                        ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.expense,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.30 : 0.55,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category leaderboard
// ---------------------------------------------------------------------------

/// Ranked list under the donut: icon, name, transaction count, amount, share and
/// a mini progress bar. Tapping a row highlights the matching donut slice.
class _CategoryLeaderboard extends StatelessWidget {
  const _CategoryLeaderboard({
    required this.slices,
    required this.formatter,
    required this.highlighted,
    required this.onHighlight,
  });

  final List<CategorySlice> slices;
  final CurrencyFormatter formatter;
  final int highlighted;
  final ValueChanged<int> onHighlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int visible = slices.length > 6 ? 6 : slices.length;

    return Column(
      children: <Widget>[
        for (int i = 0; i < visible; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onHighlight(highlighted == i ? -1 : i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: highlighted == i
                        ? Color(slices[i].colorValue).withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(slices[i].colorValue).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          IconData(
                            slices[i].iconCodePoint,
                            fontFamily: 'MaterialIcons',
                          ),
                          size: 18,
                          color: Color(slices[i].colorValue),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    slices[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatter.formatWhole(slices[i].amount),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: <Widget>[
                                Text(
                                  '${slices[i].count} '
                                  '${slices[i].count == 1 ? 'txn' : 'txns'}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 9.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '· ${formatter.percent(slices[i].share)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Color(slices[i].colorValue),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: slices[i].share.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor:
                                    scheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(slices[i].colorValue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (slices.length > visible)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+${slices.length - visible} more · see the full breakdown in '
              'Budgets',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// One of the two tonal totals under the trend chart.
class _FlowTotalTile extends StatelessWidget {
  const _FlowTotalTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.container,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color container;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
