import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
    _requestQueue.nextIncompleteReq.then((req) {
      if (req != null) {
        req.appendDataAndCheckIfComplete(data);

        if (req.isComplete) {
          _onReqCompleted(req);
        }
      } else {
        Logging.instance.log(
          "_dataHandler found a null req!",
          level: LogLevel.Warning,
        );
      }
    });
  }

  void _errorHandler(Object error, StackTrace trace) {
    _requestQueue.nextIncompleteReq.then((req) {
      if (req != null) {
        req.completer.completeError(error, trace);
        _onReqCompleted(req);
      } else {
        Logging.instance.log(
          "_errorHandler found a null req!",
          level: LogLevel.Warning,
        );
      }
    });
  }

  void _doneHandler() {
    Logging.instance.log(
      "JsonRPC doneHandler: "
      "connection closed to $host:$port, destroying socket",
      level: LogLevel.Info,
    );

    disconnect(reason: "JsonRPC _doneHandler() called");
  }

  void _onReqCompleted(_JsonRPCRequest req) {
    _requestQueue.remove(req).then((value) {
      if (kDebugMode) {
        print("Request removed from queue: $value");
      }
      // attempt to send next request
      _sendNextAvailableRequest();
    });
  }

  void _sendNextAvailableRequest() {
    _requestQueue.nextIncompleteReq.then((req) {
      if (req != null) {
        // \r\n required by electrumx server
        _socket!.write('${req.jsonRequest}\r\n');

        // TODO different timeout length?
        req.initiateTimeout(const Duration(seconds: 10));
      } else {
        Logging.instance.log(
          "_sendNextAvailableRequest found a null req!",
          level: LogLevel.Warning,
        );
      }
    });
  }

  // TODO: non dynamic type
  Future<dynamic> request(String jsonRpcRequest) async {
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

    // if this is the only/first request then send it right away
    await _requestQueue.add(
      req,
      onInitialRequestAdded: _sendNextAvailableRequest,
    );

    return req.completer.future.onError(
      (error, stackTrace) => Exception(
        "return req.completer.future.onError: $error",
      ),
    );
  }

  Future<void> disconnect({String reason = "none"}) async {
    await _requestMutex.protect(() async {
      await _subscription?.cancel();
      _subscription = null;
      _socket?.destroy();
      _socket = null;

      // clean up remaining queue
      await _requestQueue.completeRemainingWithError(
        "JsonRPC disconnect() called with reason: \"$reason\"",
      );
    });
  }

  Future<void> connect() async {
    if (_socket != null) {
      throw Exception(
        "JsonRPC attempted to connect to an already existing socket!",
      );
    }

    if (useSSL) {
      _socket = await SecureSocket.connect(
        host,
        port,
        timeout: connectionTimeout,
        onBadCertificate: (_) => true,
      ); // TODO do not automatically trust bad certificates
    } else {
      _socket = await Socket.connect(
        host,
        port,
        timeout: connectionTimeout,
      );
    }

    _subscription = _socket!.listen(
      _dataHandler,
      onError: _errorHandler,
      onDone: _doneHandler,
      cancelOnError: true,
    );
  }
}

class _JsonRPCRequestQueue {
  final m = Mutex();

  final List<_JsonRPCRequest> _rq = [];

  Future<void> add(
    _JsonRPCRequest req, {
    VoidCallback? onInitialRequestAdded,
  }) async {
    return await m.protect(() async {
      _rq.add(req);
      if (_rq.length == 1) {
        onInitialRequestAdded?.call();
      }
    });
  }

  Future<bool> remove(_JsonRPCRequest req) async {
    return await m.protect(() async => _rq.remove(req));
  }

  Future<_JsonRPCRequest?> get nextIncompleteReq async {
    return await m.protect(() async {
      try {
        return _rq.firstWhere((e) => !e.isComplete);
      } catch (_) {
        // no incomplete requests found
        return null;
      }
    });
  }

  Future<void> completeRemainingWithError(
    String error, {
    StackTrace? stackTrace,
  }) async {
    await m.protect(() async {
      for (final req in _rq) {
        if (!req.isComplete) {
          req.completer.completeError(Exception(error), stackTrace);
        }
      }
      _rq.clear();
    });
  }

  Future<bool> get isEmpty async {
    return await m.protect(() async {
      return _rq.isEmpty;
    });
  }
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
