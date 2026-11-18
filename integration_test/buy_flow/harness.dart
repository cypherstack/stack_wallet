// Buy flow integration tests, for desktop. With Flutter 3.49 or later:
//
//   flutter test integration_test/buy_flow -d macos
//
// With older Flutter versions, run each *_test.dart file in this folder on
// its own, for example:
//
//   flutter test -d macos integration_test/buy_flow/taproot_wallet_test.dart
//
// (or -d linux / -d windows). Linux needs a desktop session, because
// notifications use D-Bus, and a screen at least 800 px wide, otherwise the
// app uses its mobile UI.
//
// Each test launches the real app against a throwaway folder, sets a password
// through the UI and points Bitcoin at a fake ElectrumX server on this
// machine. The app's HTTP requests are refused. A test's Bitcoin wallets
// therefore neither depend on nor send anything to a real service; a wallet
// of another coin would still reach that coin's default server. Wallets come
// from a public test mnemonic, which makes every address a known value.
//
// One test per file: the app keeps process-wide state, so every scenario
// needs its own launch.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:stackwallet/main.dart' as app;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/keys/view_only_wallet_data.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/pages/buy_view/buy_form.dart';
import 'package:stackwallet/pages/exchange_view/choose_address_from_stack_view.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/pages/stack_privacy_calls.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';

import '../wallet_creation/drivers/desktop_driver.dart';
import '../wallet_creation/ui.dart';
import 'fake_electrumx.dart';

/// The mnemonic of the BIP44, BIP49, BIP84 and BIP86 test vectors. It is
/// public, so nobody keeps funds on it.
const testMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon about';

/// Addresses of [testMnemonic], as the BIPs list them.
const legacyAddress0 = '1LqBGSKuX5yYUonjxT5qGfpUsXKYYWeabA'; // m/44'/0'/0'/0/0
const nestedSegwitAddress0 =
    '37VucYSaXLCAsxYyAPfbSi9eh4iEcbShgf'; // m/49'/0'/0'/0/0
const segwitAddress0 =
    'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu'; // m/84'/0'/0'/0/0
const segwitAddress1 =
    'bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g'; // m/84'/0'/0'/0/1
const taprootAddress0 =
    'bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr'; // m/86'/0'/0'/0/0

void buyFlowTest(
  String description,
  Future<void> Function(BuyFlowTest t) body,
) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    description,
    (tester) async {
      final temp = await Directory.systemTemp.createTemp(
        'stack_buy_flow_test_',
      );
      debugPrint('Test folder: ${temp.path}');
      final electrumX = await FakeElectrumX.start(
        Bitcoin(CryptoCurrencyNetwork.main),
      );
      try {
        await body(BuyFlowTest._(tester, temp.path, electrumX));
      } finally {
        for (final wallet in Wallets.sharedInstance.wallets) {
          wallet.shouldAutoSync = false;
          await wallet.exit();
        }
        await electrumX.close();
      }
      // Only reached when the test passed, so failed runs keep the folder.
      // On Windows the still running app holds some of it open.
      try {
        await temp.delete(recursive: true);
      } on FileSystemException catch (_) {}
    },
    skip: !(Platform.isLinux || Platform.isMacOS || Platform.isWindows),
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

class BuyFlowTest {
  BuyFlowTest._(this.tester, this._temp, this.electrumX)
    : ui = TestUI(tester, reportPrefix: 'BUY_FLOW_');

  final WidgetTester tester;
  final String _temp;

  /// The server every Bitcoin wallet of the test talks to.
  final FakeElectrumX electrumX;
  final TestUI ui;
  final coin = Bitcoin(CryptoCurrencyNetwork.main);
  late final ProviderContainer _app;

  static const _addressField = Key('buyViewReceiveAddressFieldKey');

  /// Starts the app on an empty data folder and sets it up through the UI.
  Future<void> launch() async {
    PathProviderPlatform.instance = _TestPaths(_temp);
    StackFileSystem.setDesktopOverrideDir(p.join(_temp, 'data'));
    HttpOverrides.global = _NoHttp();
    ui.errorLog = File(p.join(_temp, 'failure.txt'));
    // Keep the real notification plugin but avoid OS permission dialogs.
    await NotificationApi.init(requestPermissions: false);
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    runZonedGuarded(
      () => app.main(const []),
      (error, stack) => ui.errors.add(error),
    );

    ui.stage = 'first launch';
    final driver = DesktopDriver(ui);
    await ui.waitFor(find.byType(IntroView));
    await ui.tap(find.byType(GetStartedButton));
    await ui.waitFor(find.byType(StackPrivacyCalls));
    await ui.tapText('Incognito');
    await ui.tapText('Continue');
    await driver.createCredentials();
    _app = ProviderScope.containerOf(tester.element(driver.home));

    // Wallets created from here on use the fake server only. Without their
    // failover flag, the default nodes are never tried.
    final nodes = _app.read(nodeServiceChangeNotifierProvider);
    for (final node in nodes.getNodesFor(coin)) {
      await nodes.setFailover(node.id, false);
    }
    final node = NodeModel(
      host: InternetAddress.loopbackIPv4.address,
      port: electrumX.port,
      name: 'Buy flow test',
      id: 'buy_flow_test',
      useSSL: false,
      enabled: true,
      coinName: coin.identifier,
      isFailover: false,
      isDown: false,
      torEnabled: false,
      clearnetEnabled: true,
      isPrimary: true,
    );
    await nodes.save(node, null, false);
    await nodes.setPrimaryNodeFor(coin: coin, node: node);
  }

  /// Restores a wallet from [testMnemonic], as the restore screens do.
  Future<BitcoinWallet> addWallet(String name) =>
      _addWallet(name, mnemonic: testMnemonic);

  /// Restores a view only wallet from one extended public key.
  Future<BitcoinWallet> addViewOnlyWallet(String name, XPub xPub) =>
      _addWallet(name, xPub: xPub);

  Future<BitcoinWallet> _addWallet(
    String name, {
    String? mnemonic,
    XPub? xPub,
  }) async {
    ui.stage = 'add "$name"';
    final db = _app.read(mainDBProvider);
    final info = WalletInfo.createNew(
      coin: coin,
      name: name,
      otherDataJsonString: xPub == null
          ? null
          : jsonEncode({
              WalletInfoKeys.isViewOnlyKey: true,
              WalletInfoKeys.viewOnlyTypeIndexKey:
                  ViewOnlyWalletType.xPub.index,
            }),
    );
    final wallet = await Wallet.create(
      walletInfo: info,
      mainDB: db,
      secureStorageInterface: _app.read(secureStoreProvider),
      nodeService: _app.read(nodeServiceChangeNotifierProvider),
      prefs: _app.read(prefsChangeNotifierProvider),
      mnemonic: mnemonic,
      mnemonicPassphrase: mnemonic == null ? null : '',
      viewOnlyData: xPub == null
          ? null
          : ExtendedKeysViewOnlyWalletData(
              walletId: info.walletId,
              xPubs: [xPub],
            ),
    );
    await _wait(() async {
      await wallet.init();
      await wallet.recover(isRescan: false);
      await wallet.info.setMnemonicVerified(isar: db.isar);
    }(), 'restore to finish');
    _app.read(pWallets).addWallet(wallet);
    return wallet as BitcoinWallet;
  }

  /// The saved receiving addresses of one type, lowest index first.
  Future<List<Address>> receiving(Wallet wallet, AddressType type) => _app
      .read(mainDBProvider)
      .isar
      .addresses
      .where()
      .walletIdEqualTo(wallet.walletId)
      .filter()
      .typeEqualTo(type)
      .subTypeEqualTo(AddressSubType.receiving)
      .sortByDerivationIndex()
      .findAll();

  /// Refreshes [wallet] until [done]. One refresh is not always enough: a
  /// refresh that is already running may have started before the change the
  /// test is waiting for.
  Future<void> refreshUntil(
    Wallet wallet,
    Future<bool> Function() done,
    String description,
  ) async {
    ui.stage = 'refresh "${wallet.info.name}"';
    // A refresh that fails still completes normally. It only fires an event.
    var failed = false;
    final events = GlobalEventBus.instance
        .on<WalletSyncStatusChangedEvent>()
        .listen(
          (event) => failed |=
              event.walletId == wallet.walletId &&
              event.newStatus == WalletSyncStatus.unableToSync,
        );
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    try {
      while (true) {
        await _wait(wallet.refresh(), 'refresh to finish');
        if (failed) {
          fail(
            '${ui.stage}: the refresh failed; '
            'the app log in the test folder has the error',
          );
        }
        if (await done()) return;
        if (DateTime.now().isAfter(deadline)) {
          fail('${ui.stage}: timed out waiting for $description');
        }
      }
    } finally {
      await events.cancel();
    }
  }

  Future<void> openBuy() async {
    ui.stage = 'open the Buy page';
    await ui.tap(find.byKey(const ValueKey('buy')));
    await ui.waitFor(find.byType(BuyForm), description: 'Buy form');
  }

  /// The text of the Buy form's receiving address field.
  String get address =>
      tester.widget<TextField>(find.byKey(_addressField)).controller!.text;

  /// Whether the Buy form is on screen and takes input. A form under a
  /// dialog, or on a page that is closing, does not.
  bool get formTakesInput =>
      find.byKey(_addressField).hitTestable().evaluate().isNotEmpty;

  /// Empties the address field with its clear button, so the next choice
  /// visibly fills it again.
  Future<void> clearAddress() async {
    await ui.tap(find.byKey(const Key('buyViewClearAddressFieldButtonKey')));
    expect(address, isEmpty);
  }

  Future<void> waitForAddress(String expected) => ui.until(
    () => address == expected,
    'the address field to show $expected',
  );

  /// Taps "Choose from Stack", then [wallet] in the list that opens.
  Future<void> chooseFromStack(Wallet wallet) async {
    ui.stage = 'choose "${wallet.info.name}" from Stack';
    await ui.tapText('Choose from Stack');
    final wallets = find.byType(ChooseAddressFromStackView);
    await ui.waitFor(wallets, description: 'wallet list');
    await ui.tap(
      find.descendant(of: wallets, matching: find.text(wallet.info.name)),
    );
    await ui.until(() => wallets.evaluate().isEmpty, 'wallet list to close');
  }

  /// Keeps frames coming, and app errors noticed, while [future] runs.
  Future<T> _wait<T>(Future<T> future, String description) async {
    var done = false;
    late final T value;
    Object? error;
    StackTrace? trace;
    unawaited(
      future
          .then<void>(
            (result) => value = result,
            onError: (Object e, StackTrace s) {
              error = e;
              trace = s;
            },
          )
          .whenComplete(() => done = true),
    );
    await ui.until(() => done, description);
    if (error != null) Error.throwWithStackTrace(error!, trace!);
    return value;
  }
}

/// Refuses the app's HTTP requests.
final class _NoHttp extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..connectionFactory = (url, proxyHost, proxyPort) => Future.error(
          SocketException('Refused by the buy flow test: ${url.host}'),
        );
}

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.temp);

  final String temp;

  Future<String> _directory(String name) async =>
      (await Directory(p.join(temp, name)).create(recursive: true)).path;

  @override
  Future<String?> getTemporaryPath() => _directory('temp');

  @override
  Future<String?> getApplicationSupportPath() => _directory('support');

  @override
  Future<String?> getLibraryPath() => _directory('library');

  @override
  Future<String?> getApplicationDocumentsPath() => _directory('documents');

  @override
  Future<String?> getApplicationCachePath() => _directory('cache');

  @override
  Future<String?> getDownloadsPath() => _directory('downloads');
}
