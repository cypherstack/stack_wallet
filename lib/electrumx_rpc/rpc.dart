import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epicmobile/utilities/logger.dart';

// hacky fix to receive large jsonrpc responses
class JsonRPC {
  JsonRPC({
    required this.host,
    required this.port,
    this.useSSL = false,
    this.connectionTimeout = const Duration(seconds: 60),
  });
  bool useSSL;
  String host;
  int port;
  Duration connectionTimeout;

  Future<dynamic> request(String jsonRpcRequest) async {
    Socket? socket;
    final completer = Completer<dynamic>();
    final List<int> responseData = [];

    void dataHandler(List<int> data) {
      responseData.addAll(data);

      // 0x0A is newline
      // https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-basics.html
      if (data.last == 0x0A) {
        try {
          final response = json.decode(String.fromCharCodes(responseData));
          completer.complete(response);
        } catch (e, s) {
          Logging.instance
              .log("JsonRPC json.decode: $e\n$s", level: LogLevel.Error);
          completer.completeError(e, s);
        } finally {
          socket?.destroy();
        }
      }
    }

    void errorHandler(Object error, StackTrace trace) {
      Logging.instance
          .log("JsonRPC errorHandler: $error\n$trace", level: LogLevel.Error);
      completer.completeError(error, trace);
      socket?.destroy();
    }

    void doneHandler() {
      socket?.destroy();
    }

    if (useSSL) {
      await SecureSocket.connect(host, port,
          timeout: connectionTimeout,
          onBadCertificate: (_) => true).then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      });
    } else {
      await Socket.connect(host, port, timeout: connectionTimeout)
          .then((Socket sock) {
        socket = sock;
        socket?.listen(dataHandler,
            onError: errorHandler, onDone: doneHandler, cancelOnError: true);
      });
    }

    socket?.write('$jsonRpcRequest\r\n');

    return completer.future;
  }
}
