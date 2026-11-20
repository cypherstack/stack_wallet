import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/exchange/chainflip/chainflip_api.dart';
import 'package:stackwallet/services/exchange/chainflip/chainflip_exchange.dart';

class _RecordingHttp extends HTTP {
  final requests = <(Uri, ({InternetAddress host, int port})?)>[];

  @override
  Future<Response> get({
    required Uri url,
    Map<String, String>? headers,
    required ({InternetAddress host, int port})? proxyInfo,
    Duration? connectionTimeout,
  }) async {
    requests.add((url, proxyInfo));
    return Response(
      utf8.encode(
        jsonEncode(<String, dynamic>{
          "assets": <Map<String, dynamic>>[
            <String, dynamic>{
              "id": "btc.btc",
              "ticker": "BTC",
              "name": "Bitcoin",
              "network": "Bitcoin",
              "assetLogo": "/assets/btc.btc/logo.svg",
              "networkLogo": "/networks/btc/logo.svg",
              "decimals": 8,
              "enabled": true,
              "direction": "both",
              "minimalAmountNative": "40000",
            },
          ],
        }),
      ),
      200,
    );
  }
}

void main() {
  final proxy = (host: InternetAddress.loopbackIPv4, port: 9050);

  tearDown(() {
    ChainflipApi.useTorOverride = null;
  });

  test("uses the onion through the Tor proxy only in Tor mode", () async {
    final http = _RecordingHttp();
    ChainflipApi.client = http;
    ChainflipApi.torProxyInfo = () => proxy;

    ChainflipApi.useTorOverride = true;
    final tor = await ChainflipExchange.forTesting().getAllCurrencies(false);
    expect(http.requests.last.$1.scheme, "http");
    expect(
      http.requests.last.$1.host,
      "chainflip37gkyf3nkgufkolp2grpbchoysvro57wz3d3kurhhyj4zad.onion",
    );
    expect(http.requests.last.$2, proxy);
    // Cached logo URLs must keep working after Tor is switched off.
    expect(
      tor.value!.single.image,
      "https://chainflip-broker.io/assets/btc.btc/logo.svg",
    );

    ChainflipApi.useTorOverride = false;
    await ChainflipExchange.forTesting().getAllCurrencies(false);
    expect(http.requests.last.$1.scheme, "https");
    expect(http.requests.last.$1.host, "chainflip-broker.io");
    expect(http.requests.last.$2, isNull);
  });
}
