import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart' as bitcoin;
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/exceptions/electrumx/broadcast_outcome_unknown.dart';
import 'package:stackwallet/models/input.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

class _Database extends Fake implements MainDB {
  final utxos = <UTXO>[];
  final transactions = <TransactionV2>[];
  bool failWrites = false;

  @override
  Isar get isar => _Isar();

  @override
  Future<void> putUTXOs(List<UTXO> entries) async {
    if (failWrites) throw StateError('disk unavailable');
    utxos.addAll(entries);
  }

  @override
  Future<List<int>> updateOrPutTransactionV2s(
    List<TransactionV2> entries,
  ) async {
    transactions.addAll(entries);
    return List.filled(entries.length, 1);
  }
}

class _Isar extends Fake implements Isar {}

class _WalletInfo extends Fake implements WalletInfo {
  @override
  final otherData = <String, dynamic>{'unrelatedSetting': true};

  @override
  Future<void> updateOtherData({
    required Map<String, dynamic> newEntries,
    required Isar isar,
  }) async {
    otherData.addAll(newEntries);
  }
}

class _Client extends Fake implements ElectrumXClient {
  Object? failure;
  String? expectedId;

  @override
  Future<String> broadcastTransaction({
    required String rawTx,
    String? requestID,
    String? expectedTxId,
    Duration? requestTimeout,
  }) async {
    expectedId = expectedTxId;
    if (failure != null) throw failure!;
    return expectedTxId!;
  }
}

class _BitcoinWallet extends BitcoinWallet {
  _BitcoinWallet() : super(CryptoCurrencyNetwork.main);
  @override
  String get walletId => 'wallet';
  @override
  final WalletInfo info = _WalletInfo();
}

// Signed legacy transaction from bitcoindart's transaction.json fixture.
const _legacyRaw =
    '0100000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe'
    '000000006b4830450221008732a460737d956fd94d49a31890b2908'
    'f7ed7025a9c1d0f25e43290f1841716'
    '022004fa7d608a291d44ebbbebbadaac18f943031e7de39ef3bf9920998c43e60c0401'
    '210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798'
    'ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064'
    'faad95db9bcdfd3d88ac00000000';

String _hashLegacy(String raw) => HEX.encode(
  sha256.convert(sha256.convert(HEX.decode(raw)).bytes).bytes.reversed.toList(),
);

TxData _transaction() => TxData(
  raw: 'signed transaction',
  usedUTXOs: [
    StandardInput(
      UTXO(
        walletId: 'wallet',
        txid: 'previous transaction',
        vout: 0,
        value: 1000,
        name: '',
        isBlocked: false,
        blockedReason: null,
        isCoinbase: false,
        blockHash: null,
        blockHeight: null,
        blockTime: null,
        used: false,
      ),
    ),
  ],
  tempTx: TransactionV2(
    walletId: 'wallet',
    blockHash: null,
    hash: 'transaction hash',
    txid: 'expected transaction id',
    timestamp: 1,
    height: null,
    inputs: [],
    outputs: [],
    version: 1,
    type: TransactionType.outgoing,
    subType: TransactionSubType.none,
    otherData: jsonEncode({'existingMetadata': 'preserved'}),
  ),
);

void main() {
  test(
    'PayNym broadcasts the construction ID without re-parsing legacy bytes',
    () async {
      final wallet = _BitcoinWallet();
      final expected = _hashLegacy(_legacyRaw);
      expect(
        expected,
        'a0ff943d3f644d8832b1fa74be4d0ad2577615dc28a7ef74ff8c271b603a082a',
      );
      final unknown = BroadcastOutcomeUnknown(
        txid: expected,
        cause: TimeoutException('lost reply'),
      );
      final client = _Client()..failure = unknown;
      wallet.mainDB = _Database();
      wallet.electrumXClient = client;
      await expectLater(
        wallet.broadcastNotificationTx(
          txData: TxData(raw: _legacyRaw, txid: expected),
        ),
        throwsA(same(unknown)),
      );
      expect(client.expectedId, expected);
    },
  );

  for (final witness in [false, true]) {
    test(
      'Frost derives the correct ID for ${witness ? 'witness' : 'legacy'} serialization',
      () async {
        final wallet = BitcoinFrostWallet(CryptoCurrencyNetwork.main);
        final transaction = bitcoin.Transaction.fromHex(_legacyRaw);
        if (witness) {
          // Witness bytes must not contribute to the transaction ID.
          transaction.setWitness(0, [
            Uint8List.fromList([1, 2, 3]),
          ]);
        }
        final client = _Client();
        wallet.mainDB = _Database();
        wallet.electrumXClient = client;
        final result = await wallet.confirmSend(
          txData: TxData(
            raw: transaction.toHex(),
            utxos: _transaction().usedUTXOs!.toSet(),
          ),
        );
        expect(client.expectedId, _hashLegacy(_legacyRaw));
        expect(result.txid, _hashLegacy(_legacyRaw));
      },
    );
  }

  for (final firo in [false, true]) {
    test(
      '${firo ? 'Firo' : 'Bitcoin'} preserves uncertain sends without success flags',
      () async {
        final Wallet wallet = firo
            ? FiroWallet(CryptoCurrencyNetwork.main)
            : BitcoinWallet(CryptoCurrencyNetwork.main);
        final db = _Database();
        final client = _Client();
        final unknown = BroadcastOutcomeUnknown(
          txid: 'expected transaction id',
          cause: TimeoutException('lost reply'),
        );
        wallet.mainDB = db;
        (wallet as ElectrumXInterface).electrumXClient = client;
        client.failure = unknown;

        await expectLater(
          wallet.confirmSend(txData: _transaction()),
          throwsA(same(unknown)),
        );

        expect(client.expectedId, 'expected transaction id');
        expect(db.utxos.single.used, isTrue);
        final pending = db.transactions.single;
        expect(pending.broadcastOutcomeUnknown, isTrue);
        expect(pending.isInstantLock, isFalse);
        expect(
          pending.statusLabel(
            currentChainHeight: 1,
            minConfirms: 1,
            minCoinbaseConfirms: 100,
          ),
          'Status unknown',
        );
        final metadata = jsonDecode(pending.otherData!) as Map;
        expect(metadata['existingMetadata'], 'preserved');
        expect(metadata[TxV2OdKeys.rawTransaction], 'signed transaction');
      },
    );
  }

  test(
    'a local cache failure preserves the uncertain broadcast error',
    () async {
      final wallet = BitcoinWallet(CryptoCurrencyNetwork.main);
      final unknown = BroadcastOutcomeUnknown(
        txid: 'txid',
        cause: TimeoutException('lost reply'),
      );
      wallet.mainDB = _Database()..failWrites = true;
      wallet.electrumXClient = _Client()..failure = unknown;
      await expectLater(
        wallet.confirmSend(txData: _transaction()),
        throwsA(same(unknown)),
      );
    },
  );

  test('preparations without tempTx retain an unknown history entry and signed bytes', () async {
    final wallet = _BitcoinWallet();
    final db = _Database();
    wallet.mainDB = db;
    final original = _transaction();
    final data = TxData(
      raw: original.raw,
      utxos: original.usedUTXOs!.toSet(),
      fee: Amount(rawValue: BigInt.from(10), fractionDigits: 8),
      recipients: [
        TxRecipient(
          address: 'recipient',
          amount: Amount(rawValue: BigInt.from(100), fractionDigits: 8),
          isChange: false,
          addressType: AddressType.p2pkh,
        ),
      ],
    );
    await wallet.preservePendingBroadcast(txData: data, txid: 'known-id');
    final pending = db.transactions.single;
    expect(pending.txid, 'known-id');
    expect(pending.broadcastOutcomeUnknown, isTrue);
    expect(pending.inputs.single.outpoint!.txid, 'previous transaction');
    expect(
      pending
          .getAmountSentFromThisWallet(fractionDigits: 8, subtractFee: true)
          .raw,
      BigInt.from(100),
    );
    expect(
      (jsonDecode(pending.otherData!) as Map)[TxV2OdKeys.rawTransaction],
      original.raw,
    );
    expect(db.utxos.single.used, isTrue);
  });

  test('unknown broadcasts without an ID retain signed bytes and inputs', () async {
    final wallet = _BitcoinWallet();
    final db = _Database();
    final unknown = BroadcastOutcomeUnknown(
      txid: null,
      cause: TimeoutException('lost reply'),
    );
    wallet.mainDB = db;
    wallet.electrumXClient = _Client()..failure = unknown;
    final data = TxData(
      raw: 'chain-specific signed bytes',
      usedUTXOs: _transaction().usedUTXOs,
    );
    await expectLater(wallet.confirmSend(txData: data), throwsA(same(unknown)));
    // Re-recording the same signed transaction must not duplicate the journal.
    await wallet.preservePendingBroadcast(txData: data);
    final entries =
        wallet.info.otherData[WalletInfoKeys.unknownElectrumBroadcasts] as List;
    expect(entries, hasLength(1));
    expect(entries.single['raw'], data.raw);
    expect(entries.single['status'], 'unknown');
    expect(entries.single['inputs'], [
      {'txid': 'previous transaction', 'vout': 0},
    ]);
    expect(wallet.info.otherData['unrelatedSetting'], isTrue);
    expect(db.transactions, isEmpty);
    expect(db.utxos.every((utxo) => utxo.used == true), isTrue);
  });

  test(
    'a definite rejection does not reserve inputs or create pending history',
    () async {
      final wallet = BitcoinWallet(CryptoCurrencyNetwork.main);
      final db = _Database();
      final rejection = Exception('transaction rejected');
      wallet.mainDB = db;
      wallet.electrumXClient = _Client()..failure = rejection;
      await expectLater(
        wallet.confirmSend(txData: _transaction()),
        throwsA(same(rejection)),
      );
      expect(db.utxos, isEmpty);
      expect(db.transactions, isEmpty);
    },
  );

  test(
    'a confirmed response keeps the existing successful send behavior',
    () async {
      final wallet = FiroWallet(CryptoCurrencyNetwork.main);
      final db = _Database();
      wallet.mainDB = db;
      wallet.electrumXClient = _Client();
      final result = await wallet.confirmSend(txData: _transaction());
      expect(result.txid, 'expected transaction id');
      expect(db.utxos.single.used, isTrue);
      expect(db.transactions.single.broadcastOutcomeUnknown, isFalse);
      expect(db.transactions.single.isInstantLock, isTrue);
    },
  );
}
