import 'package:cw_monero/pending_monero_transaction.dart';
import 'package:cw_wownero/pending_wownero_transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/wallets/isar/models/spark_coin.dart';
import 'package:tezart/tezart.dart' as tezart;
import 'package:web3dart/web3dart.dart' as web3dart;

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

  final String? memo;

  final List<({String address, Amount amount, bool isChange})>? recipients;
  final Set<UTXO>? utxos;
  final List<UTXO>? usedUTXOs;

  final String? changeAddress;

  final String? frostMSConfig;

  // paynym specific
  final PaynymAccountLite? paynymAccountLite;

  // eth token specific
  final web3dart.Transaction? web3dartTransaction;
  final int? nonce;
  final BigInt? chainId;
  final BigInt? feeInWei;

  // wownero specific
  final PendingWowneroTransaction? pendingWowneroTransaction;

  // monero specific
  final PendingMoneroTransaction? pendingMoneroTransaction;

  // firo lelantus specific
  final int? jMintValue;
  final List<int>? spendCoinIndexes;
  final int? height;
  final TransactionType? txType;
  final TransactionSubType? txSubType;
  final List<Map<String, dynamic>>? mintsMapLelantus;

  // tezos specific
  final tezart.OperationsList? tezosOperationsList;

  // firo spark specific
  final List<
      ({
        String address,
        Amount amount,
        String memo,
        bool isChange,
      })>? sparkRecipients;
  final List<TxData>? sparkMints;
  final List<SparkCoin>? usedSparkCoins;

  final TransactionV2? tempTx;

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
    this.memo,
    this.recipients,
    this.utxos,
    this.usedUTXOs,
    this.changeAddress,
    this.frostMSConfig,
    this.paynymAccountLite,
    this.web3dartTransaction,
    this.nonce,
    this.chainId,
    this.feeInWei,
    this.pendingWowneroTransaction,
    this.pendingMoneroTransaction,
    this.jMintValue,
    this.spendCoinIndexes,
    this.height,
    this.txType,
    this.txSubType,
    this.mintsMapLelantus,
    this.tezosOperationsList,
    this.sparkRecipients,
    this.sparkMints,
    this.usedSparkCoins,
    this.tempTx,
  });

  Amount? get amount => recipients != null && recipients!.isNotEmpty
      ? recipients!
          .map((e) => e.amount)
          .reduce((total, amount) => total += amount)
      : null;

  Amount? get amountSpark =>
      sparkRecipients != null && sparkRecipients!.isNotEmpty
          ? sparkRecipients!
              .map((e) => e.amount)
              .reduce((total, amount) => total += amount)
          : null;

  Amount? get amountWithoutChange =>
      recipients != null && recipients!.isNotEmpty
          ? recipients!
              .where((e) => !e.isChange)
              .map((e) => e.amount)
              .reduce((total, amount) => total += amount)
          : null;

  Amount? get amountSparkWithoutChange =>
      sparkRecipients != null && sparkRecipients!.isNotEmpty
          ? sparkRecipients!
              .where((e) => !e.isChange)
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
    String? memo,
    Set<UTXO>? utxos,
    List<UTXO>? usedUTXOs,
    List<
            ({
              String address,
              Amount amount,
              bool isChange,
            })>?
        recipients,
    String? frostMSConfig,
    String? changeAddress,
    PaynymAccountLite? paynymAccountLite,
    web3dart.Transaction? web3dartTransaction,
    int? nonce,
    BigInt? chainId,
    BigInt? feeInWei,
    PendingWowneroTransaction? pendingWowneroTransaction,
    PendingMoneroTransaction? pendingMoneroTransaction,
    int? jMintValue,
    List<int>? spendCoinIndexes,
    int? height,
    TransactionType? txType,
    TransactionSubType? txSubType,
    List<Map<String, dynamic>>? mintsMapLelantus,
    tezart.OperationsList? tezosOperationsList,
    List<
            ({
              String address,
              Amount amount,
              String memo,
              bool isChange,
            })>?
        sparkRecipients,
    List<TxData>? sparkMints,
    List<SparkCoin>? usedSparkCoins,
    TransactionV2? tempTx,
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
      memo: memo ?? this.memo,
      utxos: utxos ?? this.utxos,
      usedUTXOs: usedUTXOs ?? this.usedUTXOs,
      recipients: recipients ?? this.recipients,
      frostMSConfig: frostMSConfig ?? this.frostMSConfig,
      changeAddress: changeAddress ?? this.changeAddress,
      paynymAccountLite: paynymAccountLite ?? this.paynymAccountLite,
      web3dartTransaction: web3dartTransaction ?? this.web3dartTransaction,
      nonce: nonce ?? this.nonce,
      chainId: chainId ?? this.chainId,
      feeInWei: feeInWei ?? this.feeInWei,
      pendingWowneroTransaction:
          pendingWowneroTransaction ?? this.pendingWowneroTransaction,
      pendingMoneroTransaction:
          pendingMoneroTransaction ?? this.pendingMoneroTransaction,
      jMintValue: jMintValue ?? this.jMintValue,
      spendCoinIndexes: spendCoinIndexes ?? this.spendCoinIndexes,
      height: height ?? this.height,
      txType: txType ?? this.txType,
      txSubType: txSubType ?? this.txSubType,
      mintsMapLelantus: mintsMapLelantus ?? this.mintsMapLelantus,
      tezosOperationsList: tezosOperationsList ?? this.tezosOperationsList,
      sparkRecipients: sparkRecipients ?? this.sparkRecipients,
      sparkMints: sparkMints ?? this.sparkMints,
      usedSparkCoins: usedSparkCoins ?? this.usedSparkCoins,
      tempTx: tempTx ?? this.tempTx,
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
      'memo: $memo, '
      'recipients: $recipients, '
      'utxos: $utxos, '
      'usedUTXOs: $usedUTXOs, '
      'frostMSConfig: $frostMSConfig, '
      'changeAddress: $changeAddress, '
      'paynymAccountLite: $paynymAccountLite, '
      'web3dartTransaction: $web3dartTransaction, '
      'nonce: $nonce, '
      'chainId: $chainId, '
      'feeInWei: $feeInWei, '
      'pendingWowneroTransaction: $pendingWowneroTransaction, '
      'pendingMoneroTransaction: $pendingMoneroTransaction, '
      'jMintValue: $jMintValue, '
      'spendCoinIndexes: $spendCoinIndexes, '
      'height: $height, '
      'txType: $txType, '
      'txSubType: $txSubType, '
      'mintsMapLelantus: $mintsMapLelantus, '
      'tezosOperationsList: $tezosOperationsList, '
      'sparkRecipients: $sparkRecipients, '
      'sparkMints: $sparkMints, '
      'usedSparkCoins: $usedSparkCoins, '
      'tempTx: $tempTx, '
      '}';
}
