import 'dart:convert';

import 'package:http/http.dart' as http;

Future<bool> testStellarNodeConnection(String host) async {

  final client = http.Client();
  Uri uri = Uri.parse(host);
  final response = await client.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  ).timeout(const Duration(milliseconds: 2000),
      onTimeout: () async => http.Response('Error', 408));

  final json = jsonDecode(response.body);

  if (response.statusCode == 200 && json["horizon_version"] != null) {
    return true;
  } else {
    return false;
  }
}