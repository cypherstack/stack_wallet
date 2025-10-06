import 'package:tezart/tezart.dart' as tezart;
import 'package:web3dart/web3dart.dart' as web3dart;

import '../../models/input.dart';
import '../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../models/isar/models/isar_models.dart';
import '../../models/paynym/paynym_account_lite.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../widgets/eth_fee_form.dart';
import '../../wl_gen/interfaces/cs_monero_interface.dart'
    show CsPendingTransaction;
import '../isar/models/spark_coin.dart';
import 'name_op_state.dart';
import 'tx_recipient.dart';

export 'tx_recipient.dart';

enum TxType {
  regular,
  mweb,
  mwebPegIn,
  mwebPegOut;

  bool isMweb() => switch (this) {
    TxType.mweb => true,
    TxType.mwebPegIn => true,
    TxType.mwebPegOut => true,
    _ => false,
  };
}

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
  final Set<BaseInput>? utxos;
  final List<BaseInput>? usedUTXOs;

  final String? changeAddress;

  // frost specific
  final String? frostMSConfig;
  final List<String>? frostSigners;

  // paynym specific
  final PaynymAccountLite? paynymAccountLite;

  // eth & token specific
  final EthEIP1559Fee? ethEIP1559Fee;
  final web3dart.Transaction? web3dartTransaction;
  final int? nonce;
  final BigInt? chainId;
  // wownero and monero specific
  final CsPendingTransaction? pendingTransaction;

  // salvium
  final CsPendingTransaction? pendingSalviumTransaction;

  // tezos specific
  final tezart.OperationsList? tezosOperationsList;

  // firo spark specific
  final List<({String address, Amount amount, String memo, bool isChange})>?
  sparkRecipients;
  final List<TxData>? sparkMints;
  final List<SparkCoin>? usedSparkCoins;
  final ({
    String additionalInfo,
    String name,
    Address sparkAddress,
    int validBlocks,
  })?
  sparkNameInfo;

  // xelis specific
  final String? otherData;

  final TransactionV2? tempTx;

  final bool ignoreCachedBalanceChecks;

  // Namecoin Name related
  final NameOpState? opNameState;

  final TxType type;

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
    this.ethEIP1559Fee,
    this.web3dartTransaction,
    this.nonce,
    this.chainId,
    this.pendingTransaction,
    this.pendingSalviumTransaction,
    this.tezosOperationsList,
    this.sparkRecipients,
    this.otherData,
    this.sparkMints,
    this.usedSparkCoins,
    this.tempTx,
    this.ignoreCachedBalanceChecks = false,
    this.opNameState,
    this.sparkNameInfo,
    this.type = TxType.regular,
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
      if (pendingSalviumTransaction?.amount != null && fee != null) {
        if (pendingSalviumTransaction!.amount + fee!.raw == sum.raw) {
          return Amount(
            rawValue: pendingSalviumTransaction!.amount,
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
        if (pendingSalviumTransaction?.amount != null && fee != null) {
          if (pendingSalviumTransaction!.amount + fee!.raw == sum.raw) {
            return Amount(
              rawValue: pendingSalviumTransaction!.amount,
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

  int? get estimatedSatsPerVByte => fee != null && vSize != null
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
    Set<BaseInput>? utxos,
    List<BaseInput>? usedUTXOs,
    List<TxRecipient>? recipients,
    String? frostMSConfig,
    List<String>? frostSigners,
    String? changeAddress,
    PaynymAccountLite? paynymAccountLite,
    EthEIP1559Fee? ethEIP1559Fee,
    web3dart.Transaction? web3dartTransaction,
    int? nonce,
    BigInt? chainId,
    CsPendingTransaction? pendingTransaction,
    CsPendingTransaction? pendingSalviumTransaction,
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
    ({
      String additionalInfo,
      String name,
      Address sparkAddress,
      int validBlocks,
    })?
    sparkNameInfo,
    TxType? type,
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
      ethEIP1559Fee: ethEIP1559Fee ?? this.ethEIP1559Fee,
      web3dartTransaction: web3dartTransaction ?? this.web3dartTransaction,
      nonce: nonce ?? this.nonce,
      chainId: chainId ?? this.chainId,
      pendingTransaction: pendingTransaction ?? this.pendingTransaction,
      pendingSalviumTransaction:
          pendingSalviumTransaction ?? this.pendingSalviumTransaction,
      tezosOperationsList: tezosOperationsList ?? this.tezosOperationsList,
      sparkRecipients: sparkRecipients ?? this.sparkRecipients,
      sparkMints: sparkMints ?? this.sparkMints,
      usedSparkCoins: usedSparkCoins ?? this.usedSparkCoins,
      tempTx: tempTx ?? this.tempTx,
      ignoreCachedBalanceChecks:
          ignoreCachedBalanceChecks ?? this.ignoreCachedBalanceChecks,
      opNameState: opNameState ?? this.opNameState,
      sparkNameInfo: sparkNameInfo ?? this.sparkNameInfo,
      type: type ?? this.type,
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
      'ethEIP1559Fee: $ethEIP1559Fee, '
      'web3dartTransaction: $web3dartTransaction, '
      'nonce: $nonce, '
      'chainId: $chainId, '
      'pendingTransaction: $pendingTransaction, '
      'pendingSalviumTransaction: $pendingSalviumTransaction, '
      'tezosOperationsList: $tezosOperationsList, '
      'sparkRecipients: $sparkRecipients, '
      'sparkMints: $sparkMints, '
      'usedSparkCoins: $usedSparkCoins, '
      'otherData: $otherData, '
      'tempTx: $tempTx, '
      'ignoreCachedBalanceChecks: $ignoreCachedBalanceChecks, '
      'opNameState: $opNameState, '
      'sparkNameInfo: $sparkNameInfo, '
      'type: $type, '
      '}';
}
