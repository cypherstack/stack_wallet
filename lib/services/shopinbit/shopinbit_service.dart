import "dart:async";

import "package:drift/drift.dart";

import "../../db/drift/shared_db/shared_database.dart";
import "../../models/shopinbit/shopinbit_enums.dart";
import "../../utilities/logger.dart";
import "src/api_response.dart";
import "src/client.dart";
import "src/models/message.dart";
import "src/models/ticket.dart";

/// Display name sent to ShopinBit as `customer_pseudonym`.
const String kShopInBitCustomerPseudonym = "Satoshi";

class ShopInBitService {
  ShopInBitService({required this.client, required this.db});

  final ShopInBitClient client;
  final SharedDatabase db;

  final Map<int, Completer<void>> _inFlight = {};

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
          .map((ref) => _refreshRef(ref, key)),
    );
  }

  /// Refresh a single ticket. The row must already exist; use this for
  /// polling and post-action refreshes. For an unknown ticket id, call
  /// [refreshAll] (which has the customer-key context needed to insert).
  Future<void> refreshOne(int apiTicketId) async {
    final ShopInBitTicket? existing = await db.shopInBitTicketsDao.getByApiId(
      apiTicketId,
    );
    if (existing == null) return;
    await _refreshRef(
      TicketRef(id: existing.apiTicketId, number: existing.ticketNumber),
      existing.customerKey,
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
    String customerKey,
  ) async {
    final ApiResponse<Map<String, dynamic>> resp = await client.sendMessage(
      apiTicketId,
      message,
      customerKey: customerKey,
    );
    if (resp.hasError) return false;
    unawaited(refreshOne(apiTicketId));
    return true;
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
  Future<void> _refreshRef(TicketRef ref, String customerKey) {
    final int id = ref.id;

    final Completer<void>? pending = _inFlight[id];
    if (pending != null) return pending.future;

    final Completer<void> completer = Completer<void>();
    _inFlight[id] = completer;

    // Fire-and-forget: _runRefresh should never throw (it routes errors through
    // the completer), so the unawaited future is safe. Every caller —
    // including the first — awaits the completer, guaranteeing there's a
    // listener for any error.
    unawaited(_refreshRefBody(ref, customerKey, completer));
    return completer.future;
  }

  Future<void> _refreshRefBody(
    TicketRef ref,
    String customerKey,
    Completer<void> completer,
  ) async {
    final int id = ref.id;
    try {
      final ShopInBitTicket? existing = await db.shopInBitTicketsDao.getByApiId(
        id,
      );

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
        final ApiResponse<TicketFull>? fullResp;
        final ApiResponse<List<TicketMessage>> messagesResp;
        (fullResp, messagesResp) = await (
          existing == null
              ? client.getTicketFull(id, customerKey: customerKey)
              : (() async => null)(),
          client.getMessages(id, customerKey: customerKey),
        ).wait;

        if (existing == null) {
          await _insertHydrated(
            ref: ref,
            customerKey: customerKey,
            full: fullResp?.value,
            status: statusResp.value,
            messages: messagesResp.value,
          );
        } else {
          await _patchExisting(
            existing: existing,
            full: fullResp?.value,
            status: statusResp.value,
            messages: messagesResp.value,
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

  /// Insert path: every required field must resolve to a real value. If
  /// any of /full, /status, or /messages failed we bail rather than write
  /// a half-populated row.
  Future<void> _insertHydrated({
    required TicketRef ref,
    required String customerKey,
    required TicketFull? full,
    required TicketStatus? status,
    required List<TicketMessage>? messages,
  }) async {
    if (full == null || status == null || messages == null) return;

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
        lastAgentMessageAt: status == null
            ? const Value.absent()
            : Value(status.lastAgentMessageAt),
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
