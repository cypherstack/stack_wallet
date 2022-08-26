// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../trade_wallet_lookup.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeWalletLookupAdapter extends TypeAdapter<TradeWalletLookup> {
  @override
  final int typeId = 21;

  @override
  TradeWalletLookup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TradeWalletLookup(
      uuid: fields[0] as String,
      txid: fields[1] as String,
      tradeId: fields[2] as String,
      walletIds: fields[3] as List<String>,
    );
  }

  @override
  void write(BinaryWriter writer, TradeWalletLookup obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.txid)
      ..writeByte(2)
      ..write(obj.tradeId)
      ..writeByte(3)
      ..write(obj.walletIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeWalletLookupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
