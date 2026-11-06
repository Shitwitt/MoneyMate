import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/adapters.dart';

import 'package:paisa/core/data/super_id.dart';
import 'package:paisa/core/enum/category_type.dart';

part 'category_model.g.dart';
part 'category_model.freezed.dart';

@unfreezed
class CategoryModel extends HiveObject with _$CategoryModel implements SuperId {
  @HiveType(typeId: 1, adapterName: 'CategoryModelAdapter')
  factory CategoryModel({
    @HiveField(0) required String name,
    @HiveField(1) String? description,
    @HiveField(2) required int icon,
    @HiveField(4) int? superId,
    @HiveField(6, defaultValue: 0) double? budget,
    @HiveField(7, defaultValue: false) @Default(false) bool isBudget,
    @HiveField(8, defaultValue: 0xFFFFC107) int? color,
    @HiveField(9) @Default(CategoryType.income) CategoryType? categoryType,
  }) = _CategoryModel;

  CategoryModel._();

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}
