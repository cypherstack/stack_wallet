import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:logger/logger.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import 'regtest_chain.dart';

/// Stack's storage and services in a temp dir, with the regtest electrs as the
/// only Bitcoin regtest node. Wallets are real [BitcoinWallet]s: Isar, the
/// Hive tx cache, ElectrumX sync and coinlib signing are all the app's code.
class StackEnv {
  StackEnv._(this.root, this.logs, this.nodes, this.secrets);

  final Directory root;
  final Directory logs;
  final NodeService nodes;
  final SecureStorageInterface secrets;
  final wallets = <BitcoinWallet>[];

  static final coin = AppConfig.coins.firstWhere(
    (e) => e is Bitcoin && e.network == CryptoCurrencyNetwork.regtest,
    orElse: () => throw StateError(
      'Bitcoin regtest is off. Pass --dart-define=STACK_BITCOIN_REGTEST=true.',
    ),
  ) as Bitcoin;

  static Future<StackEnv> open(RegtestChain chain) async {
    final root = await Directory.systemTemp.createTemp(
      'stack_btc_regtest_app_',
    );
    StackFileSystem.setDesktopOverrideDir(root.path);

    final hive = DB.instance.hive;
    if (!hive.isAdapterRegistered(NodeModelAdapter().typeId)) {
      hive.registerAdapter(NodeModelAdapter());
    }
    hive.init((await StackFileSystem.applicationHiveDirectory()).path);
    await hive.openBox<dynamic>(DB.boxNameDBInfo);
    await hive.openBox<dynamic>(DB.boxNamePrefs);
    await hive.openBox<NodeModel>(DB.boxNameNodeModels);
    await Prefs.instance.init();
    // Not applicationLogsDirectory: that ignores the desktop override and
    // would write to the real app's logs. The logger prints from its own
    // isolate, which flutter test does not capture; [logTail] reads the file.
    final logs = await Directory('${root.path}/logs').create();
    await Logging.instance.initialize(logs.path, level: Level.info);
    await coinlib.loadCoinlib();
    await MainDB.instance.initMainDB();

    final secrets = FakeSecureStorage();
    final nodes = NodeService(secureStorageInterface: secrets);
    final node = coin
        .defaultNode(isPrimary: true)
        .copyWith(port: chain.electrumPort, loginName: null, trusted: true);
    await nodes.save(node, null, false);
    await nodes.setPrimaryNodeFor(coin: coin, node: node);
    return StackEnv._(root, logs, nodes, secrets);
  }

  /// Creates a wallet the way the add-wallet flow does, or restores one when
  /// [mnemonic] is given.
  Future<BitcoinWallet> createWallet(String name, {String? mnemonic}) async {
    final info = WalletInfo.createNew(coin: coin, name: name);
    final wallet = await Wallet.create(
      walletInfo: info,
      mainDB: MainDB.instance,
      secureStorageInterface: secrets,
      nodeService: nodes,
      prefs: Prefs.instance,
      mnemonic: mnemonic ?? bip39.generateMnemonic(strength: 128),
      mnemonicPassphrase: '',
    ) as BitcoinWallet;
    wallet.shouldAutoSync = false;
    wallets.add(wallet);
    await wallet.init();
    if (mnemonic != null) {
      await wallet.recover(isRescan: false);
      // recover() ends with an unawaited refresh(); this joins it.
      await wallet.refresh();
    }
    return wallet;
  }

  /// The end of the app log. Warnings and errors are written immediately.
  String logTail({int lines = 80}) {
    final file = File('${logs.path}/latest.txt');
    if (!file.existsSync()) return '(no app log)';
    final all = file.readAsLinesSync();
    return all.skip(all.length > lines ? all.length - lines : 0).join('\n');
  }

  Future<void> close() async {
    try {
      for (final wallet in wallets.reversed) {
        await wallet.exit();
      }
    } finally {
      await MainDB.instance.isar.close();
      await DB.instance.hive.close();
      if (root.existsSync()) await root.delete(recursive: true);
    }
  }
}
