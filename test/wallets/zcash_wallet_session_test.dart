import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_account_session.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../support/isar_test_utils.dart';
import 'support/xelis_test_fakes.dart';

class MutableZcashNodes extends Fake implements NodeService {
  MutableZcashNodes(this.primary);

  NodeModel primary;

  @override
  NodeModel? getPrimaryNodeFor({required CryptoCurrency currency}) => primary;
}

class WalletSessionClient implements ZcashLightwalletdClient {
  WalletSessionClient({
    required this.chainName,
    required this.tipHeight,
    this.beforeTipReturn,
  });

  final String chainName;
  final int tipHeight;
  final Future<void> Function()? beforeTipReturn;
  int infoCalls = 0;
  int tipCalls = 0;
  int closeCalls = 0;

  @override
  Future<zcash.LightdInfo> getInfo() async {
    infoCalls++;
    return zcash.LightdInfo(chainName: chainName);
  }

  @override
  Future<int> getTipHeight() async {
    tipCalls++;
    await beforeTipReturn?.call();
    return tipHeight;
  }

  @override
  Future<void> close() async {
    closeCalls++;
  }
}

class SyncWalletSessionClient extends WalletSessionClient
    implements ZcashLightwalletdSyncClient, ZcashLightwalletdTransparentClient {
  SyncWalletSessionClient({
    required super.chainName,
    required super.tipHeight,
    this.transparentValueZatoshis = 0,
  });

  final int transparentValueZatoshis;
  bool failTip = false;
  int treeStateCalls = 0;
  int transparentRefreshCalls = 0;
  int? receivedMaxRangeSize;
  int? receivedMaxUtxos;
  List<String>? queriedTransparentAddresses;
  String transparentTipHash = '44' * 32;

  @override
  Future<zcash.ZcashTransparentRefresh> getTransparentRefresh(
    zcash.ZcashTransparentState state, {
    int maxRangeSize = 1000,
    int maxUtxos = 10000,
  }) async {
    transparentRefreshCalls++;
    receivedMaxRangeSize = maxRangeSize;
    receivedMaxUtxos = maxUtxos;
    queriedTransparentAddresses = state.addresses;
    final address = state.addresses.single;
    return zcash.ZcashTransparentRefresh(
      network: state.network,
      accountFingerprint: state.accountFingerprint,
      queriedAddresses: [address],
      chainHeight: tipHeight,
      chainTipHash: transparentTipHash,
      canonicalBlockHashes: {tipHeight: transparentTipHash},
      unspentOutputs: [
        if (transparentValueZatoshis > 0)
          zcash.ZcashTransparentOutputObservation(
            address: address,
            protocolTxid: '11' * 32,
            outputIndex: 0,
            scriptHex: '51',
            valueZatoshis: transparentValueZatoshis,
            minedHeight: tipHeight,
            blockHash: transparentTipHash,
            blockTime: 1700000000,
            creationFeeZatoshis: 1000,
            isCoinbase: false,
          ),
      ],
      observedSpends: const [],
    );
  }

  @override
  Future<int> getTipHeight() {
    if (failTip) throw StateError('test tip failure');
    return super.getTipHeight();
  }

  @override
  Future<String?> getBlockHash(int height) async => null;

  @override
  Future<zcash.ZcashLightwalletdScanSource> getBlockRange(int start, int end) =>
      throw StateError('caught-up fixture must not request blocks');

  @override
  Future<zcash.TreeState> getTreeState(int height) async {
    treeStateCalls++;
    return zcash.TreeState(
      hash: '0000000000000000000000000000000000000000000000000000000000000000',
      height: height,
      time: 1,
    );
  }
}

NodeModel walletNode({required String host, required String id}) => NodeModel(
  host: host,
  port: 443,
  name: id,
  id: id,
  useSSL: true,
  enabled: true,
  coinName: 'zcash',
  isFailover: false,
  isDown: false,
  torEnabled: false,
  clearnetEnabled: true,
  isPrimary: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestIsar);
  late Directory root;

  setUpAll(() async {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      throw UnsupportedError('Run this storage scenario on a desktop host.');
    }
    root = await Directory.systemTemp.createTemp('stack_zcash_session_');
    StackFileSystem.setDesktopOverrideDir(root.path);
  });
  tearDownAll(() => root.delete(recursive: true));

  setUp(() async {
    await MainDB.instance.initMainDB();
    addTearDown(() async {
      if (MainDB.instance.isar.isOpen) await MainDB.instance.isar.close();
    });
  });

  test(
    'new wallet persists the validated next lightwalletd height before sync',
    () async {
      final node = walletNode(host: 'https://birthday.example', id: 'birthday');
      final client = SyncWalletSessionClient(chainName: 'main', tipHeight: 42);
      final wallet = await Wallet.create(
        walletInfo: WalletInfo(
          walletId: 'zcash-new-wallet-birthday',
          name: 'Zcash birthday fixture',
          mainAddressType: AddressType.zcashUnified,
          coinName: 'zcash',
        ),
        mainDB: MainDB.instance,
        secureStorageInterface: MemorySecrets(),
        nodeService: MutableZcashNodes(node),
        prefs: SessionPrefs(),
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon about',
        mnemonicPassphrase: '',
      ) as ZcashWallet;
      wallet.configureAccountSessionFactory(
        (network) =>
            ZcashAccountSession(network: network, clientFactory: (_) => client),
      );

      await wallet.init(isRestore: false);

      expect(wallet.info.restoreHeight, 43);
      expect(
        (await MainDB.instance.isar.walletInfo
                .where()
                .walletIdEqualTo(wallet.walletId)
                .findFirst())
            ?.restoreHeight,
        43,
      );
      expect(client.treeStateCalls, 1);
      await wallet.exit();
    },
  );

  test(
    'restore without a positive birthday fails before node access',
    () async {
      final node = walletNode(host: 'https://restore.example', id: 'restore');
      final client = SyncWalletSessionClient(chainName: 'main', tipHeight: 42);
      final wallet = await Wallet.create(
        walletInfo: WalletInfo(
          walletId: 'zcash-missing-restore-birthday',
          name: 'Zcash missing birthday fixture',
          mainAddressType: AddressType.zcashUnified,
          coinName: 'zcash',
        ),
        mainDB: MainDB.instance,
        secureStorageInterface: MemorySecrets(),
        nodeService: MutableZcashNodes(node),
        prefs: SessionPrefs(),
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon about',
        mnemonicPassphrase: '',
      ) as ZcashWallet;
      wallet.configureAccountSessionFactory(
        (network) =>
            ZcashAccountSession(network: network, clientFactory: (_) => client),
      );

      await expectLater(
        wallet.init(isRestore: true),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('explicit positive block height'),
          ),
        ),
      );

      expect(client.infoCalls, 0);
      expect(client.tipCalls, 0);
      expect(client.closeCalls, 0);
      await wallet.exit();
    },
  );

  test('new wallet rejects an out-of-range lightwalletd tip', () async {
    final node = walletNode(host: 'https://invalid-tip.example', id: 'bad-tip');
    final client = SyncWalletSessionClient(chainName: 'main', tipHeight: -1);
    final wallet = await Wallet.create(
      walletInfo: WalletInfo(
        walletId: 'zcash-invalid-tip-birthday',
        name: 'Zcash invalid tip fixture',
        mainAddressType: AddressType.zcashUnified,
        coinName: 'zcash',
      ),
      mainDB: MainDB.instance,
      secureStorageInterface: MemorySecrets(),
      nodeService: MutableZcashNodes(node),
      prefs: SessionPrefs(),
      mnemonic:
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about',
      mnemonicPassphrase: '',
    ) as ZcashWallet;
    wallet.configureAccountSessionFactory(
      (network) =>
          ZcashAccountSession(network: network, clientFactory: (_) => client),
    );

    await expectLater(
      wallet.init(isRestore: false),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('lightwalletd tip must be between'),
        ),
      ),
    );

    expect(wallet.info.restoreHeight, 0);
    expect(client.closeCalls, 1);
    await wallet.exit();
    expect(client.closeCalls, 1);
  });

  test(
    'wallet init, updateNode, ping, and exit own one account session',
    () async {
      final firstNode = walletNode(host: 'https://first.example', id: 'first');
      final secondNode = walletNode(
        host: 'https://second.example',
        id: 'second',
      );
      final nodes = MutableZcashNodes(firstNode);
      final clients = [
        WalletSessionClient(chainName: 'main', tipHeight: 42),
        WalletSessionClient(chainName: 'main', tipHeight: 43),
      ];
      final openedEndpoints = <ZcashEndpoint>[];

      final wallet = await Wallet.create(
        walletInfo: WalletInfo(
          walletId: 'zcash-session',
          name: 'Zcash session fixture',
          mainAddressType: AddressType.zcashUnified,
          coinName: 'zcash',
          restoreHeight: 1,
        ),
        mainDB: MainDB.instance,
        secureStorageInterface: MemorySecrets(),
        nodeService: nodes,
        prefs: SessionPrefs(),
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon about',
        mnemonicPassphrase: '',
      ) as ZcashWallet;
      wallet.configureAccountSessionFactory(
        (network) => ZcashAccountSession(
          network: network,
          clientFactory: (endpoint) {
            openedEndpoints.add(endpoint);
            return clients[openedEndpoints.length - 1];
          },
          requestTimeout: const Duration(milliseconds: 100),
        ),
      );

      await wallet.init(isRestore: true);
      expect(wallet.accountSessionGeneration, 1);
      expect(openedEndpoints.single.host, 'first.example');
      expect(await wallet.pingCheck(), isTrue);
      expect(clients.first.infoCalls, 2);
      expect(clients.first.tipCalls, 2);

      nodes.primary = secondNode;
      await wallet.updateNode();
      expect(wallet.accountSessionGeneration, 2);
      expect(openedEndpoints.last.host, 'second.example');
      expect(clients.first.closeCalls, 1);
      expect(await wallet.pingCheck(), isTrue);

      await wallet.exit();
      await wallet.exit();
      expect(clients.first.closeCalls, 1);
      expect(clients.last.closeCalls, 1);
    },
  );

  test('init failure after readiness closes the account session', () async {
    final nodes = MutableZcashNodes(
      walletNode(host: 'https://ready.example', id: 'ready'),
    );
    final client = WalletSessionClient(
      chainName: 'main',
      tipHeight: 42,
      beforeTipReturn: () async {
        await MainDB.instance.isar.close();
      },
    );
    final wallet = await Wallet.create(
      walletInfo: WalletInfo(
        walletId: 'zcash-init-rollback',
        name: 'Zcash init rollback fixture',
        mainAddressType: AddressType.zcashUnified,
        coinName: 'zcash',
        restoreHeight: 1,
      ),
      mainDB: MainDB.instance,
      secureStorageInterface: MemorySecrets(),
      nodeService: nodes,
      prefs: SessionPrefs(),
      mnemonic:
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about',
      mnemonicPassphrase: '',
    ) as ZcashWallet;
    wallet.configureAccountSessionFactory(
      (network) => ZcashAccountSession(
        network: network,
        clientFactory: (_) => client,
        requestTimeout: const Duration(milliseconds: 100),
      ),
    );

    await expectLater(wallet.init(isRestore: true), throwsA(anything));

    expect(client.infoCalls, 1);
    expect(client.tipCalls, 1);
    expect(client.closeCalls, 1);
    await wallet.exit();
    expect(client.closeCalls, 1);
  });

  test('sync hooks share state and update Stack caches', () async {
    final node = walletNode(host: 'https://sync.example', id: 'sync');
    final client = SyncWalletSessionClient(chainName: 'main', tipHeight: 42);
    final wallet = await Wallet.create(
      walletInfo: WalletInfo(
        walletId: 'zcash-sync-hooks',
        name: 'Zcash sync hooks fixture',
        mainAddressType: AddressType.zcashUnified,
        coinName: 'zcash',
        restoreHeight: 43,
      ),
      mainDB: MainDB.instance,
      secureStorageInterface: MemorySecrets(),
      nodeService: MutableZcashNodes(node),
      prefs: SessionPrefs(),
      mnemonic:
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about',
      mnemonicPassphrase: '',
    ) as ZcashWallet;
    wallet.configureAccountSessionFactory(
      (network) =>
          ZcashAccountSession(network: network, clientFactory: (_) => client),
    );
    await wallet.init(isRestore: true);

    await wallet.updateChainHeight();
    await Future.wait([wallet.updateTransactions(), wallet.updateBalance()]);

    expect(wallet.info.cachedChainHeight, 42);
    expect(wallet.info.cachedBalance.total.raw, BigInt.zero);
    expect(await wallet.updateUTXOs(), isFalse);
    expect(client.tipCalls, 3);
    await wallet.exit();
  });

  test('transparent receiver refresh reaches balance and history', () async {
    final node = walletNode(
      host: 'https://transparent.example',
      id: 'transparent',
    );
    final nodes = MutableZcashNodes(node);
    final secrets = MemorySecrets();
    final client = SyncWalletSessionClient(
      chainName: 'main',
      tipHeight: 42,
      transparentValueZatoshis: 125000,
    );
    final wallet = await Wallet.create(
      walletInfo: WalletInfo(
        walletId: 'zcash-transparent',
        name: 'Zcash transparent fixture',
        mainAddressType: AddressType.zcashUnified,
        coinName: 'zcash',
        restoreHeight: 43,
      ),
      mainDB: MainDB.instance,
      secureStorageInterface: secrets,
      nodeService: nodes,
      prefs: SessionPrefs(),
      mnemonic:
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about',
      mnemonicPassphrase: '',
    ) as ZcashWallet;
    wallet.configureAccountSessionFactory(
      (network) =>
          ZcashAccountSession(network: network, clientFactory: (_) => client),
    );
    await wallet.init(isRestore: true);

    await wallet.recover(isRescan: false);

    expect(client.transparentRefreshCalls, 1);
    expect(client.receivedMaxRangeSize, 1000);
    expect(client.receivedMaxUtxos, 10000);
    final transparentRows =
        (await MainDB.instance.getAddresses(wallet.walletId).findAll()).where(
          (row) => row.type == AddressType.p2pkh,
        );
    expect(transparentRows, hasLength(1));
    expect(client.queriedTransparentAddresses, [transparentRows.single.value]);
    expect(wallet.info.cachedBalance.total.raw, BigInt.from(125000));
    expect(wallet.info.cachedBalance.spendable.raw, BigInt.zero);
    final transactions = await MainDB.instance.isar.transactionV2s
        .where()
        .walletIdEqualTo(wallet.walletId)
        .findAll();
    expect(transactions, hasLength(1));
    expect(transactions.single.assetPools, ['transparent']);
    expect(transactions.single.timestamp, 1700000000);
    expect(transactions.single.isMetadataMissing('timestamp'), isFalse);
    expect(transactions.single.isMetadataMissing('fee'), isFalse);
    expect(
      transactions.single.getFee(fractionDigits: 8).raw,
      BigInt.from(1000),
    );

    client.transparentTipHash = '55' * 32;
    await expectLater(wallet.recover(isRescan: false), throwsA(anything));
    final retained =
        (await MainDB.instance.isar.transactionV2s
                .where()
                .walletIdEqualTo(wallet.walletId)
                .findAll())
            .single;
    expect(retained.blockHash, '44' * 32);
    expect(wallet.info.cachedBalance.total.raw, BigInt.from(125000));
    await wallet.exit();

    final restartClient = SyncWalletSessionClient(
      chainName: 'main',
      tipHeight: 42,
      transparentValueZatoshis: 125000,
    );
    final reopened = await Wallet.load(
      walletId: wallet.walletId,
      mainDB: MainDB.instance,
      secureStorageInterface: secrets,
      nodeService: nodes,
      prefs: SessionPrefs(),
    ) as ZcashWallet;
    reopened.configureAccountSessionFactory(
      (network) => ZcashAccountSession(
        network: network,
        clientFactory: (_) => restartClient,
      ),
    );
    await reopened.init(isRestore: false);
    await reopened.recover(isRescan: false);

    expect(restartClient.treeStateCalls, 0);
    expect(restartClient.transparentRefreshCalls, 1);
    expect(reopened.info.cachedBalance.total.raw, BigInt.from(125000));
    await reopened.exit();
  });

  test('restore syncs in place and rescan restarts at the birthday', () async {
    final node = walletNode(host: 'https://rescan.example', id: 'rescan');
    final client = SyncWalletSessionClient(chainName: 'main', tipHeight: 42);
    final wallet = await Wallet.create(
      walletInfo: WalletInfo(
        walletId: 'zcash-rescan',
        name: 'Zcash rescan fixture',
        mainAddressType: AddressType.zcashUnified,
        coinName: 'zcash',
        restoreHeight: 43,
      ),
      mainDB: MainDB.instance,
      secureStorageInterface: MemorySecrets(),
      nodeService: MutableZcashNodes(node),
      prefs: SessionPrefs(),
      mnemonic:
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about',
      mnemonicPassphrase: '',
    ) as ZcashWallet;
    wallet.configureAccountSessionFactory(
      (network) =>
          ZcashAccountSession(network: network, clientFactory: (_) => client),
    );
    await wallet.init(isRestore: true);
    expect(client.treeStateCalls, 1);

    await wallet.recover(isRescan: false);
    expect(client.treeStateCalls, 1);
    expect(client.transparentRefreshCalls, 1);
    expect(wallet.info.cachedChainHeight, 42);

    await MainDB.instance.updateOrPutTransactionV2s([
      TransactionV2(
        walletId: wallet.walletId,
        blockHash: 'stale-block',
        hash: 'stale-hash',
        txid: 'stale-txid',
        timestamp: 1,
        height: 1,
        inputs: const [],
        outputs: const [],
        version: 1,
        type: TransactionType.incoming,
        subType: TransactionSubType.none,
        otherData: null,
      ),
    ]);
    final receiversBefore = await MainDB.instance
        .getAddresses(wallet.walletId)
        .findAll();

    await wallet.recover(isRescan: true);

    expect(client.treeStateCalls, 2);
    expect(client.transparentRefreshCalls, 2);
    expect(
      await MainDB.instance.isar.transactionV2s
          .where()
          .walletIdEqualTo(wallet.walletId)
          .findAll(),
      isEmpty,
    );
    final receiversAfter = await MainDB.instance
        .getAddresses(wallet.walletId)
        .findAll();
    expect(
      receiversAfter.map(
        (row) => (row.value, row.type, row.subType, row.derivationIndex),
      ),
      unorderedEquals(
        receiversBefore.map(
          (row) => (row.value, row.type, row.subType, row.derivationIndex),
        ),
      ),
    );
    expect(wallet.info.cachedChainHeight, 42);
    expect(wallet.info.cachedBalance.total.raw, BigInt.zero);

    await MainDB.instance.updateOrPutTransactionV2s([
      TransactionV2(
        walletId: wallet.walletId,
        blockHash: 'last-known-block',
        hash: 'last-known-hash',
        txid: 'last-known-txid',
        timestamp: 2,
        height: 2,
        inputs: const [],
        outputs: const [],
        version: 1,
        type: TransactionType.incoming,
        subType: TransactionSubType.none,
        otherData: null,
      ),
    ]);
    client.failTip = true;

    await expectLater(wallet.recover(isRescan: true), throwsStateError);

    expect(
      await MainDB.instance.isar.transactionV2s
          .where()
          .txidWalletIdEqualTo('last-known-txid', wallet.walletId)
          .findFirst(),
      isNotNull,
    );
    expect(wallet.info.cachedChainHeight, 42);
    await wallet.exit();
  });
}
