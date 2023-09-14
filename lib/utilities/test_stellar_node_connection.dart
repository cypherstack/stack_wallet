import 'dart:convert';

import 'package:stackwallet/networking/http.dart' as http;
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<bool> testStellarNodeConnection(String host, int port) async {
  http.HTTP client = http.HTTP();
  Uri uri = Uri.parse("$host:$port");

  final response = await client
      .get(
        url: uri,
        headers: {'Content-Type': 'application/json'},
        proxyInfo:
            Prefs.instance.useTor ? TorService.sharedInstance.proxyInfo : null,
      )
      .timeout(const Duration(milliseconds: 2000),
          onTimeout: () async => http.Response(utf8.encode('Error'), 408));

  if (response.code == 200) {
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
