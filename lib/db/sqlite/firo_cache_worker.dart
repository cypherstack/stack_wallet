part of 'firo_cache.dart';

enum FCFuncName {
  _updateSparkAnonSetCoinsWith,
  _updateSparkUsedTagsWith,
  _close,
}

class FCTask {
  final id = const Uuid().v4();
  final FCFuncName func;
  final dynamic data;

  FCTask({required this.func, required this.data});
}

class _FiroCacheWorker {
  final SendPort _commands;
  final ReceivePort _responses;
  final Isolate _isolate;
  final Map<String, Completer<Object?>> _activeRequests = {};

  bool _closing = false;

  Future<void> close() async {
    final closed = runTask(FCTask(func: FCFuncName._close, data: null));
    _closing = true;
    try {
      await closed.timeout(const Duration(seconds: 15));
    } catch (_) {
      // The worker may have exited before receiving the close request, or
      // may be stuck in a task. The reset caller exits and retries deletion
      // on the next launch instead of deleting files under a live worker.
      _isolate.kill(priority: Isolate.immediate);
      rethrow;
    } finally {
      _responses.close();
    }
  }

  Future<Object?> runTask(FCTask task) async {
    if (_closing) throw StateError('Firo cache worker is closing');
    final completer = Completer<Object?>.sync();
    _activeRequests[task.id] = completer;
    _commands.send(task);
    return await completer.future;
  }

  static Future<_FiroCacheWorker> spawn(CryptoCurrencyNetwork network) async {
    final dir = await StackFileSystem.applicationFiroCacheSQLiteDirectory();
    final setCacheFilePath =
        "${dir.path}/${_FiroCache.sparkSetCacheFileName(network)}";
    final usedTagsCacheFilePath =
        "${dir.path}/${_FiroCache.sparkUsedTagsCacheFileName(network)}";

    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();

    initPort.handler = (dynamic initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(_startWorkerIsolate, (
        initPort.sendPort,
        setCacheFilePath,
        usedTagsCacheFilePath,
      ));
    } catch (_) {
      initPort.close();
      rethrow;
    }

    final (receivePort, sendPort) = await connection.future;

    return _FiroCacheWorker._(receivePort, sendPort, isolate);
  }

  _FiroCacheWorker._(this._responses, this._commands, this._isolate) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (id, error) = message as (String, Object?);
    final completer = _activeRequests.remove(id)!;

    if (error != null) {
      completer.completeError(error);
    } else {
      completer.complete(id);
    }
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
    Database setCacheDb,
    Database usedTagsCacheDb,
    Mutex mutex,
  ) {
    receivePort.listen((message) {
      final task = message as FCTask;

      mutex.protect(() async {
        try {
          final FCResult result;
          switch (task.func) {
            case FCFuncName._close:
              setCacheDb.close();
              usedTagsCacheDb.close();
              receivePort.close();
              sendPort.send((task.id, null));
              return;

            case FCFuncName._updateSparkAnonSetCoinsWith:
              final data =
                  task.data as (SparkAnonymitySetMeta, List<RawSparkCoin>);
              result = _updateSparkAnonSetCoinsWith(
                setCacheDb,
                data.$2,
                data.$1,
              );
              break;

            case FCFuncName._updateSparkUsedTagsWith:
              result = _updateSparkUsedTagsWith(
                usedTagsCacheDb,
                task.data as List<List<dynamic>>,
              );
              break;
          }

          if (result.success) {
            sendPort.send((task.id, null));
          } else {
            sendPort.send((task.id, result.error!));
          }
        } catch (e) {
          sendPort.send((task.id, e));
        }
      });
    });
  }

  static void _startWorkerIsolate((SendPort, String, String) args) {
    final receivePort = ReceivePort();
    args.$1.send(receivePort.sendPort);
    final mutex = Mutex();
    final setCacheDb = sqlite3.open(args.$2, mode: OpenMode.readWrite);
    final usedTagsCacheDb = sqlite3.open(args.$3, mode: OpenMode.readWrite);
    _handleCommandsToIsolate(
      receivePort,
      args.$1,
      setCacheDb,
      usedTagsCacheDb,
      mutex,
    );
  }
}
