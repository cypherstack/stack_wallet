import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<bool> testStellarNodeConnection(String host) async {

  final client = http.Client();
  Uri uri = Uri.parse(host);
  final response = await client.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  ).timeout(const Duration(milliseconds: 2000),
      onTimeout: () async => http.Response('Error', 408));

  if (response.statusCode == 200) {
    //Get chain height for sdk
    StellarSDK stellarSdk = StellarSDK(host);
    final height = await stellarSdk.ledgers
        .order(RequestBuilderOrder.DESC)
        .limit(1)
        .execute()
        .then((value) => value.records!.first.sequence)
        .onError((error, stackTrace) => throw ("Error getting chain height"));

    if (height > 0) {
        return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}