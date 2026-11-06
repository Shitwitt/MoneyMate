import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/adapters.dart';

part 'debit_transactions_model.g.dart';
part 'debit_transactions_model.freezed.dart';

@HiveType(typeId: 23)
enum TransactionModelType {
  @HiveField(1)
  debit,
  @HiveField(2)
  goal,
}

@unfreezed
class DebtTransactionsModel extends HiveObject with _$DebtTransactionsModel {
  @HiveType(typeId: 3, adapterName: 'DebitTransactionsModelAdapter')
  factory DebtTransactionsModel({
    @HiveField(1) required double amount,
    @HiveField(2) required DateTime now,
    @HiveField(4, defaultValue: -1) required int parentId,
    @HiveField(3) int? superId,
    @HiveField(5)
    @Default(TransactionModelType.debit)
    TransactionModelType? type,
  }) = _DebitTransactionsModel;

  DebtTransactionsModel._();

  factory DebtTransactionsModel.fromJson(Map<String, dynamic> json) =>
      _$DebtTransactionsModelFromJson(json);
}
