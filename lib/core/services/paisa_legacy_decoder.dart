// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Hemanth S
// Copyright (C) 2026 Tink contributors (adaptation)
// Adapted 2026-11-06 from confumbit/Paisa@369aee29ebf51dd5007deca2bb414917f12b208a:
// PaisaDataResponse and the account/category/transaction/debit/debt-transaction
// JSON model factories. See third_party/paisa_6_3_6/NOTICE.md and LICENSE.
// Changes: typed records instead of Hive/Freezed, strict scalar/enum/ID checks,
// bounded collections, exact legacy-version check, and both repayment key names.

import '../models/models.dart';

typedef LegacyAccount = ({
  int id,
  String name,
  String bankName,
  String type,
  num opening,
  int color,
  bool excluded,
});
typedef LegacyCategory = ({
  int id,
  String name,
  String description,
  String type,
  int icon,
  num budget,
  bool isBudget,
  int color,
});
typedef LegacyTransaction = ({
  int id,
  int accountId,
  int? fromAccountId,
  int? toAccountId,
  int categoryId,
  num amount,
  String name,
  String description,
  String type,
  DateTime date,
});
typedef LegacyDebt = ({
  int id,
  String name,
  String description,
  num amount,
  String type,
  DateTime start,
  DateTime end,
  int icon,
  int color,
  bool completed,
});
typedef LegacyPayment = ({
  int id,
  int parentId,
  num amount,
  DateTime date,
  String type,
});

class Paisa636Data {
  final List<LegacyAccount> accounts;
  final List<LegacyCategory> categories;
  final List<LegacyTransaction> transactions;
  final List<LegacyDebt> debts;
  final List<LegacyPayment> payments;

  const Paisa636Data._(
    this.accounts,
    this.categories,
    this.transactions,
    this.debts,
    this.payments,
  );

  factory Paisa636Data.fromJson(Json json) {
    final version = json['version'];
    if (version is! String ||
        !RegExp(r'^v?6\.3\.6(?:\+636)?$').hasMatch(version)) {
      throw const FormatException(
        'This importer supports Paisa 6.3.6 JSON exports only, not current Paisa backups or Tink restore files.',
      );
    }
    const allowed = {
      'version',
      'accounts',
      'categories',
      'expenses',
      'debts',
      'transactions',
      'debitTransactions',
    };
    if (json.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException(
        'Unknown backup sections. Import stopped; no data was changed.',
      );
    }
    for (final key in ['accounts', 'categories', 'expenses']) {
      if (json[key] is! List) throw FormatException('Missing legacy $key list');
    }
    List<T> models<T>(String key, T Function(Json) decode) {
      final list = json[key];
      if (list == null) return <T>[];
      if (list is! List || list.length > 200000) {
        throw FormatException('Invalid or oversized legacy $key list');
      }
      return list.map((value) {
        if (value is! Map<String, dynamic>) {
          throw FormatException('Invalid record in legacy $key');
        }
        return decode(value);
      }).toList();
    }

    // Upstream's exporter wrote `transactions`, but its parser expected
    // `debitTransactions`. Never silently drop or double-count repayments.
    final exportedPayments = models('transactions', _payment);
    final parsedPayments = models('debitTransactions', _payment);
    if (exportedPayments.isNotEmpty && parsedPayments.isNotEmpty) {
      throw const FormatException(
        'Both legacy repayment arrays contain records. Resolve the ambiguity in a copy of the backup before importing.',
      );
    }
    return Paisa636Data._(
      models('accounts', _account),
      models('categories', _category),
      models('expenses', _transaction),
      models('debts', _debt),
      exportedPayments.isNotEmpty ? exportedPayments : parsedPayments,
    );
  }

  // Adapted from AccountModelImplFromJson, account_model.g.dart.
  static LegacyAccount _account(Json json) => (
    id: _id(json['superId']),
    name: _text(json['name']),
    bankName: _text(json['bankName'], optional: true),
    type: _enum(json['cardType'], ['cash', 'bank', 'wallet'], 'bank'),
    opening: _number(json['amount'] ?? 0),
    color: _color(json['color'], 0xffffc107),
    excluded: _boolean(json['isAccountExcluded']),
  );

  // Adapted from CategoryModelImplFromJson, category_model.g.dart.
  static LegacyCategory _category(Json json) => (
    id: _id(json['superId']),
    name: _text(json['name']),
    description: _text(json['description'], optional: true),
    type: _enum(json['categoryType'], [
      'income',
      'expense',
      'transfer',
    ], 'income'),
    icon: _integer(json['icon']),
    budget: _number(json['budget'] ?? 0),
    isBudget: _boolean(json['isBudget']),
    color: _color(json['color'], 0xff916cff),
  );

  // Adapted from TransactionModelImplFromJson, transaction_model.g.dart.
  static LegacyTransaction _transaction(Json json) => (
    id: _id(json['superId']),
    accountId: _integer(json['accountId']),
    fromAccountId: json['fromAccountId'] == null
        ? null
        : _integer(json['fromAccountId']),
    toAccountId: json['toAccountId'] == null
        ? null
        : _integer(json['toAccountId']),
    categoryId: _integer(json['categoryId']),
    amount: _number(json['currency'] ?? 0),
    name: _text(json['name']),
    description: _text(json['description'], optional: true),
    type: _enum(json['type'], ['expense', 'income', 'transfer'], 'expense'),
    date: _date(json['time']),
  );

  // Adapted from DebitModelImplFromJson, debit_model.g.dart.
  static LegacyDebt _debt(Json json) => (
    id: _id(json['superId']),
    name: _text(json['name']),
    description: _text(json['description'], optional: true),
    amount: _number(json['amount']),
    type: _enum(json['debtType'], ['debit', 'credit', 'goal'], 'debit'),
    start: _date(json['startDateTime']),
    end: _date(json['expiryDateTime']),
    icon: _integer(json['icon'] ?? 0xf04b6),
    color: _color(json['color'], 0xff000000),
    completed: _boolean(json['isCompleted']),
  );

  // Adapted from DebitTransactionsModelImplFromJson, debit_transactions_model.g.dart.
  static LegacyPayment _payment(Json json) => (
    id: _id(json['superId']),
    parentId: _id(json['parentId']),
    amount: _number(json['amount']),
    date: _date(json['now']),
    type: _enum(json['type'], ['debit', 'goal'], 'debit'),
  );
}

int _integer(Object? value) {
  if (value is! num ||
      !value.isFinite ||
      value != value.truncateToDouble() ||
      value.abs() > 9007199254740991) {
    throw const FormatException(
      'Legacy IDs and icon/color codes must be finite integers.',
    );
  }
  return value.toInt();
}

int _id(Object? value) {
  final id = _integer(value);
  if (id < 0)
    throw const FormatException(
      'A legacy record has a missing or negative ID.',
    );
  return id;
}

int _color(Object? value, int fallback) {
  if (value == null) return fallback;
  final color = _integer(value);
  if (color < 0 || color > 0xffffffff)
    throw const FormatException('Invalid legacy color.');
  return color;
}

num _number(Object? value) {
  if (value is! num || !value.isFinite || value.abs() > 1000000000000) {
    throw const FormatException('A legacy amount is invalid or out of range.');
  }
  return value;
}

String _text(Object? value, {bool optional = false}) {
  if (value == null && optional) return '';
  if (value is! String ||
      value.length > 10000 ||
      !optional && value.trim().isEmpty) {
    throw const FormatException('Invalid legacy text.');
  }
  return value;
}

String _enum(Object? value, List<String> allowed, String fallback) {
  if (value == null) return fallback;
  if (value is! String || !allowed.contains(value))
    throw const FormatException('Unknown legacy record type.');
  return value;
}

bool _boolean(Object? value) {
  if (value == null) return false;
  if (value is! bool)
    throw const FormatException('Invalid legacy switch value.');
  return value;
}

DateTime _date(Object? value) {
  if (value is! String || value.length > 40) {
    throw const FormatException('Legacy dates must be ISO timestamps.');
  }
  final parts = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?(?:Z|([+-])(\d{2}):?(\d{2}))?$',
  ).firstMatch(value);
  if (parts == null)
    throw const FormatException('Legacy dates must be ISO timestamps.');
  final year = int.parse(parts[1]!);
  final month = int.parse(parts[2]!);
  final day = int.parse(parts[3]!);
  final calendar = DateTime(year, month, day);
  final date = DateTime.tryParse(value);
  if (calendar.year != year ||
      calendar.month != month ||
      calendar.day != day ||
      int.parse(parts[4]!) > 23 ||
      int.parse(parts[5]!) > 59 ||
      int.parse(parts[6]!) > 59 ||
      (parts[8] != null && int.parse(parts[8]!) > 23) ||
      (parts[9] != null && int.parse(parts[9]!) > 59) ||
      date == null ||
      date.year < 1970 ||
      date.year > 2200) {
    throw const FormatException('Invalid legacy date.');
  }
  return date;
}
