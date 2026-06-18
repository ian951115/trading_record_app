// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringPlanAdapter extends TypeAdapter<RecurringPlan> {
  @override
  final int typeId = 9;

  @override
  RecurringPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringPlan(
      id: fields[0] as String?,
      symbol: fields[1] as String,
      name: fields[2] as String,
      frequency: fields[3] as RecurringFrequency,
      dayOfMonth: (fields[4] as List).cast<int>(),
      amountPerTime: fields[5] as double,
      isActive: fields[6] as bool,
      startDate: fields[7] as DateTime,
      note: fields[8] as String?,
      pausedPeriods: (fields[9] as List?)?.cast<PausePeriod>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecurringPlan obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.dayOfMonth)
      ..writeByte(5)
      ..write(obj.amountPerTime)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.pausedPeriods);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringFrequencyAdapter extends TypeAdapter<RecurringFrequency> {
  @override
  final int typeId = 8;

  @override
  RecurringFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringFrequency.monthly;
      default:
        return RecurringFrequency.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringFrequency obj) {
    switch (obj) {
      case RecurringFrequency.monthly:
        writer.writeByte(0);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
