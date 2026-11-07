import 'package:flutter/foundation.dart';

import '../../core/enum/filter_enums.dart';
import 'map_utils.dart';

/// A wallet: cash in hand, a bank account, or a credit/debit card.
///
/// Persisted as a plain `Map<String, dynamic>` inside Hive (no code
/// generation), so [toMap] / [fromMap] are the single source of truth for the
/// on-disk shape. Keys are stable — never rename them without a migration.
@immutable
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.bankName,
    required this.number,
    required this.cardType,
    required this.initialAmount,
    required this.color,
    this.isDefault = false,
  });

  /// UUID v4 primary key.
  final String id;

  /// Account holder name, e.g. `Hemanth S`.
  final String name;

  /// Account / bank title, e.g. `HDFC Savings`.
  final String bankName;

  /// Last four digits of the account or card, `''` for cash.
  final String number;

  /// Cash / bank / card.
  final AccountType cardType;

  /// Opening balance in rupees.
  final double initialAmount;

  /// Opaque ARGB colour used for the account tile.
  final int color;

  /// Whether this is the default account pre-selected in the entry sheet.
  final bool isDefault;

  // ---------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------

  /// `•••• 1234` when a number exists, otherwise the bank title.
  String get maskedNumber {
    final String trimmed = number.trim();
    if (trimmed.isEmpty) return bankName;
    if (trimmed.length <= 4) return '•••• $trimmed';
    return '•••• ${trimmed.substring(trimmed.length - 4)}';
  }

  /// Title shown in pickers — the bank/account title.
  String get title => bankName.trim().isEmpty ? name : bankName;

  /// Card-style mask for the carousel: `•••• •••• •••• 4821`.
  ///
  /// Cash accounts carry no number, so the bank title is shown instead of a
  /// row of placeholder dots.
  String get carouselNumber {
    final String digits = number.trim();
    if (digits.isEmpty) return bankName;
    final String last4 = digits.length <= 4
        ? digits.padLeft(4, '0')
        : digits.substring(digits.length - 4);
    return '•••• •••• •••• $last4';
  }

  // ---------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'bankName': bankName,
      'number': number,
      'cardType': cardType.key,
      'initialAmount': initialAmount,
      'color': color,
      'isDefault': isDefault,
    };
  }

  factory AccountModel.fromMap(Map<dynamic, dynamic> map) {
    return AccountModel(
      id: readString(map['id']),
      name: readString(map['name']),
      bankName: readString(map['bankName']),
      number: readString(map['number']),
      cardType: AccountTypeX.fromKey(map['cardType'] as String?),
      initialAmount: readDouble(map['initialAmount']),
      color: readInt(map['color'], fallback: 0xFF00897B),
      isDefault: readBool(map['isDefault']),
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? bankName,
    String? number,
    AccountType? cardType,
    double? initialAmount,
    int? color,
    bool? isDefault,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      number: number ?? this.number,
      cardType: cardType ?? this.cardType,
      initialAmount: initialAmount ?? this.initialAmount,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AccountModel &&
      other.id == id &&
      other.name == name &&
      other.bankName == bankName &&
      other.number == number &&
      other.cardType == cardType &&
      other.initialAmount == initialAmount &&
      other.color == color &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        bankName,
        number,
        cardType,
        initialAmount,
        color,
        isDefault,
      );

  @override
  String toString() => 'AccountModel($id, $bankName, ${cardType.name})';
}
