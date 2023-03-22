// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../epicbox_server_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EpicBoxServerModelAdapter extends TypeAdapter<EpicBoxServerModel> {
  @override
  final int typeId = 71;

  @override
  EpicBoxServerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpicBoxServerModel(
      host: fields[1] as String,
      port: fields[2] as int,
      name: fields[3] as String,
      id: fields[0] as String,
      useSSL: fields[4] as bool,
      enabled: fields[5] as bool,
      isFailover: fields[6] as bool,
      isDown: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EpicBoxServerModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.host)
      ..writeByte(2)
      ..write(obj.port)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.useSSL)
      ..writeByte(5)
      ..write(obj.enabled)
      ..writeByte(6)
      ..write(obj.isFailover)
      ..writeByte(7)
      ..write(obj.isDown);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpicBoxServerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
