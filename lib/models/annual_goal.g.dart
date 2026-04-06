// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annual_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnualGoalAdapter extends TypeAdapter<AnnualGoal> {
  @override
  final int typeId = 10;

  @override
  AnnualGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnualGoal(
      id: fields[0] as String?,
      year: fields[1] as int,
      targetPnL: fields[2] as double,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AnnualGoal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.targetPnL)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnualGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
