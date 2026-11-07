import 'package:flutter/foundation.dart';

import '../../core/enum/filter_enums.dart';
import 'map_utils.dart';

/// A single ledger entry: an expense, an income, or a transfer between two of
/// the user's own accounts.
@immutable
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.time,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.description,
  });

  /// UUID v4 primary key.
  final String id;

  /// Short title, e.g. `Chai at office`.
  final String name;

  /// Always stored positive — the sign comes from [type].
  final double amount;

  /// When the money moved. Stored as an ISO-8601 string.
  final DateTime time;

  final TransactionType type;

  /// Source account. For an expense this is where money left; for income it is
  /// where money arrived; for a transfer it is the account debited.
  final String accountId;

  /// Destination account — only set for [TransactionType.transfer].
  final String? toAccountId;

  /// Category of the entry. `null` (or an orphaned id) for transfers.
  final String? categoryId;

  /// Free-form notes.
  final String? description;

  // ---------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;

  /// Amount with its display sign: `-` for expenses, `+` for income, and no
  /// prefix for transfers.
  double get signedAmount {
    switch (type) {
      case TransactionType.expense:
        return -amount;
      case TransactionType.income:
        return amount;
      case TransactionType.transfer:
        return 0;
    }
  }

  /// Effective balance change for [accountId].
  ///
  /// Returns `null` when this transaction does not touch that account.
  double? deltaForAccount(String targetAccountId) {
    switch (type) {
      case TransactionType.expense:
        return accountId == targetAccountId ? -amount : null;
      case TransactionType.income:
        return accountId == targetAccountId ? amount : null;
      case TransactionType.transfer:
        if (accountId == targetAccountId) return -amount;
        if (toAccountId == targetAccountId) return amount;
        return null;
    }
  }

  /// Calendar day with the time stripped — handy for grouping headers.
  DateTime get dateOnly => DateTime(time.year, time.month, time.day);

  // ---------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'amount': amount,
      'time': writeDateTime(time),
      'type': type.key,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel(
      id: readString(map['id']),
      name: readString(map['name']),
      amount: readAmount(map['amount']),
      time: readDateTime(map['time']),
      type: TransactionTypeX.fromKey(map['type'] as String?),
      accountId: readString(map['accountId']),
      toAccountId: readNullableString(map['toAccountId']),
      categoryId: readNullableString(map['categoryId']),
      description: readNullableString(map['description']),
    );
  }

  TransactionModel copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? time,
    TransactionType? type,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    String? description,
    bool clearToAccount = false,
    bool clearCategory = false,
    bool clearDescription = false,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      time: time ?? this.time,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      toAccountId:
          clearToAccount ? null : (toAccountId ?? this.toAccountId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      description:
          clearDescription ? null : (description ?? this.description),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionModel &&
      other.id == id &&
      other.name == name &&
      other.amount == amount &&
      other.time == time &&
      other.type == type &&
      other.accountId == accountId &&
      other.toAccountId == toAccountId &&
      other.categoryId == categoryId &&
      other.description == description;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        amount,
        time,
        type,
        accountId,
        toAccountId,
        categoryId,
        description,
      );

  @override
  String toString() =>
      'TransactionModel($id, ${type.name}, $name, $amount)';
}
