import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';

final pMonKeyService = Provider((ref) => MonKeyService());

class MonKeyService {
  static const baseURL = "https://monkey.banano.cc/api/v1/monkey/";
  HTTP client = HTTP();

  Future<Uint8List> fetchMonKey({
    required String address,
    bool png = false,
  }) async {
    try {
      String url = "https://monkey.banano.cc/api/v1/monkey/$address";

      if (png) {
        url += '?format=png&size=512&background=false';
      }

      final response = await client.get(
        url: Uri.parse(url),
        proxyInfo:
            Prefs.instance.useTor ? TorService.sharedInstance.proxyInfo : null,
      );

      if (response.code == 200) {
        return Uint8List.fromList(response.bodyBytes);
      } else {
        throw Exception(
          "statusCode=${response.code} body=${response.body}",
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "Failed fetchMonKey($address): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }
}
