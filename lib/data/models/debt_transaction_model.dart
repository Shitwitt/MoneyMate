import 'package:flutter/foundation.dart';

import 'model_codec.dart';

/// A payment or collection entry attached to a [DebtModel].
@immutable
class DebtTransactionModel {
  const DebtTransactionModel({
    required this.id,
    required this.parentId,
    required this.amount,
    required this.dateTime,
    required this.accountId,
    this.note,
  });

  /// Stable UUID.
  final String id;

  /// Id of the parent debt.
  final String parentId;

  /// Always-positive magnitude paid or collected.
  final double amount;

  /// Local date and time of the payment.
  final DateTime dateTime;

  /// Account used for the payment.
  final String accountId;

  /// Optional note.
  final String? note;

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  factory DebtTransactionModel.fromMap(dynamic raw) {
    final Map<String, dynamic> map = ModelCodec.normalize(
      raw is Map ? raw.cast<dynamic, dynamic>() : null,
    );
    return DebtTransactionModel(
      id: ModelCodec.string(map, 'id'),
      parentId: ModelCodec.string(map, 'parentId'),
      amount: ModelCodec.decimal(map, 'amount'),
      dateTime: ModelCodec.dateTime(map, 'dateTime'),
      accountId: ModelCodec.string(map, 'accountId'),
      note: ModelCodec.nullableString(map, 'note'),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'parentId': parentId,
      'amount': amount,
      'dateTime': ModelCodec.encodeDateTime(dateTime),
      'accountId': accountId,
      'note': note,
    };
  }

  DebtTransactionModel copyWith({
    Object? id = ModelCodec.unset,
    Object? parentId = ModelCodec.unset,
    Object? amount = ModelCodec.unset,
    Object? dateTime = ModelCodec.unset,
    Object? accountId = ModelCodec.unset,
    Object? note = ModelCodec.unset,
  }) {
    return DebtTransactionModel(
      id: ModelCodec.isUnset(id) ? this.id : id as String,
      parentId:
          ModelCodec.isUnset(parentId) ? this.parentId : parentId as String,
      amount: ModelCodec.isUnset(amount) ? this.amount : amount as double,
      dateTime:
          ModelCodec.isUnset(dateTime) ? this.dateTime : dateTime as DateTime,
      accountId: ModelCodec.isUnset(accountId)
          ? this.accountId
          : accountId as String,
      note: ModelCodec.isUnset(note) ? this.note : note as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DebtTransactionModel &&
            other.id == id &&
            other.parentId == parentId &&
            other.amount == amount &&
            other.dateTime == dateTime &&
            other.accountId == accountId &&
            other.note == note;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        parentId,
        amount,
        dateTime,
        accountId,
        note,
      ]);

  @override
  String toString() {
    return 'DebtTransactionModel(id: $id, parentId: $parentId, '
        'amount: $amount, dateTime: ${dateTime.toIso8601String()}, '
        'accountId: $accountId, note: $note)';
  }
}
