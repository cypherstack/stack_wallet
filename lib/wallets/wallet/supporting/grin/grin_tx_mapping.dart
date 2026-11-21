import 'dart:convert';

import 'package:grin_native/grin_native.dart';

import '../../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../../utilities/amount/amount.dart';

/// The Stack txid of a Grin log entry: the slate id, or a log id based one
/// for entries without a slate (coinbase, and outputs found by a scan).
String grinTxid(GrinTxLogEntry entry) {
  final slateId = entry.slateId;
  if (slateId != null) return slateId;
  return entry.type == GrinTxType.confirmedCoinbase
      ? "grin_cb_${entry.id}"
      : "grin_log_${entry.id}";
}

bool _isSendType(GrinTxType type) =>
    type == GrinTxType.txSent || type == GrinTxType.txSentCancelled;

bool _isReceiveType(GrinTxType type) =>
    type == GrinTxType.txReceived ||
    type == GrinTxType.txReceivedCancelled ||
    type == GrinTxType.confirmedCoinbase;

/// Turns the Grin log into Stack transactions.
///
/// Entries are grouped by txid. A self-send logs a send and a receive with
/// one slate id; they become a single row, because txid and walletId are a
/// unique index. [storedHeights] holds the heights already stored by txid,
/// which a confirmed entry keeps when the library no longer reports one.
/// [chainHeight] is used for a confirmed entry with no height at all.
List<TransactionV2> mapGrinTransactions({
  required List<GrinTxLogEntry> entries,
  required String walletId,
  required String? ownAddress,
  required Map<String, int?> storedHeights,
  required int chainHeight,
  required int fractionDigits,
}) {
  final groups = <String, List<GrinTxLogEntry>>{};
  for (final entry in entries) {
    groups.putIfAbsent(grinTxid(entry), () => []).add(entry);
  }

  return [
    for (final MapEntry(key: txid, value: group) in groups.entries)
      _mapGroup(
        txid: txid,
        group: group,
        walletId: walletId,
        ownAddress: ownAddress,
        storedHeight: storedHeights[txid],
        chainHeight: chainHeight,
        fractionDigits: fractionDigits,
      ),
  ];
}

TransactionV2 _mapGroup({
  required String txid,
  required List<GrinTxLogEntry> group,
  required String walletId,
  required String? ownAddress,
  required int? storedHeight,
  required int chainHeight,
  required int fractionDigits,
}) {
  final sent = group.where((e) => _isSendType(e.type)).firstOrNull;
  final received = group.where((e) => _isReceiveType(e.type)).firstOrNull;
  final primary = sent ?? received ?? group.first;
  final selfSend = sent != null && received != null;

  final debited = group.fold(BigInt.zero, (p, e) => p + e.amountDebited);
  final credited = group.fold(BigInt.zero, (p, e) => p + e.amountCredited);
  final fee = sent?.fee ?? primary.fee ?? BigInt.zero;
  final counterparty = group
      .map((e) => e.counterpartyAddress)
      .whereType<String>()
      .firstOrNull;

  final TransactionType type;
  if (selfSend) {
    final toSelf = counterparty == null || counterparty == ownAddress;
    type = toSelf
        ? TransactionType.sentToSelf
        : (credited > debited
              ? TransactionType.incoming
              : TransactionType.outgoing);
  } else {
    type = switch (primary.type) {
      GrinTxType.txReceived ||
      GrinTxType.confirmedCoinbase ||
      GrinTxType.txReceivedCancelled => TransactionType.incoming,
      GrinTxType.txSent ||
      GrinTxType.txSentCancelled => TransactionType.outgoing,
      GrinTxType.txReverted =>
        primary.netAmount > BigInt.zero
            ? TransactionType.incoming
            : TransactionType.outgoing,
      GrinTxType.unknown => TransactionType.unknown,
    };
  }

  final isCoinbase = primary.type == GrinTxType.confirmedCoinbase;
  final cancelled = primary.type.isCancelled;
  final reverted = group.any((e) => e.type == GrinTxType.txReverted);
  final confirmed = group.every((e) => e.confirmed) && !cancelled && !reverted;

  int? height;
  if (confirmed) {
    height =
        group.map((e) => e.confirmedHeight).whereType<int>().firstOrNull ??
        storedHeight ??
        (chainHeight > 0 ? chainHeight : null);
  }

  final inputs = <InputV2>[
    if (isCoinbase)
      InputV2.isarCantDoRequiredInDefaultConstructor(
        scriptSigHex: null,
        scriptSigAsm: null,
        sequence: null,
        outpoint: null,
        addresses: const [],
        valueStringSats: "0",
        witness: null,
        innerRedeemScriptAsm: null,
        coinbase: "grin",
        walletOwns: false,
      ),
    if (debited > BigInt.zero)
      InputV2.isarCantDoRequiredInDefaultConstructor(
        scriptSigHex: null,
        scriptSigAsm: null,
        sequence: null,
        outpoint: null,
        addresses: [?ownAddress],
        valueStringSats: debited.toString(),
        witness: null,
        innerRedeemScriptAsm: null,
        coinbase: null,
        walletOwns: true,
      ),
  ];

  final paid = debited - credited - fee;
  final outputs = <OutputV2>[
    if (credited > BigInt.zero)
      OutputV2.isarCantDoRequiredInDefaultConstructor(
        scriptPubKeyHex: "00",
        valueStringSats: credited.toString(),
        addresses: [?ownAddress],
        walletOwns: true,
      ),
    if (type == TransactionType.outgoing && paid > BigInt.zero)
      OutputV2.isarCantDoRequiredInDefaultConstructor(
        scriptPubKeyHex: "00",
        valueStringSats: paid.toString(),
        addresses: [?counterparty],
        walletOwns: false,
      ),
  ];

  final kernelExcess = group
      .map((e) => e.kernelExcess)
      .whereType<String>()
      .firstOrNull;

  final otherData = <String, dynamic>{
    TxV2OdKeys.isGrinTransaction: true,
    TxV2OdKeys.slateId: primary.slateId,
    TxV2OdKeys.isCancelled: cancelled,
    TxV2OdKeys.isReverted: reverted,
    TxV2OdKeys.grinLogIds: [for (final e in group) e.id],
    TxV2OdKeys.grinSlateState: primary.slateState?.wireName,
    TxV2OdKeys.grinHasStoredTx: group.any((e) => e.hasStoredTx),
    TxV2OdKeys.grinKernelExcess: kernelExcess,
    TxV2OdKeys.grinTtlCutoff: primary.ttlCutoffHeight,
    TxV2OdKeys.grinHasPaymentProof: group.any((e) => e.paymentProof != null),
    TxV2OdKeys.counterpartyAddress: counterparty,
    TxV2OdKeys.overrideFee: Amount(
      rawValue: fee,
      fractionDigits: fractionDigits,
    ).toJsonString(),
  };

  return TransactionV2(
    walletId: walletId,
    blockHash: null,
    hash: kernelExcess ?? txid,
    txid: txid,
    timestamp: primary.creationTime.millisecondsSinceEpoch ~/ 1000,
    height: height,
    inputs: List.unmodifiable(inputs),
    outputs: List.unmodifiable(outputs),
    version: 0,
    type: type,
    subType: TransactionSubType.none,
    otherData: jsonEncode(otherData),
  );
}
