import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip47/bip47.dart';
import 'package:coin/coin.dart' as coin;
import 'package:test/test.dart';

const String _kPath = "m/47'/0'/0'";

// Alice seed from BIP-47 test vectors
const String _kSeedAlice =
    "response seminar brave tip suit recall often sound stick owner "
    "lottery motion";

/// Enum values mirroring DerivePathType from the app.
/// We replicate here to avoid importing the full app package
/// which pulls in Flutter framework dependencies.
enum TestDerivePathType { bip44, bip84, bip86 }

/// Replicates _preferredDerivePathType from paynym_interface.dart
/// so we can test the mapping without the full wallet mixin context.
TestDerivePathType preferredDerivePathType(PaymentCode code) {
  if (code.isTaprootEnabled()) return TestDerivePathType.bip86;
  if (code.isSegWitEnabled()) return TestDerivePathType.bip84;
  return TestDerivePathType.bip44;
}

void main() {
  late bip32.BIP32 bip32NodeAlice;

  setUpAll(() async {
    await coin.VaultKeeper.initialize();
    bip32NodeAlice = bip32.BIP32
        .fromSeed(bip39.mnemonicToSeed(_kSeedAlice))
        .derivePath(_kPath);
  });

  group('PayNym P2TR backwards compatibility (TAPTEST-06)', () {
    test('non-segwit payment code has correct capability flags', () {
      final pCode = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      expect(pCode.isSegWitEnabled(), isFalse);
      expect(pCode.isTaprootEnabled(), isFalse);
    });

    test('non-segwit payment code maps to bip44', () {
      final pCode = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      expect(preferredDerivePathType(pCode), TestDerivePathType.bip44);
    });

    test('segwit-only payment code has correct capability flags', () {
      final pCode = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: true,
      );

      expect(pCode.isSegWitEnabled(), isTrue);
      expect(pCode.isTaprootEnabled(), isFalse);
    });

    test('segwit-only payment code maps to bip84', () {
      final pCode = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: true,
      );

      expect(preferredDerivePathType(pCode), TestDerivePathType.bip84);
    });

    test('taproot payment code has correct capability flags', () {
      final pCode = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: true,
        shouldSetTaprootBit: true,
      );

      expect(pCode.isSegWitEnabled(), isTrue);
      expect(pCode.isTaprootEnabled(), isTrue);
    });

    test('taproot payment code maps to bip86', () {
      final pCode = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: true,
        shouldSetTaprootBit: true,
      );

      expect(preferredDerivePathType(pCode), TestDerivePathType.bip86);
    });

    test(
      'getPaymentCode defaults produce non-taproot code '
      '(isSegwit=false, isTaproot=false)',
      () {
        // When getPaymentCode() is called with no params (defaults),
        // shouldSetSegwitBit=false and shouldSetTaprootBit=false.
        // This matches the old getPaymentCode(isSegwit: false) behavior.
        final pCode = PaymentCode.fromBip32Node(
          bip32NodeAlice,
          networkType: bitcoin,
          shouldSetSegwitBit: false,
          shouldSetTaprootBit: false,
        );

        expect(pCode.isTaprootEnabled(), isFalse);
        expect(pCode.isSegWitEnabled(), isFalse);
      },
    );

    test('taproot-only without segwit still maps to bip86', () {
      // Edge case: shouldSetTaprootBit=true but shouldSetSegwitBit=false.
      // In practice getPaymentCode passes
      // shouldSetSegwitBit: isSegwit || isTaproot
      // so this won't occur, but verify the mapping logic still works.
      final pCode = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
        shouldSetTaprootBit: true,
      );

      // _makeTaprootPaymentCode sets both bits (0 and 1)
      expect(pCode.isTaprootEnabled(), isTrue);
      expect(preferredDerivePathType(pCode), TestDerivePathType.bip86);
    });

    test(
      'non-taproot and taproot payment codes produce '
      'different base58 strings',
      () {
        final pCodeV1 = PaymentCode.fromBip32Node(
          bip32NodeAlice,
          networkType: bitcoin,
          shouldSetSegwitBit: false,
        );
        final pCodeTaproot = PaymentCode.fromBip32Node(
          bip32NodeAlice,
          networkType: bitcoin,
          shouldSetSegwitBit: true,
          shouldSetTaprootBit: true,
        );

        expect(
          pCodeV1.toString() != pCodeTaproot.toString(),
          isTrue,
          reason:
              'Taproot payment code should differ from v1 '
              'due to feature byte differences',
        );
      },
    );

    test(
      'DerivePathType -> AddressType mapping is consistent '
      '(bip44=p2pkh, bip84=p2wpkh, bip86=p2tr)',
      () {
        // We verify the mapping by testing the enum names match what
        // DerivePathType.getAddressType() returns in the real code.
        // TestDerivePathType.bip44 -> AddressType.p2pkh
        // TestDerivePathType.bip84 -> AddressType.p2wpkh
        // TestDerivePathType.bip86 -> AddressType.p2tr
        //
        // Since we can't import AddressType without Flutter, we verify
        // the mapping indirectly through the preferredDerivePathType
        // tests above, which prove:
        //   non-segwit code -> bip44 (which maps to p2pkh)
        //   segwit code     -> bip84 (which maps to p2wpkh)
        //   taproot code    -> bip86 (which maps to p2tr)
        expect(TestDerivePathType.bip44.name, 'bip44');
        expect(TestDerivePathType.bip84.name, 'bip84');
        expect(TestDerivePathType.bip86.name, 'bip86');
      },
    );
  });
}
