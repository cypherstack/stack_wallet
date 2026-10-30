import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cakepay_service.dart';
import 'src/models/order.dart';

/// Holds an in-memory cache of CakePay orders, refreshes them in the
/// background, and notifies listeners only when something actually changed.
///
/// Modelled on `PriceService` — see `lib/services/price_service.dart`.
class CakePayOrdersService extends ChangeNotifier {
  static const Duration defaultPollInterval = Duration(seconds: 15);

  final Map<String, CakePayOrder> _orders = {};
  final Map<String, Completer<void>> _inFlight = {};
  final Map<String, _Poll> _polls = {};
  Completer<void>? _refreshAllCompleter;

  /// Current cached value for [orderId], or null if not yet fetched.
  CakePayOrder? get(String orderId) => _orders[orderId];

  /// Snapshot of all cached orders, sorted by `createdAt` descending.
  List<CakePayOrder> get all {
    final list = _orders.values.toList();
    list.sort((a, b) {
      final ac = a.createdAt;
      final bc = b.createdAt;
      if (ac == null && bc == null) return 0;
      if (ac == null) return 1;
      if (bc == null) return -1;
      return bc.compareTo(ac);
    });
    return list;
  }

  bool isRefreshing(String orderId) => _inFlight.containsKey(orderId);
  bool get isRefreshingAll => _refreshAllCompleter != null;

  /// returns existing future if already in flight
  Future<void> refreshOne(String orderId) async {
    final Completer<void>? pending = _inFlight[orderId];
    if (pending != null) return pending.future;

    final Completer<void> completer = Completer<void>();
    _inFlight[orderId] = completer;
    notifyListeners();

    unawaited(() async {
      try {
        final resp = await CakePayService.instance.client.getOrder(orderId);
        if (!resp.hasError && resp.value != null) {
          _putIfChanged(resp.value!);
        }
        completer.complete();
      } catch (e, s) {
        completer.completeError(e, s);
      } finally {
        _inFlight.remove(orderId);
        notifyListeners();
      }
    }());

    return completer.future;
  }

  /// Fetch every locally-tracked order in parallel. Returns the existing
  /// future if a refresh-all is already in flight, so awaiters can be sure a
  /// refresh has actually occurred.
  Future<void> refreshAll() async {
    final Completer<void>? pending = _refreshAllCompleter;
    if (pending != null) return pending.future;

    final Completer<void> completer = Completer<void>();
    _refreshAllCompleter = completer;
    notifyListeners();

    unawaited(() async {
      try {
        final ids = await CakePayService.instance.getOrderIds();
        await Future.wait(ids.map(refreshOne));
        completer.complete();
      } catch (e, s) {
        completer.completeError(e, s);
      } finally {
        _refreshAllCompleter = null;
        notifyListeners();
      }
    }());

    return completer.future;
  }

  /// Start (or join) a refcounted poll for [orderId]. The first call kicks off
  /// an immediate refresh and creates the timer; subsequent calls just bump
  /// the refcount. Each call must be paired with [stopPolling].
  void startPolling(String orderId, {Duration interval = defaultPollInterval}) {
    final existing = _polls[orderId];
    if (existing != null) {
      existing.refs += 1;
      return;
    }
    final poll = _Poll(refs: 1, timer: null);
    _polls[orderId] = poll;
    // Immediate fetch.
    unawaited(refreshOne(orderId));
    poll.timer = Timer.periodic(interval, (_) {
      final cached = _orders[orderId];
      if (cached != null && _isTerminal(cached.status)) {
        _cancel(orderId);
        return;
      }
      unawaited(refreshOne(orderId));
    });
  }

  void stopPolling(String orderId) {
    final poll = _polls[orderId];
    if (poll == null) return;
    poll.refs -= 1;
    if (poll.refs <= 0) {
      _cancel(orderId);
    }
  }

  void _cancel(String orderId) {
    _polls.remove(orderId)?.timer?.cancel();
  }

  void _putIfChanged(CakePayOrder order) {
    final existing = _orders[order.orderId];
    if (existing == null || !_equals(existing, order)) {
      _orders[order.orderId] = order;
    }
  }

  static bool _isTerminal(CakePayOrderStatus s) =>
      s == CakePayOrderStatus.complete ||
      s == CakePayOrderStatus.expired ||
      s == CakePayOrderStatus.failed ||
      s == CakePayOrderStatus.refunded;

  static bool _equals(CakePayOrder a, CakePayOrder b) {
    return a.orderId == b.orderId &&
        a.status == b.status &&
        a.amountUsd == b.amountUsd &&
        a.expirationTime == b.expirationTime &&
        a.invoiceTime == b.invoiceTime &&
        a.commission == b.commission &&
        a.markupPercent == b.markupPercent &&
        a.createdAt == b.createdAt &&
        a.externalOrderId == b.externalOrderId;
  }

  @override
  void dispose() {
    for (final p in _polls.values) {
      p.timer?.cancel();
    }
    _polls.clear();
    super.dispose();
  }
}

class _Poll {
  _Poll({required this.refs, required this.timer});
  int refs;
  Timer? timer;
}
