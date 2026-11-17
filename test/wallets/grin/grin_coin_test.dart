import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../support/grin_fakes.dart';

void main() {
  final backend = FakeGrinBackend();
  final main = Grin(CryptoCurrencyNetwork.main, addressBackend: backend);
  final test_ = Grin(CryptoCurrencyNetwork.test, addressBackend: backend);

  test('fields', () {
    expect(main.identifier, 'grin');
    expect(test_.identifier, 'grinTestNet');
    expect(main.mainNetId, 'grin');
    expect(test_.mainNetId, 'grin');
    expect(main.ticker, 'GRIN');
    expect(test_.ticker, 'tGRIN');
    expect(main.prettyName, 'Grin');
    expect(main.uriScheme, 'grin');
    expect(main.minConfirms, 10);
    expect(main.minCoinbaseConfirms, 1440);
    expect(main.fractionDigits, 9);
    expect(main.satsPerCoin, BigInt.from(1000000000));
    expect(main.defaultSeedPhraseLength, 24);
    expect(main.possibleMnemonicLengths, [24, 12]);
    expect(main.hasMnemonicPassphraseSupport, isFalse);
    expect(main.hasBuySupport, isFalse);
    expect(main.torSupport, isTrue);
    expect(main.defaultAddressType, AddressType.mimbleWimble);
    expect(main.grinNetwork, GrinNetwork.mainnet);
    expect(test_.grinNetwork, GrinNetwork.testnet);
    expect(() => main.defaultDerivePathType, throwsUnsupportedError);
    expect(() => main.defaultBlockExplorer('x'), throwsUnsupportedError);
    expect(() => Grin(CryptoCurrencyNetwork.stage), throwsException);
  });

  test('default nodes, including testnet, never throw', () {
    final m = main.defaultNode(isPrimary: false);
    expect(m.host, 'https://grinnode.live');
    expect(m.port, 3413);
    expect(m.useSSL, isTrue);
    expect(m.torEnabled && m.clearnetEnabled, isTrue);
    expect(m.isPrimary, isFalse, reason: 'isPrimary is passed through');
    expect(m.nodeApiSecret, isNull);
    expect(main.defaultNode(isPrimary: true).isPrimary, isTrue);

    final t = test_.defaultNode(isPrimary: true);
    expect(t.host, 'http://127.0.0.1');
    expect(t.port, 13413);
    expect(t.useSSL, isFalse);
    expect(t.coinName, 'grinTestNet');
  });

  test('validateAddress uses the backend and rejects the other network', () {
    expect(main.validateAddress('grin1abc'), isTrue);
    expect(main.validateAddress('tgrin1abc'), isFalse);
    expect(test_.validateAddress('tgrin1abc'), isTrue);
    expect(main.validateAddress('http://x.onion'), isTrue);
    expect(main.validateAddress('https://wallet.example'), isTrue);
    expect(main.validateAddress('nonsense'), isFalse);
    expect(main.addressKind('grin1abc'), GrinAddressKind.slatepack);
    expect(main.addressKind('nonsense'), isNull);
    expect(main.getAddressType('grin1abc'), AddressType.mimbleWimble);
    expect(main.getAddressType('nonsense'), isNull);
  });

  test('validateAddress is false when the native library is missing', () {
    final throwing = Grin(
      CryptoCurrencyNetwork.main,
      addressBackend: _ThrowingBackend(),
    );
    expect(throwing.validateAddress('grin1abc'), isFalse);
  });

  test('isSlatepack and heightFromDate', () {
    expect(main.isSlatepack(' BEGINSLATEPACK. abc ENDSLATEPACK. '), isTrue);
    expect(main.isSlatepack('BEGINSLATEPACK. abc'), isFalse);
    expect(
      main.heightFromDate(
        DateTime.fromMillisecondsSinceEpoch(1547568086 * 1000),
      ),
      0,
    );
    expect(main.heightFromDate(DateTime.utc(2000)), 0);
    final day = main.heightFromDate(
      DateTime.fromMillisecondsSinceEpoch((1547568086 + 86400) * 1000),
    );
    expect(day, 86400 ~/ 61);
    expect(
      test_.heightFromDate(
        DateTime.fromMillisecondsSinceEpoch((1546030084 + 610) * 1000),
      ),
      10,
    );
  });
}

class _ThrowingBackend extends FakeGrinBackend {
  @override
  GrinAddressValidation validateAddressSync(
    String address,
    GrinNetwork network,
  ) => throw StateError('GRIN not enabled');
}
