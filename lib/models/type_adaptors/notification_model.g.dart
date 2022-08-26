// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 10;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationModel(
      id: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String,
      iconAssetName: fields[3] as String,
      date: fields[4] as DateTime,
      walletId: fields[5] as String,
      read: fields[6] as bool,
      shouldWatchForUpdates: fields[7] as bool,
      txid: fields[8] as String?,
      coinName: fields[9] as String,
      changeNowId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconAssetName)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.walletId)
      ..writeByte(6)
      ..write(obj.read)
      ..writeByte(7)
      ..write(obj.shouldWatchForUpdates)
      ..writeByte(8)
      ..write(obj.txid)
      ..writeByte(9)
      ..write(obj.coinName)
      ..writeByte(10)
      ..write(obj.changeNowId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
