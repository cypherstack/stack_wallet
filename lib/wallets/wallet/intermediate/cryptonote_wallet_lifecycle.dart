import 'dart:async';

import 'package:mutex/mutex.dart';

Future<void> cancelCryptonoteWalletSubscriptions(
  Iterable<StreamSubscription<dynamic>?> subscriptions,
) async {
  Object? firstError;
  StackTrace? firstStackTrace;
  for (final subscription in subscriptions) {
    try {
      await subscription?.cancel();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
  }
  if (firstError != null) {
    Error.throwWithStackTrace(firstError, firstStackTrace!);
  }
}

class CryptonoteTorTransitionGate {
  Completer<void>? _transition;

  void block() {
    _transition ??= Completer<void>();
  }

  void release() {
    final transition = _transition;
    _transition = null;
    if (transition != null && !transition.isCompleted) {
      transition.complete();
    }
  }

  Future<bool> wait({
    required bool Function() isBlocked,
    required bool Function() isCurrent,
  }) async {
    while (isBlocked()) {
      // A superseded operation must not wait for a Tor event that may never
      // arrive (its listener may already be detached by exit()).
      if (!isCurrent()) {
        return false;
      }
      final transition = _transition ??= Completer<void>();
      await transition.future;
      if (!isCurrent()) {
        return false;
      }
    }
    return true;
  }
}

/// Serializes native wallet lifecycle operations and rejects node updates once
/// shutdown begins.
class CryptonoteWalletLifecycle {
  final _mutex = Mutex();
  bool _allowsNodeUpdates = true;

  bool get allowsNodeUpdates => _allowsNodeUpdates;

  Future<void> open(
    Future<void> Function(bool Function() isCurrent) operation,
  ) => _mutex.protect(() async {
    _allowsNodeUpdates = true;
    try {
      await operation(() => _allowsNodeUpdates);
    } catch (_) {
      _allowsNodeUpdates = false;
      rethrow;
    }
  });

  Future<void> updateNode(
    Future<void> Function(bool Function() isCurrent) operation,
  ) => _mutex.protect(() async {
    if (_allowsNodeUpdates) {
      await operation(() => _allowsNodeUpdates);
    }
  });

  Future<void> runIfCurrent(Future<void> Function() operation) =>
      _mutex.protect(() async {
        if (_allowsNodeUpdates) {
          await operation();
        }
      });

  Future<T> replaceNative<T>(Future<T> Function() operation) =>
      _mutex.protect(() {
        if (!_allowsNodeUpdates) {
          throw StateError("Native wallet lifecycle is closing");
        }
        return operation();
      });

  Future<void> close({
    required Future<void> Function() stopEventSources,
    required Future<void> Function() closeNative,
  }) async {
    _allowsNodeUpdates = false;

    Object? stopError;
    StackTrace? stopStackTrace;
    Future<void> stopSources() async {
      try {
        await stopEventSources();
      } catch (error, stackTrace) {
        stopError ??= error;
        stopStackTrace ??= stackTrace;
      }
    }

    // Reserve shutdown's place in the queue immediately. Sources are stopped
    // before native close, then checked again for a concurrent open.
    final firstStopCompleted = Completer<void>();
    final serializedClose = _mutex.protect(() async {
      await firstStopCompleted.future;
      // An open() queued ahead of this close may have re-enabled updates in
      // the meantime; close was requested later, so the closed state wins.
      _allowsNodeUpdates = false;
      await stopSources();
      await closeNative();
    });

    await stopSources();
    firstStopCompleted.complete();
    await serializedClose;

    if (stopError != null) {
      Error.throwWithStackTrace(stopError!, stopStackTrace!);
    }
  }
}
