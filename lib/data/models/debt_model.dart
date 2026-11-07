import 'package:flutter/foundation.dart';

import '../../core/enum/filter_enums.dart';
import 'map_utils.dart';

/// A lending relationship: money lent to someone ([DebtType.debt]) or money
/// borrowed from a person / bank / loan / EMI ([DebtType.credit]).
///
/// The [amount] is the total payable (principal + interest). Installments are
/// recorded as separate `DebtTransactionModel` rows whose amounts are summed to
/// compute the outstanding balance.
@immutable
class DebtModel {
  const DebtModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.amount,
    required this.dateTime,
    required this.expiryDateTime,
    required this.debtType,
  });

  /// UUID v4 primary key.
  final String id;

  /// Person or bank / loan name.
  final String name;

  /// Loan notes, e.g. `12.5% p.a. · 12 EMIs of ₹4,200`.
  final String description;

  /// Total principal + interest payable.
  final double amount;

  /// Start date of the lending / loan.
  final DateTime dateTime;

  /// Due date by which the whole amount should be settled.
  final DateTime expiryDateTime;

  final DebtType debtType;

  // ---------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------

  /// Signed contribution to net worth: `+amount` when lent out, `-amount` when
  /// borrowed.
  double get netWorthImpact => amount * debtType.netWorthSign;

  /// Positive when money is still owed, zero / negative when over-settled.
  double outstanding(double paid) => amount - paid;

  /// `0..1` progress of the repayment (or collection) so far.
  double progress(double paid) {
    if (amount <= 0) return paid > 0 ? 1 : 0;
    return (paid / amount).clamp(0.0, 1.0);
  }

  /// Whole days left until [expiryDateTime]; negative once overdue.
  int daysRemaining([DateTime? now]) {
    final DateTime reference = now ?? DateTime.now();
    final DateTime today =
        DateTime(reference.year, reference.month, reference.day);
    final DateTime due = DateTime(
      expiryDateTime.year,
      expiryDateTime.month,
      expiryDateTime.day,
    );
    return due.difference(today).inDays;
  }

  bool isOverdue([DateTime? now]) => daysRemaining(now) < 0;

  bool isDueSoon({int withinDays = 7, DateTime? now}) {
    final int remaining = daysRemaining(now);
    return remaining >= 0 && remaining <= withinDays;
  }

  /// True when [paid] covers the full amount.
  bool isSettled(double paid) => paid >= amount - 0.005;

  // ---------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'dateTime': writeDateTime(dateTime),
      'expiryDateTime': writeDateTime(expiryDateTime),
      'debtType': debtType.key,
    };
  }

  factory DebtModel.fromMap(Map<dynamic, dynamic> map) {
    final DateTime start = readDateTime(map['dateTime']);
    return DebtModel(
      id: readString(map['id']),
      name: readString(map['name']),
      description: readString(map['description']),
      amount: readAmount(map['amount']),
      dateTime: start,
      expiryDateTime: readDateTime(
        map['expiryDateTime'],
        fallback: start.add(const Duration(days: 30)),
      ),
      debtType: DebtTypeX.fromKey(map['debtType'] as String?),
    );
  }

  DebtModel copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    DateTime? dateTime,
    DateTime? expiryDateTime,
    DebtType? debtType,
  }) {
    return DebtModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      expiryDateTime: expiryDateTime ?? this.expiryDateTime,
      debtType: debtType ?? this.debtType,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DebtModel &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.amount == amount &&
      other.dateTime == dateTime &&
      other.expiryDateTime == expiryDateTime &&
      other.debtType == debtType;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        amount,
        dateTime,
        expiryDateTime,
        debtType,
      );

  @override
  String toString() => 'DebtModel($id, $name, ${debtType.name}, $amount)';
}
