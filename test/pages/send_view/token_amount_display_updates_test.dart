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
import 'package:stackwallet/pages/send_view/token_send_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_token_send.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
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
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _Locale extends LocaleService {
  String value = 'en_US';
  @override
  String get locale => value;
  void change(String next) {
    value = next;
    notifyListeners();
  }
}

class _Prefs extends ConfirmationPrefs {
  AmountUnit value = AmountUnit.normal;
  @override
  bool get enableCoinControl => false;
  @override
  bool get externalCalls => false;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => value;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
  void change(AmountUnit next) {
    value = next;
    notifyListeners();
  }
}

class _Price extends PriceService {
  _Price() : super('USD');
  @override
  ({Decimal value, double change24h})? getTokenPrice(String contractAddress) =>
      (value: Decimal.one, change24h: 0);
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
  TxData? captured;
  @override
  Future<TxData> prepareSend({required TxData txData, String? assetId}) async {
    captured = txData;
    throw StateError('capture');
  }
}

void main() {
  const walletId = 'token-r2';
  for (final desktop in [false, true]) {
    for (final decimals in [6, 8, 18]) {
      for (final unitFirst in [false, true]) {
        testWidgets(
          'token input transitions desktop=$desktop decimals=$decimals unitFirst=$unitFirst',
          (tester) async {
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
            final coin = Ethereum(CryptoCurrencyNetwork.main);
            final contract = DefaultTokens.rsFiro.copyWith(decimals: decimals);
            final info = WalletInfo(
              walletId: walletId,
              name: 'Token test',
              mainAddressType: AddressType.ethereum,
              coinName: coin.identifier,
            );
            final wallet = _ParentWallet(info);
            final tokenWallet = _TokenWallet(contract, info);
            final prefs = _Prefs();
            final locale = _Locale();
            final zero = Amount.zeroWith(fractionDigits: decimals);
            final balance = Balance(
              total: zero,
              spendable: zero,
              blockedTotal: zero,
              pendingSpendable: zero,
            );
            final theme = StackTheme.fromJson(json: lightThemeJsonMap);
            final container = ProviderContainer(
              overrides: [
                pWallets.overrideWithValue(ConfirmationWallets(wallet)),
                pCurrentTokenWallet.overrideWithValue(tokenWallet),
                pWalletInfo(walletId).overrideWithValue(info),
                pWalletCoin(walletId).overrideWithValue(coin),
                pWalletName(walletId).overrideWithValue(info.name),
                pTokenBalance((
                  walletId: walletId,
                  contractAddress: contract.address,
                )).overrideWithValue(balance),
                prefsChangeNotifierProvider.overrideWithValue(prefs),
                localeServiceChangeNotifierProvider.overrideWithValue(locale),
                priceAnd24hChangeNotifierProvider.overrideWithValue(_Price()),
                themeProvider.overrideWithProvider(
                  StateProvider((ref) => theme),
                ),
                coinIconProvider(coin).overrideWithValue(
                  File('test/sample_data/light/assets/dummy.svg').absolute.path,
                ),
              ],
            );
            addTearDown(container.dispose);
            final child = desktop
                ? const DesktopTokenSend(walletId: walletId)
                : TokenSendView(
                    walletId: walletId,
                    coin: coin,
                    tokenContract: contract,
                  );
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
            final field = find.byKey(
              const Key('amountInputFieldCryptoTextFieldKey'),
            );
            await tester.enterText(field, '1.250001');
            await tester.pump(const Duration(milliseconds: 600));
            if (unitFirst) {
              prefs.change(AmountUnit.milli);
              locale.change('de_DE');
            } else {
              locale.change('de_DE');
              prefs.change(AmountUnit.milli);
            }
            await tester.pump(const Duration(milliseconds: 600));
            expect(
              tester.widget<TextField>(field).controller!.text,
              '1250,001',
            );
            final address = find.byKey(
              Key(
                desktop
                    ? 'sendViewAddressFieldKey'
                    : 'tokenSendViewAddressFieldKey',
              ),
            );
            await tester.enterText(
              address,
              '0x2744ea5ac9b11cb5e3cd63d3a88e858336aeddc2',
            );
            await tester.pump();
            if (desktop) {
              final preview = tester.widget<PrimaryButton>(
                find.widgetWithText(PrimaryButton, 'Preview send'),
              );
              expect(preview.enabled, true);
              preview.onPressed!();
            } else {
              final preview = tester.widget<TextButton>(
                find.widgetWithText(TextButton, 'Preview'),
              );
              expect(preview.onPressed, isNotNull);
              preview.onPressed!();
            }
            await tester.pump(const Duration(milliseconds: 150));
            await tester.pump(const Duration(milliseconds: 2600));
            expect(tokenWallet.captured, isNotNull);
            final amount = tokenWallet.captured!.recipients!.single.amount;
            expect(
              amount,
              Amount.tryParseCanonicalAmount(
                '1.250001',
                fractionDigits: decimals,
              ),
            );
            expect(amount.fractionDigits, decimals);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
}
