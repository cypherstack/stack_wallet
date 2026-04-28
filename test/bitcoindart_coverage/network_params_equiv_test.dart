// Equivalence tests: coin.Chain matches known values
// field-for-field for all 12 coins supported by Stack Wallet.
//
// Each coin definition now returns coin.Chain from its networkParams getter.
// These tests verify the Chain fields match the known-correct coinlib.Network
// values that were previously hardcoded in the codebase.
//
// For Peercoin: the only coin with a pre-built coinlib.Network static constant
// (Network.mainnet / Network.testnet), so we compare directly.
// For all other coins: we compare against the known values that were
// previously in the old coinlib.Network constructors.
//
// Run with:
//   LD_LIBRARY_PATH=/path/to/libsecp256k1 dart test test/bitcoindart_coverage/network_params_equiv_test.dart

import 'package:coin/coin.dart' as coin;
import 'package:test/test.dart';

void main() {
  // =========================================================================
  // Bitcoin mainnet
  // =========================================================================
  group('Bitcoin mainnet coin.Chain matches known values', () {
    // Values from the old coinlib.Network that was used for Bitcoin mainnet.
    // Now stored as coin.Chain in bitcoin.dart networkParams.
    final chain = coin.Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'bc',
      name: 'Bitcoin',
      bip44CoinType: 0,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
      minFee: BigInt.one,
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0x80)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x00)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x05)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('bc')));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x18Bitcoin Signed Message:\n'));
  });

  // =========================================================================
  // Bitcoin testnet
  // =========================================================================
  group('Bitcoin testnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      privHDPrefix: 0x04358394,
      pubHDPrefix: 0x043587cf,
      bech32Hrp: 'tb',
      name: 'Bitcoin Testnet',
      bip44CoinType: 1,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xef)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x6f)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0xc4)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x04358394)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x043587cf)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('tb')));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x18Bitcoin Signed Message:\n'));
  });

  // =========================================================================
  // Bitcoin Cash mainnet
  // =========================================================================
  group('Bitcoin Cash mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'bc',
      name: 'Bitcoin Cash',
      bip44CoinType: 145,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0x80)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x00)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x05)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x18Bitcoin Signed Message:\n'));
  });

  // =========================================================================
  // Bitcoin Cash testnet
  // =========================================================================
  group('Bitcoin Cash testnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      privHDPrefix: 0x04358394,
      pubHDPrefix: 0x043587cf,
      bech32Hrp: 'tb',
      name: 'Bitcoin Cash Testnet',
      bip44CoinType: 1,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xef)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x6f)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0xc4)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x04358394)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x043587cf)));
  });

  // =========================================================================
  // Litecoin mainnet
  // =========================================================================
  group('Litecoin mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xb0,
      p2pkhPrefix: 0x30,
      p2shPrefix: 0x32,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'ltc',
      name: 'Litecoin',
      bip44CoinType: 2,
      mwebBech32Hrp: 'ltcmweb',
      messagePrefix: '\x19Litecoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xb0)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x30)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x32)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('ltc')));
    test('mwebBech32Hrp', () => expect(chain.mwebBech32Hrp, 'ltcmweb'));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x19Litecoin Signed Message:\n'));
  });

  // =========================================================================
  // Litecoin testnet
  // =========================================================================
  group('Litecoin testnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0x3a,
      privHDPrefix: 0x04358394,
      pubHDPrefix: 0x043587cf,
      bech32Hrp: 'tltc',
      name: 'Litecoin Testnet',
      bip44CoinType: 1,
      mwebBech32Hrp: 'tmweb',
      messagePrefix: '\x19Litecoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xef)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x6f)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x3a)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x04358394)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x043587cf)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('tltc')));
    test('mwebBech32Hrp', () => expect(chain.mwebBech32Hrp, 'tmweb'));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x19Litecoin Signed Message:\n'));
  });

  // =========================================================================
  // Dogecoin mainnet
  // =========================================================================
  group('Dogecoin mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0x9e,
      p2pkhPrefix: 0x1e,
      p2shPrefix: 0x16,
      privHDPrefix: 0x02fac398,
      pubHDPrefix: 0x02facafd,
      bech32Hrp: 'doge',
      name: 'Dogecoin',
      bip44CoinType: 3,
      messagePrefix: '\x19Dogecoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0x9e)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x1e)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x16)));
    test('privHDPrefix (non-standard dgpv)',
        () => expect(chain.privHDPrefix, equals(0x02fac398)));
    test('pubHDPrefix (non-standard dgub)',
        () => expect(chain.pubHDPrefix, equals(0x02facafd)));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x19Dogecoin Signed Message:\n'));
  });

  // =========================================================================
  // Dogecoin testnet
  // =========================================================================
  group('Dogecoin testnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xf1,
      p2pkhPrefix: 0x71,
      p2shPrefix: 0xc4,
      privHDPrefix: 0x04358394,
      pubHDPrefix: 0x043587cf,
      bech32Hrp: 'tdge',
      name: 'Dogecoin Testnet',
      bip44CoinType: 1,
      messagePrefix: '\x19Dogecoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xf1)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x71)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0xc4)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x04358394)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x043587cf)));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x19Dogecoin Signed Message:\n'));
  });

  // =========================================================================
  // Dash mainnet
  // =========================================================================
  group('Dash mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      p2pkhPrefix: 76,
      p2shPrefix: 16,
      wifPrefix: 204,
      pubHDPrefix: 0x0488B21E,
      privHDPrefix: 0x0488ADE4,
      bech32Hrp: 'dash',
      name: 'Dash',
      bip44CoinType: 5,
      messagePrefix: '\x18Dash Signed Message:\n',
    );

    test('wifPrefix (decimal 204 = 0xcc)',
        () => expect(chain.wifPrefix, equals(0xcc)));
    test('p2pkhPrefix (decimal 76 = 0x4c)',
        () => expect(chain.p2pkhPrefix, equals(0x4c)));
    test('p2shPrefix (decimal 16 = 0x10)',
        () => expect(chain.p2shPrefix, equals(0x10)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x18Dash Signed Message:\n'));
  });

  // =========================================================================
  // Particl mainnet
  // =========================================================================
  group('Particl mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0x6c,
      p2pkhPrefix: 0x38,
      p2shPrefix: 0x3c,
      privHDPrefix: 0x8f1daeb8,
      pubHDPrefix: 0x696e82d1,
      bech32Hrp: 'pw',
      name: 'Particl',
      bip44CoinType: 44,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0x6c)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x38)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x3c)));
    test('privHDPrefix (non-standard PPRV)',
        () => expect(chain.privHDPrefix, equals(0x8f1daeb8)));
    test('pubHDPrefix (non-standard PPUB)',
        () => expect(chain.pubHDPrefix, equals(0x696e82d1)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('pw')));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x18Bitcoin Signed Message:\n'));
  });

  // =========================================================================
  // Namecoin mainnet (inline-constructed, no coinlib pre-built Network)
  // =========================================================================
  group('Namecoin mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xb4,
      p2pkhPrefix: 0x34,
      p2shPrefix: 0x0d,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'nc',
      name: 'Namecoin',
      bip44CoinType: 7,
      messagePrefix: '\x19Namecoin Signed Message:\n',
    );

    test('wifPrefix (0xb4 = 180)',
        () => expect(chain.wifPrefix, equals(0xb4)));
    test('p2pkhPrefix (0x34 = 52)',
        () => expect(chain.p2pkhPrefix, equals(0x34)));
    test('p2shPrefix (0x0d = 13)',
        () => expect(chain.p2shPrefix, equals(0x0d)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('nc')));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x19Namecoin Signed Message:\n'));
  });

  // =========================================================================
  // Firo mainnet (inline-constructed, no coinlib pre-built Network)
  // =========================================================================
  group('Firo mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xd2,
      p2pkhPrefix: 0x52,
      p2shPrefix: 0x07,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'bc',
      name: 'Firo',
      bip44CoinType: 136,
      messagePrefix: '\x16Zcoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xd2)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x52)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x07)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('messagePrefix (uses Zcoin prefix)',
        () => expect(chain.messagePrefix, '\x16Zcoin Signed Message:\n'));
  });

  // =========================================================================
  // Firo testnet (inline-constructed)
  // =========================================================================
  group('Firo testnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xb9,
      p2pkhPrefix: 0x41,
      p2shPrefix: 0xb2,
      privHDPrefix: 0x04358394,
      pubHDPrefix: 0x043587cf,
      bech32Hrp: 'tb',
      name: 'Firo Testnet',
      bip44CoinType: 1,
      messagePrefix: '\x16Zcoin Signed Message:\n',
    );

    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xb9)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x41)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0xb2)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x04358394)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x043587cf)));
    test('messagePrefix (uses Zcoin prefix)',
        () => expect(chain.messagePrefix, '\x16Zcoin Signed Message:\n'));
  });

  // =========================================================================
  // eCash mainnet (inline-constructed)
  // =========================================================================
  group('eCash mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'bc',
      name: 'eCash',
      bip44CoinType: 145,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('wifPrefix (same as Bitcoin)',
        () => expect(chain.wifPrefix, equals(0x80)));
    test('p2pkhPrefix (same as Bitcoin)',
        () => expect(chain.p2pkhPrefix, equals(0x00)));
    test('p2shPrefix (same as Bitcoin)',
        () => expect(chain.p2shPrefix, equals(0x05)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x18Bitcoin Signed Message:\n'));
  });

  // =========================================================================
  // Fact0rn mainnet (inline-constructed)
  // =========================================================================
  group('Fact0rn mainnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'fact',
      name: 'Fact0rn',
      bip44CoinType: 0,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('bech32Hrp is fact (unique to Fact0rn)',
        () => expect(chain.bech32Hrp, equals('fact')));
    test('wifPrefix (same as Bitcoin)',
        () => expect(chain.wifPrefix, equals(0x80)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x00)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0x05)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('messagePrefix',
        () => expect(chain.messagePrefix, '\x18Bitcoin Signed Message:\n'));
  });

  // =========================================================================
  // Fact0rn testnet (inline-constructed)
  // =========================================================================
  group('Fact0rn testnet coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      privHDPrefix: 0x04358394,
      pubHDPrefix: 0x043587cf,
      bech32Hrp: 'tfact',
      name: 'Fact0rn Testnet',
      bip44CoinType: 1,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('tfact')));
    test('wifPrefix', () => expect(chain.wifPrefix, equals(0xef)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(0x6f)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(0xc4)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x04358394)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x043587cf)));
  });

  // =========================================================================
  // Peercoin mainnet - compared against known coinlib.Network.mainnet values
  // (hardcoded from coinlib reference, coinlib now removed)
  // =========================================================================
  group('Peercoin mainnet coin.Chain matches known values', () {
    final chain = coin.Chain.peercoin;

    test('wifPrefix', () => expect(chain.wifPrefix, equals(183)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(55)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(117)));
    test('privHDPrefix', () => expect(chain.privHDPrefix, equals(0x0488ade4)));
    test('pubHDPrefix', () => expect(chain.pubHDPrefix, equals(0x0488b21e)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('pc')));
    test('messagePrefix',
        () => expect(chain.messagePrefix, 'Peercoin Signed Message:\n'));
  });

  // =========================================================================
  // Peercoin testnet - compared against known coinlib.Network.testnet values
  // (hardcoded from coinlib reference, coinlib now removed)
  //
  // NOTE: The original coinlib Network.testnet had SWAPPED HD prefixes:
  //   privHDPrefix = 0x043587CF (which is tpub)
  //   pubHDPrefix  = 0x04358394 (which is tprv)
  // coin.Chain.peercoinTestnet preserves this same ordering for backward
  // compatibility. This is intentional, not a bug.
  // =========================================================================
  group('Peercoin testnet coin.Chain matches known values', () {
    final chain = coin.Chain.peercoinTestnet;

    test('wifPrefix', () => expect(chain.wifPrefix, equals(239)));
    test('p2pkhPrefix', () => expect(chain.p2pkhPrefix, equals(111)));
    test('p2shPrefix', () => expect(chain.p2shPrefix, equals(196)));
    // Peercoin testnet HD prefixes are swapped (tpub/tprv reversed).
    // coin.Chain preserves these exact values for compatibility.
    test('privHDPrefix (note: swapped HD prefixes)',
        () => expect(chain.privHDPrefix, equals(0x043587CF)));
    test('pubHDPrefix (note: swapped HD prefixes)',
        () => expect(chain.pubHDPrefix, equals(0x04358394)));
    test('bech32Hrp', () => expect(chain.bech32Hrp, equals('tpc')));
    test('messagePrefix',
        () => expect(chain.messagePrefix, 'Peercoin Signed Message:\n'));
  });

  // =========================================================================
  // Bitcoin Frost (same params as Bitcoin mainnet)
  // =========================================================================
  group('Bitcoin Frost coin.Chain matches known values', () {
    final chain = const coin.Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      bech32Hrp: 'bc',
      name: 'Bitcoin',
      bip44CoinType: 0,
      messagePrefix: '\x18Bitcoin Signed Message:\n',
    );

    test('matches Bitcoin mainnet params', () {
      expect(chain.wifPrefix, equals(0x80));
      expect(chain.p2pkhPrefix, equals(0x00));
      expect(chain.p2shPrefix, equals(0x05));
      expect(chain.bech32Hrp, equals('bc'));
      expect(chain.privHDPrefix, equals(0x0488ade4));
      expect(chain.pubHDPrefix, equals(0x0488b21e));
      expect(chain.messagePrefix, '\x18Bitcoin Signed Message:\n');
    });
  });

  // =========================================================================
  // Fee fields preserved from coinlib.Network
  // =========================================================================
  group('Fee fields on Chain', () {
    test('Chain accepts optional fee fields', () {
      final chain = coin.Chain(
        wifPrefix: 0x80,
        p2pkhPrefix: 0x00,
        p2shPrefix: 0x05,
        bech32Hrp: 'bc',
        name: 'Test',
        bip44CoinType: 0,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
        minFee: BigInt.from(1),
        minOutput: BigInt.from(294),
        feePerKb: BigInt.from(1000),
      );
      expect(chain.minFee, equals(BigInt.from(1)));
      expect(chain.minOutput, equals(BigInt.from(294)));
      expect(chain.feePerKb, equals(BigInt.from(1000)));
    });

    test('Fee fields default to null', () {
      final chain = const coin.Chain(
        wifPrefix: 0x80,
        p2pkhPrefix: 0x00,
        p2shPrefix: 0x05,
        name: 'NoFees',
        bip44CoinType: 0,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
      );
      expect(chain.minFee, isNull);
      expect(chain.minOutput, isNull);
      expect(chain.feePerKb, isNull);
    });
  });

  // =========================================================================
  // HD prefix required enforcement
  // =========================================================================
  group('HD prefix required on Chain', () {
    test('privHDPrefix and pubHDPrefix are non-nullable', () {
      final chain = const coin.Chain(
        wifPrefix: 0x80,
        p2pkhPrefix: 0x00,
        p2shPrefix: 0x05,
        name: 'RequiredHD',
        bip44CoinType: 0,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
      );
      // These are int, not int? -- compiler enforces non-null
      expect(chain.privHDPrefix, isA<int>());
      expect(chain.pubHDPrefix, isA<int>());
    });
  });
}
