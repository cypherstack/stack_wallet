import 'package:drift/drift.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../db/drift/shared_db/tables/shopin_bit_tickets.dart';
import '../../external_api_keys.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../utilities/flutter_secure_storage_interface.dart';
import '../../utilities/logger.dart';
import 'src/client.dart';
import 'src/models/message.dart';
import 'src/models/ticket.dart';

const _kShopinBitCustomerKeyKeySecureStore = "shopinBitSecStoreCustomerKeyKey";

class ShopInBitService {
  SecureStorageInterface? _secureStorageInterface;

  SecureStorageInterface get _secure {
    if (_secureStorageInterface == null) {
      throw Exception(
        "Did you forget to call ShopInBitService.ensureInitialized()?",
      );
    }
    return _secureStorageInterface!;
  }

  /// If secure storage was already set, this function will do nothing
  void ensureInitialized(SecureStorageInterface secureStore) {
    _secureStorageInterface ??= secureStore;
  }

  ShopInBitClient? _client;
  ShopInBitClient get client {
    _client ??= ShopInBitClient(
      accessKey: kShopInBitAccessKey,
      partnerSecret: kShopInBitPartnerSecret,
      sandbox: true,
    );
    return _client!;
  }

  Future<String?> loadCustomerKey() =>
      _secure.read(key: _kShopinBitCustomerKeyKeySecureStore);

  Future<String> ensureCustomerKey() async {
    final currentKey = await loadCustomerKey();

    if (currentKey != null) {
      Logging.instance.t("ShopInBitService: loaded customer key from DB");
      client.externalCustomerKey = currentKey;
      return currentKey;
    }
    Logging.instance.i("ShopInBitService: generating new customer key");
    final resp = await client.generateKey();
    final customerKey = resp.valueOrThrow;
    await setCustomerKey(customerKey);
    Logging.instance.i("ShopInBitService: customer key stored");
    return customerKey;
  }

  Future<void> setCustomerKey(String key) async {
    await _secure.write(key: _kShopinBitCustomerKeyKeySecureStore, value: key);
    client.externalCustomerKey = key;
    Logging.instance.i("ShopInBitService: customer key stored");
  }

  Future<void> clearCustomerKey() async {
    client.externalCustomerKey = null;
    await _secure.delete(key: _kShopinBitCustomerKeyKeySecureStore);
    Logging.instance.i("ShopInBitService: customer key cleared");
  }

  /// Fetch the customer's tickets from the API and build companions for any
  /// that aren't already in the local database. Used to backfill rows for
  /// tickets created out-of-band (other devices, web dashboard, etc.).
  Future<List<ShopInBitTicketsCompanion>> fetchAllForCustomerKey(
    String customerKey,
  ) async {
    final resp = await client.getTicketsByCustomer(customerKey);
    if (resp.hasError || resp.value == null) {
      Logging.instance.w(
        "ShopInBitService.fetchAllForCustomerKey: getTicketsByCustomer failed: "
        "${resp.exception?.message}",
      );
      return const [];
    }

    final db = SharedDrift.get();
    final localRows = await db.select(db.shopInBitTickets).get();
    final knownApiIds = localRows.map((r) => r.apiTicketId).toSet();

    final newRefs = resp.value!
        .where((r) => !knownApiIds.contains(r.id))
        .toList();
    if (newRefs.isEmpty) return const [];

    // Hydrate per-ticket in parallel. status + messages are exempt from the
    // 60 req/min rate limit per the API spec; getTicketFull is only called
    // for tickets whose state maps to offerAvailable.
    final results = await Future.wait(newRefs.map(_hydrateNewTicket));
    return results.whereType<ShopInBitTicketsCompanion>().toList();
  }

  Future<ShopInBitTicketsCompanion?> _hydrateNewTicket(TicketRef ref) async {
    try {
      final statusFuture = client.getTicketStatus(ref.id);
      final messagesFuture = client.getMessages(ref.id);
      final statusResp = await statusFuture;
      final messagesResp = await messagesFuture;

      if (statusResp.hasError || statusResp.value == null) {
        Logging.instance.w(
          "ShopInBitService.fetchAllForCustomerKey: status failed for "
          "${ref.id}: ${statusResp.exception?.message}",
        );
        return null;
      }

      final apiMessages = messagesResp.value ?? const <TicketMessage>[];

      final mappedStatus =
          ShopInBitOrderModel.statusFromTicketState(statusResp.value!.state) ??
          ShopInBitOrderStatus.pending;

      String? offerProductName;
      String? offerPrice;
      if (mappedStatus == ShopInBitOrderStatus.offerAvailable) {
        final fullResp = await client.getTicketFull(ref.id);
        if (!fullResp.hasError && fullResp.value != null) {
          offerProductName = fullResp.value!.productName;
          offerPrice = fullResp.value!.customerPrice;
        }
      }

      final category = _inferCategoryFromMessages(apiMessages);
      final feeTicketNumber = category == ShopInBitCategory.car
          ? _extractFeeTicketNumber(apiMessages)
          : null;
      final requestDescription = _extractRequestDescription(apiMessages);

      final messages = apiMessages
          .map(
            (m) => ShopInBitTicketMessage(
              text: m.content,
              timestamp: m.timestamp,
              isFromUser: !m.fromAgent,
            ),
          )
          .toList();

      return ShopInBitTicketsCompanion(
        ticketId: Value(ref.number),
        displayName: const Value(""),
        category: Value(category),
        status: Value(mappedStatus),
        statusRaw: Value(statusResp.value!.stateRaw),
        requestDescription: Value(requestDescription),
        deliveryCountry: const Value(""),
        offerProductName: Value(offerProductName),
        offerPrice: Value(offerPrice),
        shippingName: const Value(""),
        shippingStreet: const Value(""),
        shippingCity: const Value(""),
        shippingPostalCode: const Value(""),
        shippingCountry: const Value(""),
        messages: Value(messages),
        createdAt: Value(DateTime.now()),
        apiTicketId: Value(ref.id),
        feeTicketNumber: Value(feeTicketNumber),
        needsCreateRequest: const Value(false),
        isPendingPayment: const Value(false),
      );
    } catch (e, s) {
      Logging.instance.e(
        "ShopInBitService.fetchAllForCustomerKey: hydrate failed for ${ref.id}",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}

// Infer category from the first user message.  The car flow always seeds
// the comment with the "car research fee" line; travel requests built by
// _buildRequestDescription always start with "Arrangement: " followed by
// structured labels. Both are fragile against template changes in the form.
final RegExp _kCarResearchFeeRegex = RegExp(r'car research fee \(#([^)]+)\)');
final RegExp _kTravelArrangementRegex = RegExp(
  r'^Arrangement:\s',
  multiLine: true,
);

ShopInBitCategory _inferCategoryFromMessages(List<TicketMessage> messages) {
  final firstUser = messages.where((m) => !m.fromAgent).firstOrNull;
  if (firstUser == null) return ShopInBitCategory.concierge;
  final content = firstUser.content;
  if (_kCarResearchFeeRegex.hasMatch(content)) {
    return ShopInBitCategory.car;
  }
  if (_kTravelArrangementRegex.hasMatch(content)) {
    return ShopInBitCategory.travel;
  }
  return ShopInBitCategory.concierge;
}

String? _extractFeeTicketNumber(List<TicketMessage> messages) {
  final firstUser = messages.where((m) => !m.fromAgent).firstOrNull;
  if (firstUser == null) return null;
  return _kCarResearchFeeRegex.firstMatch(firstUser.content)?.group(1);
}

// The original `comment` passed to POST /requests becomes the first user message.
final RegExp _kHtmlTagRegex = RegExp(r'<[^>]+>');

String _extractRequestDescription(List<TicketMessage> messages) {
  final firstUser = messages.where((m) => !m.fromAgent).firstOrNull;
  if (firstUser == null) return "";
  return firstUser.content
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(_kHtmlTagRegex, '')
      .trim();
}
