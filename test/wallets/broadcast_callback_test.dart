import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:wallet/wallet.dart' as eth;
import 'package:web3dart/web3dart.dart' as web3;

void main() {
  test(
    'Ethereum awaits the journal before broadcasting its signed bytes',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var journaled = false;
      var requests = 0;
      late String raw;
      late String localTxid;
      final client = web3.Web3Client(
        'https://ethereum.invalid',
        MockClient((request) async {
          requests++;
          expect(journaled, isTrue);
          final rpc = jsonDecode(request.body) as Map<String, dynamic>;
          expect(rpc['method'], 'eth_sendRawTransaction');
          expect((rpc['params'] as List).single, raw);
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': rpc['id'],
              'result': localTxid,
            }),
            200,
          );
        }),
      );
      addTearDown(client.dispose);

      final send = _EthereumWallet(client).confirmSend(
        txData: _ethereumTxData(),
        prepareTempTx: (txData, _) => txData,
        beforeBroadcast: (signed) async {
          raw = signed;
          expect(raw, startsWith('0x02'));
          localTxid = web3.bytesToHex(
            web3.keccak256(raw.toUint8ListFromHex),
            include0x: true,
          );
          entered.complete();
          await release.future;
          journaled = true;
        },
      );

      await entered.future;
      expect(requests, 0);
      release.complete();
      final sent = await send;
      expect(requests, 1);
      expect(sent.txid, localTxid);
      expect(sent.txHash, localTxid);
    },
  );

  test(
    'Rosen Ethereum rejects a node transaction ID that differs from its own',
    () async {
      var journaled = false;
      final client = web3.Web3Client(
        'https://ethereum.invalid',
        MockClient((request) async {
          expect(journaled, isTrue);
          final rpc = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': rpc['id'],
              'result': '0x${'00' * 32}',
            }),
            200,
          );
        }),
      );
      addTearDown(client.dispose);

      await expectLater(
        _EthereumWallet(client).confirmSend(
          txData: _ethereumTxData(),
          prepareTempTx: (txData, _) => txData,
          beforeBroadcast: (_) async => journaled = true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Ethereum node returned an unexpected transaction ID.',
          ),
        ),
      );
    },
  );

  test('Ordinary Ethereum sends preserve the existing node response', () async {
    final nodeTxid = '0x${'AB' * 32}';
    var requests = 0;
    var tempTxPrepared = false;
    final client = web3.Web3Client(
      'https://ethereum.invalid',
      MockClient((request) async {
        requests++;
        final rpc = jsonDecode(request.body) as Map<String, dynamic>;
        expect(rpc['method'], 'eth_sendRawTransaction');
        expect((rpc['params'] as List).single, startsWith('0x02'));
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': rpc['id'], 'result': nodeTxid}),
          200,
        );
      }),
    );
    addTearDown(client.dispose);

    final sent = await _EthereumWallet(client).confirmSend(
      txData: _ethereumTxData().copyWith(note: 'existing send note'),
      prepareTempTx: (txData, address) {
        expect(txData.txid, nodeTxid);
        expect(txData.txHash, nodeTxid);
        expect(address, '0x9858effd232b4033e47d90003d41ec34ecaeda94');
        tempTxPrepared = true;
        return txData;
      },
    );
    expect(requests, 1);
    expect(tempTxPrepared, isTrue);
    expect(sent.txid, nodeTxid);
    expect(sent.txHash, nodeTxid);
    expect(sent.note, 'existing send note');
  });

  test('Electrum awaits the journal before broadcasting', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var journaled = false;
    final client = _ElectrumClient(() => expect(journaled, isTrue));
    final wallet = _ElectrumWallet()
      ..mainDB = MainDB.instance
      ..electrumXClient = client;

    final send = wallet.confirmSend(
      txData: TxData(raw: '010203', usedUTXOs: []),
      beforeBroadcast: (raw) async {
        expect(raw, '010203');
        entered.complete();
        await release.future;
        journaled = true;
      },
    );

    await entered.future;
    expect(client.calls, 0);
    release.complete();
    final sent = await send;
    expect(client.calls, 1);
    expect(sent.txid, 'electrum-txid');
  });

  for (final ethereum in [true, false]) {
    for (final journal in [true, false]) {
      testWidgets('${ethereum ? 'Ethereum' : 'Electrum'} '
          '${journal ? 'bridge' : 'ordinary'} broadcast timeout scope', (
        tester,
      ) async {
        final journalEntered = Completer<void>();
        final journalRelease = Completer<void>();
        final response = Completer<String>();
        var journaled = false;
        var requests = 0;
        var txid = 'unreached';
        final client = web3.Web3Client(
          'https://ethereum.invalid',
          MockClient((request) async {
            requests++;
            expectSync(journaled, journal);
            final rpc = jsonDecode(request.body) as Map<String, dynamic>;
            expectSync(rpc['method'], 'eth_sendRawTransaction');
            final raw = (rpc['params'] as List).single as String;
            txid = web3.bytesToHex(
              web3.keccak256(raw.toUint8ListFromHex),
              include0x: true,
            );
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': rpc['id'],
                'result': await response.future,
              }),
              200,
            );
          }),
        );
        addTearDown(client.dispose);
        final ethereumWallet = _EthereumWallet(client);
        final electrumWallet = _ElectrumWallet()
          ..mainDB = MainDB.instance
          ..electrumXClient = _ElectrumClient(() {
            requests++;
            expectSync(journaled, journal);
            txid = 'electrum-txid';
          }, response: response);
        Future<void> beforeBroadcast(String raw) async {
          journalEntered.complete();
          await journalRelease.future;
          journaled = true;
        }

        final sending = ethereum
            ? ethereumWallet.confirmSend(
                txData: _ethereumTxData(),
                prepareTempTx: (txData, _) => txData,
                beforeBroadcast: journal ? beforeBroadcast : null,
              )
            : electrumWallet.confirmSend(
                txData: TxData(raw: '010203', usedUTXOs: []),
                beforeBroadcast: journal ? beforeBroadcast : null,
              );
        Object? result;
        final completed = sending.then<void>(
          (_) => result = true,
          onError: (Object error) => result = error,
        );
        try {
          await tester.pump();
          if (journal) {
            expect(journalEntered.isCompleted, isTrue);
            await tester.pump(const Duration(seconds: 31));
            expect(result, isNull);
            expect(requests, 0);
            journalRelease.complete();
            await tester.pump();
          }
          expect(requests, 1);
          await tester.pump(const Duration(seconds: 29));
          expect(result, isNull);
          await tester.pump(const Duration(seconds: 1));
          expect(response.isCompleted, isFalse);
          expect(result, journal ? isA<TimeoutException>() : isNull);
        } finally {
          if (!journalRelease.isCompleted) journalRelease.complete();
          response.complete(txid);
          await tester.pump();
          await completed;
        }
        final cacheUpdates = ethereum
            ? ethereumWallet.cacheUpdates
            : electrumWallet.cacheUpdates;
        expect(cacheUpdates, journal ? 0 : 1);
        expect(result, journal ? isA<TimeoutException>() : isTrue);
        expect(requests, 1);
      });
    }
  }
}

TxData _ethereumTxData() => TxData(
  chainId: BigInt.one,
  web3dartTransaction: web3.Transaction(
    to: eth.EthereumAddress.fromHex(
      '0x00112233445566778899aabbccddeeff00112233',
    ),
    value: eth.EtherAmount.zero(),
    nonce: 7,
    maxGas: 21000,
    maxFeePerGas: eth.EtherAmount.inWei(BigInt.from(30)),
    maxPriorityFeePerGas: eth.EtherAmount.inWei(BigInt.from(2)),
  ),
);

class _EthereumWallet extends EthereumWallet {
  _EthereumWallet(this.client) : super(CryptoCurrencyNetwork.main);

  final web3.Web3Client client;
  int cacheUpdates = 0;

  @override
  web3.Web3Client getEthClient() => client;

  @override
  Future<String> getMnemonic() async =>
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  @override
  Future<String> getMnemonicPassphrase() async => '';

  @override
  Future<Address?> getCurrentReceivingAddress() async => Address(
    walletId: 'test',
    value: '0x9858effd232b4033e47d90003d41ec34ecaeda94',
    publicKey: [],
    derivationIndex: 0,
    derivationPath: null,
    type: cryptoCurrency.defaultAddressType,
    subType: AddressSubType.receiving,
  );

  @override
  Future<TxData> updateSentCachedTxData({required TxData txData}) async {
    cacheUpdates++;
    return txData;
  }
}

class _ElectrumWallet extends FiroWallet {
  _ElectrumWallet() : super(CryptoCurrencyNetwork.main);

  int cacheUpdates = 0;

  @override
  Future<TxData> updateSentCachedTxData({required TxData txData}) async {
    cacheUpdates++;
    return txData;
  }
}

class _ElectrumClient extends Fake implements ElectrumXClient {
  _ElectrumClient(this.beforeSend, {this.response});

  final void Function() beforeSend;
  final Completer<String>? response;
  int calls = 0;

  @override
  Future<String> broadcastTransaction({
    required String rawTx,
    String? requestID,
  }) async {
    beforeSend();
    calls++;
    return response == null ? 'electrum-txid' : await response!.future;
  }
}
