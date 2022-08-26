import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stackwallet/utilities/logger.dart';

Future<bool> testMoneroNodeConnection(Uri uri) async {
  try {
    final client = http.Client();
    final response = await client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"jsonrpc": "2.0", "id": "0", "method": "get_info"}),
        )
        .timeout(const Duration(milliseconds: 1200),
            onTimeout: () async => http.Response('Error', 408));

    final result = jsonDecode(response.body);
    // TODO: json decoded without error so assume connection exists?
    // or we can check for certain values in the response to decide
    return true;
  } catch (e, s) {
    Logging.instance.log("$e\n$s", level: LogLevel.Warning);
    return false;
  }
}
