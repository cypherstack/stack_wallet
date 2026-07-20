import 'package:blockchain_utils/bip/bip/bip39/bip39_seed_generator.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/xrp_wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

// Standard BIP-39 test mnemonic.
const _mnemonic =
    "abandon abandon abandon abandon abandon abandon abandon abandon "
    "abandon abandon abandon about";

// A well-known example classic XRP address (from the XRPL docs).
const _validClassic = "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh";

// Known-answer vector for [_mnemonic] at m/44'/144'/0'/0/0 (secp256k1),
// cross-verified against iancoleman.io/bip39 (coin: XRP). Guarantees import
// interop with Trust Wallet / Ledger / iancoleman for the same mnemonic.
const _knownAddress = "rHsMGQEkVNJmpGWs8XUBoTBiAAbwxZN5v3";

/// Replicates XrpWallet's derivation: BIP44 m/44'/144'/0'/0/0 (secp256k1),
/// address computed via xrpl_dart from that key.
String _deriveViaXrpl(String mnemonic, {String passphrase = ""}) {
  final seed = Bip39SeedGenerator(
    Mnemonic.fromString(mnemonic),
  ).generate(passphrase);
  final node = Bip44.fromSeed(seed, Bip44Coins.ripple).deriveDefaultPath;
  final key = XRPPrivateKey.fromBytes(
    node.privateKey.raw,
    algorithm: XRPKeyAlgorithm.secp256k1,
  );
  return key.getPublic().toAddress().toAddress();
}

/// The same BIP44 path, but address computed by blockchain_utils itself.
String _deriveViaBlockchainUtils(String mnemonic, {String passphrase = ""}) {
  final seed = Bip39SeedGenerator(
    Mnemonic.fromString(mnemonic),
  ).generate(passphrase);
  return Bip44.fromSeed(
    seed,
    Bip44Coins.ripple,
  ).deriveDefaultPath.publicKey.toAddress;
}

void main() {
  final xrp = Xrp(CryptoCurrencyNetwork.main);

  group("Xrp address validation", () {
    test("accepts a valid classic r-address", () {
      expect(xrp.validateAddress(_validClassic), isTrue);
    });

    test("rejects a Bitcoin address, junk, and empty", () {
      expect(
        xrp.validateAddress("1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"),
        isFalse,
      );
      expect(xrp.validateAddress("not an address"), isFalse);
      expect(xrp.validateAddress(""), isFalse);
    });

    test("getAddressType returns xrp for valid, null for invalid", () {
      expect(xrp.getAddressType(_validClassic), AddressType.xrp);
      expect(xrp.getAddressType("garbage"), isNull);
    });
  });

  group("Xrp units", () {
    test("1 XRP = 1,000,000 drops (fractionDigits 6)", () {
      expect(xrp.fractionDigits, 6);
      expect(xrp.satsPerCoin, BigInt.from(1000000));
    });
  });

  group("Xrp derivation (BIP44 m/44'/144'/0'/0/0, secp256k1)", () {
    test("blockchain_utils and xrpl_dart agree on the address", () {
      final viaXrpl = _deriveViaXrpl(_mnemonic);
      final viaBu = _deriveViaBlockchainUtils(_mnemonic);
      // ignore: avoid_print
      print("XRP address (xrpl_dart):        $viaXrpl");
      // ignore: avoid_print
      print("XRP address (blockchain_utils): $viaBu");
      // Fund-safety: the address we DISPLAY (derived via xrpl_dart, the signer)
      // must equal the standard BIP44 address a peer wallet would derive.
      expect(
        viaXrpl,
        viaBu,
        reason: "displayed address must match the signing key's address",
      );
      expect(viaXrpl.startsWith("r"), isTrue);
    });

    test("known-answer vector (verified vs iancoleman.io/bip39)", () {
      expect(_deriveViaXrpl(_mnemonic), _knownAddress);
      expect(_deriveViaBlockchainUtils(_mnemonic), _knownAddress);
    });

    test("passphrase changes the derived address", () {
      expect(
        _deriveViaXrpl(_mnemonic),
        isNot(_deriveViaXrpl(_mnemonic, passphrase: "TREZOR")),
      );
    });
  });

  group("Xrp X-address / destination tag", () {
    test("round-trips classic + tag through an X-address", () {
      const tag = 12345;
      final x = XRPAddress(_validClassic).toXAddress(tag: tag);
      expect(x.startsWith("X"), isTrue);

      final decoded = XRPAddress(x, allowXAddress: true);
      // .address is always the classic form; .tag carries the embedded tag.
      expect(decoded.address, _validClassic);
      expect(decoded.tag, tag);
    });

    test("classic address carries no embedded tag", () {
      final a = XRPAddress(_validClassic, allowXAddress: true);
      expect(a.address, _validClassic);
      expect(a.tag, isNull);
    });
  });

  group("Xrp Payment build + sign", () {
    XRPPrivateKey key() {
      final seed = Bip39SeedGenerator(
        Mnemonic.fromString(_mnemonic),
      ).generate();
      final node = Bip44.fromSeed(seed, Bip44Coins.ripple).deriveDefaultPath;
      return XRPPrivateKey.fromBytes(
        node.privateKey.raw,
        algorithm: XRPKeyAlgorithm.secp256k1,
      );
    }

    Payment buildSignedPayment(XRPPrivateKey k) {
      final payment = Payment(
        account: k.getPublic().toAddress().toAddress(),
        destination: _validClassic,
        amount: CurrencyAmount.xrp(BigInt.from(1000000)), // 1 XRP
        destinationTag: 42,
        fee: BigInt.from(12),
        sequence: 1,
        lastLedgerSequence: 100,
        signer: XRPLSignature.signer(k.getPublic().toHex()),
      );
      payment.setSignature(k.sign(payment.toBlob()));
      return payment;
    }

    test("carries the intended fields and a non-empty signed blob", () {
      final k = key();
      final payment = buildSignedPayment(k);
      expect(payment.account, k.getPublic().toAddress().toAddress());
      expect(payment.destination, _validClassic);
      expect(payment.destinationTag, 42);
      expect(payment.amount.xrp, BigInt.from(1000000));
      expect(payment.toBlob(forSigning: false).isNotEmpty, isTrue);
    });

    test("signing is deterministic (stable hash)", () {
      final k = key();
      expect(buildSignedPayment(k).getHash(), buildSignedPayment(k).getHash());
    });
  });

  group("Xrp family-seed import", () {
    // Canonical XRPL genesis vector.
    const genesisSeed = "snoPBrXtMeMyMHUVTgbuqAfg1SUTb";
    const genesisAddress = "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh";

    test("isValidFamilySeed accepts a seed and rejects non-seeds", () {
      expect(XrpWallet.isValidFamilySeed(genesisSeed), isTrue);
      expect(XrpWallet.isValidFamilySeed("  $genesisSeed  "), isTrue);
      expect(XrpWallet.isValidFamilySeed("not a seed"), isFalse);
      // A classic r-address must not be mistaken for a family seed.
      expect(XrpWallet.isValidFamilySeed(_validClassic), isFalse);
      expect(XrpWallet.isValidFamilySeed(""), isFalse);
    });

    test("family seed decodes to the expected address", () {
      final key = XRPPrivateKey.fromSeed(genesisSeed);
      expect(key.getPublic().toAddress().toAddress(), genesisAddress);
    });
  });

  group("Xrp destination tag validation", () {
    test("accepts null, 0 and the uint32 boundary", () {
      expect(XrpWallet.isValidDestinationTag(null), isTrue); // no tag
      expect(XrpWallet.isValidDestinationTag(0), isTrue);
      expect(XrpWallet.isValidDestinationTag(4294967295), isTrue); // 2^32 - 1
    });

    test(
      "rejects negative and out-of-range tags (would wrap on serialize)",
      () {
        expect(XrpWallet.isValidDestinationTag(-1), isFalse);
        expect(XrpWallet.isValidDestinationTag(4294967296), isFalse); // 2^32
        // The 10-digit value the send field's maxLength would otherwise allow.
        expect(XrpWallet.isValidDestinationTag(9999999999), isFalse);
      },
    );
  });
}
