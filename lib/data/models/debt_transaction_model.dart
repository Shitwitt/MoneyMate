import 'package:flutter/foundation.dart';

import 'map_utils.dart';

/// One installment / repayment against a `DebtModel`.
///
/// For `DebtType.credit` (money borrowed) this is a payment made *to* the
/// lender, so it debits [accountId]. For `DebtType.debt` (money lent) this is
/// money received *back*, so it credits [accountId]. The owning debt's type
/// decides the direction — this row only records facts, and
/// `PaisaProvider.addDebtInstallment` writes the matching income/expense row.
@immutable
class DebtTransactionModel {
  const DebtTransactionModel({
    required this.id,
    required this.parentId,
    required this.amount,
    required this.dateTime,
    required this.accountId,
    this.note = '',
  });

  /// UUID v4 primary key.
  final String id;

  /// `DebtModel.id` this installment belongs to.
  final String parentId;

  /// Installment / repayment amount, always positive.
  final double amount;

  /// When the payment happened.
  final DateTime dateTime;

  /// Bank / cash account that paid or received this installment.
  final String accountId;

  /// Optional note, e.g. `EMI 4 of 12`.
  final String note;

  // ---------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'parentId': parentId,
      'amount': amount,
      'dateTime': writeDateTime(dateTime),
      'accountId': accountId,
      'note': note,
    };
  }

  factory DebtTransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return DebtTransactionModel(
      id: readString(map['id']),
      parentId: readString(map['parentId']),
      amount: readAmount(map['amount']),
      dateTime: readDateTime(map['dateTime']),
      accountId: readString(map['accountId']),
      note: readString(map['note']),
    );
  }

  DebtTransactionModel copyWith({
    String? id,
    String? parentId,
    double? amount,
    DateTime? dateTime,
    String? accountId,
    String? note,
  }) {
    return DebtTransactionModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DebtTransactionModel &&
      other.id == id &&
      other.parentId == parentId &&
      other.amount == amount &&
      other.dateTime == dateTime &&
      other.accountId == accountId &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, parentId, amount, dateTime, accountId, note);

  @override
  String toString() =>
      'DebtTransactionModel($id, parent: $parentId, $amount)';
}
