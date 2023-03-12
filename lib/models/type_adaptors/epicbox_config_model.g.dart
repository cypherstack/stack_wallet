// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../epicbox_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EpicBoxConfigModelAdapter extends TypeAdapter<EpicBoxConfigModel> {
  @override
  final int typeId = 72;

  @override
  EpicBoxConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpicBoxConfigModel(
      host: fields[1] as String,
      port: fields[2] as int,
      protocolInsecure: fields[3] as bool,
      addressIndex: fields[4] as int,
      // name: fields[5] as String,
      // id: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EpicBoxConfigModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.host)
      ..writeByte(1)
      ..write(obj.port)
      ..writeByte(2)
      ..write(obj.protocolInsecure)
      ..writeByte(3)
      ..write(obj.addressIndex);
    // ..writeByte(4)
    // ..write(obj.id)
    // ..writeByte(5)
    // ..write(obj.name)
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpicBoxConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
