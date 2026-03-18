// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeAdapter extends TypeAdapter<Trade> {
  @override
  final int typeId = 0;

  @override
  Trade read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trade(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      symbol: fields[2] as String,
      name: fields[3] as String,
      type: fields[4] as TradeType,
      price: fields[5] as double,
      quantity: fields[6] as int,
      fee: fields[7] as double,
      tax: fields[8] as double,
      note: fields[9] as String?,
      tags: (fields[10] as List).cast<String>(),
      assetType: fields[11] as AssetType,
    );
  }

  @override
  void write(BinaryWriter writer, Trade obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.fee)
      ..writeByte(8)
      ..write(obj.tax)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.assetType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TradeTypeAdapter extends TypeAdapter<TradeType> {
  @override
  final int typeId = 1;

  @override
  TradeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TradeType.buy;
      case 1:
        return TradeType.sell;
      default:
        return TradeType.buy;
    }
  }

  @override
  void write(BinaryWriter writer, TradeType obj) {
    switch (obj) {
      case TradeType.buy:
        writer.writeByte(0);
        break;
      case TradeType.sell:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AssetTypeAdapter extends TypeAdapter<AssetType> {
  @override
  final int typeId = 4;

  @override
  AssetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AssetType.stock;
      case 1:
        return AssetType.future;
      case 2:
        return AssetType.crypto;
      case 3:
        return AssetType.option;
      case 4:
        return AssetType.other;
      default:
        return AssetType.stock;
    }
  }

  @override
  void write(BinaryWriter writer, AssetType obj) {
    switch (obj) {
      case AssetType.stock:
        writer.writeByte(0);
        break;
      case AssetType.future:
        writer.writeByte(1);
        break;
      case AssetType.crypto:
        writer.writeByte(2);
        break;
      case AssetType.option:
        writer.writeByte(3);
        break;
      case AssetType.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
