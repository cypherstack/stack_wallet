import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as cl;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_hd_currency.dart';
import '../intermediate/frost_currency.dart';

class BitcoinFrost extends FrostCurrency {
  BitcoinFrost(super.network) {
    _idMain = "bitcoinFrost";
    _uriScheme = "bitcoin";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Bitcoin Frost";
        _ticker = "BTC";
      case CryptoCurrencyNetwork.test:
        _id = "bitcoinFrostTestNet";
        _name = "tBitcoin Frost";
        _ticker = "tBTC";
      case CryptoCurrencyNetwork.test4:
        _id = "bitcoinFrostTestNet4";
        _name = "t4Bitcoin Frost";
        _ticker = "t4BTC";
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
  int get minConfirms => 1;

  @override
  bool get torSupport => true;

  @override
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "bitcoin.stackwallet.com",
          port: 50002,
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
        return NodeModel(
          host: "bitcoin-testnet.stackwallet.com",
          port: 51002,
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

      case CryptoCurrencyNetwork.test4:
        return NodeModel(
          host: "bitcoin-testnet4.stackwallet.com",
          port: 50002,
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

      default:
        throw UnimplementedError();
    }
  }

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
      case CryptoCurrencyNetwork.test:
        return "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943";
      case CryptoCurrencyNetwork.test4:
        return "00000000da84f2bafbbc53dee25a72ae507ff4914b867c565be350b0da8bf043";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit =>
      Amount(rawValue: BigInt.from(294), fractionDigits: fractionDigits);

  @override
  Uint8List addressToPubkey({required String address}) {
    try {
      final addr = coinlib.Address.fromString(address, networkParams);
      return addr.program.script.compiled;
    } catch (e) {
      rethrow;
    }
  }

  @override
  String addressToScriptHash({required String address}) {
    try {
      return Bip39HDCurrency.convertBytesToScriptHash(
        addressToPubkey(address: address),
      );
    } catch (e) {
      rethrow;
    }
  }

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
      case CryptoCurrencyNetwork.test4:
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
  bool validateAddress(String address) {
    try {
      coinlib.Address.fromString(address, networkParams);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  int get defaultSeedPhraseLength => 0;

  @override
  int get fractionDigits => 8;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [];

  @override
  AddressType get defaultAddressType => AddressType.frostMS;

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 600;

  @override
  DerivePathType get defaultDerivePathType =>
      throw UnsupportedError(
        "$runtimeType does not use bitcoin style derivation paths",
      );

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://mempool.space/tx/$txid");
      case CryptoCurrencyNetwork.test:
        return Uri.parse("https://mempool.space/testnet/tx/$txid");
      case CryptoCurrencyNetwork.test4:
        return Uri.parse("https://mempool.space/testnet4/tx/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  // @override
  BigInt get defaultFeeRate => BigInt.from(1000);
  // https://github.com/bitcoin/bitcoin/blob/feab35189bc00bc4cf15e9dcb5cf6b34ff3a1e91/test/functional/mempool_limit.py#L259

  @override
  AddressType? getAddressType(String address) {
    try {
      final clAddress = cl.Address.fromString(address, networkParams);

      return switch (clAddress) {
        cl.P2PKHAddress() => AddressType.p2pkh,
        cl.P2WSHAddress() => AddressType.p2sh,
        cl.P2WPKHAddress() => AddressType.p2wpkh,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}
