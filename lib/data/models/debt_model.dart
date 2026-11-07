import 'package:flutter/foundation.dart';

import '../../core/enum/filter_enums.dart';
import 'model_codec.dart';

/// A loan or credit record stored as Hive primitives.
@immutable
class DebtModel {
  const DebtModel({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.expiryDateTime,
    required this.debtType,
  });

  /// Stable UUID.
  final String id;

  /// Person, bank, or loan name.
  final String name;

  /// Notes about the debt.
  final String description;

  /// Original principal in the user's base currency.
  final double amount;

  /// Date the debt was created.
  final DateTime dateTime;

  /// Due date or EMI end date.
  final DateTime expiryDateTime;

  /// [DebtType.debt] is money lent out; [DebtType.credit] is money borrowed.
  final DebtType debtType;

  bool get isCredit => debtType == DebtType.credit;
  bool get isLent => debtType == DebtType.debt;
  bool get isOverdue => DateTime.now().isAfter(expiryDateTime);

  int get daysUntilExpiry {
    final DateTime now = DateTime.now();
    return expiryDateTime.difference(now).inDays;
  }

  double remainingAmount(double totalPaidOrCollected) {
    final double remaining = amount - totalPaidOrCollected;
    return remaining < 0 ? 0 : remaining;
  }

  double repaymentProgress(double totalPaidOrCollected) {
    if (amount <= 0) return 0;
    final double progress = totalPaidOrCollected / amount;
    if (progress < 0) return 0;
    if (progress > 1) return 1;
    return progress;
  }

  factory DebtModel.fromMap(dynamic raw) {
    final Map<String, dynamic> map = ModelCodec.normalize(
      raw is Map ? raw.cast<dynamic, dynamic>() : null,
    );
    return DebtModel(
      id: ModelCodec.string(map, 'id'),
      name: ModelCodec.string(map, 'name', fallback: 'Debt'),
      description: ModelCodec.string(map, 'description'),
      amount: ModelCodec.decimal(map, 'amount'),
      dateTime: ModelCodec.dateTime(map, 'dateTime'),
      expiryDateTime: ModelCodec.dateTime(map, 'expiryDateTime'),
      debtType: ModelCodec.decodeEnum<DebtType>(
        map,
        'debtType',
        DebtType.values,
        DebtType.debt,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'dateTime': ModelCodec.encodeDateTime(dateTime),
      'expiryDateTime': ModelCodec.encodeDateTime(expiryDateTime),
      'debtType': ModelCodec.encodeEnum(debtType),
    };
  }

  DebtModel copyWith({
    Object? id = ModelCodec.unset,
    Object? name = ModelCodec.unset,
    Object? description = ModelCodec.unset,
    Object? amount = ModelCodec.unset,
    Object? dateTime = ModelCodec.unset,
    Object? expiryDateTime = ModelCodec.unset,
    Object? debtType = ModelCodec.unset,
  }) {
    return DebtModel(
      id: ModelCodec.isUnset(id) ? this.id : id as String,
      name: ModelCodec.isUnset(name) ? this.name : name as String,
      description: ModelCodec.isUnset(description)
          ? this.description
          : description as String,
      amount: ModelCodec.isUnset(amount) ? this.amount : amount as double,
      dateTime:
          ModelCodec.isUnset(dateTime) ? this.dateTime : dateTime as DateTime,
      expiryDateTime: ModelCodec.isUnset(expiryDateTime)
          ? this.expiryDateTime
          : expiryDateTime as DateTime,
      debtType:
          ModelCodec.isUnset(debtType) ? this.debtType : debtType as DebtType,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DebtModel &&
            other.id == id &&
            other.name == name &&
            other.description == description &&
            other.amount == amount &&
            other.dateTime == dateTime &&
            other.expiryDateTime == expiryDateTime &&
            other.debtType == debtType;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        name,
        description,
        amount,
        dateTime,
        expiryDateTime,
        debtType,
      ]);

  @override
  String toString() {
    return 'DebtModel(id: $id, name: $name, description: $description, '
        'amount: $amount, dateTime: ${dateTime.toIso8601String()}, '
        'expiryDateTime: ${expiryDateTime.toIso8601String()}, '
        'debtType: ${debtType.name})';
  }
}
