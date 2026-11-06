// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebitModelAdapter extends TypeAdapter<_$DebitModelImpl> {
  @override
  final int typeId = 4;

  @override
  _$DebitModelImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$DebitModelImpl(
      description: fields[1] as String,
      amount: fields[2] as double,
      startDateTime: fields[3] as DateTime,
      expiryDateTime: fields[4] as DateTime,
      debtType: fields[5] as DebitType,
      superId: fields[6] as int?,
      name: fields[7] as String,
      icon: fields[8] as int?,
      isCompleted: fields[9] as bool?,
      color: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, _$DebitModelImpl obj) {
    writer
      ..writeByte(10)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.startDateTime)
      ..writeByte(4)
      ..write(obj.expiryDateTime)
      ..writeByte(5)
      ..write(obj.debtType)
      ..writeByte(6)
      ..write(obj.superId)
      ..writeByte(7)
      ..write(obj.name)
      ..writeByte(8)
      ..write(obj.icon)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DebitModelImpl _$$DebitModelImplFromJson(Map<String, dynamic> json) =>
    _$DebitModelImpl(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      expiryDateTime: DateTime.parse(json['expiryDateTime'] as String),
      debtType: $enumDecodeNullable(_$DebitTypeEnumMap, json['debtType']) ??
          DebitType.debit,
      superId: (json['superId'] as num?)?.toInt(),
      name: json['name'] as String,
      icon: (json['icon'] as num?)?.toInt() ?? 0xf04b6,
      isCompleted: json['isCompleted'] as bool? ?? false,
      color: (json['color'] as num?)?.toInt() ?? 0xFF000000,
    );

Map<String, dynamic> _$$DebitModelImplToJson(_$DebitModelImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
      'amount': instance.amount,
      'startDateTime': instance.startDateTime.toIso8601String(),
      'expiryDateTime': instance.expiryDateTime.toIso8601String(),
      'debtType': _$DebitTypeEnumMap[instance.debtType]!,
      'superId': instance.superId,
      'name': instance.name,
      'icon': instance.icon,
      'isCompleted': instance.isCompleted,
      'color': instance.color,
    };

const _$DebitTypeEnumMap = {
  DebitType.debit: 'debit',
  DebitType.credit: 'credit',
  DebitType.goal: 'goal',
};
