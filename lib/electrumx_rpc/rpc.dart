import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// import 'package:mutex/mutex.dart';

import 'package:stackwallet/utilities/logger.dart';

// hacky fix to receive large jsonrpc responses
class JsonRPC {
  JsonRPC({
    required this.host,
    required this.port,
    this.useSSL = false,
    this.connectionTimeout = const Duration(seconds: 60),
  });
  final bool useSSL;
  final String host;
  final int port;
  final Duration connectionTimeout;

  Socket? socket;
  StreamSubscription<Uint8List>? _subscription;

  // final m = Mutex();

  void Function(List<int>)? _onData;
  void Function(Object, StackTrace)? _onError;

  List<dynamic>? _requestQueue; // TODO make Request model

  Future<dynamic> request(String jsonRpcRequest) async {
    final completer = Completer<dynamic>();
    final List<int> responseData = [];

    void dataHandler(List<int> data) {
      responseData.addAll(data);

      // 0x0A is newline
      // https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-basics.html
      if (data.last == 0x0A) {
        try {
          final response = json.decode(String.fromCharCodes(responseData));
          completer.complete(response); // TODO only complete on last chunk?
        } catch (e, s) {
          Logging.instance
              .log("JsonRPC json.decode: $e\n$s", level: LogLevel.Error);
          completer.completeError(e, s);
        } finally {
          Logging.instance.log(
            "JsonRPC dataHandler: not destroying socket ${socket?.address}:${socket?.port}",
            level: LogLevel.Info,
          );
          // socket?.destroy();
          // TODO is this all we need to do?
        }
      }
    }

    _onData = dataHandler;

    void errorHandler(Object error, StackTrace trace) {
      Logging.instance
          .log("JsonRPC errorHandler: $error\n$trace", level: LogLevel.Error);
      completer.completeError(error, trace);
      Logging.instance.log(
        "JsonRPC errorHandler: not destroying socket ${socket?.address}:${socket?.port}",
        level: LogLevel.Info,
      );
      // socket?.destroy();
      // TODO do we need to recreate the socket?
    }

    _onError = errorHandler;

    void doneHandler() {
      Logging.instance.log(
        "JsonRPC doneHandler: not destroying socket ${socket?.address}:${socket?.port}",
        level: LogLevel.Info,
      );
      // socket?.destroy();
      // TODO is this all we need?
    }

    if (socket != null) {
      // TODO check if the socket is valid, alive, connected, etc
    }
    // Do we need to check the subscription, too?

    // await m.acquire();

    if (useSSL) {
      socket ??= await SecureSocket.connect(host, port,
          timeout: connectionTimeout, onBadCertificate: (_) => true); // TODO do not automatically trust bad certificates
      _subscription ??= socket!.listen(
        _onData,
        onError: _onError,
        onDone: doneHandler,
        cancelOnError: true,
      );
    } else {
      socket ??= await Socket.connect(
        host,
        port,
        timeout: connectionTimeout,
      );
      _subscription ??= socket!.listen(
        _onData,
        onError: _onError,
        onDone: doneHandler,
        cancelOnError: true,
      );
    }

    socket?.write('$jsonRpcRequest\r\n');

    // m.release();

    return completer.future;
  }
}
