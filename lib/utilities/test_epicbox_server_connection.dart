import 'dart:io';

import 'logger.dart';

Future<bool> _testEpicBoxConnection(String host, int port, bool useSSL) async {
  final client = HttpClient();
  try {
    final protocol = useSSL ? 'https' : 'http';

    client.connectionTimeout = const Duration(seconds: 5);

    final request = await client.getUrl(Uri.parse('$protocol://$host:$port'));
    final response = await request.close();
    final body = await response
        .transform(const SystemEncoding().decoder)
        .join();

    client.close();

    // epicbox servers return an HTML page containing "Epicbox"
    return response.statusCode == 200 && body.contains('Epicbox');
  } catch (e, s) {
    Logging.instance.e(
      "_testEpicBoxConnection failed on \"$host:$port\"",
      error: e,
      stackTrace: s,
    );
    return false;
  } finally {
    client.close(force: true);
  }
}

Future<EpicBoxFormData?> testEpicBoxServerConnection(
  EpicBoxFormData data,
) async {
  if (data.host == null || data.port == null) {
    return null;
  }

  try {
    final useSSL = data.useSSL ?? true;
    if (await _testEpicBoxConnection(data.host!, data.port!, useSSL)) {
      return data;
    } else {
      return null;
    }
  } catch (e, s) {
    Logging.instance.w("$e\n$s", error: e, stackTrace: s);
    return null;
  }
}

class EpicBoxFormData {
  String? name, host;
  int? port;
  bool? useSSL, isFailover;

  @override
  String toString() {
    return "{ name: $name, host: $host, port: $port, useSSL: $useSSL }";
  }
}
