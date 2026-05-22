import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import 'shopinbit_service.dart';

/// Holds canonical [ShopInBitOrderModel] instances keyed by `apiTicketId`,
/// refreshes them in the background, and notifies listeners only when
/// something actually changed.
///
/// Modelled on `PriceService`, see `lib/services/price_service.dart`.
class ShopInBitOrdersService extends ChangeNotifier {
  ShopInBitOrdersService({required this.shopInBitService});

  static const Duration defaultPollInterval = Duration(seconds: 30);

  final ShopInBitService shopInBitService;

  final Map<int, ShopInBitOrderModel> _tickets = {};
  final Set<int> _inflight = {};
  final Map<int, _Poll> _polls = {};

  /// Register [model] as the canonical instance for its `apiTicketId`. If a
  /// canonical instance already exists, returns it; otherwise stores and
  /// returns [model]. Callers should use the returned instance.
  ShopInBitOrderModel upsert(ShopInBitOrderModel model) {
    final existing = _tickets[model.apiTicketId];
    if (existing != null) return existing;
    _tickets[model.apiTicketId] = model;
    return model;
  }

  ShopInBitOrderModel? get(int apiTicketId) => _tickets[apiTicketId];

  bool isRefreshing(int apiTicketId) => _inflight.contains(apiTicketId);

  /// Fetch latest status + messages (+ offer details if applicable) for the
  /// given ticket. No-ops if a fetch for this ticket is already in flight.
  Future<void> refreshOne(int apiTicketId) async {
    if (apiTicketId == 0) return;
    if (_inflight.contains(apiTicketId)) return;
    final model = _tickets[apiTicketId];
    if (model == null) return;

    _inflight.add(apiTicketId);
    notifyListeners();
    try {
      final client = shopInBitService.client;

      // Fire both off concurrently, then await individually for typed access.
      final messagesFuture = client.getMessages(apiTicketId);
      final statusFuture = client.getTicketStatus(apiTicketId);
      final messagesResp = await messagesFuture;
      final statusResp = await statusFuture;

      bool changed = false;

      if (!messagesResp.hasError && messagesResp.value != null) {
        final apiMessages = messagesResp.value!;
        final last = model.messages.isEmpty ? null : model.messages.last;
        final apiLast = apiMessages.isEmpty ? null : apiMessages.last;
        final lengthsDiffer = model.messages.length != apiMessages.length;
        final lastTimestampDiffers = last?.timestamp != apiLast?.timestamp;
        if (lengthsDiffer || lastTimestampDiffers) {
          model.clearMessages();
          for (final m in apiMessages) {
            model.addMessage(
              ShopInBitMessage(
                text: m.content,
                timestamp: m.timestamp,
                isFromUser: !m.fromAgent,
              ),
            );
          }
          changed = true;
        }
      }

      if (!statusResp.hasError && statusResp.value != null) {
        final newStatus = ShopInBitOrderModel.statusFromTicketState(
          statusResp.value!.state,
        );
        if (model.status != newStatus) {
          model.status = newStatus;
          changed = true;
        }
      }

      if (model.status == ShopInBitOrderStatus.offerAvailable &&
          (model.offerProductName == null || model.offerPrice == null)) {
        final offerResp = await client.getTicketFull(apiTicketId);
        if (!offerResp.hasError && offerResp.value != null) {
          final t = offerResp.value!;
          model.setOffer(productName: t.productName, price: t.customerPrice);
          changed = true;
        }
      }

      if (changed && model.ticketId != null) {
        final db = SharedDrift.get();
        unawaited(
          db
              .into(db.shopInBitTickets)
              .insertOnConflictUpdate(model.toCompanion()),
        );
      }
    } catch (_) {
      // Silently leave the cached model in place.
    } finally {
      _inflight.remove(apiTicketId);
      notifyListeners();
    }
  }

  /// Start (or join) a refcounted poll for [apiTicketId]. The first call
  /// kicks off an immediate refresh and creates the timer; subsequent calls
  /// just bump the refcount. Pair each call with [stopPolling].
  ///
  /// If [pollInBackground] is false, the immediate refresh still runs but no
  /// timer is created (matches the existing behavior for car-research
  /// tickets).
  void startPolling(
    int apiTicketId, {
    Duration interval = defaultPollInterval,
    bool pollInBackground = true,
  }) {
    if (apiTicketId == 0) return;
    final existing = _polls[apiTicketId];
    if (existing != null) {
      existing.refs += 1;
      return;
    }
    final poll = _Poll(refs: 1, timer: null);
    _polls[apiTicketId] = poll;
    unawaited(refreshOne(apiTicketId));
    if (pollInBackground) {
      poll.timer = Timer.periodic(interval, (_) {
        unawaited(refreshOne(apiTicketId));
      });
    }
  }

  void stopPolling(int apiTicketId) {
    final poll = _polls[apiTicketId];
    if (poll == null) return;
    poll.refs -= 1;
    if (poll.refs <= 0) {
      _polls.remove(apiTicketId)?.timer?.cancel();
    }
  }

  /// Sync the customer's full ticket list from the API, walking each one to
  /// refresh status / messages / offer in parallel. Used by the requests
  /// list view.
  Future<void> refreshAll() async {
    try {
      final customerKey = await shopInBitService.ensureCustomerKey();
      final resp = await shopInBitService.client.getTicketsByCustomer(
        customerKey,
      );
      if (resp.hasError || resp.value == null) return;

      final db = SharedDrift.get();
      final localRows = await db.select(db.shopInBitTickets).get();
      final byApiId = {for (final r in localRows) r.apiTicketId: r};

      final List<Future<void>> tasks = [];
      for (final ticketRef in resp.value!) {
        final row = byApiId[ticketRef.id];
        if (row == null) continue;
        final model = upsert(ShopInBitOrderModel.fromDriftRow(row));
        tasks.add(refreshOne(model.apiTicketId));
      }
      await Future.wait(tasks);
    } catch (_) {
      // Listeners still see whatever Drift / cache held before.
    }
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
