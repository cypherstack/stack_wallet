import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_service.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

import '../hive/hive_ce_test_utils.dart';
import '../utilities/tls_test_server.dart';

class _Wallet extends Fake implements ElectrumXInterface<Bitcoin> {
  @override
  String get walletId => 'watched-wallet';
  @override
  Bitcoin get cryptoCurrency => Bitcoin(CryptoCurrencyNetwork.main);
  @override
  late ElectrumXClient electrumXClient;
}

class _Tor extends Fake implements TorService {}

class _Prefs extends Fake implements Prefs {
  @override
  bool get useTor => false;
  @override
  bool get wifiOnly => false;
  @override
  bool get externalCalls => false;
}

class _Trades extends Fake implements TradesService {}

Future<void> _until(bool Function() done, String waitingFor) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > const Duration(seconds: 2)) {
      fail('Timed out waiting for $waitingFor');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory logs;
  setUpAll(() async {
    logs = await Directory.systemTemp.createTemp('notification_tls');
    await Logging.instance.initialize(logs.path, level: Level.off);
  });
  tearDownAll(() => logs.delete(recursive: true));

  /// Watches two transactions of a Bitcoin wallet whose primary node is
  /// [server], checking every 50ms until the test stops it.
  Future<({NodeService service, NodeModel node})> watch(
    TlsElectrumServer server,
  ) async {
    await setUpHiveCeTest();
    final nodeAdapter = NodeModelAdapter();
    if (!DB.instance.hive.isAdapterRegistered(nodeAdapter.typeId)) {
      DB.instance.hive.registerAdapter(nodeAdapter);
    }
    final notificationAdapter = NotificationModelAdapter();
    if (!DB.instance.hive.isAdapterRegistered(notificationAdapter.typeId)) {
      DB.instance.hive.registerAdapter(notificationAdapter);
    }
    final nodes = await DB.instance.hive.openBox<NodeModel>(
      DB.boxNameNodeModels,
    );
    final watched = await DB.instance.hive.openBox<NotificationModel>(
      DB.boxNameWatchedTransactions,
    );
    final wallet = _Wallet();
    final coin = wallet.cryptoCurrency;
    final node = NodeModel(
      id: 'n',
      host: '127.0.0.1',
      port: server.port,
      name: 'Node',
      useSSL: true,
      enabled: true,
      coinName: coin.identifier,
      isFailover: false,
      isDown: false,
      torEnabled: true,
      clearnetEnabled: true,
      isPrimary: true,
      trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
    );
    await nodes.put(node.id, node);
    await watched.put(
      0,
      NotificationModel(
        id: 0,
        title: 'Transaction (0/${coin.minConfirms})',
        description: '',
        iconAssetName: '',
        date: DateTime.now(),
        walletId: wallet.walletId,
        read: false,
        shouldWatchForUpdates: true,
        txid: 'a' * 64,
        coinName: coin.identifier,
      ),
    );
    await watched.put(
      1,
      NotificationModel(
        id: 1,
        title: 'Transaction (0/${coin.minConfirms})',
        description: '',
        iconAssetName: '',
        date: DateTime.now(),
        walletId: wallet.walletId,
        read: false,
        shouldWatchForUpdates: true,
        txid: 'b' * 64,
        coinName: coin.identifier,
      ),
    );
    final client = ElectrumXClient.from(
      node: ElectrumXNode(
        address: node.host,
        port: node.port,
        name: node.name,
        id: node.id,
        useSSL: true,
        trustedCertificatePem: node.trustedCertificatePem,
        torEnabled: true,
        clearnetEnabled: true,
      ),
      prefs: _Prefs(),
      torService: _Tor(),
      failovers: const [],
      cryptoCurrency: coin,
    );
    wallet.electrumXClient = client;
    // The shared registry keeps the wallet added by an earlier test.
    if (!Wallets.sharedInstance.wallets.any(
      (e) => e.walletId == wallet.walletId,
    )) {
      Wallets.sharedInstance.addWallet(wallet);
    }
    final service = NodeService(secureStorageInterface: FakeSecureStorage());
    final notifications = NotificationsService.instance;
    await notifications.init(
      nodeService: service,
      tradesService: _Trades(),
      prefs: _Prefs(),
    );
    final interval = NotificationsService.notificationRefreshInterval;
    addTearDown(() async {
      notifications.stopCheckingWatchedTransactions();
      NotificationsService.notificationRefreshInterval = interval;
      await client.closeAdapter();
      await server.close();
      await tearDownHiveCeTest();
    });
    NotificationsService.notificationRefreshInterval = const Duration(
      milliseconds: 50,
    );
    notifications.startCheckingWatchedNotifications();
    return (service: service, node: node);
  }

  test('notification checks use the wallet connection', () async {
    // A node or approval change replaces the wallet's client through
    // updateNode(), so the checks need no connection of their own.
    final server = await TlsElectrumServer.start();
    await watch(server);
    await _until(
      () =>
          server.methods
              .where((method) => method == 'blockchain.transaction.get')
              .length >=
          2,
      'both watched transactions to be checked',
    );
    NotificationsService.instance.stopCheckingWatchedTransactions();
    expect(server.accepted, 1);
    expect(server.disconnections, 0);
  });
}
