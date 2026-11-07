import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'model_codec.dart';

/// A spending or income category stored as Hive primitives.
@immutable
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.budget,
    required this.isBudgetActive,
    required this.isDefault,
  });

  /// Stable UUID.
  final String id;

  /// Category name, for example `Food & Dining`.
  final String name;

  /// Optional user-facing description.
  final String description;

  /// Material icon code point.
  final int icon;

  /// ARGB color value.
  final int color;

  /// Monthly budget in the user's base currency.
  final double budget;

  /// Whether [budget] participates in budget calculations and alerts.
  final bool isBudgetActive;

  /// Whether this category was created during onboarding and cannot be deleted.
  final bool isDefault;

  IconData get iconData => IconData(icon, fontFamily: 'MaterialIcons');
  Color get colorValue => Color(color);
  bool get hasBudget => isBudgetActive && budget > 0;

  double budgetUsedPercent(double spent) {
    if (!hasBudget) return 0;
    return (spent / budget) * 100;
  }

  factory CategoryModel.fromMap(dynamic raw) {
    final Map<String, dynamic> map = ModelCodec.normalize(
      raw is Map ? raw.cast<dynamic, dynamic>() : null,
    );
    return CategoryModel(
      id: ModelCodec.string(map, 'id'),
      name: ModelCodec.string(map, 'name', fallback: 'Category'),
      description: ModelCodec.string(map, 'description'),
      icon: ModelCodec.integer(map, 'icon', fallback: Icons.category.codePoint),
      color: ModelCodec.color(map, 'color'),
      budget: ModelCodec.decimal(map, 'budget'),
      isBudgetActive: ModelCodec.boolean(map, 'isBudgetActive'),
      isDefault: ModelCodec.boolean(map, 'isDefault'),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'budget': budget,
      'isBudgetActive': isBudgetActive,
      'isDefault': isDefault,
    };
  }

  CategoryModel copyWith({
    Object? id = ModelCodec.unset,
    Object? name = ModelCodec.unset,
    Object? description = ModelCodec.unset,
    Object? icon = ModelCodec.unset,
    Object? color = ModelCodec.unset,
    Object? budget = ModelCodec.unset,
    Object? isBudgetActive = ModelCodec.unset,
    Object? isDefault = ModelCodec.unset,
  }) {
    return CategoryModel(
      id: ModelCodec.isUnset(id) ? this.id : id as String,
      name: ModelCodec.isUnset(name) ? this.name : name as String,
      description:
          ModelCodec.isUnset(description) ? this.description : description as String,
      icon: ModelCodec.isUnset(icon) ? this.icon : icon as int,
      color: ModelCodec.isUnset(color) ? this.color : color as int,
      budget: ModelCodec.isUnset(budget) ? this.budget : budget as double,
      isBudgetActive: ModelCodec.isUnset(isBudgetActive)
          ? this.isBudgetActive
          : isBudgetActive as bool,
      isDefault: ModelCodec.isUnset(isDefault) ? this.isDefault : isDefault as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategoryModel &&
            other.id == id &&
            other.name == name &&
            other.description == description &&
            other.icon == icon &&
            other.color == color &&
            other.budget == budget &&
            other.isBudgetActive == isBudgetActive &&
            other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        name,
        description,
        icon,
        color,
        budget,
        isBudgetActive,
        isDefault,
      ]);

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, description: $description, '
        'icon: $icon, color: $color, budget: $budget, '
        'isBudgetActive: $isBudgetActive, isDefault: $isDefault)';
  }
}
