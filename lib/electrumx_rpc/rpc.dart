import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mutex/mutex.dart';
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

  final _requestMutex = Mutex();
  final _JsonRPCRequestQueue _requestQueue = _JsonRPCRequestQueue();
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;

  void _dataHandler(List<int> data) {
    if (_requestQueue.isEmpty) {
      // probably just return although this case should never actually hit
      return;
    }

    final req = _requestQueue.next;
    req.appendDataAndCheckIfComplete(data);

    if (req.isComplete) {
      _onReqCompleted(req);
    }
  }

  void _errorHandler(Object error, StackTrace trace) {
    Logging.instance.log(
      "JsonRPC errorHandler: $error\n$trace",
      level: LogLevel.Error,
    );

    final req = _requestQueue.next;
    req.completer.completeError(error, trace);
    _onReqCompleted(req);
  }

  void _doneHandler() {
    Logging.instance.log(
      "JsonRPC doneHandler: "
      "connection closed to $host:$port, destroying socket",
      level: LogLevel.Info,
    );

    if (_requestQueue.isNotEmpty) {
      Logging.instance.log(
        "JsonRPC doneHandler: queue not empty but connection closed, "
        "completing pending requests with errors",
        level: LogLevel.Error,
      );

      for (final req in _requestQueue.queue) {
        if (!req.isComplete) {
          try {
            throw Exception(
              "JsonRPC doneHandler: socket closed "
              "before request could complete",
            );
          } catch (e, s) {
            req.completer.completeError(e, s);
          }
        }
      }
      _requestQueue.clear();
    }

    disconnect();
  }

  void _onReqCompleted(_JsonRPCRequest req) {
    _requestQueue.remove(req);
    if (_requestQueue.isNotEmpty) {
      _sendNextAvailableRequest();
    }
  }

  void _sendNextAvailableRequest() {
    if (_requestQueue.isEmpty) {
      // TODO handle properly
      throw Exception("JSON RPC queue empty");
    }

    final req = _requestQueue.next;

    _socket!.write('${req.jsonRequest}\r\n');

    req.initiateTimeout(const Duration(seconds: 10));
    // Logging.instance.log(
    //   "JsonRPC request: wrote request ${req.jsonRequest} "
    //   "to socket $host:$port",
    //   level: LogLevel.Info,
    // );
  }

  Future<dynamic> request(String jsonRpcRequest) async {
    // todo: handle this better?
    // Do we need to check the subscription, too?
    await _requestMutex.protect(() async {
      if (_socket == null) {
        Logging.instance.log(
          "JsonRPC request: opening socket $host:$port",
          level: LogLevel.Info,
        );
        await connect();
      }
    });

    final req = _JsonRPCRequest(
      jsonRequest: jsonRpcRequest,
      completer: Completer<dynamic>(),
    );

    _requestQueue.add(req);

    // if this is the only/first request then send it right away
    if (_requestQueue.length == 1) {
      _sendNextAvailableRequest();
    } else {
      // Logging.instance.log(
      //   "JsonRPC request: queued request $jsonRpcRequest "
      //   "to socket $host:$port",
      //   level: LogLevel.Info,
      // );
    }

    return req.completer.future.onError(
      (error, stackTrace) =>
          Exception("return req.completer.future.onError: $error"),
    );
  }

  void disconnect() {
    // TODO: maybe clear req queue here and wrap in mutex?
    _subscription?.cancel().then((_) => _subscription = null);
    _socket?.destroy();
    _socket = null;
  }

  Future<void> connect() async {
    if (useSSL) {
      _socket ??= await SecureSocket.connect(
        host,
        port,
        timeout: connectionTimeout,
        onBadCertificate: (_) => true,
      ); // TODO do not automatically trust bad certificates
    } else {
      _socket ??= await Socket.connect(
        host,
        port,
        timeout: connectionTimeout,
      );
    }
    await _subscription?.cancel();
    _subscription = _socket!.listen(
      _dataHandler,
      onError: _errorHandler,
      onDone: _doneHandler,
      cancelOnError: true,
    );
  }
}

class _JsonRPCRequestQueue {
  final List<_JsonRPCRequest> _rq = [];

  void add(_JsonRPCRequest req) => _rq.add(req);

  bool remove(_JsonRPCRequest req) => _rq.remove(req);

  void clear() => _rq.clear();

  bool get isEmpty => _rq.isEmpty;
  bool get isNotEmpty => _rq.isNotEmpty;
  int get length => _rq.length;
  _JsonRPCRequest get next => _rq.first;
  List<_JsonRPCRequest> get queue => _rq.toList(growable: false);
}

class _JsonRPCRequest {
  final String jsonRequest;
  final Completer<dynamic> completer;
  final List<int> _responseData = [];

  _JsonRPCRequest({required this.jsonRequest, required this.completer});

  void appendDataAndCheckIfComplete(List<int> data) {
    _responseData.addAll(data);
    // 0x0A is newline
    // https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-basics.html
    if (data.last == 0x0A) {
      try {
        final response = json.decode(String.fromCharCodes(_responseData));
        completer.complete(response);
      } catch (e, s) {
        Logging.instance.log(
          "JsonRPC json.decode: $e\n$s",
          level: LogLevel.Error,
        );
        completer.completeError(e, s);
      }
    }
  }

  void initiateTimeout(Duration timeout) {
    Future<void>.delayed(timeout).then((_) {
      if (!isComplete) {
        try {
          throw Exception("_JsonRPCRequest timed out: $jsonRequest");
        } catch (e, s) {
          completer.completeError(e, s);
        }
      }
    });
  }

  bool get isComplete => completer.isCompleted;
}
