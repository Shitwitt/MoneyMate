import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:paisa/core/common.dart';

part 'category_type.g.dart';

@HiveType(typeId: 24)
enum CategoryType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer
}

extension CategoryTypeExtension on CategoryType {
  String stringValue(BuildContext context) {
    switch (this) {
      case CategoryType.income:
        return context.loc.income;
      case CategoryType.expense:
        return context.loc.expense;
      case CategoryType.transfer:
        return context.loc.transfer;
    }
  }
}
