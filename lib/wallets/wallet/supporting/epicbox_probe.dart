import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Connects to an Epicbox relay at [uri] and returns whether it greets with
/// a challenge. Throws if the connection fails or times out.
Future<bool> probeEpicboxServer(
  Uri uri, {
  Duration connectTimeout = const Duration(seconds: 10),
  Duration replyTimeout = const Duration(seconds: 2),
}) async {
  WebSocketChannel? channel;
  try {
    channel = WebSocketChannel.connect(uri);
    await channel.ready.timeout(connectTimeout);
    final dynamic response = await channel.stream.first.timeout(replyTimeout);
    return response is String && response.contains("Challenge");
  } finally {
    // After a failed connection sink.close() never completes, so awaiting it
    // here would leave the caller (a send in progress) waiting forever.
    channel?.sink.close().ignore();
  }
}
