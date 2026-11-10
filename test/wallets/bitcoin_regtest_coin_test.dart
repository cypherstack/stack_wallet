import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  final regtest = Bitcoin(CryptoCurrencyNetwork.regtest);
  final testnet = Bitcoin(CryptoCurrencyNetwork.test);

  test('regtest is its own test network', () {
    expect(regtest.identifier, 'bitcoinRegtest');
    expect(regtest.mainNetId, 'bitcoin');
    expect(regtest.network.isTestNet, isTrue);
    expect(
      regtest.genesisHash,
      '0f9188f13cb7b2c71f2a335e3a4fc328bf5beb436012afca590b1a11466e2206',
    );
    expect(regtest.defaultNode(isPrimary: true).useSSL, isFalse);
  });

  test('regtest is not an app coin without STACK_BITCOIN_REGTEST', () {
    expect(AppConfig.bitcoinRegtest, isFalse);
    expect(
      AppConfig.coins.map((e) => e.identifier),
      isNot(contains('bitcoinRegtest')),
    );
  });

  group('addresses', () {
    setUpAll(coinlib.loadCoinlib);

    test('match testnet except for the bcrt prefix', () {
      final key = coinlib.ECPrivateKey(
        Uint8List.fromList(List.generate(32, (i) => i + 1)),
      ).pubkey;
      for (final type in [
        DerivePathType.bip44,
        DerivePathType.bip49,
        DerivePathType.bip84,
        DerivePathType.bip86,
      ]) {
        final r = regtest
            .getAddressForPublicKey(publicKey: key, derivePathType: type)
            .address
            .toString();
        final t = testnet
            .getAddressForPublicKey(publicKey: key, derivePathType: type)
            .address
            .toString();
        if (type == DerivePathType.bip84 || type == DerivePathType.bip86) {
          expect(r, startsWith('bcrt1'));
          expect(
            coinlib.Address.fromString(
              r,
              regtest.networkParams,
            ).program.script.compiled,
            coinlib.Address.fromString(
              t,
              testnet.networkParams,
            ).program.script.compiled,
          );
          expect(regtest.validateAddress(t), isFalse);
        } else {
          // Base58 versions are shared with testnet.
          expect(r, t);
        }
        expect(regtest.validateAddress(r), isTrue);
      }
    });

    test('derive on coin type 1', () {
      expect(
        regtest.constructDerivePath(
          derivePathType: DerivePathType.bip86,
          chain: 0,
          index: 0,
        ),
        "m/86'/1'/0'/0/0",
      );
    });
  });
}
