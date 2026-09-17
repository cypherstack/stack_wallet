import 'dart:async';

final class XelisEventBatch<T> {
  const XelisEventBatch({
    required this.transactions,
    required this.topoheightChanged,
    required this.balanceChanged,
  });

  final List<T> transactions;
  final bool topoheightChanged;
  final bool balanceChanged;

  bool get isEmpty =>
      transactions.isEmpty && !topoheightChanged && !balanceChanged;
}

final class XelisEventBatcher<T> {
  XelisEventBatcher({required this.flushInterval, required this.flush});

  final Duration flushInterval;
  final Future<void> Function(XelisEventBatch<T> batch) flush;

  final List<T> _transactions = [];
  bool _topoheightChanged = false;
  bool _balanceChanged = false;
  bool _isFlushing = false;
  Timer? _flushTimer;

  void queueTransaction(T transaction) {
    _transactions.add(transaction);
    _scheduleFlush();
  }

  void queueTopoheightChanged() {
    _topoheightChanged = true;
    _scheduleFlush();
  }

  void queueBalanceChanged() {
    _balanceChanged = true;
    _scheduleFlush();
  }

  void reset() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _transactions.clear();
    _topoheightChanged = false;
    _balanceChanged = false;
  }

  void _scheduleFlush() {
    if (!_isFlushing) {
      _flushTimer ??= Timer(flushInterval, () => unawaited(_flushNow()));
    }
  }

  Future<void> _flushNow() async {
    _flushTimer = null;
    final batch = XelisEventBatch<T>(
      transactions: List.of(_transactions),
      topoheightChanged: _topoheightChanged,
      balanceChanged: _balanceChanged,
    );
    _transactions.clear();
    _topoheightChanged = false;
    _balanceChanged = false;

    if (batch.isEmpty) {
      return;
    }

    _isFlushing = true;
    try {
      await flush(batch);
    } finally {
      _isFlushing = false;
      if (_transactions.isNotEmpty || _topoheightChanged || _balanceChanged) {
        _scheduleFlush();
      }
    }
  }
}
