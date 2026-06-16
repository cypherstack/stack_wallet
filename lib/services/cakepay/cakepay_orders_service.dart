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
  final Set<String> _inflight = {};
  final Map<String, _Poll> _polls = {};
  bool _refreshingAll = false;

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

  bool isRefreshing(String orderId) => _inflight.contains(orderId);
  bool get isRefreshingAll => _refreshingAll;

  /// Fetch a single order. No-ops if a fetch for [orderId] is already in
  /// flight.
  Future<void> refreshOne(String orderId) async {
    if (_inflight.contains(orderId)) return;
    _inflight.add(orderId);
    notifyListeners();
    try {
      final resp = await CakePayService.instance.client.getOrder(orderId);
      if (!resp.hasError && resp.value != null) {
        _putIfChanged(resp.value!);
      }
    } catch (_) {
      // Silently leave the cached value in place.
    } finally {
      _inflight.remove(orderId);
      notifyListeners();
    }
  }

  /// Fetch every locally-tracked order in parallel.
  Future<void> refreshAll() async {
    if (_refreshingAll) return;
    _refreshingAll = true;
    notifyListeners();
    try {
      final ids = await CakePayService.instance.getOrderIds();
      await Future.wait(ids.map(refreshOne));
    } catch (_) {
      // Listeners still hold whatever was cached.
    } finally {
      _refreshingAll = false;
      notifyListeners();
    }
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
