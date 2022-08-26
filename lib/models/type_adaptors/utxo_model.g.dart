// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../paymint/utxo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UtxoDataAdapter extends TypeAdapter<UtxoData> {
  @override
  final typeId = 6;

  @override
  UtxoData read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UtxoData(
        totalUserCurrency: fields[0] as String,
        satoshiBalance: fields[1] as int,
        bitcoinBalance: fields[2] as dynamic,
        unspentOutputArray: (fields[3] as List).cast<UtxoObject>(),
        satoshiBalanceUnconfirmed: fields[4]);
  }

  @override
  void write(BinaryWriter writer, UtxoData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.totalUserCurrency)
      ..writeByte(1)
      ..write(obj.satoshiBalance)
      ..writeByte(2)
      ..write(obj.bitcoinBalance)
      ..writeByte(3)
      ..write(obj.unspentOutputArray)
      ..writeByte(4)
      ..write(obj.satoshiBalanceUnconfirmed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UtxoDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UtxoObjectAdapter extends TypeAdapter<UtxoObject> {
  @override
  final typeId = 7;

  @override
  UtxoObject read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UtxoObject(
      txid: fields[0] as String,
      vout: fields[1] as int,
      status: fields[2] as Status,
      value: fields[3] as int,
      fiatWorth: fields[4] as String,
      txName: fields[5] as String,
      blocked: fields[6] as bool,
      isCoinbase: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UtxoObject obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.txid)
      ..writeByte(1)
      ..write(obj.vout)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.fiatWorth)
      ..writeByte(5)
      ..write(obj.txName)
      ..writeByte(6)
      ..write(obj.blocked)
      ..writeByte(7)
      ..write(obj.isCoinbase);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UtxoObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StatusAdapter extends TypeAdapter<Status> {
  @override
  final typeId = 8;

  @override
  Status read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Status(
      confirmed: fields[0] as bool,
      blockHash: fields[1] as String,
      blockHeight: fields[2] as int,
      blockTime: fields[3] as int,
      confirmations: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Status obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.confirmed)
      ..writeByte(1)
      ..write(obj.blockHash)
      ..writeByte(2)
      ..write(obj.blockHeight)
      ..writeByte(3)
      ..write(obj.blockTime)
      ..writeByte(4)
      ..write(obj.confirmations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
