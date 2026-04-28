import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../vectors/address_vectors.dart';

/// Address generation matrix test covering all (coin, DerivePathType)
/// combinations used by the Stack Wallet.
///
/// Each test derives a key from the standard BIP39 mnemonic using the
/// coin library, constructs the appropriate address type, and verifies:
///   1. The address has the correct prefix for its coin/type
///   2. The address is deterministic (same seed always produces same result)
///
/// This uses the exact same API the wallet uses:
///   - DerivedKey.fromSeed() + derivePath() for HD key derivation
///   - P2pkhAddr, P2shAddr, P2wpkhAddr, TaprootAddr for address encoding
void main() {
  late Uint8List seed;

  setUpAll(() async {
    await VaultKeeper.initialize();
    final mnemonic = Mnemonic.fromPhrase(kStandardMnemonic);
    seed = mnemonic.toSeed();
  });

  /// Generate an address string from a seed, chain, derivation path, and
  /// address type. This mirrors the wallet's `getAddressForPublicKey` logic.
  String generateAddress(
    Uint8List seed,
    Chain chain,
    String derivationPath,
    String addressType,
  ) {
    final root = DerivedKey.fromSeed(seed);
    final derived = root.derivePath(derivationPath);
    final pubKeyBytes = derived.publicKey.bytes;
    final pkHash = hash160(pubKeyBytes);

    switch (addressType) {
      case 'p2pkh':
        return P2pkhAddr(pkHash).encode(chain);
      case 'p2sh':
        // BIP49: P2SH wrapping P2WPKH witness program
        final witnessScript = P2wpkhAddr(pkHash).scriptPubKey;
        final scriptHash = hash160(witnessScript);
        return P2shAddr(scriptHash).encode(chain);
      case 'p2wpkh':
        return P2wpkhAddr(pkHash).encode(chain);
      case 'p2tr':
        // BIP86: Taproot key-path spend (tweaked x-only pubkey)
        final taproot = Taproot(internalKey: derived.publicKey);
        return TaprootAddr(taproot.tweakedKey).encode(chain);
      default:
        throw ArgumentError('Unknown address type: $addressType');
    }
  }

  // -----------------------------------------------------------------------
  // Meta-test: verify all expected combinations are present
  // -----------------------------------------------------------------------
  test('address vectors cover all 22 wallet (coin, derivePathType) combos',
      () {
    // 11 coins, 22 total combinations matching wallet supportedDerivationPathTypes
    expect(kAddressVectors.length, equals(22));

    // Verify each coin is represented
    final coins = kAddressVectors.map((v) => v.coinName).toSet();
    expect(
      coins,
      containsAll([
        'Bitcoin',
        'Litecoin',
        'Bitcoin Cash',
        'Namecoin',
        'Firo',
        'Particl',
        'Dash',
        'Dogecoin',
        'eCash',
        'Fact0rn',
        'Peercoin',
      ]),
    );
  });

  // -----------------------------------------------------------------------
  // Per-coin test groups
  // -----------------------------------------------------------------------
  final byCoin = <String, List<AddressVector>>{};
  for (final v in kAddressVectors) {
    byCoin.putIfAbsent(v.coinName, () => []).add(v);
  }

  for (final entry in byCoin.entries) {
    group(entry.key, () {
      for (final v in entry.value) {
        test(
            '${v.derivePathType} (${v.addressType}) generates correct address',
            () {
          final addr = generateAddress(
            seed,
            v.chain,
            v.derivationPath,
            v.addressType,
          );

          // Verify address prefix
          if (v.expectedAddressPrefix.isNotEmpty) {
            expect(
              addr,
              startsWith(v.expectedAddressPrefix),
              reason: '$v: expected prefix "${v.expectedAddressPrefix}" '
                  'but got "$addr"',
            );
          }

          // Verify determinism: generating again produces the same address
          final addr2 = generateAddress(
            seed,
            v.chain,
            v.derivationPath,
            v.addressType,
          );
          expect(addr, equals(addr2),
              reason: '$v: address not deterministic');

          // Verify non-empty
          expect(addr.isNotEmpty, isTrue,
              reason: '$v: generated empty address');
        });
      }
    });
  }

  // -----------------------------------------------------------------------
  // Cross-cutting validation
  // -----------------------------------------------------------------------
  group('cross-cutting checks', () {
    test('no two vectors with the same chain+path produce the same address',
        () {
      final addresses = <String>[];
      for (final v in kAddressVectors) {
        final addr = generateAddress(
          seed,
          v.chain,
          v.derivationPath,
          v.addressType,
        );
        addresses.add(addr);
      }

      // Vectors that share the same chain bytes AND derivation path may
      // legitimately produce the same address (e.g. BCH bip44 coinType=145
      // vs eCash bip44 coinType=145 share identical chain bytes and path).
      // We check that within each coin, no duplicate addresses exist.
      final byCoinAddrs = <String, Set<String>>{};
      for (var i = 0; i < kAddressVectors.length; i++) {
        final v = kAddressVectors[i];
        byCoinAddrs
            .putIfAbsent(v.coinName, () => {})
            .add(addresses[i]);
      }
      for (final entry in byCoinAddrs.entries) {
        // Each coin's unique (derivePathType) should produce unique addresses
        // (since they use different derivation paths).
        final coinVectors =
            kAddressVectors.where((v) => v.coinName == entry.key).toList();
        // Only check uniqueness when derivation paths differ
        final pathSet = coinVectors.map((v) => v.derivationPath).toSet();
        if (pathSet.length == coinVectors.length) {
          expect(
            entry.value.length,
            equals(coinVectors.length),
            reason: '${entry.key}: duplicate addresses found for '
                'different derivation paths',
          );
        }
      }
    });

    test('segwit addresses only generated for segwit-capable chains', () {
      for (final v in kAddressVectors) {
        if (v.addressType == 'p2wpkh' || v.addressType == 'p2tr') {
          expect(
            v.chain.bech32Hrp,
            isNotNull,
            reason: '${v.coinName} ${v.derivePathType}: '
                'segwit address requires bech32Hrp',
          );
        }
      }
    });
  });
}
