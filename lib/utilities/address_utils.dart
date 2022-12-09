import 'dart:convert';

import 'package:bitcoindart/bitcoindart.dart';
import 'package:crypto/crypto.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/logger.dart';
import 'package:flutter_libepiccash/epic_cash.dart';

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
      case Coin.epicCash:
        return validateSendAddress(address) == "1";
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
