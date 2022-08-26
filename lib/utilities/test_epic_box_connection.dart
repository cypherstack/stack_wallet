import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stackwallet/utilities/logger.dart';

Future<bool> testEpicBoxNodeConnection(Uri uri) async {
  try {
    final client = http.Client();
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(milliseconds: 1200),
        onTimeout: () async => http.Response('Error', 408));

    final json = jsonDecode(response.body);

    if (response.statusCode == 200 && json["node_version"] != null) {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e\n$s", level: LogLevel.Warning);
    return false;
  }
}
