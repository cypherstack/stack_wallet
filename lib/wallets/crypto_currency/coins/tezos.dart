import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib_flutter/coinlib_flutter.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';
import 'package:tezart/src/crypto/crypto.dart';
import 'package:tezart/tezart.dart';

class Tezos extends Bip39Currency {
  Tezos(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.tezos;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  // ===========================================================================
  // =========== Public ========================================================

  static DerivationPath get standardDerivationPath =>
      DerivationPath()..value = "m/44'/1729'/0'/0'";

  static List<DerivationPath> get possibleDerivationPaths => [
        standardDerivationPath,
        DerivationPath()..value = "",
        DerivationPath()..value = "m/44'/1729'/0'/0'/0'",
        DerivationPath()..value = "m/44'/1729'/0'/0/0",
      ];

  static Keystore mnemonicToKeyStore({
    required String mnemonic,
    String mnemonicPassphrase = "",
    String derivationPath = "",
  }) {
    if (derivationPath.isEmpty) {
      return Keystore.fromMnemonic(mnemonic, password: mnemonicPassphrase);
    }

    final pathArray = _derivationPathToArray(derivationPath);
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: mnemonicPassphrase);
    ({Uint8List privateKey, Uint8List chainCode}) node = _deriveRootNode(seed);
    for (final index in pathArray) {
      node = _deriveChildNode(node, index);
    }

    final encoded = encodeWithPrefix(
      prefix: Prefixes.edsk2,
      bytes: node.privateKey,
    );

    return Keystore.fromSeed(encoded);
  }

  // ===========================================================================
  // =========== Overrides =====================================================

  @override
  String get genesisHash => throw UnimplementedError(
        "Not used in tezos at the moment",
      );

  @override
  int get minConfirms => 1;

  @override
  bool validateAddress(String address) {
    return RegExp(r"^tz[1-9A-HJ-NP-Za-km-z]{34}$").hasMatch(address);
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://mainnet.api.tez.ie",
          port: 443,
          name: DefaultNodes.defaultName,
          id: DefaultNodes.buildId(Coin.tezos),
          useSSL: true,
          enabled: true,
          coinName: Coin.tezos.name,
          isFailover: true,
          isDown: false,
        );

      default:
        throw UnimplementedError();
    }
  }

  // ===========================================================================
  // =========== Private =======================================================

  static ({Uint8List privateKey, Uint8List chainCode}) _deriveRootNode(
      Uint8List seed) {
    return _deriveNode(seed, Uint8List.fromList(utf8.encode("ed25519 seed")));
  }

  static ({Uint8List privateKey, Uint8List chainCode}) _deriveNode(
      Uint8List msg, Uint8List key) {
    final hMac = hmacSha512(key, msg);
    final privateKey = hMac.sublist(0, 32);
    final chainCode = hMac.sublist(32);
    return (privateKey: privateKey, chainCode: chainCode);
  }

  static ({Uint8List privateKey, Uint8List chainCode}) _deriveChildNode(
      ({Uint8List privateKey, Uint8List chainCode}) node, int index) {
    Uint8List indexBuf = Uint8List(4);
    ByteData.view(indexBuf.buffer).setUint32(0, index, Endian.big);

    Uint8List message = Uint8List.fromList([
      Uint8List(1)[0],
      ...node.privateKey,
      ...indexBuf,
    ]);

    return _deriveNode(message, Uint8List.fromList(node.chainCode));
  }

  static List<int> _derivationPathToArray(String derivationPath) {
    if (derivationPath.isEmpty) {
      return [];
    }

    derivationPath = derivationPath.replaceAll('m/', '').replaceAll("'", 'h');

    return derivationPath.split('/').map((level) {
      if (level.endsWith("h")) {
        level = level.substring(0, level.length - 1);
      }
      final int levelNumber = int.parse(level);
      if (levelNumber >= 0x80000000) {
        throw ArgumentError('Invalid derivation path. Out of bound.');
      }
      return levelNumber + 0x80000000;
    }).toList();
  }

  // ===========================================================================
}
