import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib_flutter/coinlib_flutter.dart';
import 'package:tezart/src/crypto/crypto.dart';
import 'package:tezart/tezart.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Tezos extends Bip39Currency {
  Tezos(super.network) {
    _idMain = "tezos";
    _uriScheme = "tezos";
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "Tezos";
        _ticker = "XTZ";
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
  bool get torSupport => true;

  @override
  bool validateAddress(String address) {
    return RegExp(r"^tz[1-9A-HJ-NP-Za-km-z]{34}$").hasMatch(address);
  }

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          // TODO: ?Change this to stack wallet one?
          host: "https://mainnet.api.tez.ie",
          port: 443,
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

  // ===========================================================================
  // =========== Private =======================================================

  static ({Uint8List privateKey, Uint8List chainCode}) _deriveRootNode(
    Uint8List seed,
  ) {
    return _deriveNode(seed, Uint8List.fromList(utf8.encode("ed25519 seed")));
  }

  static ({Uint8List privateKey, Uint8List chainCode}) _deriveNode(
    Uint8List msg,
    Uint8List key,
  ) {
    final hMac = hmacSha512(key, msg);
    final privateKey = hMac.sublist(0, 32);
    final chainCode = hMac.sublist(32);
    return (privateKey: privateKey, chainCode: chainCode);
  }

  static ({Uint8List privateKey, Uint8List chainCode}) _deriveChildNode(
    ({Uint8List privateKey, Uint8List chainCode}) node,
    int index,
  ) {
    final Uint8List indexBuf = Uint8List(4);
    ByteData.view(indexBuf.buffer).setUint32(0, index, Endian.big);

    final Uint8List message = Uint8List.fromList([
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

  @override
  int get defaultSeedPhraseLength => 24;

  @override
  int get fractionDigits => 6;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 12];

  @override
  AddressType get defaultAddressType => AddressType.tezos;

  @override
  BigInt get satsPerCoin => BigInt.from(1000000);

  @override
  int get targetBlockTimeSeconds => 60;

  @override
  DerivePathType get defaultDerivePathType =>
      throw UnsupportedError("Is this even used?");

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return Uri.parse("https://tzstats.com/$txid");
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }
}
