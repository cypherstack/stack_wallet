import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:on_chain/ada/src/provider/blockfrost/core/core.dart';
import 'package:on_chain/ada/src/provider/service/service.dart';

import '../../../utilities/logger.dart';

class BlockfrostHttpProvider implements BlockfrostServiceProvider {
  BlockfrostHttpProvider(
      {required this.url,
        this.version = "v0",
        this.projectId,
        http.Client? client,
        this.defaultRequestTimeout = const Duration(seconds: 30)})
      : client = client ?? http.Client();
  @override
  final String url;
  final String version;
  final String? projectId;
  final http.Client client;
  final Duration defaultRequestTimeout;

  @override
  Future<dynamic> get(BlockforestRequestDetails params,
      [Duration? timeout]) async {
    final response =
    await client.get(Uri.parse(params.url(url, "api/$version")), headers: {
      'Content-Type': 'application/json',
      "Accept": "application/json",
      if (projectId != null) ...{"project_id": projectId!},
    }).timeout(timeout ?? defaultRequestTimeout);
    final data = json.decode(response.body);
    return data;
  }

  @override
  Future<dynamic> post(BlockforestRequestDetails params,
      [Duration? timeout]) async {
    final response = await client
        .post(Uri.parse(params.url(url, "api/$version")),
        headers: {
          "Accept": "application/json",
          if (projectId != null) ...{"project_id": projectId!},
          ...params.header
        },
        body: params.body)
        .timeout(timeout ?? defaultRequestTimeout);
    final data = json.decode(response.body);
    return data;
  }
}