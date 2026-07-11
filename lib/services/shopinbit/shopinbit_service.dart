import "dart:async";
import "dart:io";

import "package:drift/drift.dart";
import "package:flutter/foundation.dart";

import "../../db/drift/shared_db/shared_database.dart";
import "../../db/drift/shared_db/tables/notifications.dart";
import "../../models/shopinbit/shopinbit_enums.dart";
import "../../utilities/logger.dart";
import "../notifications_api.dart";
import "src/api_response.dart";
import "src/client.dart";
import "src/models/message.dart";
import "src/models/ticket.dart";

/// Display name sent to ShopinBit as `customer_pseudonym`.
const String kShopInBitCustomerPseudonym = "Satoshi";

/// A refresh currently in flight for one ticket. [forced] records whether it
/// will (re)fetch the message list, so a later forced caller knows whether it
/// can safely piggy-back on this one or must run its own forced refresh.
class _InFlightRefresh {
  const _InFlightRefresh(this.completer, this.forced);
  final Completer<void> completer;
  final bool forced;
}

class ShopInBitService {
  ShopInBitService({required this.client, required this.db});

  final ShopInBitClient client;
  final SharedDatabase db;

  final Map<int, _InFlightRefresh> _inFlight = {};

  /// The ticket whose conversation is currently on screen, if any. Kept in
  /// sync by the ticket-detail view with its actual visibility (topmost route,
  /// app foregrounded). A new reply for it skips the system notification and
  /// is recorded already-read — the user is looking right at it.
  int? viewingTicketId;

  // -- Customer key --

  /// Returns the most-recently-used customer key. Generates a new one if
  /// the DB has no settings yet. Always leaves [client] pointing at the
  /// returned key.
  Future<String> ensureCustomerKey() async {
    final ShopInBitSetting? current = await db.shopInBitSettingsDao
        .getCurrentSettings();
    if (current != null) {
      await db.shopInBitSettingsDao.touch(current.customerKey);
      return current.customerKey;
    }
    return generateCustomerKey();
  }

  Future<String> generateCustomerKey() async {
    final ApiResponse<String> resp = await client.generateKey();
    return useCustomerKey(resp.valueOrThrow);
  }

  Future<String> recoverCustomerKey(String key) => useCustomerKey(key);

  /// Switch the active customer key. Tickets for OTHER customer keys stay
  /// in the DB — switching is just a header change plus an upsert into
  /// settings. The UI filters tickets by the active key.
  Future<String> useCustomerKey(String key) async {
    await db.shopInBitSettingsDao.upsert(key);
    return key;
  }

  // -- Refresh --

  /// Refresh every ticket the API reports for the current customer key.
  /// New tickets are hydrated and inserted; existing tickets are patched.
  Future<void> refreshAll() async {
    final String key = await ensureCustomerKey();
    final ApiResponse<List<TicketRef>> resp = await client.getTicketsByCustomer(
      key,
    );
    if (resp.hasError || resp.value == null) {
      Logging.instance.w(
        "ShopInBitService.refreshAll: failed to fetch ticket list",
        error: resp.exception,
      );
      return;
    }
    await Future.wait(
      resp.value!
          .where((e) => !e.isKnownReceipt)
          .map((ref) => _refreshRef(ref, key, false)),
    );
  }

  /// Refresh a single ticket. The row must already exist; use this for
  /// polling and post-action refreshes. For an unknown ticket id, call
  /// [refreshAll] (which has the customer-key context needed to insert).
  Future<void> refreshOne(
    int apiTicketId, {
    bool forceUpdateMessages = false,
  }) async {
    final ShopInBitTicket? existing = await db.shopInBitTicketsDao.getByApiId(
      apiTicketId,
    );
    if (existing == null) return;
    await _refreshRef(
      TicketRef(id: existing.apiTicketId, number: existing.ticketNumber),
      existing.customerKey,
      forceUpdateMessages,
    );
  }

  // -- Actions --

  /// Create a new ticket. We know every required field at this point
  /// (they're the inputs we just sent), so the DB row is inserted
  /// synchronously with full provenance data and an empty conversation;
  /// dynamic fields are then patched in by a background refresh.
  Future<TicketRef?> createRequest({
    required ShopInBitCategory category,
    required String comment,
    required String deliveryCountry,
    String? voucherCode,
  }) async {
    final String key = await ensureCustomerKey();
    final ApiResponse<TicketRef> resp = await client.createRequest(
      customerPseudonym: kShopInBitCustomerPseudonym,
      externalCustomerKey: key,
      serviceType: category.apiValue,
      comment: comment,
      deliveryCountry: deliveryCountry,
      voucherCode: voucherCode,
    );
    if (resp.hasError || resp.value == null) return null;
    final TicketRef ref = resp.value!;

    const ticketState = TicketState.newTicket;
    await db.shopInBitTicketsDao.insertTicket(
      ShopInBitTicketsCompanion.insert(
        apiTicketId: ref.id,
        customerKey: key,
        ticketNumber: ref.number,
        category: category,
        requestDescription: comment,
        deliveryCountry: deliveryCountry,
        status: ShopInBitOrderStatus.fromTicketState(ticketState)!,
        statusRaw: ticketState.value,
      ),
    );

    unawaited(refreshOne(ref.id));
    return ref;
  }

  Future<bool> sendMessage(
    int apiTicketId,
    String message,
    String customerKey, {
    List<File>? attachments,
  }) async {
    final ApiResponse<Map<String, dynamic>> resp =
        attachments != null && attachments.isNotEmpty
        ? await client.sendAttachments(
            apiTicketId,
            message: message,
            customerKey: customerKey,
            attachments: attachments,
          )
        : await client.sendMessage(
            apiTicketId,
            message,
            customerKey: customerKey,
          );
    if (resp.hasError) return false;
    unawaited(refreshOne(apiTicketId, forceUpdateMessages: true));
    return true;
  }

  /// Mark a ticket read, so it stops surfacing as unread. Read state is
  /// local-only and never round-trips to the API. Also clears the ticket's
  /// notification rows so the bell/feed drop it in step with the dot.
  ///
  /// The recorded read time is clamped up to the ticket's own
  /// `lastAgentMessageAt`: unread is derived by comparing that (server-set)
  /// timestamp against lastReadAt, so a client clock lagging real time would
  /// otherwise write a read time earlier than the reply and leave the dot lit
  /// after the user has plainly read it. All times are UTC.
  ///
  /// Best-effort: callers fire-and-forget (poll loop, view dispose), so a DB
  /// failure is logged, not thrown.
  Future<void> markTicketRead(int apiTicketId) async {
    try {
      final ticket = await db.shopInBitTicketsDao.getByApiId(apiTicketId);
      final DateTime now = DateTime.now().toUtc();
      final DateTime? lastAgent = ticket?.lastAgentMessageAt?.toUtc();
      final DateTime readAt = (lastAgent != null && lastAgent.isAfter(now))
          ? lastAgent
          : now;
      await db.shopInBitTicketsDao.markRead(apiTicketId, readAt);
      await db.appNotificationsDao.markReadByTarget(
        AppNotificationType.shopinbit,
        "$apiTicketId",
      );
    } catch (e, s) {
      Logging.instance.w(
        "ShopInBitService.markTicketRead failed",
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Mark the active customer key's ShopinBit notifications read — called when
  /// the user views the notifications list, so the bell/feed clear like the
  /// wallet notifications do. Per-ticket dots (lastReadAt) are untouched.
  ///
  /// Best-effort: callers fire-and-forget from view dispose, so a DB failure
  /// is logged, not thrown as an unhandled async error.
  Future<void> markAllNotificationsRead() async {
    try {
      final settings = await db.shopInBitSettingsDao.getCurrentSettings();
      if (settings == null) return;
      await db.appNotificationsDao.markAllRead(
        type: AppNotificationType.shopinbit,
        scopeId: settings.customerKey,
      );
    } catch (e, s) {
      Logging.instance.w(
        "ShopInBitService.markAllNotificationsRead failed",
        error: e,
        stackTrace: s,
      );
    }
  }

  // -- Internals --

  /// Hydrate-or-update one ticket. Branches on whether the row already
  /// exists: existing rows get a partial patch, brand-new rows are only
  /// inserted if /full, /status, and /messages all succeed (no empty
  /// placeholder rows).
  ///
  /// Concurrent calls for the same ticket id are coalesced onto the
  /// in-flight refresh — later callers await the same completer rather
  /// than kicking off a second round-trip.
  Future<void> _refreshRef(
    TicketRef ref,
    String customerKey,
    bool forceUpdateMessages,
  ) {
    final int id = ref.id;

    final _InFlightRefresh? pending = _inFlight[id];
    if (pending != null) {
      // Join the in-flight refresh only if it will do what we need. An unforced
      // caller is always satisfied; a forced caller is satisfied only if the
      // in-flight refresh is itself forced (it will fetch messages too).
      // Otherwise joining would silently drop our force, so wait for the
      // in-flight one to settle and then run our own forced refresh — a
      // just-sent message MUST actually be fetched, or the view removes its
      // optimistic bubble and the message vanishes until the next refresh.
      if (pending.forced || !forceUpdateMessages) {
        return pending.completer.future;
      }
      return pending.completer.future.then(
        (_) => _refreshRef(ref, customerKey, true),
        onError: (_, _) => _refreshRef(ref, customerKey, true),
      );
    }

    final Completer<void> completer = Completer<void>();
    _inFlight[id] = _InFlightRefresh(completer, forceUpdateMessages);

    // Fire-and-forget: _runRefresh should never throw (it routes errors through
    // the completer), so the unawaited future is safe. Every caller —
    // including the first — awaits the completer, guaranteeing there's a
    // listener for any error.
    unawaited(
      _refreshRefBody(ref, customerKey, forceUpdateMessages, completer),
    );
    return completer.future;
  }

  Future<void> _refreshRefBody(
    TicketRef ref,
    String customerKey,
    bool forceUpdateMessages,
    Completer<void> completer,
  ) async {
    final int id = ref.id;
    try {
      // get status first. If it fails there is no reason to make the remaining
      // two API calls
      final statusResp = await client.getTicketStatus(
        id,
        customerKey: customerKey,
      );

      if (statusResp.exception?.statusCode == 403) {
        Logging.instance.w(
          "$runtimeType._refreshBody status call permission denied. "
          "Ignoring ticket.",
        );
      } else {
        final status = statusResp.valueOrThrow;

        final ShopInBitTicket? existing = await db.shopInBitTicketsDao
            .getByApiId(id);

        final ApiResponse<TicketFull>? fullResp;
        if (existing == null ||
            // status.state.value != existing.statusRaw ||
            status.updatedAt.isAfter(existing.updatedAt)) {
          fullResp = await client.getTicketFull(id, customerKey: customerKey);

          if (kDebugMode) {
            final detail = existing == null
                ? "existing == null"
                : status.state.value != existing.statusRaw
                ? "status.state.value != existing.statusRaw"
                : "status.updatedAt.isAfter(existing.updatedAt)";

            Logging.instance.w(
              "Called getTicketFull($id, customerKey: $customerKey) because: "
              "$detail\n\n"
              "Response: ${fullResp.value ?? fullResp.exception}",
            );
          }
        } else {
          fullResp = null;
        }

        Future<List<TicketMessage>> fetchMessages() async {
          final messagesResp = await client.getMessages(
            id,
            customerKey: customerKey,
          );
          return messagesResp.valueOrThrow;
        }

        if (existing == null) {
          if (fullResp == null) {
            throw Exception("Expected actual ticket full response (not null)");
          }

          await _insertHydrated(
            ref: ref,
            customerKey: customerKey,
            full: fullResp.valueOrThrow,
            status: status,
            messages: await fetchMessages(),
          );
        } else {
          final List<TicketMessage>? messages;

          // Use the same predicate as the notify path (its documented single
          // source of truth): a null stored timestamp with an incoming reply
          // counts as new, so a ticket's FIRST agent reply is fetched — not
          // just bannered — instead of being skipped and never pulled in.
          if (forceUpdateMessages ||
              _hasNewerAgentMessage(existing, status) ||
              existing.messages.isEmpty) {
            messages = await fetchMessages();
            if (kDebugMode) {
              Logging.instance.w(
                "Called fetchMessages for id=${ref.id} "
                "AND number=${ref.number}\n\n"
                "Response: $messages",
              );
            }
          } else {
            messages = null;
          }

          await _patchExisting(
            existing: existing,
            full: fullResp?.value,
            status: status,
            messages: messages,
          );
        }
      }

      completer.complete();
    } catch (e, s) {
      completer.completeError(e, s);
    } finally {
      _inFlight.remove(id);
    }
  }

  Future<void> _insertHydrated({
    required TicketRef ref,
    required String customerKey,
    required TicketFull full,
    required TicketStatus status,
    required List<TicketMessage> messages,
  }) async {
    final ShopInBitOrderStatus? mappedStatus =
        ShopInBitOrderStatus.fromTicketState(status.state);
    if (mappedStatus == null) return;

    final ShopInBitCategory category = _inferCategory(messages);

    await db.shopInBitTicketsDao.insertTicket(
      ShopInBitTicketsCompanion.insert(
        apiTicketId: ref.id,
        customerKey: customerKey,
        ticketNumber: ref.number,
        category: category,
        requestDescription: _extractRequestDescription(messages),
        deliveryCountry: full.deliveryCountry,
        status: mappedStatus,
        statusRaw: status.stateRaw,
        offerProductName: Value(full.productName),
        offerPrice: Value(full.customerPrice),
        paymentInvoiceStatus: Value(status.paymentInvoiceStatus),
        trackingLink: Value(status.trackingLink),
        lastAgentMessageAt: Value(status.lastAgentMessageAt),
        feeTicketNumber: Value(
          category == ShopInBitCategory.car
              ? _extractFeeTicketNumber(messages)
              : null,
        ),
        messages: Value(messages),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Patch path: only touches columns the API actually returned. Stable
  /// provenance fields (category, requestDescription, ticketNumber) are
  /// never overwritten on update — they were authoritative at insert time.
  Future<void> _patchExisting({
    required ShopInBitTicket existing,
    required TicketFull? full,
    required TicketStatus? status,
    required List<TicketMessage>? messages,
  }) async {
    final ShopInBitOrderStatus? mappedStatus = status == null
        ? null
        : ShopInBitOrderStatus.fromTicketState(status.state);

    await db.shopInBitTicketsDao.updateTicket(
      existing.apiTicketId,
      ShopInBitTicketsCompanion(
        // From /status — only patch when we got a recognised state.
        status: mappedStatus == null
            ? const Value.absent()
            : Value(mappedStatus),
        statusRaw: status == null
            ? const Value.absent()
            : Value(status.stateRaw),
        paymentInvoiceStatus: status == null
            ? const Value.absent()
            : Value(status.paymentInvoiceStatus),
        trackingLink: status == null
            ? const Value.absent()
            : Value(status.trackingLink),
        lastAgentMessageAt: status?.lastAgentMessageAt == null
            ? const Value.absent()
            : Value(status!.lastAgentMessageAt),
        deliveryCountry: full == null
            ? const Value.absent()
            : Value(full.deliveryCountry),
        offerProductName: full == null
            ? const Value.absent()
            : Value(full.productName),
        offerPrice: full == null
            ? const Value.absent()
            : Value(full.customerPrice),

        // From /messages.
        messages: messages == null ? const Value.absent() : Value(messages),
        feeTicketNumber: messages == null
            ? const Value.absent()
            : Value(
                existing.category == ShopInBitCategory.car
                    ? _extractFeeTicketNumber(messages)
                    : null,
              ),

        updatedAt: Value(DateTime.now()),
      ),
    );

    await _maybeNotifyNewReply(existing, status);
  }

  static bool _hasNewerAgentMessage(
    ShopInBitTicket existing,
    TicketStatus status,
  ) {
    final DateTime? incoming = status.lastAgentMessageAt;
    if (incoming == null) return false;
    final DateTime? stored = existing.lastAgentMessageAt;
    return stored == null || incoming.isAfter(stored);
  }

  Future<void> _maybeNotifyNewReply(
    ShopInBitTicket existing,
    TicketStatus? status,
  ) async {
    if (status == null || !_hasNewerAgentMessage(existing, status)) return;
    final DateTime newAgentAt = status.lastAgentMessageAt!;
    // A message the user has already read is not news, even when the stored
    // agent timestamp is missing (bare-insert rows, or an API response that
    // omitted the field on an earlier poll).
    final DateTime? lastReadAt = existing.lastReadAt;
    if (lastReadAt != null && !newAgentAt.isAfter(lastReadAt)) return;

    const String title = "ShopinBit";
    final String body = "New reply to request ${existing.ticketNumber}";

    final bool viewing = existing.apiTicketId == viewingTicketId;

    // iconAsset stays null: the card falls back to the ShopinBit brand icon,
    // and not persisting the path means an asset move can't strand old rows.
    await db.appNotificationsDao.add(
      AppNotificationsCompanion.insert(
        type: AppNotificationType.shopinbit,
        title: title,
        body: Value(body),
        scopeId: Value(existing.customerKey),
        targetId: Value("${existing.apiTicketId}"),
        read: Value(viewing),
      ),
    );

    if (viewing) {
      // Mark read here rather than waiting for the detail view's next poll:
      // that poll reads a not-yet-requeried snapshot and would leave the
      // bell/dot lit for a full interval while the user reads the reply.
      await markTicketRead(existing.apiTicketId);
    } else {
      unawaited(NotificationApi.showLocalOnly(title: title, body: body));
    }

    // Keep this scope's notification history bounded now that a row was added.
    await db.appNotificationsDao.pruneScope(
      AppNotificationType.shopinbit,
      existing.customerKey,
    );
  }
}

// -- Message parsers --
//
// All "rich" fields the API doesn't surface directly are parsed from the
// first user message. The car flow seeds the comment with the standard
// "car research fee (#XYZ)" line; travel requests start with
// "Arrangement:" followed by structured labels. If either format changes
// server-side, update these regexes.

final RegExp _kCarResearchFeeRegex = RegExp(r"car research fee \(#([^)]+)\)");
final RegExp _kTravelArrangementRegex = RegExp(
  r"^Arrangement:\s",
  multiLine: true,
);
final RegExp _kHtmlBrRegex = RegExp(r"<br\s*/?>", caseSensitive: false);
final RegExp _kHtmlTagRegex = RegExp(r"<[^>]+>");

TicketMessage? _firstUserMessage(List<TicketMessage> messages) {
  for (final TicketMessage m in messages) {
    if (!m.fromAgent) return m;
  }
  return null;
}

ShopInBitCategory _inferCategory(List<TicketMessage> messages) {
  final TicketMessage? first = _firstUserMessage(messages);
  if (first == null) return ShopInBitCategory.concierge;
  final String content = first.content;
  if (_kCarResearchFeeRegex.hasMatch(content)) return ShopInBitCategory.car;
  if (_kTravelArrangementRegex.hasMatch(content)) {
    return ShopInBitCategory.travel;
  }
  return ShopInBitCategory.concierge;
}

String? _extractFeeTicketNumber(List<TicketMessage> messages) {
  final TicketMessage? first = _firstUserMessage(messages);
  if (first == null) return null;
  return _kCarResearchFeeRegex.firstMatch(first.content)?.group(1);
}

String _extractRequestDescription(List<TicketMessage> messages) {
  final TicketMessage? first = _firstUserMessage(messages);
  if (first == null) return "";
  return first.content
      .replaceAll(_kHtmlBrRegex, "\n")
      .replaceAll(_kHtmlTagRegex, "")
      .trim();
}
