// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../paymint/transactions_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionDataAdapter extends TypeAdapter<TransactionData> {
  @override
  final typeId = 1;

  @override
  TransactionData read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionData(
      txChunks: (fields[0] as List).cast<TransactionChunk>(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionData obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.txChunks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionChunkAdapter extends TypeAdapter<TransactionChunk> {
  @override
  final typeId = 2;

  @override
  TransactionChunk read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionChunk(
      timestamp: fields[0] as int,
      transactions: (fields[1] as List).cast<Transaction>(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionChunk obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.transactions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionChunkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final typeId = 3;

  @override
  Transaction read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      txid: fields[0] as String,
      confirmedStatus: fields[1] as bool,
      timestamp: fields[2] as int,
      txType: fields[3] as String,
      amount: fields[4] as int,
      aliens: (fields[5] as List).cast<dynamic>(),
      worthNow: fields[6] as String,
      worthAtBlockTimestamp: fields[7] as String,
      fees: fields[8] as int,
      inputSize: fields[9] as int,
      outputSize: fields[10] as int,
      inputs: (fields[11] as List).cast<Input>(),
      outputs: (fields[12] as List).cast<Output>(),
      address: fields[13] as String,
      height: fields[14] as int,
      subType: fields[15] as String,
      confirmations: fields[16] as int,
      isCancelled: fields[17] as bool,
      slateId: fields[18] as String?,
      otherData: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.txid)
      ..writeByte(1)
      ..write(obj.confirmedStatus)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.txType)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.aliens)
      ..writeByte(6)
      ..write(obj.worthNow)
      ..writeByte(7)
      ..write(obj.worthAtBlockTimestamp)
      ..writeByte(8)
      ..write(obj.fees)
      ..writeByte(9)
      ..write(obj.inputSize)
      ..writeByte(10)
      ..write(obj.outputSize)
      ..writeByte(11)
      ..write(obj.inputs)
      ..writeByte(12)
      ..write(obj.outputs)
      ..writeByte(13)
      ..write(obj.address)
      ..writeByte(14)
      ..write(obj.height)
      ..writeByte(15)
      ..write(obj.subType)
      ..writeByte(16)
      ..write(obj.confirmations)
      ..writeByte(17)
      ..write(obj.isCancelled)
      ..writeByte(18)
      ..write(obj.slateId)
      ..writeByte(19)
      ..write(obj.otherData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InputAdapter extends TypeAdapter<Input> {
  @override
  final typeId = 4;

  @override
  Input read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Input(
      txid: fields[0] as String,
      vout: fields[1] as int,
      prevout: fields[2] as Output?,
      scriptsig: fields[3] as String?,
      scriptsigAsm: fields[4] as String?,
      witness: (fields[5] as List).cast<dynamic>(),
      isCoinbase: fields[6] as bool?,
      sequence: fields[7] as int?,
      innerRedeemscriptAsm: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Input obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.txid)
      ..writeByte(1)
      ..write(obj.vout)
      ..writeByte(2)
      ..write(obj.prevout)
      ..writeByte(3)
      ..write(obj.scriptsig)
      ..writeByte(4)
      ..write(obj.scriptsigAsm)
      ..writeByte(5)
      ..write(obj.witness)
      ..writeByte(6)
      ..write(obj.isCoinbase)
      ..writeByte(7)
      ..write(obj.sequence)
      ..writeByte(8)
      ..write(obj.innerRedeemscriptAsm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InputAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OutputAdapter extends TypeAdapter<Output> {
  @override
  final typeId = 5;

  @override
  Output read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Output(
      scriptpubkey: fields[0] as String,
      scriptpubkeyAsm: fields[1] as String,
      scriptpubkeyType: fields[2] as String,
      scriptpubkeyAddress: fields[3] as String,
      value: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Output obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.scriptpubkey)
      ..writeByte(1)
      ..write(obj.scriptpubkeyAsm)
      ..writeByte(2)
      ..write(obj.scriptpubkeyType)
      ..writeByte(3)
      ..write(obj.scriptpubkeyAddress)
      ..writeByte(4)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutputAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
