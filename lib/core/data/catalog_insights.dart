import '../models/models.dart';
import '../utils/dates.dart';
import 'ledger.dart';

/// IDs, never names, define a category subtree. Cycle protection also keeps
/// old/imported data finite; validation still rejects invalid new hierarchies.
Set<String> categorySubtree(ProfileData data, String root) {
  final ids = <String>{root};
  var changed = true;
  while (changed) {
    changed = false;
    for (final category in data.categories) {
      if (category.parentId.isNotEmpty && ids.contains(category.parentId)) {
        changed = ids.add(category.id) || changed;
      }
    }
  }
  return ids;
}

String categoryPath(ProfileData data, String id) {
  final names = <String>[], seen = <String>{};
  while (id.isNotEmpty && seen.add(id)) {
    final category = data.categories.where((c) => c.id == id).firstOrNull;
    if (category == null) break;
    names.insert(0, category.name);
    id = category.parentId;
  }
  return names.join(' › ');
}

bool entityMatches(NamedEntity entity, MoneyTransaction entry) =>
    switch (entity.kind) {
      'person' => entry.personIds.contains(entity.id),
      'place' => entry.placeId == entity.id,
      _ => entry.labelIds.contains(entity.id),
    };

int transactionNet(Ledger ledger, Iterable<MoneyTransaction> entries) =>
    entries.fold<int>(
      0,
      (sum, e) =>
          sum +
          (e.type == 'transfer'
              ? 0
              : ledger.entryValue(e) * (e.type == 'income' ? 1 : -1)),
    );

/// Category analytics consistently use posted, included-account records. A
/// transfer's volume can be inspected, but is never labeled income or expense.
class CategoryActivity {
  final Ledger ledger;
  final DateTime now;
  final Category category;
  final Set<String> ids;
  final List<MoneyTransaction> entries;
  const CategoryActivity._(
    this.ledger,
    this.category,
    this.now,
    this.ids,
    this.entries,
  );
  factory CategoryActivity(
    Ledger ledger,
    Category category,
    DateTime now, {
    String? only,
  }) {
    final subtree = categorySubtree(ledger.data, category.id);
    final ids = only != null && subtree.contains(only) ? {only} : subtree;
    final entries =
        ledger.data.transactions
            .where(
              (e) =>
                  e.type == category.type &&
                  ids.contains(e.categoryId) &&
                  !e.date.isAfter(now) &&
                  !ledger.account(e.accountId).excluded,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return CategoryActivity._(ledger, category, now, ids, entries);
  }
  DateWindow get month => financialMonth(now, ledger.settings.monthStart);
  List<MoneyTransaction> scope(bool overall) =>
      overall ? entries : entries.where((e) => month.contains(e.date)).toList();
  int sum(Iterable<MoneyTransaction> records) =>
      records.fold<int>(0, (s, e) => s + ledger.entryValue(e));
  int total(bool overall) => sum(scope(overall));
  int average(bool overall) {
    final records = scope(overall);
    return records.isEmpty ? 0 : (sum(records) / records.length).round();
  }

  int largest(bool overall) => scope(
    overall,
  ).fold<int>(0, (n, e) => n > ledger.entryValue(e) ? n : ledger.entryValue(e));
  double get entriesPerElapsedDay =>
      scope(false).length / (calendarDaysBetween(month.start, now) + 1);
  DateTime? get lastDate => entries.firstOrNull?.date;
  List<DateWindow> get months =>
      monthlyWindows(now, ledger.settings.monthStart, 18);
  List<DateWindow> get weeks {
    final date = dayOnly(now);
    final offset = (date.weekday - ledger.settings.weekStart + 7) % 7;
    final start = DateTime(date.year, date.month, date.day - offset);
    return List.generate(8, (i) {
      final from = DateTime(start.year, start.month, start.day - (7 - i) * 7);
      return DateWindow(from, DateTime(from.year, from.month, from.day + 7));
    });
  }

  List<int> buckets(List<DateWindow> windows) => [
    for (final w in windows) sum(entries.where((e) => w.contains(e.date))),
  ];
  Map<String, int> get breakdown {
    final values = <String, int>{};
    for (final e in entries)
      values.update(
        e.categoryId,
        (v) => v + ledger.entryValue(e),
        ifAbsent: () => ledger.entryValue(e),
      );
    return Map.fromEntries(
      values.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}
