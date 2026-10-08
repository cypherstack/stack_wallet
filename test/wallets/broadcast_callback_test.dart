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
    'Ethereum rejects a node transaction ID that differs from its own',
    () async {
      final client = web3.Web3Client(
        'https://ethereum.invalid',
        MockClient((request) async {
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
  Future<TxData> updateSentCachedTxData({required TxData txData}) async =>
      txData;
}

class _ElectrumWallet extends FiroWallet {
  _ElectrumWallet() : super(CryptoCurrencyNetwork.main);

  @override
  Future<TxData> updateSentCachedTxData({required TxData txData}) async =>
      txData;
}

class _ElectrumClient extends Fake implements ElectrumXClient {
  _ElectrumClient(this.beforeSend);

  final void Function() beforeSend;
  int calls = 0;

  @override
  Future<String> broadcastTransaction({
    required String rawTx,
    String? requestID,
  }) async {
    beforeSend();
    calls++;
    return 'electrum-txid';
  }
}
