// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../node_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NodeModelAdapter extends TypeAdapter<NodeModel> {
  @override
  final int typeId = 12;

  @override
  NodeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NodeModel(
      host: fields[1] as String,
      port: fields[2] as int,
      name: fields[3] as String,
      id: fields[0] as String,
      useSSL: fields[4] as bool,
      enabled: fields[6] as bool,
      loginName: fields[5] as String?,
      coinName: fields[7] as String,
      isFailover: fields[8] as bool,
      isDown: fields[9] as bool,
      trusted: fields[10] as bool?,
      torEnabled: fields[11] as bool? ?? true,
      clearnetEnabled: fields[12] as bool? ?? true,
      forceNoTor: fields[13] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, NodeModel obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.loginName)
      ..writeByte(6)
      ..write(obj.enabled)
      ..writeByte(7)
      ..write(obj.coinName)
      ..writeByte(8)
      ..write(obj.isFailover)
      ..writeByte(9)
      ..write(obj.isDown)
      ..writeByte(10)
      ..write(obj.trusted)
      ..writeByte(11)
      ..write(obj.torEnabled)
      ..writeByte(12)
      ..write(obj.clearnetEnabled)
      ..writeByte(13)
      ..write(obj.forceNoTor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
