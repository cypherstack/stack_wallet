// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../mwcmqs_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MwcMqsConfigModelAdapter extends TypeAdapter<MwcMqsConfigModel> {
  @override
  final int typeId = 82;

  @override
  MwcMqsConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MwcMqsConfigModel(
      host: fields[1] as String,
      port: fields[2] as int?,
      protocolInsecure: fields[3] as bool?,
      addressIndex: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MwcMqsConfigModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(1)
      ..write(obj.host)
      ..writeByte(2)
      ..write(obj.port)
      ..writeByte(3)
      ..write(obj.protocolInsecure)
      ..writeByte(4)
      ..write(obj.addressIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MwcMqsConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
