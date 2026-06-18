// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pause_period.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PausePeriodAdapter extends TypeAdapter<PausePeriod> {
  @override
  final int typeId = 12;

  @override
  PausePeriod read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PausePeriod(
      pausedAt: fields[0] as DateTime,
      resumedAt: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PausePeriod obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.pausedAt)
      ..writeByte(1)
      ..write(obj.resumedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PausePeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
