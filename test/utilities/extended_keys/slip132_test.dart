import 'package:coinlib_flutter/coinlib_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/extended_keys/slip132.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

// BIP-0084 test vector (mnemonic "abandon abandon ... about"), account
// m/84'/0'/0'. The same key material serialized with different SLIP-0132
// version bytes. The zpub is quoted verbatim from the BIP-0084 spec; the xpub
// and ypub were derived from it by a lossless version-byte swap.
const _zpub =
    "zpub6rFR7y4Q2AijBEqTUquhVz398htDFrtymD9xYYfG1m4wAcvPhXNf"
    "E3EfH1r1ADqtfSdVCToUG868RvUUkgDKf31mGDtKsAYz2oz2AGutZYs";

const _xpub =
    "xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3X"
    "yuvPEbvqAQY3rAPshWcMLoP2fMFMKHPJ4ZeZXYVUhLv1VMrjPC7PW6V";

const _ypub =
    "ypub6XR9pJPUsVBFKweLeV85HtwdxjjmKEuUr6djm9mNdkh47X7ASsD6"
    "byaXFotRAKByFoWgSzCuoTjaYdrv2yoJroLAPtBuHFjVm5vNmhyNehE";

void main() {
  int pub(bool testnet, DerivePathType t) =>
      Slip132.pubVersion(isTestnet: testnet, derivePathType: t);
  int priv(bool testnet, DerivePathType t) =>
      Slip132.privVersion(isTestnet: testnet, derivePathType: t);
  DerivePathType? inv(int v, {bool testnet = false, bool ltc = false}) =>
      Slip132.derivePathTypeForPubVersion(
        v,
        isTestnet: testnet,
        includeLitecoinLegacy: ltc,
      );

  group("Slip132 version-byte mapping", () {
    test("mainnet pub versions per path type", () {
      expect(pub(false, DerivePathType.bip44), 0x0488b21e);
      expect(pub(false, DerivePathType.bip49), 0x049d7cb2);
      expect(pub(false, DerivePathType.bip84), 0x04b24746);
      // No SLIP-0132 taproot prefix: bip86 stays xpub.
      expect(pub(false, DerivePathType.bip86), 0x0488b21e);
    });

    test("testnet pub versions per path type", () {
      expect(pub(true, DerivePathType.bip44), 0x043587cf);
      expect(pub(true, DerivePathType.bip49), 0x044a5262);
      expect(pub(true, DerivePathType.bip84), 0x045f1cf6);
    });

    test("priv versions", () {
      expect(priv(false, DerivePathType.bip84), 0x04b2430c);
      expect(priv(false, DerivePathType.bip49), 0x049d7878);
      expect(priv(true, DerivePathType.bip49), 0x044a4e28);
      expect(priv(true, DerivePathType.bip84), 0x045f18bc);
    });

    test("inverse: unambiguous prefixes map to path type", () {
      expect(inv(0x049d7cb2), DerivePathType.bip49);
      expect(inv(0x04b24746), DerivePathType.bip84);
      expect(inv(0x044a5262, testnet: true), DerivePathType.bip49);
      expect(inv(0x045f1cf6, testnet: true), DerivePathType.bip84);
    });

    test("inverse: ambiguous xpub/tpub returns null", () {
      expect(inv(0x0488b21e), isNull);
      expect(inv(0x043587cf, testnet: true), isNull);
    });

    test("inverse: litecoin legacy accepted only when enabled", () {
      expect(inv(Slip132.ltub), isNull);
      expect(inv(Slip132.ltub, ltc: true), DerivePathType.bip44);
      expect(inv(Slip132.mtub, ltc: true), DerivePathType.bip49);
      expect(inv(Slip132.ttub, testnet: true, ltc: true), DerivePathType.bip44);
    });

    test("humanPubPrefix", () {
      expect(Slip132.humanPubPrefix(0x0488b21e), "xpub");
      expect(Slip132.humanPubPrefix(0x049d7cb2), "ypub");
      expect(Slip132.humanPubPrefix(0x04b24746), "zpub");
      expect(Slip132.humanPubPrefix(0x045f1cf6), "vpub");
      // Unknown/non-SLIP-0132 prefix (Dogecoin dgub) -> null, not "xpub".
      expect(Slip132.humanPubPrefix(0x02facafd), isNull);
    });
  });

  group("Bitcoin currency SLIP-132 overrides", () {
    final btc = Bitcoin(CryptoCurrencyNetwork.main);
    final tbtc = Bitcoin(CryptoCurrencyNetwork.test);

    test("mainnet emits xpub/ypub/zpub per path", () {
      expect(btc.slip132PubVersion(DerivePathType.bip44), 0x0488b21e);
      expect(btc.slip132PubVersion(DerivePathType.bip49), 0x049d7cb2);
      expect(btc.slip132PubVersion(DerivePathType.bip84), 0x04b24746);
      expect(btc.slip132PubVersion(DerivePathType.bip86), 0x0488b21e);
    });

    test("testnet emits tpub/upub/vpub per path", () {
      expect(tbtc.slip132PubVersion(DerivePathType.bip49), 0x044a5262);
      expect(tbtc.slip132PubVersion(DerivePathType.bip84), 0x045f1cf6);
    });

    test("import inverse: zpub -> bip84, xpub ambiguous -> null", () {
      expect(
        btc.derivePathTypeForExtendedKeyVersion(0x04b24746),
        DerivePathType.bip84,
      );
      expect(btc.derivePathTypeForExtendedKeyVersion(0x0488b21e), isNull);
    });

    test("does not accept litecoin legacy Ltub", () {
      expect(btc.derivePathTypeForExtendedKeyVersion(Slip132.ltub), isNull);
    });
  });

  group("Litecoin currency SLIP-132 overrides", () {
    final ltc = Litecoin(CryptoCurrencyNetwork.main);

    test("emits Bitcoin-style zpub/ypub for segwit", () {
      expect(ltc.slip132PubVersion(DerivePathType.bip84), 0x04b24746);
      expect(ltc.slip132PubVersion(DerivePathType.bip49), 0x049d7cb2);
    });

    test("accepts legacy Ltub/Mtub and Bitcoin-style zpub on import", () {
      expect(
        ltc.derivePathTypeForExtendedKeyVersion(Slip132.ltub),
        DerivePathType.bip44,
      );
      expect(
        ltc.derivePathTypeForExtendedKeyVersion(Slip132.mtub),
        DerivePathType.bip49,
      );
      expect(
        ltc.derivePathTypeForExtendedKeyVersion(0x04b24746),
        DerivePathType.bip84,
      );
    });
  });

  group("Bip39HDCurrency.extendedKeyVersion", () {
    test("reads version bytes from serialized keys", () {
      expect(Bip39HDCurrency.extendedKeyVersion(_zpub), 0x04b24746);
      expect(Bip39HDCurrency.extendedKeyVersion(_xpub), 0x0488b21e);
      expect(Bip39HDCurrency.extendedKeyVersion(_ypub), 0x049d7cb2);
    });

    test("tolerates surrounding whitespace", () {
      expect(Bip39HDCurrency.extendedKeyVersion("  $_zpub  "), 0x04b24746);
    });

    test("returns null for non-base58 / empty input", () {
      expect(Bip39HDCurrency.extendedKeyVersion("not a key"), isNull);
      expect(Bip39HDCurrency.extendedKeyVersion(""), isNull);
    });
  });

  group("coinlib lossless version swap (real BIP-0084 vector)", () {
    setUpAll(() => loadCoinlib());

    test("xpub re-encoded with SLIP-132 bytes yields zpub/ypub", () {
      final node = HDPublicKey.decode(_xpub);
      expect(node.encode(Slip132.zpub), _zpub);
      expect(node.encode(Slip132.ypub), _ypub);
      expect(node.encode(Slip132.xpub), _xpub);
    });

    test("zpub decodes despite non-xpub version and swaps back", () {
      // decode() ignores version bytes when none is passed, so a zpub parses.
      final node = HDPublicKey.decode(_zpub);
      expect(node.encode(Slip132.xpub), _xpub);
    });
  });
}
