// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../lelantus_coin.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LelantusCoinAdapter extends TypeAdapter<LelantusCoin> {
  @override
  final int typeId = 9;

  @override
  LelantusCoin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LelantusCoin(
      fields[0] as int,
      fields[1] as int,
      fields[2] as String,
      fields[3] as String,
      fields[4] as int,
      fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LelantusCoin obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.index)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.publicCoin)
      ..writeByte(3)
      ..write(obj.txId)
      ..writeByte(4)
      ..write(obj.anonymitySetId)
      ..writeByte(5)
      ..write(obj.isUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LelantusCoinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
