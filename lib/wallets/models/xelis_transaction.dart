import 'dart:convert';

import '../../models/isar/models/blockchain_data/transaction.dart';
import '../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../utilities/amount/amount.dart';
import '../../wl_gen/interfaces/lib_xelis_interface.dart';

TransactionV2? projectXelisTransaction({
  required TransactionEntryWrapper tx,
  required String ownAddress,
  required String walletId,
  required String xelisAsset,
  required int fractionDigits,
}) {
  Amount amount(BigInt raw) =>
      Amount(rawValue: raw, fractionDigits: fractionDigits);
  final inputs = <InputV2>[];
  final outputs = <OutputV2>[];
  var fee = BigInt.zero;
  BigInt? nonce;
  var type = TransactionType.incoming;
  String? action;
  void input(BigInt value) => inputs.add(
    InputV2.isarCantDoRequiredInDefaultConstructor(
      scriptSigHex: null,
      scriptSigAsm: null,
      sequence: null,
      outpoint: null,
      addresses: [ownAddress],
      valueStringSats: value.toString(),
      witness: null,
      innerRedeemScriptAsm: null,
      coinbase: null,
      walletOwns: true,
    ),
  );
  void output(BigInt value, String destination, {required bool owned}) =>
      outputs.add(
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: '',
          valueStringSats: value.toString(),
          addresses: [destination],
          walletOwns: owned,
        ),
      );
  switch (tx.entryType) {
    case CoinbaseEntryWrapper(:final reward):
      output(reward, ownAddress, owned: true);
    case BurnEntryWrapper(:final amount, :final fee, :final asset):
      type = TransactionType.outgoing;
      input(fee);
      if (asset == xelisAsset) {
        input(amount);
        output(amount, 'burn', owned: false);
      }
      action = 'burn';
    // Pattern bindings are final, so assign the transaction fee below.
    case IncomingEntryWrapper(:final from, :final transfers):
      type = from == ownAddress
          ? TransactionType.sentToSelf
          : TransactionType.incoming;
      for (final transfer in transfers.where((e) => e.asset == xelisAsset)) {
        output(transfer.amount, ownAddress, owned: true);
      }
      if (outputs.isEmpty) return null;
    case OutgoingEntryWrapper(
      :final transfers,
      fee: final outgoingFee,
      nonce: final outgoingNonce,
    ):
      fee = outgoingFee;
      nonce = outgoingNonce;
      type = TransactionType.outgoing;
      input(fee);
      for (final transfer in transfers.where((e) => e.asset == xelisAsset)) {
        input(transfer.amount);
        output(
          transfer.amount,
          transfer.destination,
          owned: transfer.destination == ownAddress,
        );
      }
      if (outputs.isNotEmpty && outputs.every((e) => e.walletOwns)) {
        type = TransactionType.sentToSelf;
      }
    case XelisActionEntryWrapper(
      kind: final kind,
      :final spent,
      :final received,
      fee: final actionFee,
      nonce: final actionNonce,
    ):
      fee = actionFee;
      nonce = actionNonce;
      action = kind;
      input(spent + fee);
      if (spent > BigInt.zero) output(spent, kind, owned: false);
      if (received > BigInt.zero) output(received, ownAddress, owned: true);
      type = spent + fee > received
          ? TransactionType.outgoing
          : TransactionType.incoming;
    case UnknownEntryWrapper():
      return null;
  }
  if (tx.entryType case BurnEntryWrapper(fee: final burnFee)) fee = burnFee;
  return TransactionV2(
    walletId: walletId,
    blockHash: '',
    hash: tx.hash,
    txid: tx.hash,
    timestamp: (tx.timestamp?.millisecondsSinceEpoch ?? 0) ~/ 1000,
    height: tx.topoheight == null ? null : xelisStorageInt(tx.topoheight!),
    inputs: List.unmodifiable(inputs),
    outputs: List.unmodifiable(outputs),
    version: -1,
    type: type,
    subType: TransactionSubType.none,
    otherData: jsonEncode({
      TxV2OdKeys.overrideFee: amount(fee).toJsonString(),
      if (nonce != null) 'xelisNonce': nonce.toString(),
      if (action != null) 'xelisAction': action,
    }),
  );
}
