import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/db/sqlite/firo_cache.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/electrumx_response/spark_models.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/spark_coin.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';

import '../support/isar_test_utils.dart';

class _Client extends Mock implements ElectrumXClient {
  final started = Completer<void>();
  final pendingTags = Completer<List<List<dynamic>>>();
  int tagRequests = 0;
  @override
  Future<int> getSparkLatestCoinId({String? requestID}) async => 1;
  @override
  Future<SparkAnonymitySetMeta> getSparkAnonymitySetMeta({
    String? requestID,
    required int coinGroupId,
  }) async => SparkAnonymitySetMeta(
    coinGroupId: coinGroupId,
    blockHash: 'block',
    setHash: 'set',
    size: 0,
  );
  @override
  Future<List<List<dynamic>>> getSparkUnhashedUsedCoinsTagsWithTxHashes({
    String? requestID,
    required int startNumber,
  }) {
    tagRequests++;
    if (tagRequests == 1) {
      started.complete();
      return pendingTags.future;
    }
    return Future.value([]);
  }

  @override
  Future<Set<String>> getMempoolTxids({String? requestID}) async => {};
}

class _ResettingClient extends _Client {
  @override
  Future<List<List<dynamic>>> getSparkUnhashedUsedCoinsTagsWithTxHashes({
    String? requestID,
    required int startNumber,
  }) async {
    tagRequests++;
    // Every batch is retired by another shared reset before it lands.
    await FiroCacheCoordinator.clearSharedCache(
      CryptoCurrencyNetwork.main,
      clearOnlyUsedTagsCache: true,
    );
    return [];
  }
}

class _Wallet extends FiroWallet {
  _Wallet(_Client client) : super(CryptoCurrencyNetwork.main) {
    mainDB = MainDB.instance;
    electrumXClient = client;
  }
  @override
  String get walletId => 'firo-reset-refresh';
  @override
  WalletInfo get info => mainDB.isar.walletInfo.getByWalletIdSync(walletId)!;
  @override
  bool get isViewOnly => false;
  @override
  Future<int> get chainHeight async => 1000;
  @override
  Future<void> updateChainHeight() async {}
  @override
  Future<void> checkReceivingAddressForTransactions() async {}
  @override
  Future<void> checkChangeAddressForTransactions() async {}
  @override
  Future<void> updateTransactions() async {}
  @override
  Future<bool> updateUTXOs() async => false;
  @override
  Future<void> updateBalance() async {}
  @override
  Future<void> refreshSparkNames() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Isar isar;
  setUpAll(() async {
    await initializeTestIsar();
    root = await Directory.systemTemp.createTemp('firo-wallet-reset-');
    StackFileSystem.setDesktopOverrideDir(root.path);
    await FiroCacheCoordinator.init();
  });
  setUp(() async {
    isar = await Isar.open(
      [WalletInfoSchema, SparkCoinSchema],
      directory: root.path,
      name: 'firo-wallet-reset',
      inspector: false,
    );
    await MainDB.instance.initMainDB(mock: isar);
    await isar.writeTxn(
      () => isar.walletInfo.put(
        WalletInfo(
          walletId: 'firo-reset-refresh',
          name: 'Firo fixture',
          coinName: 'firo',
          mainAddressType: AddressType.p2pkh,
        ),
      ),
    );
    await FiroCacheCoordinator.clearSharedCache(CryptoCurrencyNetwork.main);
  });
  tearDown(() => isar.close(deleteFromDisk: true));
  tearDownAll(() async {
    await FiroCacheCoordinator.close();
    await root.delete(recursive: true);
  });
  for (final tagsOnly in [false, true]) {
    test(
      'cache reset retries real wallet refresh without disconnecting tagsOnly=$tagsOnly',
      () async {
        final client = _Client();
        final wallet = _Wallet(client);
        final statuses = <WalletSyncStatus>[];
        final connections = <NodeConnectionStatus>[];
        final sync = GlobalEventBus.instance
            .on<WalletSyncStatusChangedEvent>()
            .listen((e) => statuses.add(e.newStatus));
        final connection = GlobalEventBus.instance
            .on<NodeConnectionStatusChangedEvent>()
            .listen((e) => connections.add(e.newStatus));
        addTearDown(sync.cancel);
        addTearDown(connection.cancel);
        final refresh = wallet.refresh();
        await client.started.future.timeout(const Duration(seconds: 5));
        await FiroCacheCoordinator.clearSharedCache(
          CryptoCurrencyNetwork.main,
          clearOnlyUsedTagsCache: tagsOnly,
        ).timeout(const Duration(seconds: 3));
        await refresh.timeout(const Duration(seconds: 5));
        await Future<void>.delayed(Duration.zero);
        expect(client.tagRequests, 2);
        expect(statuses, [WalletSyncStatus.syncing, WalletSyncStatus.synced]);
        expect(connections, isNot(contains(NodeConnectionStatus.disconnected)));
        client.pendingTags.completeError(StateError('late retired response'));
        await Future<void>.delayed(Duration.zero);
      },
    );
  }
  test('a real node error still reports unable to sync', () async {
    final client = _Client();
    final wallet = _Wallet(client);
    final statuses = <WalletSyncStatus>[];
    final subscription = GlobalEventBus.instance
        .on<WalletSyncStatusChangedEvent>()
        .listen((e) => statuses.add(e.newStatus));
    addTearDown(subscription.cancel);
    final refresh = wallet.refresh();
    await client.started.future.timeout(const Duration(seconds: 5));
    client.pendingTags.completeError(const SocketException('node unavailable'));
    await refresh.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);
    expect(statuses, [WalletSyncStatus.syncing, WalletSyncStatus.unableToSync]);
    expect(client.tagRequests, 1);
  });

  test('repeated resets stop retrying and report a failed refresh', () async {
    final client = _ResettingClient();
    final wallet = _Wallet(client);
    final statuses = <WalletSyncStatus>[];
    final subscription = GlobalEventBus.instance
        .on<WalletSyncStatusChangedEvent>()
        .listen((e) => statuses.add(e.newStatus));
    addTearDown(subscription.cancel);
    await wallet.refresh().timeout(const Duration(seconds: 10));
    await Future<void>.delayed(Duration.zero);
    expect(client.tagRequests, SparkInterface.maxSparkRefreshResetRetries + 1);
    expect(statuses, [WalletSyncStatus.syncing, WalletSyncStatus.unableToSync]);
  });
}
