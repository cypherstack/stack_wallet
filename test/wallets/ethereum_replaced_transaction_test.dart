import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:web3dart/web3dart.dart' as web3;

const _walletId = "wallet";
const _otherWalletId = "otherWallet";
const _address = "0x1111111111111111111111111111111111111111";
const _nativeTxid =
    "0x1111111111111111111111111111111111111111111111111111111111111111";
const _tokenTxid =
    "0x2222222222222222222222222222222222222222222222222222222222222222";
const _minedTxid =
    "0x3333333333333333333333333333333333333333333333333333333333333333";

void main() {
  test("finds replaced pending ETH and token transactions", () async {
    final nativeTransaction = _transaction(
      id: 1,
      txid: _nativeTxid,
      nonce: 6,
      subType: TransactionSubType.none,
    );
    final tokenTransaction = _transaction(
      id: 2,
      txid: _tokenTxid,
      nonce: 7,
      subType: TransactionSubType.ethToken,
      type: TransactionType.sentToSelf,
    );
    final transactions = <String, web3.TransactionInformation?>{
      _nativeTxid: null,
      _tokenTxid: _transactionInformation(_tokenTxid, mined: false),
    };
    final lookedUpTxids = <String>[];
    int transactionCountCalls = 0;

    final replacedTransactions = await findReplacedPendingEthereumTransactions(
      walletId: _walletId,
      transactions: [nativeTransaction, tokenTransaction],
      getLatestConfirmedNonce: () async {
        transactionCountCalls++;
        return 8;
      },
      getTransactionByHash: (txid) async {
        lookedUpTxids.add(txid);
        return transactions[txid];
      },
    );

    expect(
      replacedTransactions.map((transaction) => transaction.id),
      unorderedEquals([nativeTransaction.id, tokenTransaction.id]),
    );
    expect(transactionCountCalls, 1);
    expect(lookedUpTxids, unorderedEquals([_nativeTxid, _tokenTxid]));
  });

  test("preserves transactions without replacement proof", () async {
    final unconsumed = _transaction(id: 1, txid: "unconsumed", nonce: 9);
    final mined = _transaction(id: 2, txid: _minedTxid, nonce: 8);
    final incoming = _transaction(
      id: 3,
      txid: "incoming",
      nonce: 7,
      type: TransactionType.incoming,
    );
    final unsupportedSubtype = _transaction(
      id: 4,
      txid: "unsupportedSubtype",
      nonce: 6,
      subType: TransactionSubType.cashFusion,
    );
    final confirmed = _transaction(
      id: 5,
      txid: "confirmed",
      nonce: 5,
      height: 1,
    );
    final otherWallet = _transaction(
      id: 6,
      txid: "otherWallet",
      nonce: 4,
      walletId: _otherWalletId,
    );
    final missingNonce = _transaction(id: 7, txid: "missingNonce", nonce: null);
    final lookedUpTxids = <String>[];

    final replacedTransactions = await findReplacedPendingEthereumTransactions(
      walletId: _walletId,
      transactions: [
        unconsumed,
        mined,
        incoming,
        unsupportedSubtype,
        confirmed,
        otherWallet,
        missingNonce,
      ],
      getLatestConfirmedNonce: () async => 9,
      getTransactionByHash: (txid) async {
        lookedUpTxids.add(txid);
        return _transactionInformation(txid);
      },
    );

    expect(replacedTransactions, isEmpty);
    expect(lookedUpTxids, [_minedTxid]);
  });

  test("preserves pending transactions when nonce lookup fails", () async {
    int transactionLookupCalls = 0;
    Object? lookupError;

    final replacedTransactions = await findReplacedPendingEthereumTransactions(
      walletId: _walletId,
      transactions: [_transaction(id: 1, txid: _nativeTxid, nonce: 1)],
      getLatestConfirmedNonce: () async =>
          throw StateError("nonce lookup failed"),
      getTransactionByHash: (txid) async {
        transactionLookupCalls++;
        return null;
      },
      onNonceLookupError: (error, stackTrace) {
        lookupError = error;
      },
    );

    expect(replacedTransactions, isEmpty);
    expect(transactionLookupCalls, 0);
    expect(lookupError, isA<StateError>());
  });

  test("preserves pending transactions when hash lookup fails", () async {
    Object? lookupError;
    TransactionV2? failedTransaction;

    final transaction = _transaction(id: 1, txid: _nativeTxid, nonce: 1);
    final replacedTransactions = await findReplacedPendingEthereumTransactions(
      walletId: _walletId,
      transactions: [transaction],
      getLatestConfirmedNonce: () async => 2,
      getTransactionByHash: (txid) async =>
          throw StateError("hash lookup failed"),
      onTransactionLookupError: (transaction, error, stackTrace) {
        failedTransaction = transaction;
        lookupError = error;
      },
    );

    expect(replacedTransactions, isEmpty);
    expect(failedTransaction, same(transaction));
    expect(lookupError, isA<StateError>());
  });

  test("does not query the node without pending transactions", () async {
    int transactionCountCalls = 0;
    int transactionLookupCalls = 0;

    final replacedTransactions = await findReplacedPendingEthereumTransactions(
      walletId: _walletId,
      transactions: [
        _transaction(
          id: 1,
          txid: "incoming",
          nonce: 1,
          type: TransactionType.incoming,
        ),
      ],
      getLatestConfirmedNonce: () async {
        transactionCountCalls++;
        return 2;
      },
      getTransactionByHash: (txid) async {
        transactionLookupCalls++;
        return null;
      },
    );

    expect(replacedTransactions, isEmpty);
    expect(transactionCountCalls, 0);
    expect(transactionLookupCalls, 0);
  });
}

TransactionV2 _transaction({
  required int id,
  required String txid,
  required int? nonce,
  String walletId = _walletId,
  int? height,
  TransactionType type = TransactionType.outgoing,
  TransactionSubType subType = TransactionSubType.none,
}) => TransactionV2(
  walletId: walletId,
  blockHash: height == null ? null : "blockHash",
  hash: txid,
  txid: txid,
  timestamp: 1,
  height: height,
  inputs: const [],
  outputs: const [],
  version: -1,
  type: type,
  subType: subType,
  otherData: jsonEncode({TxV2OdKeys.nonce: nonce}),
)..id = id;

web3.TransactionInformation _transactionInformation(
  String txid, {
  bool mined = true,
}) => web3.TransactionInformation.fromMap({
  "blockHash": mined ? "blockHash" : null,
  "blockNumber": mined ? "1" : null,
  "from": _address,
  "gas": "21000",
  "gasPrice": "1",
  "hash": txid,
  "input": "0x",
  "nonce": "1",
  "to": _address,
  "transactionIndex": mined ? "0" : null,
  "value": "1",
  "v": "27",
  "r": "0x1",
  "s": "0x1",
});
