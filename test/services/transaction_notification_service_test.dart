import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/services/event_bus/events/global/crypto_notification_event.dart';
import 'package:stackwallet/services/transaction_notification_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

class _MemoryNotificationStore implements TransactionNotificationStore {
  _MemoryNotificationStore({this.isInitialized = true});

  @override
  bool isInitialized;

  final Set<String> delivered = {};

  @override
  Set<String> get deliveredTxids => delivered;

  @override
  Future<void> recordDelivered(String txid) async {
    delivered.add(txid);
  }

  @override
  Future<void> markInitialized() async {
    isInitialized = true;
  }
}

TransactionV2 _transaction(
  String txid, {
  TransactionType type = TransactionType.incoming,
  int? height,
}) => TransactionV2(
  walletId: "wallet-id",
  blockHash: null,
  hash: txid,
  txid: txid,
  timestamp: 1,
  height: height,
  inputs: const [],
  outputs: [
    OutputV2.isarCantDoRequiredInDefaultConstructor(
      scriptPubKeyHex: "",
      valueStringSats: "100000000",
      addresses: const ["address"],
      walletOwns: true,
    ),
  ],
  version: 2,
  type: type,
  subType: TransactionSubType.none,
  otherData: null,
);

void main() {
  late Bitcoin bitcoin;
  late List<CryptoNotificationEvent> notifications;

  setUp(() {
    bitcoin = Bitcoin(CryptoCurrencyNetwork.main);
    notifications = [];
  });

  test("keeps only the newest delivered transaction ids", () {
    final result = TransactionNotificationTracker.mergeDeliveredTxids(
      {"oldest": true, "middle": true, "newest": true},
      ["latest"],
      maxEntries: 3,
    );

    expect(result.keys, ["middle", "newest", "latest"]);
  });

  TransactionNotificationService serviceFor(
    TransactionNotificationStore store, {
    CryptoNotificationSink? notificationSink,
  }) => TransactionNotificationService(
    store: store,
    notificationSink:
        notificationSink ??
        (event) async {
          notifications.add(event);
        },
  );

  test("notifies only new incoming transactions", () async {
    final store = _MemoryNotificationStore()..delivered.add("notified");

    await serviceFor(store).notifyNewIncomingTransactions(
      knownTxids: {"known"},
      transactions: [
        _transaction("known"),
        _transaction("outgoing", type: TransactionType.outgoing),
        _transaction("notified"),
        _transaction("new"),
      ],
      coin: bitcoin,
      walletId: "wallet-id",
      walletName: "Bitcoin wallet",
      chainHeight: 10,
      supportsConfirmationUpdates: true,
    );

    expect(notifications.map((event) => event.txid), ["new"]);
    expect(notifications.single.payload, "1.00000000 BTC");
    expect(store.delivered, contains("new"));
  });

  test("first empty-database scan establishes a silent baseline", () async {
    final store = _MemoryNotificationStore(isInitialized: false);

    await serviceFor(store).notifyNewIncomingTransactions(
      knownTxids: {},
      transactions: [
        _transaction("historical-1"),
        _transaction("historical-2"),
      ],
      coin: bitcoin,
      walletId: "wallet-id",
      walletName: "Restored wallet",
      chainHeight: 10,
      supportsConfirmationUpdates: true,
    );

    expect(notifications, isEmpty);
    expect(store.isInitialized, isTrue);
    expect(store.delivered, isEmpty);
  });

  test(
    "upgrade scan still notifies for transactions absent before refresh",
    () async {
      final store = _MemoryNotificationStore(isInitialized: false);

      await serviceFor(store).notifyNewIncomingTransactions(
        knownTxids: {"known"},
        transactions: [_transaction("known"), _transaction("new")],
        coin: bitcoin,
        walletId: "wallet-id",
        walletName: "Existing wallet",
        chainHeight: 10,
        supportsConfirmationUpdates: true,
      );

      expect(notifications.map((event) => event.txid), ["new"]);
      expect(store.isInitialized, isTrue);
    },
  );

  test("records delivery only after the notification succeeds", () async {
    final store = _MemoryNotificationStore();
    final completer = Completer<void>();
    final future =
        serviceFor(
          store,
          notificationSink: (event) {
            notifications.add(event);
            return completer.future;
          },
        ).notifyNewIncomingTransactions(
          knownTxids: const {},
          transactions: [_transaction("new")],
          coin: bitcoin,
          walletId: "wallet-id",
          walletName: "Bitcoin wallet",
          chainHeight: 10,
          supportsConfirmationUpdates: true,
        );

    await Future<void>.delayed(Duration.zero);
    expect(notifications, hasLength(1));
    expect(store.delivered, isEmpty);

    completer.complete();
    await future;
    expect(store.delivered, {"new"});
  });

  test("retries after notification delivery fails", () async {
    final store = _MemoryNotificationStore();
    final service = serviceFor(
      store,
      notificationSink: (_) => Future<void>.error(Exception("delivery")),
    );

    Future<void> notify() => service.notifyNewIncomingTransactions(
      knownTxids: const {},
      transactions: [_transaction("new")],
      coin: bitcoin,
      walletId: "wallet-id",
      walletName: "Bitcoin wallet",
      chainHeight: 10,
      supportsConfirmationUpdates: true,
    );

    await expectLater(notify(), throwsException);
    expect(store.delivered, isEmpty);
    await expectLater(notify(), throwsException);
    expect(store.delivered, isEmpty);
  });

  test("does not record delivery without a registered listener", () async {
    final store = _MemoryNotificationStore();
    final service = TransactionNotificationService(store: store);

    final future = service.notifyNewIncomingTransactions(
      knownTxids: const {},
      transactions: [_transaction("new")],
      coin: bitcoin,
      walletId: "wallet-id",
      walletName: "Bitcoin wallet",
      chainHeight: 10,
      supportsConfirmationUpdates: true,
    );

    await expectLater(future, throwsStateError);
    expect(store.delivered, isEmpty);
  });

  test("watches confirmations only for supported wallets", () async {
    final store = _MemoryNotificationStore();

    await serviceFor(store).notifyNewIncomingTransactions(
      knownTxids: const {},
      transactions: [_transaction("new")],
      coin: bitcoin,
      walletId: "wallet-id",
      walletName: "Bitcoin wallet",
      chainHeight: 10,
      supportsConfirmationUpdates: false,
    );

    expect(notifications.single.shouldWatchForUpdates, isFalse);
  });
}
