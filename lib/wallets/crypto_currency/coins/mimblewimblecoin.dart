import 'package:flutter_libmwc/lib.dart' as mimblewimblecoin;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/mwc_transaction_method.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Mimblewimblecoin extends Bip39Currency {
  Mimblewimblecoin(super.network) {
    _idMain = "mimblewimblecoin";
    _uriScheme = "mimblewimblecoin"; // ?
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _id = _idMain;
        _name = "MimbleWimbleCoin";
        _ticker = "MWC";
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
  String get genesisHash {
    return "not used in mimblewimblecoin";
  }

  @override
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 3;

  @override
  bool validateAddress(String address) {
    // Check if it's a slatepack first.
    if (isSlatepack(address)) {
      return true;
    }

    // Check URI schemes (HTTP, HTTPS, MWCMQS).
    final Uri? uri = Uri.tryParse(address);
    if (uri != null &&
        (uri.scheme == "http" ||
            uri.scheme == "https" ||
            uri.scheme == "mwcmqs") &&
        uri.host.isNotEmpty) {
      return true;
    }

    // Use libmwc for other address validation.
    return mimblewimblecoin.Libmwc.validateSendAddress(address: address);
  }

  /// Check if data is a slatepack.
  bool isSlatepack(String data) {
    return data.trim().startsWith('BEGINSLATE') &&
        (data.trim().endsWith('ENDSLATEPACK') ||
            data.trim().endsWith('ENDSLATEPACK.') ||
            data.trim().endsWith('ENDSLATE_BIN') ||
            data.trim().endsWith('ENDSLATE_BIN.'));
  }

  /// Check if address is MWCMQS format.
  bool isMwcmqsAddress(String address) {
    return address.startsWith('mwcmqs://');
  }

  /// Check if address is HTTP format.
  bool isHttpAddress(String address) {
    return address.startsWith('http://') || address.startsWith('https://');
  }

  /// Detect transaction type based on address/data format.
  TransactionMethod getTransactionMethod(String addressOrData) {
    if (isSlatepack(addressOrData)) {
      return TransactionMethod.slatepack;
    } else if (isMwcmqsAddress(addressOrData)) {
      return TransactionMethod.mwcmqs;
    } else if (isHttpAddress(addressOrData)) {
      return TransactionMethod.http;
    } else {
      return TransactionMethod.unknown;
    }
  }

  /// Validate slatepack format.
  bool validateSlatepack(String slatepack) {
    try {
      final trimmed = slatepack.trim();
      if (!isSlatepack(trimmed)) {
        return false;
      }

      // Basic structure validation.
      final lines = trimmed.split('\n');
      if (lines.length < 3) {
        return false;
      }

      // Should have header, content, and footer.
      return lines.first.startsWith('BEGINSLATEPACK.') &&
          lines.last.endsWith('.ENDSLATEPACK') &&
          lines.length > 2;
    } catch (e) {
      return false;
    }
  }

  /// Get expected slatepack type from content (S1, S2, S3).
  String? getSlatepackType(String slatepack) {
    if (!validateSlatepack(slatepack)) {
      return null;
    }

    try {
      // This is a simplified approach - in reality you'd need to decode
      // the slatepack content to determine the exact type.
      final lines = slatepack.trim().split('\n');
      final header = lines.first;

      // Basic heuristic based on header format.
      if (header.contains('BEGINSLATEPACK.')) {
        return 'unknown'; // Would need proper decoding to determine S1/S2/S3.
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  NodeModel defaultNode({required bool isPrimary}) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return NodeModel(
          host: "https://mwc713.mwc.mw",
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
          isPrimary: true,
        );

      default:
        throw UnimplementedError();
    }
  }

  @override
  int get defaultSeedPhraseLength => 12;

  @override
  int get fractionDigits => 9;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 24];

  @override
  AddressType get defaultAddressType => AddressType.mimbleWimble;

  @override
  BigInt get satsPerCoin => BigInt.from(1000000000);

  @override
  int get targetBlockTimeSeconds => 60;

  @override
  DerivePathType get defaultDerivePathType =>
      throw UnsupportedError(
        "$runtimeType does not use bitcoin style derivation paths",
      );

  @override
  Uri defaultBlockExplorer(String txid) {
    switch (network) {
      default:
        throw Exception(
          "Unsupported network for defaultBlockExplorer(): $network",
        );
    }
  }

  @override
  AddressType? getAddressType(String address) {
    return AddressType.mimbleWimble;
  }
}
