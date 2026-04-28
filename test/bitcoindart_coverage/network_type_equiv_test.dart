import 'package:coin/coin_chains.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  group('Particl Chain equivalence', () {
    test('wifPrefix matches bitcoindart NetworkType.wif', () {
      expect(ParticlParams.particl.chain.wifPrefix, equals(kParticlWif));
    });

    test('p2pkhPrefix matches bitcoindart NetworkType.pubKeyHash', () {
      expect(ParticlParams.particl.chain.p2pkhPrefix, equals(kParticlP2pkh));
    });

    test('p2shPrefix matches bitcoindart NetworkType.scriptHash', () {
      expect(ParticlParams.particl.chain.p2shPrefix, equals(kParticlP2sh));
    });

    test('bech32Hrp matches bitcoindart NetworkType.bech32', () {
      expect(ParticlParams.particl.chain.bech32Hrp, equals(kParticlBech32));
    });
  });

  group('Firo Chain equivalence', () {
    // No FiroParams in coin (Pitfall 8 from research) -- construct inline
    // to prove the Chain values match what bitcoindart NetworkType uses.
    final firoChain = const Chain(
      wifPrefix: 0xd2,
      p2pkhPrefix: 0x52,
      p2shPrefix: 0x07,
      bech32Hrp: 'bc',
      name: 'Firo',
      bip44CoinType: 136,
      supportsSegwit: false,
      supportsTaproot: false,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      messagePrefix: '\x16Zcoin Signed Message:\n',
    );

    test('wifPrefix matches bitcoindart NetworkType.wif', () {
      expect(firoChain.wifPrefix, equals(kFiroWif));
    });

    test('p2pkhPrefix matches bitcoindart NetworkType.pubKeyHash', () {
      expect(firoChain.p2pkhPrefix, equals(kFiroP2pkh));
    });

    test('p2shPrefix matches bitcoindart NetworkType.scriptHash', () {
      expect(firoChain.p2shPrefix, equals(kFiroP2sh));
    });

    test('bech32Hrp matches bitcoindart NetworkType.bech32', () {
      expect(firoChain.bech32Hrp, equals(kFiroBech32));
    });
  });

  group('Bitcoin mainnet Chain equivalence', () {
    test('BitcoinParams.bitcoin.chain fields match known values', () {
      final chain = BitcoinParams.bitcoin.chain;
      expect(chain.wifPrefix, equals(0x80));
      expect(chain.p2pkhPrefix, equals(0x00));
      expect(chain.p2shPrefix, equals(0x05));
      expect(chain.bech32Hrp, equals('bc'));
    });
  });

  group('Chain now carries messagePrefix and HD prefix fields', () {
    test('Chain has messagePrefix field ', () {
      // coin Chain exposes a messagePrefix field.
      expect(
        ParticlParams.particl.chain.messagePrefix,
        equals('\x18Bitcoin Signed Message:\n'),
      );
    });

    test('Chain has bip32 HD prefix fields ', () {
      // coin Chain HD prefixes are required fields.
      expect(BitcoinParams.bitcoin.chain.privHDPrefix, equals(0x0488ade4));
      expect(BitcoinParams.bitcoin.chain.pubHDPrefix, equals(0x0488b21e));
    });
  });
}
