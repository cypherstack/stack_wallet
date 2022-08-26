// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../exchange/change_now/exchange_transaction_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExchangeTransactionStatusAdapter
    extends TypeAdapter<ExchangeTransactionStatus> {
  @override
  final int typeId = 16;

  @override
  ExchangeTransactionStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeTransactionStatus(
      status: ChangeNowTransactionStatus.values[fields[0] as int],
      payinAddress: fields[1] as String,
      payoutAddress: fields[2] as String,
      fromCurrency: fields[3] as String,
      toCurrency: fields[4] as String,
      id: fields[5] as String,
      updatedAt: fields[6] as String,
      expectedSendAmountDecimal: fields[7] as String,
      expectedReceiveAmountDecimal: fields[8] as String,
      createdAt: fields[9] as String,
      isPartner: fields[26] as bool,
      depositReceivedAt: fields[10] as String,
      payinExtraIdName: fields[11] as String,
      payoutExtraIdName: fields[12] as String,
      payinHash: fields[13] as String,
      payoutHash: fields[14] as String,
      payinExtraId: fields[15] as String,
      payoutExtraId: fields[16] as String,
      amountSendDecimal: fields[17] as String,
      amountReceiveDecimal: fields[18] as String,
      tokensDestination: fields[19] as String,
      refundAddress: fields[20] as String,
      refundExtraId: fields[21] as String,
      validUntil: fields[22] as String,
      verificationSent: fields[23] as bool,
      userId: fields[24] as String,
      payload: fields[25] as Object?,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeTransactionStatus obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.status.index)
      ..writeByte(1)
      ..write(obj.payinAddress)
      ..writeByte(2)
      ..write(obj.payoutAddress)
      ..writeByte(3)
      ..write(obj.fromCurrency)
      ..writeByte(4)
      ..write(obj.toCurrency)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.expectedSendAmountDecimal)
      ..writeByte(8)
      ..write(obj.expectedReceiveAmountDecimal)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.depositReceivedAt)
      ..writeByte(11)
      ..write(obj.payinExtraIdName)
      ..writeByte(12)
      ..write(obj.payoutExtraIdName)
      ..writeByte(13)
      ..write(obj.payinHash)
      ..writeByte(14)
      ..write(obj.payoutHash)
      ..writeByte(15)
      ..write(obj.payinExtraId)
      ..writeByte(16)
      ..write(obj.payoutExtraId)
      ..writeByte(17)
      ..write(obj.amountSendDecimal)
      ..writeByte(18)
      ..write(obj.amountReceiveDecimal)
      ..writeByte(19)
      ..write(obj.tokensDestination)
      ..writeByte(20)
      ..write(obj.refundAddress)
      ..writeByte(21)
      ..write(obj.refundExtraId)
      ..writeByte(22)
      ..write(obj.validUntil)
      ..writeByte(23)
      ..write(obj.verificationSent)
      ..writeByte(24)
      ..write(obj.userId)
      ..writeByte(25)
      ..write(obj.payload)
      ..writeByte(26)
      ..write(obj.isPartner);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeTransactionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
