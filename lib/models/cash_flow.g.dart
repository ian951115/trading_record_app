// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashFlowAdapter extends TypeAdapter<CashFlow> {
  @override
  final int typeId = 3;

  @override
  CashFlow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashFlow(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      type: fields[2] as CashFlowType,
      amount: fields[3] as double,
      note: fields[4] as String?,
      tradeId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CashFlow obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.tradeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashFlowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CashFlowTypeAdapter extends TypeAdapter<CashFlowType> {
  @override
  final int typeId = 2;

  @override
  CashFlowType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CashFlowType.deposit;
      case 1:
        return CashFlowType.withdraw;
      default:
        return CashFlowType.deposit;
    }
  }

  @override
  void write(BinaryWriter writer, CashFlowType obj) {
    switch (obj) {
      case CashFlowType.deposit:
        writer.writeByte(0);
        break;
      case CashFlowType.withdraw:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashFlowTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
