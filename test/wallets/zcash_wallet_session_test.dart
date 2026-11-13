import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
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
}
