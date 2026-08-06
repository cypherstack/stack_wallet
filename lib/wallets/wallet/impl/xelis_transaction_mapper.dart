import 'dart:convert';

import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../utilities/amount/amount.dart';
import '../../../wl_gen/interfaces/lib_xelis_interface.dart';

TransactionV2 mapXelisTransactionEntry({
  required TransactionEntryWrapper transactionEntry,
  required String walletId,
  required String walletAddress,
  required int fractionDigits,
}) {
  final inputs = <InputV2>[];
  final outputs = <OutputV2>[];
  final otherData = <String, dynamic>{};
  final entry = transactionEntry.entryType;

  InputV2 walletInput(int value) =>
      InputV2.isarCantDoRequiredInDefaultConstructor(
        scriptSigHex: null,
        scriptSigAsm: null,
        sequence: null,
        outpoint: null,
        addresses: [walletAddress],
        valueStringSats: value.toString(),
        witness: null,
        innerRedeemScriptAsm: null,
        coinbase: null,
        walletOwns: true,
      );

  OutputV2 output(int value, String address, {required bool walletOwns}) =>
      OutputV2.isarCantDoRequiredInDefaultConstructor(
        scriptPubKeyHex: '',
        valueStringSats: value.toString(),
        addresses: [address],
        walletOwns: walletOwns,
      );

  void setFee(int fee) {
    otherData['overrideFee'] = Amount(
      rawValue: BigInt.from(fee),
      fractionDigits: fractionDigits,
    ).toJsonString();
  }

  void addIncomingContractTransfers(Map<String, Map<String, int>> transfers) {
    for (final contractEntry in transfers.entries) {
      for (final assetEntry in contractEntry.value.entries) {
        outputs.add(output(assetEntry.value, walletAddress, walletOwns: true));
      }
    }
  }

  final TransactionType transactionType;
  int? nonce;

  switch (entry) {
    case CoinbaseEntryWrapper(:final reward):
      transactionType = TransactionType.incoming;
      outputs.add(output(reward, walletAddress, walletOwns: true));
      otherData['xelisEntryType'] = 'coinbase';
      setFee(0);

    case BurnEntryWrapper(:final amount, :final fee, :final asset):
      transactionType = TransactionType.outgoing;
      nonce = entry.nonce;
      inputs.add(walletInput(amount + fee));
      outputs.add(output(amount, 'burn', walletOwns: false));
      otherData['xelisEntryType'] = 'burn';
      otherData['burnAsset'] = asset;
      setFee(fee);

    case IncomingEntryWrapper(:final from, :final transfers):
      transactionType = from == walletAddress
          ? TransactionType.sentToSelf
          : TransactionType.incoming;
      for (final transfer in transfers) {
        outputs.add(output(transfer.amount, walletAddress, walletOwns: true));
        otherData['asset_${transfer.asset}'] = transfer.amount.toString();
        if (transfer.extraData != null) {
          otherData['extraData_${transfer.asset}'] = transfer.extraData;
        }
      }
      otherData['xelisEntryType'] = 'incoming';
      otherData['from'] = from;
      setFee(0);

    case OutgoingEntryWrapper(:final fee, :final transfers):
      transactionType = TransactionType.outgoing;
      nonce = entry.nonce;
      inputs.add(walletInput(fee));
      for (final transfer in transfers) {
        inputs.add(walletInput(transfer.amount));
        outputs.add(
          output(transfer.amount, transfer.destination, walletOwns: false),
        );
        otherData['asset_${transfer.asset}_amount'] = transfer.amount
            .toString();
        if (transfer.extraData != null) {
          otherData['extraData_${transfer.asset}'] = transfer.extraData;
        }
      }
      otherData['xelisEntryType'] = 'outgoing';
      setFee(fee);

    case MultisigEntryWrapper(
      :final participants,
      :final threshold,
      :final fee,
    ):
      transactionType = TransactionType.outgoing;
      nonce = entry.nonce;
      inputs.add(walletInput(fee));
      for (final participant in participants) {
        outputs.add(output(0, participant, walletOwns: false));
      }
      otherData['xelisEntryType'] = 'multisig';
      otherData['participants'] = participants;
      otherData['threshold'] = threshold;
      setFee(fee);

    case InvokeContractEntryWrapper(
      :final contract,
      :final deposits,
      :final received,
      :final chunkId,
      :final fee,
      :final maxGas,
    ):
      transactionType = TransactionType.outgoing;
      nonce = entry.nonce;
      inputs.add(walletInput(fee));
      for (final deposit in deposits.entries) {
        inputs.add(walletInput(deposit.value));
        outputs.add(output(deposit.value, contract, walletOwns: false));
      }
      addIncomingContractTransfers(received);
      otherData['xelisEntryType'] = 'invokeContract';
      otherData['contract'] = contract;
      otherData['deposits'] = deposits;
      otherData['received'] = received;
      otherData['chunkId'] = chunkId;
      otherData['maxGas'] = maxGas;
      setFee(fee);

    case DeployContractEntryWrapper(:final fee, :final invoke):
      transactionType = TransactionType.outgoing;
      nonce = entry.nonce;
      inputs.add(walletInput(fee));
      if (invoke != null) {
        for (final deposit in invoke.deposits.entries) {
          inputs.add(walletInput(deposit.value));
          outputs.add(
            output(deposit.value, 'contract-deployment', walletOwns: false),
          );
        }
      }
      otherData['xelisEntryType'] = 'deployContract';
      if (invoke != null) {
        otherData['invoke'] = {
          'maxGas': invoke.maxGas,
          'deposits': invoke.deposits,
        };
      }
      setFee(fee);

    case IncomingContractEntryWrapper(:final transfers):
      transactionType = TransactionType.incoming;
      addIncomingContractTransfers(transfers);
      otherData['xelisEntryType'] = 'incomingContract';
      otherData['transfers'] = transfers;
      setFee(0);

    case OutgoingBlobEntryWrapper(:final destinations, :final fee, :final data):
      transactionType = TransactionType.outgoing;
      nonce = entry.nonce;
      inputs.add(walletInput(fee));
      for (final destination in destinations) {
        outputs.add(output(0, destination, walletOwns: false));
      }
      otherData['xelisEntryType'] = 'outgoingBlob';
      otherData['destinations'] = destinations;
      otherData['data'] = data;
      setFee(fee);

    case IncomingBlobEntryWrapper(
      :final from,
      :final destinations,
      :final data,
    ):
      transactionType = from == walletAddress
          ? TransactionType.sentToSelf
          : TransactionType.incoming;
      for (final destination in destinations) {
        outputs.add(
          output(0, destination, walletOwns: destination == walletAddress),
        );
      }
      otherData['xelisEntryType'] = 'incomingBlob';
      otherData['from'] = from;
      otherData['destinations'] = destinations;
      otherData['data'] = data;
      setFee(0);

    case UnknownEntryWrapper(:final entryType, :final data):
      transactionType = TransactionType.unknown;
      otherData['xelisEntryType'] = entryType;
      if (data != null) {
        otherData['data'] = data;
      }
      setFee(0);
  }

  if (nonce != null) {
    otherData['nonce'] = nonce;
  }

  return TransactionV2(
    walletId: walletId,
    blockHash: '',
    hash: transactionEntry.hash,
    txid: transactionEntry.hash,
    timestamp:
        (transactionEntry.timestamp?.millisecondsSinceEpoch ?? 0) ~/ 1000,
    height: transactionEntry.topoheight,
    inputs: List.unmodifiable(inputs),
    outputs: List.unmodifiable(outputs),
    version: -1,
    type: transactionType,
    subType: TransactionSubType.none,
    otherData: jsonEncode(otherData),
  );
}
