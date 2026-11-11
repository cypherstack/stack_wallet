import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_service.dart';
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
}

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

  /// Watches one transaction of a Bitcoin wallet whose primary node is
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
      await server.close();
      await tearDownHiveCeTest();
    });
    NotificationsService.notificationRefreshInterval = const Duration(
      milliseconds: 50,
    );
    notifications.startCheckingWatchedNotifications();
    return (service: service, node: node);
  }

  test('Forget retires a pending background notification connection', () async {
    final server = await TlsElectrumServer.start(respond: false);
    final (:service, :node) = await watch(server);
    final notifications = NotificationsService.instance;
    await _until(
      () => server.methods.contains('server.version'),
      'notification RPC setup',
    );
    notifications.stopCheckingWatchedTransactions();
    expect(server.disconnections, 0);
    await service.save(
      NodeModel.fromStackBackup({
        ...node.toMap(),
        'id': 'other-coin',
        'coinName': 'litecoin',
      }),
      null,
      true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      server.disconnections,
      0,
      reason: 'unrelated node changes keep the connection',
    );
    await service.forgetTrustedCertificate(node);
    await _until(
      () => server.disconnections > 0,
      'Forget to disconnect the notification',
    );
    expect(
      DB.instance.hive
          .box<NodeModel>(DB.boxNameNodeModels)
          .get(node.id)!
          .trustedCertificatePem,
      null,
    );
    expect(server.methods, isNot(contains('blockchain.transaction.get')));
  });

  test('a finished notification check closes its own connection', () async {
    final server = await TlsElectrumServer.start();
    await watch(server);
    await _until(
      () => server.methods.contains('blockchain.transaction.get'),
      'the notification check',
    );
    await _until(
      () => server.disconnections == server.accepted,
      'the check to close its connection',
    );
    NotificationsService.instance.stopCheckingWatchedTransactions();
    expect(server.accepted, greaterThanOrEqualTo(1));
  });
}
