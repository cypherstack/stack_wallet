import 'package:mutex/mutex.dart';

enum XelisOperation {
  idle,
  connecting,
  refreshing,
  rescanning,
  processingEvent,
  exiting,
}

final class XelisOperationCoordinator {
  XelisOperationCoordinator(this._mutex);

  final Mutex _mutex;

  Future<void>? _latestSyncFuture;
  Future<void>? _pendingExitFuture;
  ({XelisOperation operation, Future<void> future})? _latestLifecycle;

  XelisOperation _activeOperation = XelisOperation.idle;

  XelisOperation get activeOperation => _activeOperation;

  Future<void> connect(
    Future<void> Function() operation, {
    bool joinExisting = true,
  }) {
    final latestLifecycle = _latestLifecycle;
    if (joinExisting &&
        latestLifecycle?.operation == XelisOperation.connecting) {
      return latestLifecycle!.future;
    }

    late final Future<void> future;
    future = _run(XelisOperation.connecting, operation).whenComplete(() {
      _clearLatestLifecycle(future);
      _clearLatestSync(future);
    });

    _latestLifecycle = (operation: XelisOperation.connecting, future: future);
    _latestSyncFuture = future;
    return future;
  }

  Future<void> refresh(Future<void> Function() operation) {
    final latestSyncFuture = _latestSyncFuture;
    if (latestSyncFuture != null) {
      return latestSyncFuture;
    }

    if (_pendingExitFuture != null) {
      return Future<void>.value();
    }

    return _scheduleSync(XelisOperation.refreshing, operation);
  }

  Future<void> rescan(Future<void> Function() operation) {
    if (_pendingExitFuture != null) {
      return Future<void>.error(
        StateError('Cannot rescan a Xelis wallet while it is exiting'),
      );
    }

    return _scheduleSync(XelisOperation.rescanning, operation);
  }

  Future<void> processEvent(Future<void> Function() operation) {
    if (_pendingExitFuture != null) {
      return Future<void>.value();
    }

    return _run(XelisOperation.processingEvent, operation);
  }

  Future<void> processSyncEvent(Future<void> Function() operation) {
    if (_pendingExitFuture != null) {
      return Future<void>.value();
    }

    return refresh(operation);
  }

  Future<void> exit(Future<void> Function() operation) {
    final latestLifecycle = _latestLifecycle;
    if (latestLifecycle?.operation == XelisOperation.exiting) {
      return latestLifecycle!.future;
    }

    _latestSyncFuture = null;

    late final Future<void> future;
    future = _run(XelisOperation.exiting, operation).whenComplete(() {
      if (identical(_pendingExitFuture, future)) {
        _pendingExitFuture = null;
      }
      _clearLatestLifecycle(future);
    });

    _latestLifecycle = (operation: XelisOperation.exiting, future: future);
    _pendingExitFuture = future;
    return future;
  }

  Future<void> _scheduleSync(
    XelisOperation operationType,
    Future<void> Function() operation,
  ) {
    late final Future<void> future;
    future = _run(operationType, operation).whenComplete(() {
      _clearLatestSync(future);
    });

    _latestSyncFuture = future;
    return future;
  }

  Future<void> _run(
    XelisOperation operationType,
    Future<void> Function() operation,
  ) {
    return _mutex.protect(() async {
      assert(_activeOperation == XelisOperation.idle);
      _activeOperation = operationType;
      try {
        await operation();
      } finally {
        _activeOperation = XelisOperation.idle;
      }
    });
  }

  void _clearLatestSync(Future<void> completedFuture) {
    if (identical(_latestSyncFuture, completedFuture)) {
      _latestSyncFuture = null;
    }
  }

  void _clearLatestLifecycle(Future<void> completedFuture) {
    if (identical(_latestLifecycle?.future, completedFuture)) {
      _latestLifecycle = null;
    }
  }
}
