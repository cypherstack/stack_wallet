import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:regtest_support/regtest_support.dart';
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
import 'package:stackwallet/wallets/wallet/wallet.dart';

import 'stack_wallet_fixture.dart';

/// A UI-independent Stack application environment rooted in a temporary
/// directory.
///
/// Stack's filesystem override and preferences are process-global. Tests must
/// therefore use one [StackTestEnvironment] per app process; process isolation
/// is also the boundary used by the integration-test runner.
final class StackTestEnvironment implements RegtestResource {
  StackTestEnvironment._({
    required this.root,
    required this.logs,
    required this.secrets,
    required this.nodes,
  });

  static bool _processClaimed = false;

  final Directory root;
  final Directory logs;
  final SecureStorageInterface secrets;
  final NodeService nodes;

  MainDB get mainDB => MainDB.instance;
  Prefs get prefs => Prefs.instance;

  bool _closed = false;

  static Future<StackTestEnvironment> open({
    String tempPrefix = 'stack_regtest_app_',
    Level logLevel = Level.info,
  }) async {
    if (_processClaimed) {
      throw StateError(
        'StackTestEnvironment is process-global; start another app process '
        'for an isolated fixture',
      );
    }
    _processClaimed = true;

    Directory? root;
    var hiveStarted = false;
    var mainDbStarted = false;
    try {
      root = await Directory.systemTemp.createTemp(tempPrefix);
      StackFileSystem.setDesktopOverrideDir(root.path);

      final hive = DB.instance.hive;
      if (!hive.isAdapterRegistered(NodeModelAdapter().typeId)) {
        hive.registerAdapter(NodeModelAdapter());
      }
      hive.init((await StackFileSystem.applicationHiveDirectory()).path);
      hiveStarted = true;
      await hive.openBox<dynamic>(DB.boxNameDBInfo);
      await hive.openBox<dynamic>(DB.boxNamePrefs);
      await hive.openBox<NodeModel>(DB.boxNameNodeModels);
      await Prefs.instance.init();

      final logs = await Directory('${root.path}/logs').create();
      await Logging.instance.initialize(logs.path, level: logLevel);
      await MainDB.instance.initMainDB();
      mainDbStarted = true;

      final secrets = FakeSecureStorage();
      return StackTestEnvironment._(
        root: root,
        logs: logs,
        secrets: secrets,
        nodes: NodeService(secureStorageInterface: secrets),
      );
    } catch (error, stack) {
      if (mainDbStarted && MainDB.instance.isar.isOpen) {
        try {
          await MainDB.instance.isar.close();
        } catch (_) {
          // Preserve the initialization failure.
        }
      }
      if (hiveStarted) {
        try {
          await DB.instance.hive.close();
        } catch (_) {
          // Preserve the initialization failure.
        }
      }
      if (root != null && root.existsSync()) {
        try {
          await root.delete(recursive: true);
        } on FileSystemException {
          // Preserve the initialization failure. Windows may retain the log
          // file until the logger isolate exits.
        }
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  String get name => 'Stack test environment';

  @override
  String diagnostics({int maxLines = 100}) {
    if (maxLines < 0) {
      throw ArgumentError.value(maxLines, 'maxLines', 'must not be negative');
    }
    final file = File('${logs.path}/latest.txt');
    if (!file.existsSync()) return '(no Stack app log)';
    final lines = file.readAsLinesSync();
    return lines
        .skip(lines.length > maxLines ? lines.length - maxLines : 0)
        .join('\n');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    Object? firstError;
    StackTrace? firstStack;

    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }

    if (MainDB.instance.isar.isOpen) {
      await attempt(() => MainDB.instance.isar.close());
    }
    await attempt(DB.instance.hive.close);
    await attempt(() async {
      if (!root.existsSync()) return;
      try {
        await root.delete(recursive: true);
      } on FileSystemException {
        if (!Platform.isWindows) rethrow;
      }
    });

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStack!);
    }
  }
}

typedef StackNodeFactory = NodeModel Function(Uri endpoint);

/// Persists one host- or device-visible endpoint through Stack's [NodeService].
final class StackNodeEndpointDelivery {
  const StackNodeEndpointDelivery({
    required this.currency,
    required this.endpointName,
    required this.nodeFactory,
    this.password,
  });

  final CryptoCurrency currency;
  final String endpointName;
  final StackNodeFactory nodeFactory;
  final String? password;

  Future<void> call(
    RegtestResource resource,
    EndpointBundle endpoints,
    StackEndpointAudience audience,
    RegtestCancellation cancellation,
  ) async {
    if (resource is! StackTestEnvironment) {
      throw ArgumentError.value(
        resource,
        'environment',
        'must be a StackTestEnvironment',
      );
    }
    if (cancellation.isCancelled) {
      throw StateError('Endpoint delivery was cancelled');
    }
    final endpoint = selectStackEndpoint(
      endpoints,
      name: endpointName,
      audience: audience,
    );
    if (!endpoint.hasAuthority || endpoint.host.isEmpty || !endpoint.hasPort) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'must be an absolute URI with an explicit port',
      );
    }
    final node = nodeFactory(endpoint);
    if (node.coinName != currency.identifier) {
      throw StateError(
        'Endpoint node coin ${node.coinName} does not match '
        '${currency.identifier}',
      );
    }
    await resource.nodes.save(node, password, false);
    if (cancellation.isCancelled) {
      await resource.nodes.delete(node.id, false);
      throw StateError('Endpoint delivery was cancelled');
    }
    await resource.nodes.setPrimaryNodeFor(coin: currency, node: node);
  }
}

typedef StackWalletInitializer<WalletType extends Wallet> =
    Future<void> Function(WalletType wallet, bool isRestore);

typedef StackWalletInfoFactory = WalletInfo Function(
  CryptoCurrency currency,
  String name,
);

/// Uses Stack's production [Wallet.create], [Wallet.load], and [Wallet.exit]
/// paths while leaving coin-specific native initialization explicit.
final class StackMnemonicWalletFactory<WalletType extends Wallet>
    implements StackRegtestWalletFactory<WalletType> {
  StackMnemonicWalletFactory({
    required this.environment,
    required this.currency,
    required this.createRecoveryMaterial,
    required this.initializeWallet,
    this.walletInfoFactory,
    this.mnemonicPassphrase = '',
  });

  final StackTestEnvironment environment;
  final CryptoCurrency currency;
  final FutureOr<String> Function() createRecoveryMaterial;
  final StackWalletInitializer<WalletType> initializeWallet;
  final StackWalletInfoFactory? walletInfoFactory;
  final String mnemonicPassphrase;

  @override
  Future<WalletType> create(
    String name,
    RegtestCancellation cancellation,
  ) async {
    final recoveryMaterial = await createRecoveryMaterial();
    return _create(name, recoveryMaterial, false, cancellation);
  }

  @override
  Future<WalletType> restore(
    String name,
    String recoveryMaterial,
    RegtestCancellation cancellation,
  ) => _create(name, recoveryMaterial, true, cancellation);

  Future<WalletType> _create(
    String name,
    String recoveryMaterial,
    bool isRestore,
    RegtestCancellation cancellation,
  ) async {
    if (cancellation.isCancelled) throw StateError('Wallet creation cancelled');
    Wallet? wallet;
    try {
      wallet = await Wallet.create(
        walletInfo:
            walletInfoFactory?.call(currency, name) ??
            WalletInfo.createNew(coin: currency, name: name),
        mainDB: environment.mainDB,
        secureStorageInterface: environment.secrets,
        nodeService: environment.nodes,
        prefs: environment.prefs,
        mnemonic: recoveryMaterial,
        mnemonicPassphrase: mnemonicPassphrase,
      );
      if (wallet is! WalletType) {
        throw StateError(
          'Expected $WalletType for ${currency.identifier}, got '
          '${wallet.runtimeType}',
        );
      }
      wallet.shouldAutoSync = false;
      await initializeWallet(wallet, isRestore);
      if (cancellation.isCancelled) {
        throw StateError('Wallet creation cancelled');
      }
      return wallet;
    } catch (_) {
      if (wallet != null) await wallet.exit();
      rethrow;
    }
  }

  @override
  Future<WalletType> reopen(
    WalletType wallet,
    RegtestCancellation cancellation,
  ) async {
    final walletId = wallet.walletId;
    await wallet.exit();
    if (cancellation.isCancelled) throw StateError('Wallet reopen cancelled');
    final replacement = await Wallet.load(
      walletId: walletId,
      mainDB: environment.mainDB,
      secureStorageInterface: environment.secrets,
      nodeService: environment.nodes,
      prefs: environment.prefs,
    );
    if (replacement is! WalletType) {
      await replacement.exit();
      throw StateError(
        'Expected $WalletType when reopening $walletId, got '
        '${replacement.runtimeType}',
      );
    }
    replacement.shouldAutoSync = false;
    try {
      await initializeWallet(replacement, false);
      return replacement;
    } catch (_) {
      await replacement.exit();
      rethrow;
    }
  }

  @override
  Future<void> close(WalletType wallet) => wallet.exit();
}
