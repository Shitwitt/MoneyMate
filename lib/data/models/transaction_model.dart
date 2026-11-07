import 'package:flutter/foundation.dart';

import '../../core/enum/filter_enums.dart';
import 'model_codec.dart';

/// A single income, expense, or transfer stored as Hive primitives.
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

  /// Stable UUID.
  final String id;

  /// Merchant, payee, or user-supplied title.
  final String name;

  /// Always-positive magnitude in the user's base currency.
  final double amount;

  /// Local date and time for the transaction.
  final DateTime time;

  /// Direction of the ledger entry.
  final TransactionType type;

  /// Source account id.
  final String accountId;

  /// Destination account id for transfers.
  final String? toAccountId;

  /// Category id; null for transfers and uncategorized entries.
  final String? categoryId;

  /// Optional note.
  final String? description;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;
  bool get requiresCategory => !isTransfer;
  bool get canHaveDestination => isTransfer;
  bool get hasDestination => toAccountId != null && toAccountId!.isNotEmpty;
  bool get isCategorized => categoryId != null && categoryId!.isNotEmpty;
  bool get hasNote => description != null && description!.trim().isNotEmpty;

  /// Signed contribution to a net balance calculation.
  double get signedAmount {
    switch (type) {
      case TransactionType.income:
        return amount;
      case TransactionType.expense:
        return -amount;
      case TransactionType.transfer:
        return 0;
    }
  }

  String get displayAmount {
    switch (type) {
      case TransactionType.income:
        return '+$amount';
      case TransactionType.expense:
        return '-$amount';
      case TransactionType.transfer:
        return '↔ $amount';
    }
  }

  factory TransactionModel.fromMap(dynamic raw) {
    final Map<String, dynamic> map = ModelCodec.normalize(
      raw is Map ? raw.cast<dynamic, dynamic>() : null,
    );
    return TransactionModel(
      id: ModelCodec.string(map, 'id'),
      name: ModelCodec.string(map, 'name', fallback: 'Transaction'),
      amount: ModelCodec.decimal(map, 'amount'),
      time: ModelCodec.dateTime(map, 'time'),
      type: ModelCodec.decodeEnum<TransactionType>(
        map,
        'type',
        TransactionType.values,
        TransactionType.expense,
      ),
      accountId: ModelCodec.string(map, 'accountId'),
      toAccountId: ModelCodec.nullableString(map, 'toAccountId'),
      categoryId: ModelCodec.nullableString(map, 'categoryId'),
      description: ModelCodec.nullableString(map, 'description'),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'amount': amount,
      'time': ModelCodec.encodeDateTime(time),
      'type': ModelCodec.encodeEnum(type),
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'description': description,
    };
  }

  TransactionModel copyWith({
    Object? id = ModelCodec.unset,
    Object? name = ModelCodec.unset,
    Object? amount = ModelCodec.unset,
    Object? time = ModelCodec.unset,
    Object? type = ModelCodec.unset,
    Object? accountId = ModelCodec.unset,
    Object? toAccountId = ModelCodec.unset,
    Object? categoryId = ModelCodec.unset,
    Object? description = ModelCodec.unset,
  }) {
    return TransactionModel(
      id: ModelCodec.isUnset(id) ? this.id : id as String,
      name: ModelCodec.isUnset(name) ? this.name : name as String,
      amount: ModelCodec.isUnset(amount) ? this.amount : amount as double,
      time: ModelCodec.isUnset(time) ? this.time : time as DateTime,
      type: ModelCodec.isUnset(type) ? this.type : type as TransactionType,
      accountId:
          ModelCodec.isUnset(accountId) ? this.accountId : accountId as String,
      toAccountId: ModelCodec.isUnset(toAccountId)
          ? this.toAccountId
          : toAccountId as String?,
      categoryId: ModelCodec.isUnset(categoryId)
          ? this.categoryId
          : categoryId as String?,
      description: ModelCodec.isUnset(description)
          ? this.description
          : description as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
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
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        name,
        amount,
        time,
        type,
        accountId,
        toAccountId,
        categoryId,
        description,
      ]);

  @override
  String toString() {
    return 'TransactionModel(id: $id, name: $name, amount: $amount, '
        'time: ${time.toIso8601String()}, type: ${type.name}, '
        'accountId: $accountId, toAccountId: $toAccountId, '
        'categoryId: $categoryId, description: $description)';
  }
}
