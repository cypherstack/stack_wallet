import 'dart:async';
import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/main.dart' as app;
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/stack_privacy_calls.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_auth_send.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../wallet_creation/drivers/desktop_driver.dart';
import '../wallet_creation/ui.dart';
import 'helpers.dart';
import 'regtest_chain.dart';

/// The real app, driven through its desktop send form: the wallet is funded
/// by the node, the form is filled in and confirmed with the password, and
/// the node checks what arrived. The fee is the form's default; regtest has
/// no estimates, so this is Stack's fallback rate.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a send typed into the desktop form reaches the node', (
    tester,
  ) async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      fail('The desktop send scenario requires a desktop host.');
    }
    final chain = await RegtestChain.start();
    final root = await Directory.systemTemp.createTemp('stack_btc_regtest_ui_');
    final ui = TestUI(tester);
    final driver = DesktopDriver(ui);
    addTearDown(() async {
      try {
        for (final wallet in Wallets.sharedInstance.wallets) {
          wallet.shouldAutoSync = false;
          await wallet.exit();
        }
      } finally {
        await chain.stop();
      }
      // The app keeps its databases open until the process exits. Unix lets
      // open files be unlinked; elsewhere the OS cleans the temp dir.
      if (!Platform.isWindows) {
        try {
          await root.delete(recursive: true);
        } on FileSystemException {
          // Best effort.
        }
      }
    });
    addTearDown(() => printOnFailure('--- bitcoind\n${chain.logTail}'));

    // Keep the app's data and logs under the temp dir. The logs path is a
    // pref because the logs dir ignores the desktop data dir override.
    StackFileSystem.setDesktopOverrideDir(root.path);
    final logs = await Directory('${root.path}/logs').create();
    final hive = DB.instance.hive;
    hive.init((await StackFileSystem.applicationHiveDirectory()).path);
    final prefsBox = await hive.openBox<dynamic>(DB.boxNamePrefs);
    await prefsBox.put('logsPath', logs.path);
    await prefsBox.put('showTestNetCoins', true);
    await prefsBox.close();

    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    runZonedGuarded(
      () => app.main(const []),
      (error, stack) => ui.errors.add(error),
    );

    ui.stage = 'onboarding';
    await ui.waitFor(find.byType(IntroView));
    await ui.tap(find.byType(GetStartedButton));
    await ui.waitFor(find.byType(StackPrivacyCalls));
    await ui.tapText('Incognito');
    await ui.tapText('Continue');
    await driver.createCredentials();

    ui.stage = 'wallet setup';
    final container = ProviderScope.containerOf(tester.element(driver.home));
    final coin = AppConfig.coins.firstWhere(
      (e) => e is Bitcoin && e.network == CryptoCurrencyNetwork.regtest,
      orElse: () => throw StateError('Pass STACK_BITCOIN_REGTEST=true.'),
    );
    final nodes = container.read(nodeServiceChangeNotifierProvider);
    final node = coin
        .defaultNode(isPrimary: true)
        .copyWith(
          host: chain.electrumHost,
          port: chain.electrumPort,
          loginName: null,
          trusted: true,
        );
    await nodes.save(node, null, true);
    await nodes.setPrimaryNodeFor(coin: coin, node: node);
    final wallet = await Wallet.create(
      walletInfo: WalletInfo.createNew(coin: coin, name: 'ui sender'),
      mainDB: container.read(mainDBProvider),
      secureStorageInterface: container.read(secureStoreProvider),
      nodeService: nodes,
      prefs: container.read(prefsChangeNotifierProvider),
      mnemonic: bip39.generateMnemonic(strength: 128),
      mnemonicPassphrase: '',
    ) as BitcoinWallet;
    await wallet.init();
    container.read(pWallets).addWallet(wallet);
    await chain.pay(await receivingAddress(wallet), '1.0');
    await chain.mine(1);
    await wallet.refresh();
    expect(wallet.info.cachedBalance.spendable.raw, sats('1.0'));

    ui.stage = 'send form';
    await driver.openWallet(wallet);
    await ui.tap(find.byKey(const ValueKey('customTab_Send')));
    final destination =
        await chain.rpc('getnewaddress', ['', 'bech32'], 'miner') as String;
    await ui.enter(
      find.byKey(const Key('sendViewAddressFieldKey')),
      destination,
    );
    await ui.enter(
      find.byKey(const Key('amountInputFieldCryptoTextFieldKey')),
      '0.25',
    );
    await ui.tapText('Preview send');

    ui.stage = 'confirm';
    final confirm = find.byType(ConfirmTransactionView);
    await ui.waitFor(confirm, description: 'confirm dialog');
    await ui.tapText('Send', within: confirm);
    final auth = find.byType(DesktopAuthSend);
    await ui.waitFor(auth, description: 'password dialog');
    await ui.enter(
      find.descendant(
        of: auth,
        matching: find.byKey(const Key('desktopLoginPasswordFieldKey')),
      ),
      testPassword,
    );
    await ui.tapText('Confirm', within: auth);

    ui.stage = 'broadcast';
    late List<String> mempool;
    await ui.until(() async {
      mempool = await chain.mempool();
      return mempool.isNotEmpty;
    }, 'the send in the node mempool');
    await ui.until(
      () => confirm.evaluate().isEmpty,
      'the confirm dialog to close',
    );
    final txid = mempool.single;
    final entry = Map<String, dynamic>.from(
      await chain.rpc('getmempoolentry', [txid]) as Map,
    );
    final fee = btcToSats((entry['fees'] as Map)['base'] as num);
    expect(fee >= BigInt.from(entry['vsize'] as int), isTrue);

    await chain.mine(1);
    final received = Map<String, dynamic>.from(
      await chain.rpc('gettransaction', [txid], 'miner') as Map,
    );
    expect(received['confirmations'], 1);
    expect(btcToSats(received['amount'] as num), sats('0.25'));

    await wallet.refresh();
    expect(
      wallet.info.cachedBalance.spendable.raw,
      sats('1.0') - sats('0.25') - fee,
    );
    final sent = (await history(wallet)).where((t) => t.txid == txid);
    expect(sent.map((t) => t.type), [TransactionType.outgoing]);
    await ui.pump();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
