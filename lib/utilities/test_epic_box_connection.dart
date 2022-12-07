import 'dart:convert';

import 'package:epicmobile/pages/settings_views/network_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:http/http.dart' as http;

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

Future<bool> testEpicNodeConnection(NodeFormData data) async {
  if (data.host == null || data.port == null || data.useSSL == null) {
    return false;
  }
  const String path = "/v1/version";

  String uriString;
  if (data.useSSL!) {
    uriString = "https://${data.host!}:${data.port!}$path";
  } else {
    uriString = "http://${data.host!}:${data.port!}$path";
  }

  try {
    return await testEpicBoxNodeConnection(Uri.parse(uriString));
  } catch (e, s) {
    Logging.instance.log("$e\n$s", level: LogLevel.Warning);
    return false;
  }
}
