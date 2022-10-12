// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeAdapter extends TypeAdapter<Trade> {
  @override
  final int typeId = 22;

  @override
  Trade read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trade(
      uuid: fields[0] as String,
      tradeId: fields[1] as String,
      rateType: fields[2] as String,
      direction: fields[3] as String,
      timestamp: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      payInCurrency: fields[6] as String,
      payInAmount: fields[7] as String,
      payInAddress: fields[8] as String,
      payInNetwork: fields[9] as String,
      payInExtraId: fields[10] as String,
      payInTxid: fields[11] as String,
      payOutCurrency: fields[12] as String,
      payOutAmount: fields[13] as String,
      payOutAddress: fields[14] as String,
      payOutNetwork: fields[15] as String,
      payOutExtraId: fields[16] as String,
      payOutTxid: fields[17] as String,
      refundAddress: fields[18] as String,
      refundExtraId: fields[19] as String,
      status: fields[20] as String,
      exchangeName: fields[21] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Trade obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.tradeId)
      ..writeByte(2)
      ..write(obj.rateType)
      ..writeByte(3)
      ..write(obj.direction)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.payInCurrency)
      ..writeByte(7)
      ..write(obj.payInAmount)
      ..writeByte(8)
      ..write(obj.payInAddress)
      ..writeByte(9)
      ..write(obj.payInNetwork)
      ..writeByte(10)
      ..write(obj.payInExtraId)
      ..writeByte(11)
      ..write(obj.payInTxid)
      ..writeByte(12)
      ..write(obj.payOutCurrency)
      ..writeByte(13)
      ..write(obj.payOutAmount)
      ..writeByte(14)
      ..write(obj.payOutAddress)
      ..writeByte(15)
      ..write(obj.payOutNetwork)
      ..writeByte(16)
      ..write(obj.payOutExtraId)
      ..writeByte(17)
      ..write(obj.payOutTxid)
      ..writeByte(18)
      ..write(obj.refundAddress)
      ..writeByte(19)
      ..write(obj.refundExtraId)
      ..writeByte(20)
      ..write(obj.status)
      ..writeByte(21)
      ..write(obj.exchangeName);
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
