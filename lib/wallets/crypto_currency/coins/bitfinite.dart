import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter/foundation.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/bfx_cashaddr.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

/// BitFinite (BFX) — a Bitcoin Cash Node (BCHN) fork.
///
/// Ground-truth params (bitfinite-core/src/chainparams.cpp):
///   cashaddr prefix : "bfx" (mainnet) / "bfxtest" (testnet)
///   base58 p2pkh    : 0   (== BCH)  |  p2sh: 5  |  WIF: 128
///   xpub/xprv       : 0x0488B21E / 0x0488ADE4  (== BCH)
///   SLIP-44 coinType: 9116  (web-wallet default m/44'/9116'/0')  [alt "bitcoin.com" = 0]
///   genesis (main)  : 000000000900096d5b0f4a3489f919362f12fce06524e15074c3cd3c19aeabea
///
/// The address-layer differences from BCH are (1) the cashaddr prefix "bfx" and
/// (2) a custom base32 alphabet with `q` and `f` swapped (see BfxCashAddr /
/// bitfinite-core cashaddr.cpp CHARSET). P2PKH is still type 0, so BFX addresses
/// render as "bfx:f..." (version byte 0 -> charset[0] = 'f'). Because of the
/// custom alphabet we route ALL BFX cashaddr encode/decode through BfxCashAddr,
/// NOT the stock bitbox/coinlib cashaddr code (which uses the standard alphabet
/// and would fail the checksum on "bfx:" strings).
class Bitfinite extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Bitfinite(super.network) {
    _idMain = "bitfinite";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "BitFinite";
        _ticker = "BFX";
        _uriScheme = "bfx";
      case CryptoCurrencyNetwork.test:
        _id = "bitfiniteTestnet";
        _name = "tBitFinite";
        _ticker = "tBFX";
        _uriScheme = "bfxtest";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  late final String _id;
  @override
  String get identifier => _id;

  late final String _idMain;
  @override
  String get mainNetId => _idMain;

  late final String _name;
  @override
  String get prettyName => _name;

  late final String _uriScheme;
  @override
  String get uriScheme => _uriScheme;

  late final String _ticker;
  @override
  String get ticker => _ticker;

  @override
  int get maxUnusedAddressGap => 50;

  @override
  int get minConfirms => 0; // BCH-style zeroconf

  /// COINBASE_MATURITY from our own consensus header, not an assumption.
  /// Stated here rather than left to the default because this is the one
  /// chain we control, so it is the one where "we checked" should be on the
  /// record. Zeroconf above is about payments; a block reward is a consensus
  /// rule and the node will refuse a spend before 100.
  @override
  int get minCoinbaseConfirms => 100;

  @override
  bool get torSupport => true;

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
    DerivePathType.bip44,
  ];

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000900096d5b0f4a3489f919362f12fce06524e15074c3cd3c19aeabea";
      case CryptoCurrencyNetwork.test:
        // TODO: fill in from chainparams.cpp testnet genesis before enabling testnet.
        throw UnimplementedError("BFX testnet genesis hash not yet wired");
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit =>
      Amount(rawValue: BigInt.from(546), fractionDigits: fractionDigits);

  @override
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        // Byte-identical to BCH mainnet (verified against chainparams.cpp).
        return coinlib.Network(
          wifPrefix: 0x80,
          p2pkhPrefix: 0x00,
          p2shPrefix: 0x05,
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "bc", // vestigial (BFX uses cashaddr, not bech32)
          messagePrefix: '\x18Bitcoin Signed Message:\n',
          minFee: BigInt.from(1),
          minOutput: dustLimit.raw,
          feePerKb: BigInt.from(1),
        );
      case CryptoCurrencyNetwork.test:
        return coinlib.Network(
          wifPrefix: 0xef,
          p2pkhPrefix: 0x6f,
          p2shPrefix: 0xc4,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tb",
          messagePrefix: "\x18Bitcoin Signed Message:\n",
          minFee: BigInt.from(1),
          minOutput: dustLimit.raw,
          feePerKb: BigInt.from(1),
        );
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  String addressToScriptHash({required String address}) {
    try {
      if (BfxCashAddr.isValid(address)) {
        final decoded = BfxCashAddr.decode(address);
        // Build the standard scriptPubKey from the hash160 (the cashaddr alphabet
        // only affects the string form, not the underlying script).
        final Uint8List script;
        if (decoded.type == BfxCashAddr.typeP2SH) {
          // OP_HASH160 <20> OP_EQUAL
          script = Uint8List.fromList([0xa9, 0x14, ...decoded.hash160, 0x87]);
        } else {
          // P2PKH: OP_DUP OP_HASH160 <20> OP_EQUALVERIFY OP_CHECKSIG
          script = Uint8List.fromList(
            [0x76, 0xa9, 0x14, ...decoded.hash160, 0x88, 0xac],
          );
        }
        return Bip39HDCurrency.convertBytesToScriptHash(script);
      }

      // Legacy base58 (starts with "1"/"3") — still valid, coinlib handles it.
      final addr = coinlib.Address.fromString(address, networkParams);
      return Bip39HDCurrency.convertBytesToScriptHash(
        addr.program.script.compiled,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    String coinType;

    switch (networkParams.wifPrefix) {
      case 0x80:
        switch (derivePathType) {
          case DerivePathType.bip44:
            coinType = "9116"; // BFX mainnet (SLIP-44) — web-wallet default
            break;
          default:
            throw Exception(
              "DerivePathType $derivePathType not supported for coinType",
            );
        }
        break;
      case 0xef:
        coinType = "1"; // testnet
        break;
      default:
        throw Exception("Invalid BitFinite network wif used!");
    }

    final int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
        purpose = 44;
        break;
      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }

    return "m/$purpose'/$coinType'/$account'/$chain/$index";
  }

  @override
  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  }) {
    switch (derivePathType) {
      case DerivePathType.bip44:
        final addr = coinlib.P2PKHAddress.fromPublicKey(
          publicKey,
          version: networkParams.p2pkhPrefix,
        );
        return (address: addr, addressType: AddressType.p2pkh);
      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }
  }

  @override
  bool validateAddress(String address) {
    try {
      if (network.isTestNet) {
        return true;
      }
      // BFX cashaddr (checksum-validated under the BFX alphabet), or legacy base58.
      if (BfxCashAddr.isValid(address)) {
        return true;
      }
      return address.startsWith("1") || address.startsWith("3");
    } catch (e) {
      return false;
    }
  }

  @override
  AddressType? getAddressType(String address) {
    if (BfxCashAddr.isValid(address)) {
      final decoded = BfxCashAddr.decode(address);
      return decoded.type == BfxCashAddr.typeP2SH
          ? AddressType.p2sh
          : AddressType.p2pkh;
    }
    return super.getAddressType(address);
  }

  @override
  DerivePathType addressType({required String address}) {
    if (BfxCashAddr.isValid(address)) {
      final decoded = BfxCashAddr.decode(address);
      if (decoded.type == BfxCashAddr.typeP2PKH) return DerivePathType.bip44;
      if (decoded.type == BfxCashAddr.typeP2SH) return DerivePathType.bip49;
      throw ArgumentError('$address unsupported cashaddr type');
    }
    // Legacy base58.
    final decodeBase58 = bs58check.decode(address);
    if (decodeBase58[0] == networkParams.p2pkhPrefix) return DerivePathType.bip44;
    if (decodeBase58[0] == networkParams.p2shPrefix) return DerivePathType.bip49;
    throw ArgumentError('$address has no matching Script');
  }

  @override
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        // Raw ElectrumX TCP/SSL on the carrier-safe port 443 (mobile carriers
        // block :50002). nginx `stream` + `ssl_preread` on 443 routes
        // electr.bitfinitechain.org -> electrs, other SNI -> web vhosts.
        // (:50002 still works on networks that allow it.)
        return NodeModel(
          host: "electr.bitfinitechain.org",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
          torEnabled: true,
          clearnetEnabled: true,
          isPrimary: isPrimary,
        );
      case CryptoCurrencyNetwork.test:
        throw UnimplementedError();
      default:
        throw UnimplementedError();
    }
  }

  @override
  List<NodeModel> get additionalDefaultNodes =>
      network == CryptoCurrencyNetwork.main
          ? [
            // Secondary public Electrum server (raw ElectrumX SSL on the
            // carrier-safe port 443). isFailover:true → ElectrumXClient moves
            // here when a request to the primary fails, and stays here for
            // subsequent requests rather than retrying the primary each time.
            NodeModel(
              host: "electrum2.bitfinitechain.org",
              port: 443,
              name: "BitFinite Electrum 2",
              id: "${DefaultNodes.defaultNodeIdPrefix}${identifier}_electrum2",
              useSSL: true,
              enabled: true,
              coinName: identifier,
              isFailover: true,
              isDown: false,
              torEnabled: true,
              clearnetEnabled: true,
              isPrimary: false,
            ),
          ]
          : const [];

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 8;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get defaultAddressType => defaultDerivePathType.getAddressType();

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 300; // 5-min blocks

  @override
  DerivePathType get defaultDerivePathType => DerivePathType.bip44;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://explorer.bitfinitechain.org/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 2;

  @override
  // sats/kB. BFX electrum servers don't implement `estimatefee` (JSON-RPC
  // "Method not found"), so the wallet always falls back to this default. At
  // exactly 1000 (1 sat/vByte) coinlib's ~1-byte size underestimate per input
  // leaves the fee 1 sat below vSize, and prepareSend rejects it
  // ("Transaction fee cannot be less than vSize"). 1200 (1.2 sat/vByte) keeps a
  // margin above the 1 sat/vByte floor while staying negligibly cheap on BFX.
  BigInt get defaultFeeRate => BigInt.from(1200);

  /// Brand blue-700 #2258E6, so BFX keeps its identity under EXTERNAL themes.
  ///
  /// The bundled light/dark themes still win via colors.coin (blue-600 light,
  /// blue-700 dark) — this is only the fallback the five external themes hit.
  /// Without it, pCoinColor fell through to the theme's own primary and BFX
  /// wallets wore Forest teal or OceanBreeze blue while Pepecoin and
  /// Bellscoin kept their published colours: the one coin that IS the product
  /// was the only one losing its face. Blue-700 rather than blue-600 because
  /// it is the step measured to pass both sides (5.82:1 under white ink,
  /// 3.14:1 against the dark page) — the same reason the dark theme uses it.
  @override
  int get brandColorValue => 0xFF2258E6;
}
