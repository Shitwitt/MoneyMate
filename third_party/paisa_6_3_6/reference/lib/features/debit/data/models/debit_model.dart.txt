import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/adapters.dart';

import 'package:paisa/core/enum/debt_type.dart';

part 'debit_model.g.dart';
part 'debit_model.freezed.dart';

@unfreezed
class DebtModel extends HiveObject with _$DebtModel {
  @HiveType(typeId: 4, adapterName: 'DebitModelAdapter')
  factory DebtModel({
    @HiveField(1) required String description,
    @HiveField(2) required double amount,
    @HiveField(3) required DateTime startDateTime,
    @HiveField(4) required DateTime expiryDateTime,
    @HiveField(5) @Default(DebitType.debit) DebitType debtType,
    @HiveField(6) int? superId,
    @HiveField(7) required String name,
    @HiveField(8) @Default(0xf04b6) int? icon,
    @HiveField(9) @Default(false) bool? isCompleted,
    @HiveField(10) @Default(0xFF000000) int? color,
  }) = _DebitModel;

  DebtModel._();

  factory DebtModel.fromJson(Map<String, dynamic> json) =>
      _$DebtModelFromJson(json);
}
