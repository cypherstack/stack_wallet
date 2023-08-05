import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/utilities/logger.dart';

final pMonKeyService = Provider((ref) => MonKeyService());

class MonKeyService {
  static const baseURL = "https://monkey.banano.cc/api/v1/monkey/";

  Future<Uint8List> fetchMonKey({
    required String address,
    bool png = false,
  }) async {
    try {
      String url = "https://monkey.banano.cc/api/v1/monkey/$address";

      if (png) {
        url += '?format=png&size=512&background=false';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
          "statusCode=${response.statusCode} body=${response.body}",
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
