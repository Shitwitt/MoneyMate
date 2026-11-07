import 'package:flutter/foundation.dart';

import 'map_utils.dart';

/// An expense / income category, optionally budgeted.
@immutable
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.icon,
    required this.color,
    this.budget = 0,
    this.isBudgetActive = false,
    this.isDefault = false,
  });

  /// UUID v4 primary key (stable names are used for seeded defaults so a
  /// re-seed never duplicates rows).
  final String id;

  /// Display name, e.g. `Food & Dining`.
  final String name;

  /// Optional helper text shown under the name in the category editor.
  final String description;

  /// Material icon `codePoint`. Resolved through a whitelist map in the UI so
  /// tree-shaken icon fonts still work.
  final int icon;

  /// Opaque ARGB colour for the category avatar and chart slices.
  final int color;

  /// Monthly budget limit in rupees. `0` means "no budget".
  final double budget;

  /// Whether the budget is enforced / shown on the home screen.
  final bool isBudgetActive;

  /// Seeded out-of-the-box categories cannot be deleted (they can be renamed).
  final bool isDefault;

  /// True when this category should render a budget ring.
  bool get hasBudget => isBudgetActive && budget > 0;

  // ---------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------

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

  factory CategoryModel.fromMap(Map<dynamic, dynamic> map) {
    return CategoryModel(
      id: readString(map['id']),
      name: readString(map['name']),
      description: readString(map['description']),
      icon: readInt(map['icon']),
      color: readInt(map['color'], fallback: 0xFF00897B),
      budget: readDouble(map['budget']),
      isBudgetActive: readBool(map['isBudgetActive']),
      isDefault: readBool(map['isDefault']),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    int? icon,
    int? color,
    double? budget,
    bool? isBudgetActive,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budget: budget ?? this.budget,
      isBudgetActive: isBudgetActive ?? this.isBudgetActive,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Percentage of the budget consumed, clamped to `0..1`. Returns `1` when the
  /// budget is exceeded so progress rings never overflow.
  double budgetProgress(double spent) {
    if (!hasBudget) return 0;
    return (spent / budget).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryModel &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.icon == icon &&
      other.color == color &&
      other.budget == budget &&
      other.isBudgetActive == isBudgetActive &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        icon,
        color,
        budget,
        isBudgetActive,
        isDefault,
      );

  @override
  String toString() => 'CategoryModel($id, $name)';
}
