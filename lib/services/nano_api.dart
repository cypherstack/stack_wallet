import 'dart:convert';

import 'package:nanodart/nanodart.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/prefs.dart';

class NanoAPI {
  static Future<
      ({
        NAccountInfo? accountInfo,
        Exception? exception,
      })> getAccountInfo({
    required Uri server,
    required bool representative,
    required String account,
  }) async {
    NAccountInfo? accountInfo;
    Exception? exception;

    HTTP client = HTTP();

    try {
      final response = await client.post(
        url: server,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "action": "account_info",
          "representative": "true",
          "account": account,
        }),
        proxyInfo:
            Prefs.instance.useTor ? TorService.sharedInstance.proxyInfo : null,
      );

      final map = jsonDecode(response.body);

      if (map is Map && map["error"] != null) {
        throw Exception(map["error"].toString());
      }

      accountInfo = NAccountInfo(
        frontier: map["frontier"] as String,
        representative: map["representative"] as String,
      );
    } on Exception catch (e) {
      exception = e;
    } catch (e) {
      exception = Exception(e.toString());
    }

    return (accountInfo: accountInfo, exception: exception);
  }

  static Future<bool> changeRepresentative({
    required Uri server,
    required int accountType,
    required String account,
    required String newRepresentative,
    required String previousBlock,
    required String balance,
    required String privateKey,
    required String work,
  }) async {
    Map<String, String> block = {
      "type": "state",
      "account": account,
      "previous": previousBlock,
      "representative": newRepresentative,
      "balance": balance,
      "link":
          "0000000000000000000000000000000000000000000000000000000000000000",
      "work": work,
    };

    final String hash;

    try {
      hash = NanoBlocks.computeStateHash(
        accountType,
        account,
        previousBlock,
        newRepresentative,
        BigInt.parse(balance),
        block["link"] as String,
      );
    } catch (e) {
      if (e is RangeError) {
        throw Exception("Invalid representative format");
      }
      rethrow;
    }

    final signature = NanoSignatures.signBlock(hash, privateKey);

    block["signature"] = signature;

    final map = await postBlock(server: server, block: block);

    if (map is Map && map["error"] != null) {
      throw Exception(map["error"].toString());
    }

    return map["error"] == null;
  }

  // TODO: GET RID OF DYNAMIC AND USED TYPED DATA
  static Future<dynamic> postBlock({
    required Uri server,
    required Map<String, dynamic> block,
  }) async {
    HTTP client = HTTP();

    final response = await client.post(
      url: server,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "action": "process",
        "json_block": "true",
        "subtype": "change",
        "block": block,
      }),
      proxyInfo:
          Prefs.instance.useTor ? TorService.sharedInstance.proxyInfo : null,
    );

    return jsonDecode(response.body);
  }
}

class NAccountInfo {
  final String frontier;
  final String representative;

  NAccountInfo({required this.frontier, required this.representative});
}
