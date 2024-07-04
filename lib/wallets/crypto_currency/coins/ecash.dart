import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

class Ecash extends Bip39HDCurrency with ElectrumXCurrencyInterface {
  Ecash(super.network) {
    _idMain = "eCash";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "eCash";
        _ticker = "XEC";
        _uriScheme = "ecash";
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
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 0; // bch zeroconf

  @override
  bool get torSupport => true;

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        DerivePathType.eCash44,
        DerivePathType.bip44,
      ];

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
      case CryptoCurrencyNetwork.test:
        return "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(546),
        fractionDigits: fractionDigits,
      );

  @override
  coinlib.Network get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return coinlib.Network(
          wifPrefix: 0x80,
          p2pkhPrefix: 0x00,
          p2shPrefix: 0x05,
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "bc",
          messagePrefix: '\x18Bitcoin Signed Message:\n',
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
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
          minFee: BigInt.from(1), // Not used in stack wallet currently
          minOutput: dustLimit.raw, // Not used in stack wallet currently
          feePerKb: BigInt.from(1), // Not used in stack wallet currently
        );
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  String addressToScriptHash({required String address}) {
    try {
      if (bitbox.Address.detectFormat(address) ==
              bitbox.Address.formatCashAddr &&
          _validateCashAddr(address)) {
        address = bitbox.Address.toLegacyAddress(address);
      }

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
      case 0x80: //   mainnet wif
        switch (derivePathType) {
          case DerivePathType.bip44:
            coinType = "145";
            break;
          case DerivePathType.eCash44:
            coinType = "899";
            break;
          default:
            throw Exception(
              "DerivePathType $derivePathType not supported for coinType",
            );
        }
        break;
      case 0xef: //   testnet wif
        throw Exception(
          "DerivePathType $derivePathType not supported for coinType",
        );
      default:
        throw Exception("Invalid ECash network wif used!");
    }

    int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
      case DerivePathType.eCash44:
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
      case DerivePathType.eCash44:
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
      // 0 for bitcoincash: address scheme, 1 for legacy address
      final format = bitbox.Address.detectFormat(address);

      if (format == bitbox.Address.formatCashAddr) {
        return _validateCashAddr(address);
      } else {
        return address.startsWith("1");
      }
    } catch (e) {
      return false;
    }
  }

  bool _validateCashAddr(String cashAddr) {
    String addr = cashAddr;
    if (cashAddr.contains(":")) {
      addr = cashAddr.split(":").last;
    }

    return addr.startsWith("q") /*|| addr.startsWith("p")*/;
    // Do not validate "p" (P2SH) addresses.
  }

  @override
  DerivePathType addressType({required String address}) {
    Uint8List? decodeBase58;
    Segwit? decodeBech32;
    try {
      if (bitbox.Address.detectFormat(address) ==
          bitbox.Address.formatCashAddr) {
        if (_validateCashAddr(address)) {
          address = bitbox.Address.toLegacyAddress(address);
        } else {
          throw ArgumentError('$address is not currently supported');
        }
      }
    } catch (_) {
      // invalid cash addr format
    }
    try {
      decodeBase58 = bs58check.decode(address);
    } catch (err) {
      // Base58check decode fail
    }
    if (decodeBase58 != null) {
      if (decodeBase58[0] == networkParams.p2pkhPrefix) {
        // P2PKH
        return DerivePathType.bip44;
      }
      if (decodeBase58[0] == networkParams.p2shPrefix) {
        // P2SH
        return DerivePathType.bip49;
      }

      throw ArgumentError('Invalid version or Network mismatch');
    } else {
      try {
        decodeBech32 = segwit.decode(address);
      } catch (err) {
        // Bech32 decode fail
      }

      if (decodeBech32 != null) {
        if (networkParams.bech32Hrp != decodeBech32.hrp) {
          throw ArgumentError('Invalid prefix or Network mismatch');
        }
        if (decodeBech32.version != 0) {
          throw ArgumentError('Invalid address version');
        }
      }
    }
    throw ArgumentError('$address has no matching Script');
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "ecash.stackwallet.com",
          port: 59002,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(this),
          useSSL: true,
          enabled: true,
          coinName: identifier,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 2;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get defaultAddressType => defaultDerivePathType.getAddressType();

  @override
  BigInt get satsPerCoin => BigInt.from(100);

  @override
  int get targetBlockTimeSeconds => 600;

  @override
  DerivePathType get defaultDerivePathType => DerivePathType.eCash44;

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://explorer.e.cash/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  int get transactionVersion => 2;

  @override
  BigInt get defaultFeeRate => BigInt.from(200);
}
