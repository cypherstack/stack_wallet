import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/exceptions/electrumx/broadcast_outcome_unknown.dart';
import 'package:stackwallet/models/fusion_progress_ui_state.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoincash_wallet.dart';

class _Wallet extends BitcoincashWallet<Bitcoincash> {
  _Wallet() : super(CryptoCurrencyNetwork.main);

  @override
  String get walletId => 'wallet';
}

class _Database extends Fake implements MainDB {
  final inputs = <UTXO>[];
  final transactions = <TransactionV2>[];

  @override
  Future<void> putUTXOs(List<UTXO> entries) async => inputs.addAll(entries);

  @override
  Future<List<int>> updateOrPutTransactionV2s(
    List<TransactionV2> entries,
  ) async {
    transactions.addAll(entries);
    return List.filled(entries.length, 1);
  }
}

class _Client extends Fake implements ElectrumXClient {
  Object? failure;
  int broadcasts = 0;
  String? expectedId;

  @override
  Future<String> broadcastTransaction({
    required String rawTx,
    String? requestID,
    String? expectedTxId,
    Duration? requestTimeout,
  }) async {
    broadcasts++;
    expectedId = expectedTxId;
    if (failure != null) throw failure!;
    return expectedTxId!;
  }
}

void main() {
  final ownHash = '01' * 32;
  final otherHash = '02' * 32;
  final ownAddress = coinlib.P2PKHAddress.fromHash(
    Uint8List(20)..fillRange(0, 20, 3),
    version: 0,
  );
  final otherAddress = coinlib.P2PKHAddress.fromHash(
    Uint8List(20)..fillRange(0, 20, 4),
    version: 0,
  );
  final transaction = coinlib.Transaction(
    version: 2,
    inputs: [
      coinlib.RawInput(
        prevOut: coinlib.OutPoint.fromHex(ownHash, 2),
        scriptSig: Uint8List(0),
      ),
      coinlib.RawInput(
        prevOut: coinlib.OutPoint.fromHex(otherHash, 0),
        scriptSig: Uint8List(0),
      ),
    ],
    outputs: [
      coinlib.Output.fromAddress(BigInt.from(1900), ownAddress),
      coinlib.Output.fromAddress(BigInt.from(4500), otherAddress),
    ],
  );

  UTXO owned(int vout) => UTXO(
    walletId: 'wallet',
    txid: ownHash,
    vout: vout,
    value: 2000,
    name: '',
    isBlocked: false,
    blockedReason: null,
    isCoinbase: false,
    blockHash: null,
    blockHeight: null,
    blockTime: null,
    address: ownAddress.toString(),
    used: false,
  );

  late _Wallet wallet;
  late _Database db;
  late _Client client;
  setUp(() {
    db = _Database();
    client = _Client();
    wallet = _Wallet()
      ..mainDB = db
      ..electrumXClient = client
      ..uiState = FusionProgressUIState();
  });

  Future<String> broadcast() => wallet.broadcastFusionTransaction(
    transaction.toHex(),
    walletUtxos: [owned(2), owned(3)],
    walletAddresses: [ownAddress.toString()],
  );

  test('legacy fusion fixture txid matches the transmitted bytes', () {
    final digest = sha256.convert(sha256.convert(transaction.toBytes()).bytes);
    final txid = coinlib.bytesToHex(
      Uint8List.fromList(digest.bytes.reversed.toList()),
    );
    expect(transaction.txid, txid);
    expect(
      txid,
      '06491ada379641d488029a6a84cdbb75c3daa8a37817c187f3d2b50af975378d',
    );
  });

  test(
    'unknown fusion preserves owned inputs and stops further broadcasts',
    () async {
      final unknown = BroadcastOutcomeUnknown(
        txid: transaction.txid,
        cause: TimeoutException('lost broadcast reply'),
      );
      client.failure = unknown;
      await expectLater(broadcast(), throwsA(same(unknown)));

      expect(client.expectedId, transaction.txid);
      expect(db.inputs.single.vout, 2);
      expect(db.inputs.single.txid, ownHash);
      expect(db.inputs.single.used, isTrue);
      final pending = db.transactions.single;
      expect(pending.txid, transaction.txid);
      expect(pending.version, 2);
      expect(pending.subType, TransactionSubType.cashFusion);
      expect(pending.broadcastOutcomeUnknown, isTrue);
      expect(pending.inputs.single.outpoint!.txid, ownHash);
      expect(pending.outputs.single.value, BigInt.from(1900));
      expect(pending.outputs.single.walletOwns, isTrue);
      expect(pending.getFee(fractionDigits: 8).raw, BigInt.from(100));
      expect(
        (jsonDecode(pending.otherData!) as Map)[TxV2OdKeys.rawTransaction],
        transaction.toHex(),
      );
      expect(wallet.uiState.running, isFalse);
      expect(wallet.uiState.failed, isFalse);
      expect(wallet.uiState.fusionRoundsFailed, 0);
      expect(wallet.uiState.fusing.status, CashFusionStatus.waiting);
      expect(
        wallet.uiState.fusing.info,
        contains('Transaction status unknown'),
      );
      expect(wallet.uiState.fusing.info, contains(transaction.txid));

      // Even a late or repeated library callback must not send another round.
      client.failure = null;
      await expectLater(broadcast(), throwsA(same(unknown)));
      expect(client.broadcasts, 1);
      expect(db.transactions, hasLength(1));
    },
  );

  test(
    'definite fusion rejection does not reserve inputs or cache uncertainty',
    () async {
      final rejected = Exception('transaction rejected');
      client.failure = rejected;
      await expectLater(broadcast(), throwsA(same(rejected)));
      expect(db.inputs, isEmpty);
      expect(db.transactions, isEmpty);
      expect(wallet.uiState.fusing.info, isNull);
    },
  );

  test(
    'successful fusion broadcast still returns its exact transaction id',
    () async {
      expect(await broadcast(), transaction.txid);
      expect(db.inputs, isEmpty);
      expect(db.transactions, isEmpty);
      expect(await broadcast(), transaction.txid);
      expect(client.broadcasts, 2);
    },
  );
}
