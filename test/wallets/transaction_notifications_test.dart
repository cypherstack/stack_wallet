import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/services/event_bus/events/global/crypto_notification_event.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/wallets/wallet/impl/solana_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';

import '../hive/hive_ce_test_utils.dart';
import '../support/isar_test_utils.dart';

class _Wallet extends Wallet {
  _Wallet() : super(Bitcoin(CryptoCurrencyNetwork.main));

  final transactions = <TransactionV2>[];

  @override
  String get walletId => 'wallet';

  @override
  WalletInfo get info => WalletInfo(
    walletId: walletId,
    name: 'Test wallet',
    mainAddressType: AddressType.p2pkh,
    coinName: 'bitcoin',
  );

  @override
  Future<void> refresh() =>
      updateTransactionsWithNotifications(updateTransactions);

  @override
  Future<void> updateTransactions() async {
    await mainDB.updateOrPutTransactionV2s(transactions);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SolanaParent extends SolanaWallet {
  _SolanaParent() : super(CryptoCurrencyNetwork.main);
  @override
  Future<void> refresh() async {}
}

class _Token extends SolanaTokenWallet {
  _Token()
    : super(
        _SolanaParent(),
        SolContract(
          address: 'mint',
          name: 'USD Coin',
          symbol: 'USDC',
          decimals: 6,
        ),
      );
  final transactions = <TransactionV2>[];
  @override
  String get walletId => 'wallet';
  @override
  WalletInfo get info => _Wallet().info;
  @override
  Future<void> updateBalance() async {}
  @override
  Future<void> updateTransactions() async {
    await mainDB.updateOrPutTransactionV2s(transactions);
  }
}

TransactionV2 transaction(String txid, {String? mint}) => TransactionV2(
  walletId: 'wallet',
  blockHash: null,
  hash: txid,
  txid: txid,
  timestamp: 1,
  height: null,
  inputs: const [],
  outputs: [
    OutputV2.isarCantDoRequiredInDefaultConstructor(
      scriptPubKeyHex: '',
      valueStringSats: '100000000',
      addresses: const ['address'],
      walletOwns: true,
    ),
  ],
  version: 2,
  type: TransactionType.incoming,
  subType: mint == null ? TransactionSubType.none : TransactionSubType.splToken,
  otherData: mint == null ? null : jsonEncode({"contractAddress": mint}),
);

void main() {
  late Directory directory;
  late Isar isar;
  late _Wallet wallet;
  late TransactionNotificationTracker tracker;
  StreamSubscription<CryptoNotificationEvent>? listener;
  final delivered = <String>[];
  final events = <CryptoNotificationEvent>[];

  setUpAll(initializeTestIsar);
  setUp(() async {
    await setUpHiveCeTest();
    await DB.instance.hive.openBox<dynamic>(DB.boxNamePrefs);
    directory = await Directory.systemTemp.createTemp('notification-wallet-');
    isar = await Isar.open([TransactionV2Schema], directory: directory.path);
    await MainDB.instance.initMainDB(mock: isar);
    wallet = _Wallet()..mainDB = MainDB.instance;
    tracker = TransactionNotificationTracker(walletId: wallet.walletId);
    await tracker.markInitialized();
    delivered.clear();
    events.clear();
  });

  tearDown(() async {
    if (listener != null) {
      await listener!.cancel();
      CryptoNotificationsEventBus.unregisterListener();
      listener = null;
    }
    await isar.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
    await tearDownHiveCeTest();
  });

  void listen() {
    listener = CryptoNotificationsEventBus.instance
        .on<CryptoNotificationEvent>()
        .listen((event) {
          events.add(event);
          delivered.add(event.txid!);
          event.completeDelivery();
        });
    CryptoNotificationsEventBus.registerListener();
  }

  test(
    'an overridden refresh retries delivery after the transaction is stored',
    () async {
      wallet.transactions.add(transaction('incoming'));
      await wallet.refresh();
      expect(tracker.pendingTxids, {'incoming'});
      expect(await isar.transactionV2s.count(), 1);

      listen();
      await wallet.refresh();
      expect(delivered, ['incoming']);
      expect(tracker.pendingTxids, isEmpty);

      await wallet.refresh();
      expect(delivered, ['incoming']);
    },
  );

  test(
    'Solana token refresh filters other assets and uses token decimals',
    () async {
      final token = _Token()..mainDB = MainDB.instance;
      final tokenTracker = TransactionNotificationTracker(
        walletId: 'wallet:mint',
      );
      await tokenTracker.markInitialized();
      listen();
      token.transactions.addAll([
        transaction('token', mint: 'mint'),
        transaction('other-token', mint: 'other-mint'),
        transaction('native'),
      ]);
      await token.refresh();
      expect(delivered, ['token']);
      expect(events.single.payload, '100.000000 USDC');
      expect(events.single.title, 'Incoming USD Coin transaction');
      expect(tokenTracker.deliveredTxids, {'token'});
      expect(tracker.deliveredTxids, isEmpty);
    },
  );

  test('concurrent updates deliver each incoming transaction once', () async {
    listen();
    wallet.transactions.add(transaction('incoming'));
    await Future.wait([wallet.refresh(), wallet.refresh()]);
    expect(delivered, ['incoming']);
  });
}
