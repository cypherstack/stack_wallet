import 'dart:convert';
import 'dart:io';
import 'package:on_chain/ada/src/provider/blockfrost/core/core.dart';
import 'package:on_chain/ada/src/provider/service/service.dart';

class BlockfrostHttpProvider implements BlockfrostServiceProvider {
  BlockfrostHttpProvider({
    required this.url,
    this.version = "v0",
    this.projectId,
    HttpClient? client,
    this.defaultRequestTimeout = const Duration(seconds: 30),
  }) : client = client ?? HttpClient();
  @override
  final String url;
  final String version;
  final String? projectId;
  final HttpClient client;
  final Duration defaultRequestTimeout;

  @override
  Future<dynamic> get(BlockforestRequestDetails params,
      [Duration? timeout,]) async {
    final response = await client.getUrl(Uri.parse(params.url(url, "api/$version"))).timeout(timeout ?? defaultRequestTimeout);
    response.headers.add("Content-Type", "application/json");
    response.headers.add("Accept", "application/json");
    if (projectId != null) {
      response.headers.add("project_id", projectId!);
    }
    final responseStream = await response.close();
    final data = json.decode(await responseStream.transform(utf8.decoder).join());
    return data;
  }

  @override
  Future<dynamic> post(BlockforestRequestDetails params,
      [Duration? timeout,]) async {
    final request = await client.postUrl(Uri.parse(params.url(url, "api/$version"))).timeout(timeout ?? defaultRequestTimeout);
    request.headers.add("Content-Type", "application/json");
    request.headers.add("Accept", "application/json");
    if (projectId != null) {
      request.headers.add("project_id", projectId!);
    }
    request.write(json.encode(params.body));
    final response = await request.close();
    final data = json.decode(await response.transform(utf8.decoder).join());
    return data;
  }
}
