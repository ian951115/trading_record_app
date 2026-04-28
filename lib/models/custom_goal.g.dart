// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomGoalAdapter extends TypeAdapter<CustomGoal> {
  @override
  final int typeId = 11;

  @override
  CustomGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomGoal(
      id: fields[0] as String?,
      title: fields[1] as String,
      goalTypeStr: fields[2] as String,
      stockSymbol: fields[3] as String?,
      stockName: fields[4] as String?,
      targetAmount: fields[5] as double,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime,
      note: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomGoal obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.goalTypeStr)
      ..writeByte(3)
      ..write(obj.stockSymbol)
      ..writeByte(4)
      ..write(obj.stockName)
      ..writeByte(5)
      ..write(obj.targetAmount)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
