// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../exchange/change_now/exchange_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExchangeTransactionAdapter extends TypeAdapter<ExchangeTransaction> {
  @override
  final int typeId = 13;

  @override
  ExchangeTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeTransaction(
      id: fields[0] as String,
      payinAddress: fields[1] as String,
      payoutAddress: fields[2] as String,
      payinExtraId: fields[3] as String,
      payoutExtraId: fields[4] as String,
      fromCurrency: fields[5] as String,
      toCurrency: fields[6] as String,
      amount: fields[7] as String,
      refundAddress: fields[8] as String,
      refundExtraId: fields[9] as String,
      payoutExtraIdName: fields[10] as String,
      uuid: fields[11] as String,
      date: fields[12] as DateTime,
      statusString: fields[13] as String,
      statusObject: fields[14] as ExchangeTransactionStatus?,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeTransaction obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.payinAddress)
      ..writeByte(2)
      ..write(obj.payoutAddress)
      ..writeByte(3)
      ..write(obj.payinExtraId)
      ..writeByte(4)
      ..write(obj.payoutExtraId)
      ..writeByte(5)
      ..write(obj.fromCurrency)
      ..writeByte(6)
      ..write(obj.toCurrency)
      ..writeByte(7)
      ..write(obj.amount)
      ..writeByte(8)
      ..write(obj.refundAddress)
      ..writeByte(9)
      ..write(obj.refundExtraId)
      ..writeByte(10)
      ..write(obj.payoutExtraIdName)
      ..writeByte(11)
      ..write(obj.uuid)
      ..writeByte(12)
      ..write(obj.date)
      ..writeByte(13)
      ..write(obj.statusString)
      ..writeByte(14)
      ..write(obj.statusObject);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
