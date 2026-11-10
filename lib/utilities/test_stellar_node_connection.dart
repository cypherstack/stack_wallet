import 'dart:convert';
import 'dart:io';

import 'package:socks5_proxy/socks.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../app_config.dart';
import '../networking/http.dart' as http;
import '../services/tor_service.dart';
import 'prefs.dart';

Future<bool> testStellarNodeConnection(String host, int port) async {
  final http.HTTP client = http.HTTP();
  final Uri uri = Uri.parse("$host:$port");

  final response = await client
      .get(
        url: uri,
        headers: {'Content-Type': 'application/json'},
        proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
            ? null
            : Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      )
      .timeout(
        const Duration(milliseconds: 2000),
        onTimeout: () async => http.Response(utf8.encode('Error'), 408),
      );

  if (response.code == 200) {
    //Get chain height for sdk
    HttpClient? httpClient;
    if (AppConfig.hasFeature(AppFeature.tor) && Prefs.instance.useTor) {
      final proxyInfo = TorService.sharedInstance.getProxyInfo();
      httpClient = HttpClient();
      SocksTCPClient.assignToHttpClient(httpClient, [
        ProxySettings(proxyInfo.host, proxyInfo.port),
      ]);
    }
    final StellarSDK stellarSdk = StellarSDK(host, httpClient: httpClient);
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
