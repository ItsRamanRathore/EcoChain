// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LotLocalAdapter extends TypeAdapter<LotLocal> {
  @override
  final int typeId = 1;

  @override
  LotLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LotLocal(
      id: fields[0] as String,
      materialCategory: fields[1] as String,
      approximateWeight: fields[2] as double,
      imagePath: fields[3] as String,
      timestamp: fields[4] as DateTime,
      isSynced: fields[5] as bool,
      serverId: fields[6] as String?,
      handoverCompleted: fields[11] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, LotLocal obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.materialCategory)
      ..writeByte(2)
      ..write(obj.approximateWeight)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.isSynced)
      ..writeByte(6)
      ..write(obj.serverId)
      ..writeByte(11)
      ..write(obj.handoverCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LotLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
