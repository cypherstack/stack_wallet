import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';

class TxData {
  final FeeRateType? feeRateType;
  final int? feeRateAmount;
  final int? satsPerVByte;

  final Amount? fee;
  final int? vSize;

  final String? raw;

  final String? txid;
  final String? txHash;

  final String? note;
  final String? noteOnChain;

  final List<({String address, Amount amount})>? recipients;
  final Set<UTXO>? utxos;

  final String? changeAddress;

  final String? frostMSConfig;

  TxData({
    this.feeRateType,
    this.feeRateAmount,
    this.satsPerVByte,
    this.fee,
    this.vSize,
    this.raw,
    this.txid,
    this.txHash,
    this.note,
    this.noteOnChain,
    this.recipients,
    this.utxos,
    this.changeAddress,
    this.frostMSConfig,
  });

  Amount? get amount => recipients != null && recipients!.isNotEmpty
      ? recipients!
          .map((e) => e.amount)
          .reduce((total, amount) => total += amount)
      : null;

  int? get estimatedSatsPerVByte => fee != null && vSize != null
      ? (fee!.raw ~/ BigInt.from(vSize!)).toInt()
      : null;

  TxData copyWith({
    FeeRateType? feeRateType,
    int? feeRateAmount,
    int? satsPerVByte,
    Amount? fee,
    int? vSize,
    String? raw,
    String? txid,
    String? txHash,
    String? note,
    String? noteOnChain,
    Set<UTXO>? utxos,
    List<({String address, Amount amount})>? recipients,
    String? frostMSConfig,
    String? changeAddress,
  }) {
    return TxData(
      feeRateType: feeRateType ?? this.feeRateType,
      feeRateAmount: feeRateAmount ?? this.feeRateAmount,
      satsPerVByte: satsPerVByte ?? this.satsPerVByte,
      fee: fee ?? this.fee,
      vSize: vSize ?? this.vSize,
      raw: raw ?? this.raw,
      txid: txid ?? this.txid,
      txHash: txHash ?? this.txHash,
      note: note ?? this.note,
      noteOnChain: noteOnChain ?? this.noteOnChain,
      utxos: utxos ?? this.utxos,
      recipients: recipients ?? this.recipients,
      frostMSConfig: frostMSConfig ?? this.frostMSConfig,
      changeAddress: changeAddress ?? this.changeAddress,
    );
  }

  @override
  String toString() => 'TxData{'
      'feeRateType: $feeRateType, '
      'feeRateAmount: $feeRateAmount, '
      'satsPerVByte: $satsPerVByte, '
      'fee: $fee, '
      'vSize: $vSize, '
      'raw: $raw, '
      'txid: $txid, '
      'txHash: $txHash, '
      'note: $note, '
      'noteOnChain: $noteOnChain, '
      'recipients: $recipients, '
      'utxos: $utxos, '
      'frostMSConfig: $frostMSConfig, '
      'changeAddress: $changeAddress'
      '}';
}
