import 'dart:async';

class TradeOperationGuard {
  /// A refresh must finish first so its database write cannot follow deletion.
  /// Bounded because the exchange HTTP layer sets no response timeout, so a
  /// stalled provider would otherwise block deletion forever.
  static const refreshWaitTimeout = Duration(seconds: 5);

  Future<void> _statusRefresh = Future.value();

  bool _deletionRequested = false;

  bool get deletionRequested => _deletionRequested;

  void trackStatusRefresh(Future<void> refresh) {
    if (!_deletionRequested) {
      _statusRefresh = refresh;
    }
  }

  Future<bool> deleteAfterRefresh(Future<void> Function() delete) async {
    if (_deletionRequested) {
      return false;
    }

    _deletionRequested = true;
    try {
      await _statusRefresh.timeout(refreshWaitTimeout, onTimeout: () {});
      await delete();
      return true;
    } catch (_) {
      _deletionRequested = false;
      rethrow;
    }
  }
}
