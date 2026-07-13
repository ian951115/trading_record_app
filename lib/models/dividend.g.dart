// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dividend.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DividendAdapter extends TypeAdapter<Dividend> {
  @override
  final int typeId = 5;

  @override
  Dividend read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dividend(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      symbol: fields[2] as String,
      name: fields[3] as String,
      type: fields[4] as DividendType,
      pricePerShare: fields[5] as double,
      shareAmount: fields[6] as int,
      heldShares: fields[7] as int,
      fee: fields[8] as double,
      healthInsurance: fields[9] as double,
      note: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Dividend obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.symbol)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.pricePerShare)
      ..writeByte(6)
      ..write(obj.shareAmount)
      ..writeByte(7)
      ..write(obj.heldShares)
      ..writeByte(8)
      ..write(obj.fee)
      ..writeByte(9)
      ..write(obj.healthInsurance)
      ..writeByte(10)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DividendAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DividendTypeAdapter extends TypeAdapter<DividendType> {
  @override
  final int typeId = 7;

  @override
  DividendType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DividendType.cash;
      case 1:
        return DividendType.stock;
      default:
        return DividendType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, DividendType obj) {
    switch (obj) {
      case DividendType.cash:
        writer.writeByte(0);
        break;
      case DividendType.stock:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DividendTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
