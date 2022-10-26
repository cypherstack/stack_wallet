import 'dart:convert';

import 'package:bitcoindart/bitcoindart.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_libepiccash/epic_cash.dart';
import 'package:stackwallet/services/coins/bitcoincash/bitcoincash_wallet.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/namecoin/namecoin_wallet.dart';
import 'package:stackwallet/services/coins/particl/particl_wallet.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';

class AddressUtils {
  static String condenseAddress(String address) {
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  /// attempts to convert a string to a valid scripthash
  ///
  /// Returns the scripthash or throws an exception on invalid firo address
  static String convertToScriptHash(String address, NetworkType network) {
    try {
      final output = Address.addressToOutputScript(address, network);
      final hash = sha256.convert(output.toList(growable: false)).toString();

      final chars = hash.split("");
      final reversedPairs = <String>[];
      // TODO find a better/faster way to do this?
      var i = chars.length - 1;
      while (i > 0) {
        reversedPairs.add(chars[i - 1]);
        reversedPairs.add(chars[i]);
        i -= 2;
      }
      return reversedPairs.join("");
    } catch (e) {
      rethrow;
    }
  }

  static bool validateAddress(String address, Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
        return Address.validateAddress(address, bitcoin);
      case Coin.bitcoincash:
        return Address.validateAddress(address, bitcoincash);
      case Coin.dogecoin:
        return Address.validateAddress(address, dogecoin);
      case Coin.epicCash:
        return validateSendAddress(address) == "1";
      case Coin.firo:
        return Address.validateAddress(address, firoNetwork);
      case Coin.monero:
        return RegExp("[a-zA-Z0-9]{95}").hasMatch(address) ||
            RegExp("[a-zA-Z0-9]{106}").hasMatch(address);
      case Coin.wownero:
        return RegExp("[a-zA-Z0-9]{95}").hasMatch(address) ||
            RegExp("[a-zA-Z0-9]{106}").hasMatch(address);
      case Coin.namecoin:
        return Address.validateAddress(address, namecoin, namecoin.bech32!);
      case Coin.particl:
        return Address.validateAddress(address, particl);
      case Coin.bitcoinTestNet:
        return Address.validateAddress(address, testnet);
      case Coin.bitcoincashTestnet:
        return Address.validateAddress(address, bitcoincashtestnet);
      case Coin.firoTestNet:
        return Address.validateAddress(address, firoTestNetwork);
      case Coin.dogecoinTestNet:
        return Address.validateAddress(address, dogecointestnet);
    }
  }

  /// parse an address uri
  /// returns an empty map if the input string does not begin with "firo:"
  static Map<String, String> parseUri(String uri) {
    Map<String, String> result = {};
    try {
      final u = Uri.parse(uri);
      if (u.hasScheme) {
        result["scheme"] = u.scheme.toLowerCase();
        result["address"] = u.path;
        result.addAll(u.queryParameters);
      }
    } catch (e) {
      Logging.instance
          .log("Exception caught in parseUri($uri): $e", level: LogLevel.Error);
    }
    return result;
  }

  /// builds a uri string with the given address and query parameters if any
  static String buildUriString(
    Coin coin,
    String address,
    Map<String, String> params,
  ) {
    String uriString = "${coin.uriScheme}:$address";
    if (params.isNotEmpty) {
      uriString += Uri(queryParameters: params).toString();
    }
    return uriString;
  }

  /// returns empty if bad data
  static Map<String, dynamic> decodeQRSeedData(String data) {
    Map<String, dynamic> result = {};
    try {
      result = Map<String, dynamic>.from(jsonDecode(data) as Map);
    } catch (e) {
      Logging.instance.log("Exception caught in parseQRSeedData($data): $e",
          level: LogLevel.Error);
    }
    return result;
  }

  /// encode mnemonic words to qrcode formatted string
  static String encodeQRSeedData(List<String> words) {
    return jsonEncode({"mnemonic": words});
  }
}
