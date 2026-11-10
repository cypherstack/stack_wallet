import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages/send_view/token_send_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_token_send.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/eth/current_token_wallet_provider.dart';
import 'package:stackwallet/wallets/isar/providers/eth/token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _Locale extends LocaleService {
  @override
  String get locale => 'en_US';
}

class _Prefs extends ConfirmationPrefs {
  AmountUnit selectedUnit = AmountUnit.normal;
  @override
  bool get enableCoinControl => false;
  @override
  bool get externalCalls => true;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => selectedUnit;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
  void changeUnit(AmountUnit next) {
    selectedUnit = next;
    notifyListeners();
  }
}

class _Price extends PriceService {
  _Price() : super('USD');
  @override
  ({Decimal value, double change24h})? getPrice(CryptoCurrency coin) =>
      (value: Decimal.one, change24h: 0);
  @override
  ({Decimal value, double change24h})? getTokenPrice(String contractAddress) =>
      (value: Decimal.one, change24h: 0);
}

class _XelisWallet extends TestWallet {
  _XelisWallet(this.info) : super(FakeNative());
  final _coin = Xelis(CryptoCurrencyNetwork.test);
  @override
  Xelis get cryptoCurrency => _coin;
  @override
  final WalletInfo info;
}

EthFeeObject get _fees => EthFeeObject(
  suggestBaseFee: BigInt.one,
  numberOfBlocksFast: 1,
  numberOfBlocksAverage: 1,
  numberOfBlocksSlow: 1,
  fast: BigInt.one,
  medium: BigInt.one,
  slow: BigInt.one,
);

class _ParentWallet extends Fake implements Wallet<Ethereum> {
  _ParentWallet(this.info);
  @override
  final WalletInfo info;
  @override
  Ethereum get cryptoCurrency => info.coin as Ethereum;
  @override
  Future<FeeObject> get fees async => _fees;
  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async =>
      Amount.zeroWith(fractionDigits: 18);
}

class _TokenWallet extends Fake implements EthTokenWallet {
  _TokenWallet(this.tokenContract, this.info);
  @override
  final EthContract tokenContract;
  @override
  final WalletInfo info;
  @override
  Ethereum get cryptoCurrency => info.coin as Ethereum;
  @override
  Future<EthFeeObject> get fees async => _fees;
  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async =>
      Amount.zeroWith(fractionDigits: 18);
}

void main() {
  const walletId = 'fiat-clear';
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);

  List<Override> commonOverrides({
    required WalletInfo info,
    required CryptoCurrency coin,
    required _Prefs prefs,
  }) => [
    pWalletInfo(walletId).overrideWithValue(info),
    pWalletCoin(walletId).overrideWithValue(coin),
    pWalletName(walletId).overrideWithValue(info.name),
    prefsChangeNotifierProvider.overrideWithValue(prefs),
    localeServiceChangeNotifierProvider.overrideWithValue(_Locale()),
    priceAnd24hChangeNotifierProvider.overrideWithValue(_Price()),
    themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
    coinIconProvider(coin).overrideWithValue(
      File('test/sample_data/light/assets/dummy.svg').absolute.path,
    ),
  ];

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    required bool desktop,
    required List<Override> overrides,
    required Widget child,
  }) async {
    final oldPlatform = Util.layoutPlatform;
    final oldThemes = StackFileSystem.themesDir;
    Util.layoutPlatform = platform.FakePlatform(
      operatingSystem: desktop ? 'linux' : 'android',
    );
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      Util.layoutPlatform = oldPlatform;
      StackFileSystem.themesDir = oldThemes;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: desktop
              ? Scaffold(body: SingleChildScrollView(child: child))
              : child,
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return container;
  }

  // Types a fiat amount, clears it again, then switches the display unit.
  // The crypto field must stay blank: a cleared field has no amount to
  // reformat, so the unit change must not write "0" into it.
  Future<void> clearFiatThenChangeUnit(
    WidgetTester tester,
    _Prefs prefs, {
    required void Function() expectCleared,
  }) async {
    final fiat = find.byKey(const Key('amountInputFieldFiatTextFieldKey'));
    final crypto = find.byKey(const Key('amountInputFieldCryptoTextFieldKey'));
    expect(fiat, findsOneWidget);
    String cryptoText() => tester.widget<TextField>(crypto).controller!.text;

    await tester.enterText(fiat, '1');
    await tester.pump(const Duration(milliseconds: 600));
    expect(cryptoText(), '1');

    await tester.enterText(fiat, '');
    await tester.pump(const Duration(milliseconds: 600));
    expect(cryptoText(), '');
    expectCleared();

    prefs.changeUnit(AmountUnit.milli);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(
      cryptoText(),
      '',
      reason: 'A unit change must not fill a cleared amount field',
    );
    expectCleared();
  }

  for (final desktop in [false, true]) {
    testWidgets('cleared fiat stays blank after unit change desktop=$desktop', (
      tester,
    ) async {
      final info = WalletInfo(
        walletId: walletId,
        name: 'Test wallet',
        mainAddressType: AddressType.xelis,
        coinName: Xelis(CryptoCurrencyNetwork.test).identifier,
      );
      final wallet = _XelisWallet(info);
      final coin = wallet.cryptoCurrency;
      final prefs = _Prefs();
      final spendable = Amount(
        rawValue: BigInt.from(1000000000),
        fractionDigits: coin.fractionDigits,
      );
      final zero = Amount.zeroWith(fractionDigits: coin.fractionDigits);
      final container = await mount(
        tester,
        desktop: desktop,
        overrides: [
          ...commonOverrides(info: info, coin: coin, prefs: prefs),
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletBalance(walletId).overrideWithValue(
            Balance(
              total: spendable,
              spendable: spendable,
              blockedTotal: zero,
              pendingSpendable: zero,
            ),
          ),
        ],
        child: desktop
            ? const DesktopSend(walletId: walletId)
            : SendView(walletId: walletId, coin: coin),
      );
      await clearFiatThenChangeUnit(
        tester,
        prefs,
        expectCleared: () => expect(container.read(pSendAmount), isNull),
      );
    });

    testWidgets(
      'cleared token fiat stays blank after unit change desktop=$desktop',
      (tester) async {
        final coin = Ethereum(CryptoCurrencyNetwork.main);
        final contract = DefaultTokens.rsFiro;
        final info = WalletInfo(
          walletId: walletId,
          name: 'Token test',
          mainAddressType: AddressType.ethereum,
          coinName: coin.identifier,
        );
        final prefs = _Prefs();
        final zero = Amount.zeroWith(fractionDigits: contract.decimals);
        final container = await mount(
          tester,
          desktop: desktop,
          overrides: [
            ...commonOverrides(info: info, coin: coin, prefs: prefs),
            pWallets.overrideWithValue(
              ConfirmationWallets(_ParentWallet(info)),
            ),
            pCurrentTokenWallet.overrideWithValue(_TokenWallet(contract, info)),
            pTokenBalance((
              walletId: walletId,
              contractAddress: contract.address,
            )).overrideWithValue(
              Balance(
                total: zero,
                spendable: zero,
                blockedTotal: zero,
                pendingSpendable: zero,
              ),
            ),
          ],
          child: desktop
              ? const DesktopTokenSend(walletId: walletId)
              : TokenSendView(
                  walletId: walletId,
                  coin: coin,
                  tokenContract: contract,
                ),
        );
        // The token views keep their amount in widget state, so the blank
        // field is the only observable after the clear.
        await clearFiatThenChangeUnit(
          tester,
          prefs,
          expectCleared: () => expect(
            container.read(previewTokenTxButtonStateProvider.state).state,
            isFalse,
          ),
        );
      },
    );
  }
}
