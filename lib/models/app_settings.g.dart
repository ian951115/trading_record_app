// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      redUpGreenDown: fields[0] as bool,
      pnlMethod: fields[1] as String,
      defaultFeeRate: fields[2] as double,
      defaultTaxRate: fields[3] as double,
      minFeePerShare: fields[4] as double,
      minFeePerLot: fields[5] as double,
      waterLevelThreshold: fields[6] as double,
      autoDepositDefault: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.redUpGreenDown)
      ..writeByte(1)
      ..write(obj.pnlMethod)
      ..writeByte(2)
      ..write(obj.defaultFeeRate)
      ..writeByte(3)
      ..write(obj.defaultTaxRate)
      ..writeByte(4)
      ..write(obj.minFeePerShare)
      ..writeByte(5)
      ..write(obj.minFeePerLot)
      ..writeByte(6)
      ..write(obj.waterLevelThreshold)
      ..writeByte(7)
      ..write(obj.autoDepositDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
