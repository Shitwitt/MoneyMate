import 'package:flutter/material.dart';

import '../../core/data/ledger.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/forms.dart';

Future<TransactionFilter?> showTransactionFilters(
  BuildContext context,
  ProfileData profile,
  TransactionFilter initial,
) async {
  var accounts = {...initial.accounts},
      categories = {...initial.categories},
      excludedCategories = {...initial.excludedCategories},
      labels = {...initial.labels},
      people = {...initial.people},
      places = {...initial.places};
  var type = initial.type, sort = initial.sort;
  var posted = initial.postedOnly,
      included = initial.includedOnly,
      cashFlow = initial.cashFlowOnly,
      lastWeek = initial.lastWeekOfMonth;
  var weekday = initial.weekday;
  final exact = TextEditingController(text: initial.exactName);
  var dates = initial.dates;
  final min = TextEditingController(
    text: initial.minMinor == null
        ? ''
        : fromMinor(initial.minMinor!, profile.profile.currency).toString(),
  );
  final max = TextEditingController(
    text: initial.maxMinor == null
        ? ''
        : fromMinor(initial.maxMinor!, profile.profile.currency).toString(),
  );
  TransactionFilter? result;
  await showEditor(
    context,
    title: 'Find exactly what matters',
    saveLabel: 'Apply filters',
    fields: (context, setLocal) => [
      SwitchListTile.adaptive(
        title: const Text('Posted records only'),
        value: posted,
        onChanged: (v) => setLocal(() => posted = v),
      ),
      SwitchListTile.adaptive(
        title: const Text('Included accounts only'),
        value: included,
        onChanged: (v) => setLocal(() => included = v),
      ),
      SwitchListTile.adaptive(
        title: const Text('Income and expense only'),
        value: cashFlow,
        onChanged: (v) => setLocal(() => cashFlow = v),
      ),
      SwitchListTile.adaptive(
        title: const Text('Final seven calendar days of each month'),
        value: lastWeek,
        onChanged: (v) => setLocal(() => lastWeek = v),
      ),
      formSelect(
        'Weekday',
        weekday?.toString() ?? '',
        ['', for (var i = 0; i < 7; i++) '$i'],
        (v) => setLocal(() => weekday = int.tryParse(v)),
        display: (v) => v.isEmpty
            ? 'Any weekday'
            : const [
                'Sunday',
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
              ][int.parse(v)],
      ),
      formText(exact, 'Exact transaction name (optional)'),
      formSelect('Transaction type', type, [
        'all',
        'expense',
        'income',
        'transfer',
      ], (value) => setLocal(() => type = value)),
      OutlinedButton.icon(
        icon: const Icon(Icons.date_range_rounded),
        label: Text(
          dates == null
              ? 'All dates · choose a range'
              : '${dates!.start.toString().substring(0, 10)} — ${dates!.end.subtract(const Duration(days: 1)).toString().substring(0, 10)}',
        ),
        onPressed: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(1970),
            lastDate: DateTime(2200),
            initialDateRange: dates == null
                ? null
                : DateTimeRange(
                    start: dates!.start,
                    end: dates!.end.subtract(const Duration(days: 1)),
                  ),
          );
          if (range != null) {
            setLocal(
              () =>
                  dates = DateWindow(dayOnly(range.start), nextDay(range.end)),
            );
          }
        },
      ),
      if (dates != null)
        TextButton(
          onPressed: () => setLocal(() => dates = null),
          child: const Text('Clear date range'),
        ),
      formChips(
        'Accounts',
        {for (final item in profile.accounts) item.id: item.name},
        accounts,
        (value) => setLocal(() => accounts = value),
      ),
      formChips(
        'Categories',
        {for (final item in profile.categories) item.id: item.name},
        categories,
        (value) => setLocal(() => categories = value),
      ),
      formChips(
        'Exclude categories (including children)',
        {for (final item in profile.categories) item.id: item.name},
        excludedCategories,
        (value) => setLocal(() => excludedCategories = value),
      ),
      for (final kind in ['label', 'person', 'place'])
        if (profile.entities.any((item) => item.kind == kind))
          formChips(
            switch (kind) {
              'person' => 'People',
              'place' => 'Places',
              _ => 'Labels',
            },
            {
              for (final item in profile.entities.where(
                (item) => item.kind == kind,
              ))
                item.id: item.name,
            },
            kind == 'label'
                ? labels
                : kind == 'person'
                ? people
                : places,
            (value) => setLocal(() {
              if (kind == 'label') {
                labels = value;
              } else if (kind == 'person') {
                people = value;
              } else {
                places = value;
              }
            }),
          ),
      Row(
        children: [
          Expanded(
            child: formText(
              min,
              'Minimum (${profile.profile.currency})',
              numeric: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: formText(max, 'Maximum', numeric: true)),
        ],
      ),
      formSelect('Sort', sort, [
        'newest',
        'oldest',
        'largest',
        'smallest',
      ], (value) => setLocal(() => sort = value)),
      TextButton(
        onPressed: () => setLocal(() {
          exact.clear();
          posted = false;
          included = false;
          cashFlow = false;
          lastWeek = false;
          weekday = null;
          accounts = {};
          categories = {};
          excludedCategories = {};
          labels = {};
          people = {};
          places = {};
          type = 'all';
          dates = null;
          min.clear();
          max.clear();
          sort = 'newest';
        }),
        child: const Text('Clear every filter'),
      ),
    ],
    onSave: () async {
      int? parse(TextEditingController controller) {
        if (controller.text.trim().isEmpty) return null;
        final value = num.tryParse(controller.text.replaceAll(',', ''));
        if (value == null || !value.isFinite || value < 0) {
          throw const FormatException('Enter a nonnegative filter amount');
        }
        return toMinor(value, profile.profile.currency);
      }

      final low = parse(min), high = parse(max);
      if (low != null && high != null && low > high) {
        throw const FormatException('Minimum cannot exceed maximum');
      }
      result = TransactionFilter(
        query: initial.query,
        exactName: exact.text,
        postedOnly: posted,
        includedOnly: included,
        cashFlowOnly: cashFlow,
        lastWeekOfMonth: lastWeek,
        weekday: weekday,
        dates: dates,
        accounts: accounts,
        categories: categories,
        excludedCategories: excludedCategories,
        labels: labels,
        people: people,
        places: places,
        type: type,
        minMinor: low,
        maxMinor: high,
        sort: sort,
      );
    },
  );
  exact.dispose();
  min.dispose();
  max.dispose();
  return result;
}
