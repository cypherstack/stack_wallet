import 'package:cs_monero/cs_monero.dart' as lib_monero;
import 'package:tezart/tezart.dart' as tezart;
import 'package:web3dart/web3dart.dart' as web3dart;

import '../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../models/isar/models/isar_models.dart';
import '../../models/paynym/paynym_account_lite.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../isar/models/spark_coin.dart';
import 'name_op_state.dart';

typedef TxRecipient = ({String address, Amount amount, bool isChange});

class TxData {
  final FeeRateType? feeRateType;
  final BigInt? feeRateAmount;
  final int? satsPerVByte;

  final Amount? fee;
  final int? vSize;

  final String? raw;

  final String? txid;
  final String? txHash;

  final String? note;
  final String? noteOnChain;

  final String? memo;

  final List<TxRecipient>? recipients;
  final Set<UTXO>? utxos;
  final List<UTXO>? usedUTXOs;

  final String? changeAddress;

  // frost specific
  final String? frostMSConfig;
  final List<String>? frostSigners;

  // paynym specific
  final PaynymAccountLite? paynymAccountLite;

  // eth token specific
  final web3dart.Transaction? web3dartTransaction;
  final int? nonce;
  final BigInt? chainId;
  final BigInt? feeInWei;

  // wownero and monero specific
  final lib_monero.PendingTransaction? pendingTransaction;

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
  final List<({String address, Amount amount, String memo, bool isChange})>?
  sparkRecipients;
  final List<TxData>? sparkMints;
  final List<SparkCoin>? usedSparkCoins;

  // xelis specific
  final String? otherData;

  final TransactionV2? tempTx;

  final bool ignoreCachedBalanceChecks;

  // Namecoin Name related
  final NameOpState? opNameState;

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
    this.frostSigners,
    this.paynymAccountLite,
    this.web3dartTransaction,
    this.nonce,
    this.chainId,
    this.feeInWei,
    this.pendingTransaction,
    this.jMintValue,
    this.spendCoinIndexes,
    this.height,
    this.txType,
    this.txSubType,
    this.mintsMapLelantus,
    this.tezosOperationsList,
    this.sparkRecipients,
    this.otherData,
    this.sparkMints,
    this.usedSparkCoins,
    this.tempTx,
    this.ignoreCachedBalanceChecks = false,
    this.opNameState,
  });

  Amount? get amount {
    if (recipients != null && recipients!.isNotEmpty) {
      final sum = recipients!
          .map((e) => e.amount)
          .reduce((total, amount) => total += amount);

      // special xmr/wow check
      if (pendingTransaction?.amount != null && fee != null) {
        if (pendingTransaction!.amount + fee!.raw == sum.raw) {
          return Amount(
            rawValue: pendingTransaction!.amount,
            fractionDigits: recipients!.first.amount.fractionDigits,
          );
        }
      }

      return sum;
    }

    return null;
  }

  Amount? get amountSpark =>
      sparkRecipients != null && sparkRecipients!.isNotEmpty
          ? sparkRecipients!
              .map((e) => e.amount)
              .reduce((total, amount) => total += amount)
          : null;

  Amount? get amountWithoutChange {
    if (recipients != null && recipients!.isNotEmpty) {
      if (recipients!.where((e) => !e.isChange).isEmpty) {
        return Amount(
          rawValue: BigInt.zero,
          fractionDigits: recipients!.first.amount.fractionDigits,
        );
      } else {
        final sum = recipients!
            .where((e) => !e.isChange)
            .map((e) => e.amount)
            .reduce((total, amount) => total += amount);

        // special xmr/wow check
        if (pendingTransaction?.amount != null && fee != null) {
          if (pendingTransaction!.amount + fee!.raw == sum.raw) {
            return Amount(
              rawValue: pendingTransaction!.amount,
              fractionDigits: recipients!.first.amount.fractionDigits,
            );
          }
        }

        return sum;
      }
    } else {
      return null;
    }
  }

  Amount? get amountSparkWithoutChange {
    if (sparkRecipients != null && sparkRecipients!.isNotEmpty) {
      if (sparkRecipients!.where((e) => !e.isChange).isEmpty) {
        return Amount(
          rawValue: BigInt.zero,
          fractionDigits: sparkRecipients!.first.amount.fractionDigits,
        );
      } else {
        return sparkRecipients!
            .where((e) => !e.isChange)
            .map((e) => e.amount)
            .reduce((total, amount) => total += amount);
      }
    } else {
      return null;
    }
  }

  int? get estimatedSatsPerVByte =>
      fee != null && vSize != null
          ? (fee!.raw ~/ BigInt.from(vSize!)).toInt()
          : null;

  TxData copyWith({
    FeeRateType? feeRateType,
    BigInt? feeRateAmount,
    int? satsPerVByte,
    Amount? fee,
    int? vSize,
    String? raw,
    String? txid,
    String? txHash,
    String? note,
    String? noteOnChain,
    String? memo,
    String? otherData,
    Set<UTXO>? utxos,
    List<UTXO>? usedUTXOs,
    List<TxRecipient>? recipients,
    String? frostMSConfig,
    List<String>? frostSigners,
    String? changeAddress,
    PaynymAccountLite? paynymAccountLite,
    web3dart.Transaction? web3dartTransaction,
    int? nonce,
    BigInt? chainId,
    BigInt? feeInWei,
    lib_monero.PendingTransaction? pendingTransaction,
    int? jMintValue,
    List<int>? spendCoinIndexes,
    int? height,
    TransactionType? txType,
    TransactionSubType? txSubType,
    List<Map<String, dynamic>>? mintsMapLelantus,
    tezart.OperationsList? tezosOperationsList,
    List<({String address, Amount amount, String memo, bool isChange})>?
    sparkRecipients,
    List<TxData>? sparkMints,
    List<SparkCoin>? usedSparkCoins,
    TransactionV2? tempTx,
    bool? ignoreCachedBalanceChecks,
    NameOpState? opNameState,
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
      otherData: otherData ?? this.otherData,
      utxos: utxos ?? this.utxos,
      usedUTXOs: usedUTXOs ?? this.usedUTXOs,
      recipients: recipients ?? this.recipients,
      frostMSConfig: frostMSConfig ?? this.frostMSConfig,
      frostSigners: frostSigners ?? this.frostSigners,
      changeAddress: changeAddress ?? this.changeAddress,
      paynymAccountLite: paynymAccountLite ?? this.paynymAccountLite,
      web3dartTransaction: web3dartTransaction ?? this.web3dartTransaction,
      nonce: nonce ?? this.nonce,
      chainId: chainId ?? this.chainId,
      feeInWei: feeInWei ?? this.feeInWei,
      pendingTransaction: pendingTransaction ?? this.pendingTransaction,
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
      ignoreCachedBalanceChecks:
          ignoreCachedBalanceChecks ?? this.ignoreCachedBalanceChecks,
      opNameState: opNameState ?? this.opNameState,
    );
  }

  @override
  String toString() =>
      'TxData{'
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
      'frostSigners: $frostSigners, '
      'changeAddress: $changeAddress, '
      'paynymAccountLite: $paynymAccountLite, '
      'web3dartTransaction: $web3dartTransaction, '
      'nonce: $nonce, '
      'chainId: $chainId, '
      'feeInWei: $feeInWei, '
      'pendingTransaction: $pendingTransaction, '
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
      'otherData: $otherData, '
      'tempTx: $tempTx, '
      'ignoreCachedBalanceChecks: $ignoreCachedBalanceChecks, '
      'opNameState: $opNameState, '
      '}';
}
