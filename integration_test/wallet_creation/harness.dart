import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/main.dart' as app;
import 'package:stackwallet/pages/add_wallet_views/add_token_view/edit_wallet_tokens_view.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/add_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/name_your_wallet_view/name_your_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_options/new_wallet_options_view.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/new_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table_item.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import 'package:stackwallet/pages/add_wallet_views/verify_recovery_phrase_view/verify_recovery_phrase_view.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/pages/stack_privacy_calls.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/biometrics.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/token_wallet_info.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/models/wallet_solana_token_info.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/mnemonic_interface.dart';

import 'coin_cases.dart';
import 'drivers/desktop_driver.dart';
import 'drivers/mobile_driver.dart';
import 'drivers/platform_driver.dart';
import 'seed_validators.dart';
import 'storage.dart';
import 'ui.dart';

String phraseFingerprint(String phrase) =>
    sha256.convert(utf8.encode(phrase)).toString();

void walletCreationTest({required bool allCoins}) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const selected = String.fromEnvironment(
    'WALLET_TEST_COIN',
    defaultValue: 'bitcoin',
  );
  const phase = String.fromEnvironment(
    'WALLET_TEST_PHASE',
    defaultValue: 'create',
  );
  testWidgets(
    'wallet creation ${allCoins ? 'all main coins' : selected}: $phase',
    (tester) async {
      expect(['create', 'reopen'], contains(phase));
      expect(
        const String.fromEnvironment('WALLET_TEST_PLATFORM'),
        Platform.operatingSystem,
        reason: 'The requested target must match the native OS',
      );
      expect(
        Biometrics.integrationTestFlag,
        isTrue,
        reason:
            'Pass --dart-define=IS_INTEGRATION_TEST=true for biometric opt-out',
      );
      final coins = creationCoins();
      if (!allCoins) {
        expect(
          defaultWordCounts.containsKey(selected),
          isTrue,
          reason: 'Unknown coin; FROST is a separate multisig scenario',
        );
        coins.retainWhere((coin) => coin.identifier == selected);
      }
      final ui = TestUI(tester);
      final storage = await TestStorage.prepare(reopen: phase == 'reopen');
      ui.errorLog = File('${storage.root.path}/failure.txt');
      final driver = storage.mobile ? MobileDriver(ui) : DesktopDriver(ui);
      final test = CreationScenario(ui, storage, driver);
      var succeeded = false;
      // Keep the real notification plugin but avoid OS permission dialogs,
      // which Flutter's widget driver cannot dismiss on a fresh mobile install.
      await NotificationApi.init(requestPermissions: false);

      // Set a usable desktop surface only. Mobile uses the real device viewport
      // and OS; no layoutPlatform, screenWidth, or isIpad overrides.
      if (!storage.mobile) {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
      }
      runZonedGuarded(
        () => app.main(const []),
        (error, stack) => ui.errors.add(error),
      );
      try {
        if (phase == 'create') {
          await test.onboard();
          for (final coin in coins) {
            await test.create(coin);
          }
          await storage.manifest.writeAsString(
            jsonEncode(test.snapshots),
            flush: true,
          );
        } else {
          await driver.unlock();
          test.checkPlatform();
          final saved =
              jsonDecode(await storage.manifest.readAsString()) as List;
          expect(
            saved.map((entry) => entry['coin']).toSet(),
            coins.map((coin) => coin.identifier).toSet(),
          );
          test.snapshots.addAll(saved.cast<Map<String, dynamic>>());
          await test.verifySavedWallets(open: true);
        }
        await ui.pump();
        succeeded = true;
      } finally {
        // The runner removes desktop files after Flutter terminates,
        // when database locks and background services can no longer hold them.
        for (final wallet in Wallets.sharedInstance.wallets) {
          wallet.shouldAutoSync = false;
          await wallet.exit();
        }
        if (storage.mobile && succeeded && phase == 'reopen') {
          await tester.pumpWidget(const SizedBox.shrink());
          await storage.clearMobileTestKeys();
        }
      }
    },
    timeout: Timeout(Duration(minutes: allCoins ? 60 : 20)),
  );
}

class CreationScenario {
  CreationScenario(this.ui, this.storage, this.driver);
  final TestUI ui;
  final TestStorage storage;
  final PlatformDriver driver;
  final snapshots = <Map<String, dynamic>>[];

  MainDB get db => MainDB.instance;

  void checkPlatform() {
    const expected = String.fromEnvironment('WALLET_TEST_PLATFORM');
    expect(
      expected,
      Platform.operatingSystem,
      reason: 'Test target must match the actual native OS',
    );
    expect(
      Util.isDesktop,
      !storage.mobile,
      reason: 'Use an iPhone for mobile iOS and a desktop for Linux desktop',
    );
  }

  Future<void> onboard() async {
    ui.stage = 'fresh install onboarding';
    await ui.waitFor(find.byType(IntroView));
    checkPlatform();
    expect(await db.isar.walletInfo.count(), 0);
    await ui.tap(find.byType(GetStartedButton));
    await ui.waitFor(find.byType(StackPrivacyCalls));
    await ui.tapText('Incognito');
    await ui.tapText('Continue');
    await driver.createCredentials();
    final container = ProviderScope.containerOf(ui.tester.element(driver.home));
    final keys = await container.read(secureStoreProvider).keys;
    expect(keys.where((key) => key.endsWith('_mnemonic')), isEmpty);
    expect(await db.isar.walletInfo.count(), 0);
  }

  Future<void> create(CryptoCurrency coin) async {
    ui.stage = '${coin.identifier}: select and name';
    await driver.addWallet();
    await ui.waitFor(find.byType(AddWalletView));
    await ui.enter(
      find.descendant(
        of: find.byType(AddWalletView),
        matching: find.byType(TextField),
      ),
      coin.identifier,
    );
    await ui.tap(
      find.byKey(
        Key('coinSelectItemButtonKey_${coin.prettyName}${coin.ticker}'),
      ),
    );
    await ui.tapText('Next');
    await ui.tapText('Create new wallet');
    await ui.waitFor(find.byType(NameYourWalletView));
    final name = 'Test ${coin.ticker}';
    await ui.enter(
      find.descendant(
        of: find.byType(NameYourWalletView),
        matching: find.byType(TextField),
      ),
      name,
    );
    await ui.tapText('Next');
    ui.stage = '${coin.identifier}: default options';
    await ui.until(
      () =>
          find.byType(NewWalletOptionsView).evaluate().isNotEmpty ||
          find.byType(NewWalletRecoveryPhraseWarningView).evaluate().isNotEmpty,
      'wallet options or recovery warning',
    );
    if (find.byType(NewWalletOptionsView).evaluate().isNotEmpty) {
      await ui.tapText('Continue', within: find.byType(NewWalletOptionsView));
    }
    await ui.waitFor(find.byType(NewWalletRecoveryPhraseWarningView));
    await ui.tap(find.byType(Checkbox));
    ui.stage = '${coin.identifier}: generate';
    await ui.tapText('View recovery phrase');
    await ui.waitFor(
      find.byType(NewWalletRecoveryPhraseView),
      description: 'generated recovery phrase',
      timeout: const Duration(minutes: 10),
    );
    final screen = ui.tester.widget<NewWalletRecoveryPhraseView>(
      find.byType(NewWalletRecoveryPhraseView),
    );
    final wallet = screen.wallet;
    final words = <String>[];
    final items =
        ui.tester
            .widgetList<MnemonicTableItem>(find.byType(MnemonicTableItem))
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number));
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      expect(item.number, index + 1);
      final finder = find.byWidget(item);
      await ui.reveal(finder);
      final text = find.descendant(of: finder, matching: find.byType(Text));
      final rendered = ui.tester
          .widgetList<Text>(text)
          .map((w) => w.data)
          .toList();
      expect(rendered.length, 2);
      words.add(rendered.last!);
    }
    validatePhrase(coin, words);
    final phrase = words.join(' ');
    final mnemonicWallet = wallet as MnemonicInterface;
    expect(
      await mnemonicWallet.getMnemonic() == phrase,
      isTrue,
      reason: '${coin.identifier}: displayed seed differs from secure storage',
    );
    expect(
      await wallet.secureStorageInterface.read(
            key: Wallet.mnemonicKey(walletId: wallet.walletId),
          ) ==
          phrase,
      isTrue,
    );
    expect(await wallet.info.isMnemonicVerified(db.isar), isFalse);

    ui.stage = '${coin.identifier}: confirm recovery phrase';
    await ui.tapText('I saved my recovery phrase');
    await ui.waitFor(find.byType(VerifyRecoveryPhraseView));
    final challenge = ui.tester.widget<Text>(
      find.byKey(const Key('recoveryPhraseWordIndex')),
    );
    final index = int.parse(challenge.data!) - 1;
    expect(index >= 0 && index < words.length, isTrue);
    await ui.tap(find.byKey(Key('coinSelectItemButtonKey_${words[index]}')));
    await ui.tapText(driver.verificationButton);
    if (coin is Ethereum || coin is Solana) {
      await ui.waitFor(find.byType(EditWalletTokensView));
      await ui.tapText('Next', within: find.byType(EditWalletTokensView));
    }
    await ui.waitFor(driver.home);
    expect(await wallet.info.isMnemonicVerified(db.isar), isTrue);
    expect(wallet.info.name, name);
    expect(wallet.info.coin, coin);
    expect(wallet.info.isViewOnly, isFalse);
    expect(await db.isar.walletInfo.count(), snapshots.length + 1);

    ui.stage = '${coin.identifier}: open created wallet';
    // CryptoNote wallets populate their first receiving address in open(),
    // reached by normal wallet-list navigation, after seed confirmation.
    await driver.openWallet(wallet);
    final address = await wallet.getCurrentReceivingAddress();
    expect(address, isNotNull);
    expect(
      address!.value.isNotEmpty && coin.validateAddress(address.value),
      isTrue,
    );
    expect(address.value, wallet.info.cachedReceivingAddress);
    await verifyOpenNativeWallet(wallet, address.value);
    await driver.verifyReceiveAddress(wallet, address.value);
    await driver.backToHome();
    // Opening a wallet may enable background refresh. Do not wait for a scan.
    wallet.shouldAutoSync = false;

    ui.stage = '${coin.identifier}: recovery identity';
    await verifyRecoveryIdentity(wallet, phrase, storage.root.path);
    expect(await db.isar.walletInfo.count(), snapshots.length + 1);
    final fingerprint = phraseFingerprint(phrase);
    expect(
      snapshots.any((saved) => saved['seed'] == fingerprint),
      isFalse,
      reason: '${coin.identifier}: a previous wallet seed was reused',
    );
    snapshots.add({
      'id': wallet.walletId,
      'coin': coin.identifier,
      'name': name,
      'seed': fingerprint,
      'address': address.value,
    });
    await verifySavedWallets();
    ui.report(
      'OK ${Platform.operatingSystem} '
      '${coin.identifier} create',
    );
  }

  Future<void> verifySavedWallets({bool open = false}) async {
    expect(await db.isar.walletInfo.count(), snapshots.length);
    expect(await db.isar.tokenWalletInfo.count(), 0);
    expect(await db.isar.walletSolanaTokenInfo.count(), 0);
    for (final saved in snapshots) {
      ui.stage = '${saved['coin']}: check persisted wallet';
      await ui.until(
        () => Wallets.sharedInstance.wallets.any(
          (w) => w.walletId == saved['id'],
        ),
        'loaded wallet',
      );
      final wallet = Wallets.sharedInstance.getWallet(saved['id'] as String);
      expect(wallet.info.name, saved['name']);
      expect(wallet.cryptoCurrency.identifier, saved['coin']);
      expect(wallet.cryptoCurrency.network, CryptoCurrencyNetwork.main);
      expect(await wallet.info.isMnemonicVerified(db.isar), isTrue);
      final phrase = await (wallet as MnemonicInterface).getMnemonic();
      expect(
        phraseFingerprint(phrase) == saved['seed'],
        isTrue,
        reason: '${saved['coin']}: recovery phrase changed',
      );
      expect(wallet.info.tokenContractAddresses, isEmpty);
      expect(wallet.info.solanaTokenMintAddresses, isEmpty);
      expect(wallet.info.solanaCustomTokenMintAddresses, isEmpty);
      if (open) await driver.openWallet(wallet);
      final address = await wallet.getCurrentReceivingAddress();
      expect(address?.value, saved['address']);
      expect(wallet.info.cachedReceivingAddress, saved['address']);
      if (open) {
        await verifyOpenNativeWallet(wallet, address!.value);
        await driver.verifyReceiveAddress(wallet, address.value);
        await verifyRecoveryIdentity(wallet, phrase, storage.root.path);
        await driver.backToHome();
        wallet.shouldAutoSync = false;
        ui.report(
          'OK ${Platform.operatingSystem} '
          '${saved['coin']} reopen',
        );
      }
    }
  }
}
