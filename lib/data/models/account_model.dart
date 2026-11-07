import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/enum/filter_enums.dart';
import 'model_codec.dart';

/// A wallet, bank account, or card stored as Hive primitives.
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
    required this.isDefault,
  });

  /// Stable UUID.
  final String id;

  /// Account holder name.
  final String name;

  /// Bank or card issuer name.
  final String bankName;

  /// Last four digits of the account/card number.
  final String number;

  /// Account classification. The field keeps the Paisa `cardType` name while
  /// using the shared [AccountType] enum.
  final AccountType cardType;

  /// Opening balance in the user's base currency.
  final double initialAmount;

  /// ARGB color value.
  final int color;

  /// Whether this account is used by default on the add-transaction screen.
  final bool isDefault;

  AccountType get accountType => cardType;
  Color get colorValue => Color(color);
  bool get isCard => cardType == AccountType.card;
  bool get isBank => cardType == AccountType.bank;
  bool get isCash => cardType == AccountType.cash;

  String get maskedNumber {
    final String digits = number.trim();
    if (digits.isEmpty) return '••••';
    return '•••• $digits';
  }

  String get subtitle {
    final List<String> parts = <String>[
      if (bankName.trim().isNotEmpty) bankName.trim(),
      cardType.label,
    ];
    return parts.join(' · ');
  }

  factory AccountModel.fromMap(dynamic raw) {
    final Map<String, dynamic> map = ModelCodec.normalize(
      raw is Map ? raw.cast<dynamic, dynamic>() : null,
    );
    return AccountModel(
      id: ModelCodec.string(map, 'id'),
      name: ModelCodec.string(map, 'name', fallback: 'Account'),
      bankName: ModelCodec.string(map, 'bankName'),
      number: ModelCodec.string(map, 'number'),
      cardType: ModelCodec.decodeEnum<AccountType>(
        map,
        'cardType',
        AccountType.values,
        AccountType.bank,
      ),
      initialAmount: ModelCodec.decimal(map, 'initialAmount'),
      color: ModelCodec.color(map, 'color'),
      isDefault: ModelCodec.boolean(map, 'isDefault'),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'bankName': bankName,
      'number': number,
      'cardType': ModelCodec.encodeEnum(cardType),
      'initialAmount': initialAmount,
      'color': color,
      'isDefault': isDefault,
    };
  }

  AccountModel copyWith({
    Object? id = ModelCodec.unset,
    Object? name = ModelCodec.unset,
    Object? bankName = ModelCodec.unset,
    Object? number = ModelCodec.unset,
    Object? cardType = ModelCodec.unset,
    Object? initialAmount = ModelCodec.unset,
    Object? color = ModelCodec.unset,
    Object? isDefault = ModelCodec.unset,
  }) {
    return AccountModel(
      id: ModelCodec.isUnset(id) ? this.id : id as String,
      name: ModelCodec.isUnset(name) ? this.name : name as String,
      bankName: ModelCodec.isUnset(bankName) ? this.bankName : bankName as String,
      number: ModelCodec.isUnset(number) ? this.number : number as String,
      cardType: ModelCodec.isUnset(cardType) ? this.cardType : cardType as AccountType,
      initialAmount: ModelCodec.isUnset(initialAmount)
          ? this.initialAmount
          : initialAmount as double,
      color: ModelCodec.isUnset(color) ? this.color : color as int,
      isDefault: ModelCodec.isUnset(isDefault) ? this.isDefault : isDefault as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountModel &&
            other.id == id &&
            other.name == name &&
            other.bankName == bankName &&
            other.number == number &&
            other.cardType == cardType &&
            other.initialAmount == initialAmount &&
            other.color == color &&
            other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        name,
        bankName,
        number,
        cardType,
        initialAmount,
        color,
        isDefault,
      ]);

  @override
  String toString() {
    return 'AccountModel(id: $id, name: $name, bankName: $bankName, '
        'number: $maskedNumber, cardType: ${cardType.name}, '
        'initialAmount: $initialAmount, color: $color, isDefault: $isDefault)';
  }
}
