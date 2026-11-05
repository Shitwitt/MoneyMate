import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/money.dart';
import '../../shared/forms.dart';

Future<void> editRecurring(
  BuildContext context,
  WidgetRef ref, [
  Recurring? initial,
]) async {
  final profile = ref.read(profileProvider)!;
  var accountId =
          initial?.accountId ??
          profile.accounts.firstWhere((item) => !item.archived).id,
      type = initial?.type ?? 'expense',
      frequency = initial?.frequency ?? 'monthly';
  var categoryId =
      initial?.categoryId ??
      profile.categories.firstWhere((item) => item.type == 'expense').id;
  final name = TextEditingController(text: initial?.name ?? ''),
      amount = TextEditingController(
        text: initial == null
            ? ''
            : fromMinor(
                initial.amountMinor,
                profile.accounts
                    .firstWhere((item) => item.id == accountId)
                    .currency,
              ).toString(),
      ),
      interval = TextEditingController(text: '${initial?.interval ?? 1}'),
      notes = TextEditingController(text: initial?.notes ?? '');
  var start = initial?.start ?? DateTime.now().add(const Duration(days: 1));
  var end = initial?.end ?? DateTime.now().add(const Duration(days: 365));
  var hasEnd = initial?.end != null;
  var auto = initial?.autoPost ?? false;
  var reminder = initial?.reminderDays ?? 0;
  var budgetId = initial?.budgetId ?? '', placeId = initial?.placeId ?? '';
  var labels = {...?initial?.labelIds}, people = {...?initial?.personIds};
  await showEditor(
    context,
    title: initial == null ? 'New recurring' : 'Edit recurring',
    description:
        'All amounts use the selected account currency. Automatic entries are created only when Tink opens or resumes, never by a payment provider.',
    fields: (context, setLocal) => [
      formText(name, 'Name', required: true),
      formSelect(
        'Type',
        type,
        ['expense', 'income'],
        (value) => setLocal(() {
          type = value;
          categoryId = profile.categories
              .firstWhere((item) => item.type == type)
              .id;
        }),
      ),
      formSelect(
        'Account',
        accountId,
        profile.accounts.map((item) => item.id).toList(),
        (value) => setLocal(() => accountId = value),
        display: (id) =>
            '${profile.accounts.firstWhere((item) => item.id == id).name} · ${profile.accounts.firstWhere((item) => item.id == id).currency}',
      ),
      formText(
        amount,
        'Amount (account currency)',
        required: true,
        numeric: true,
      ),
      formSelect(
        'Category',
        categoryId,
        profile.categories
            .where((item) => item.type == type)
            .map((item) => item.id)
            .toList(),
        (value) => setLocal(() => categoryId = value),
        display: (id) =>
            profile.categories.firstWhere((item) => item.id == id).name,
      ),
      formSelect(
        'Frequency',
        frequency,
        frequencies,
        (value) => setLocal(() => frequency = value),
      ),
      formText(
        interval,
        frequency == 'custom'
            ? 'Every N days'
            : 'Every N ${frequency == 'daily'
                  ? 'days'
                  : frequency == 'weekly'
                  ? 'weeks'
                  : frequency == 'yearly'
                  ? 'years'
                  : frequency == 'quarterly'
                  ? 'quarters'
                  : frequency == 'half-yearly'
                  ? 'half-years'
                  : frequency == 'fortnightly'
                  ? 'fortnights'
                  : 'months'}',
        required: true,
        numeric: true,
      ),
      formDate(
        context,
        'Starts',
        start,
        (value) => setLocal(() => start = value),
        includeTime: true,
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('End on a date'),
        value: hasEnd,
        onChanged: (value) => setLocal(() => hasEnd = value),
      ),
      if (hasEnd)
        formDate(
          context,
          'Ends (inclusive)',
          end,
          (value) => setLocal(
            () => end = DateTime(value.year, value.month, value.day, 23, 59),
          ),
        ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Auto-create due entries'),
        subtitle: const Text('Otherwise remind me and let me confirm each one'),
        value: auto,
        onChanged: (value) => setLocal(() => auto = value),
      ),
      formSelect(
        'Reminder',
        '$reminder',
        ['0', '1', '3', '7', '14', '30'],
        (value) => setLocal(() => reminder = int.parse(value)),
        display: (value) =>
            value == '0' ? 'On the due date' : '$value days before',
      ),
      const Text(
        'Requires local notifications in Settings. OS delivery may be delayed; the web cannot schedule notifications.',
        style: TextStyle(fontSize: 12),
      ),
      if (profile.budgets.isNotEmpty)
        formSelect(
          'Link a budget',
          budgetId,
          ['', ...profile.budgets.map((b) => b.id)],
          (value) => setLocal(() => budgetId = value),
          display: (id) => id.isEmpty
              ? 'No linked budget'
              : profile.budgets.firstWhere((b) => b.id == id).name,
        ),
      for (final kind in ['label', 'person'])
        if (profile.entities.any((e) => e.kind == kind))
          formChips(
            kind == 'label' ? 'Labels' : 'People',
            {
              for (final e in profile.entities.where((e) => e.kind == kind))
                e.id: e.name,
            },
            kind == 'label' ? labels : people,
            (values) => setLocal(() {
              if (kind == 'label') {
                labels = values;
              } else {
                people = values;
              }
            }),
          ),
      if (profile.entities.any((e) => e.kind == 'place'))
        formSelect(
          'Place',
          placeId,
          [
            '',
            ...profile.entities
                .where((e) => e.kind == 'place')
                .map((e) => e.id),
          ],
          (value) => setLocal(() => placeId = value),
          display: (id) => id.isEmpty
              ? 'No place'
              : profile.entities.firstWhere((e) => e.id == id).name,
        ),
      formText(notes, 'Notes', lines: 2),
    ],
    onSave: () async {
      final step = int.tryParse(interval.text);
      if (step == null || step < 1 || step > 365) {
        throw const FormatException('Interval must be 1–365');
      }
      final currency = profile.accounts
          .firstWhere((item) => item.id == accountId)
          .currency;
      await ref
          .read(appProvider.notifier)
          .upsertRecurring(
            Recurring(
              id: initial?.id ?? uuid.v4(),
              name: name.text.trim(),
              amountMinor: toMinor(evaluateAmount(amount.text), currency),
              accountId: accountId,
              categoryId: categoryId,
              start: start,
              nextDue: initial != null && initial.start == start
                  ? initial.nextDue
                  : start,
              type: type,
              frequency: frequency,
              interval: step,
              end: hasEnd
                  ? DateTime(end.year, end.month, end.day, 23, 59, 59, 999, 999)
                  : null,
              autoPost: auto,
              archived: initial?.archived ?? false,
              reminderDays: reminder,
              budgetId: budgetId,
              placeId: placeId,
              labelIds: labels.toList(),
              personIds: people.toList(),
              enabled: initial?.enabled ?? true,
              notes: notes.text.trim(),
            ),
          );
      await ref.read(appProvider.notifier).processRecurring();
    },
  );
  for (final controller in [name, amount, interval, notes]) {
    controller.dispose();
  }
}
