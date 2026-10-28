import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/networking/tor_aware_network_image.dart';

void main() {
  late HttpServer server;
  late List<HttpRequest> requests;

  setUp(() async {
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      requests.add(request);
      request.response.add([1]);
      request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  String url(String path) => "http://127.0.0.1:${server.port}$path";

  test("network image sends headers but keys the cache on the url", () async {
    await fetchTorAwareBytes(
      url("/a.png"),
      headers: {"Authorization": "Bearer abc"},
    );
    expect(requests.single.headers.value("Authorization"), "Bearer abc");

    expect(
      TorAwareNetworkImage(
        url("/a.png"),
        headers: const {"Authorization": "a"},
      ),
      TorAwareNetworkImage(
        url("/a.png"),
        headers: const {"Authorization": "b"},
      ),
    );
  });
}
