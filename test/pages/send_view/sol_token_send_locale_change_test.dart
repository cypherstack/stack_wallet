import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/send_view/sol_token_send_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_sol_token_send.dart';
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
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import 'package:stackwallet/wallets/isar/providers/solana/sol_token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';
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
  @override
  bool get enableCoinControl => false;
  @override
  bool get externalCalls => true;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => AmountUnit.normal;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
}

class _Price extends PriceService {
  _Price() : super('USD');
  @override
  ({Decimal value, double change24h})? getTokenPrice(String contractAddress) =>
      (value: Decimal.one, change24h: 0);
}

final _fee = Amount(rawValue: BigInt.from(5000), fractionDigits: 9);

FeeObject get _fees => FeeObject(
  numberOfBlocksFast: 1,
  numberOfBlocksAverage: 1,
  numberOfBlocksSlow: 1,
  fast: _fee.raw,
  medium: _fee.raw,
  slow: _fee.raw,
);

class _ParentWallet extends Fake implements Wallet<Solana> {
  _ParentWallet(this.info);
  @override
  final WalletInfo info;
  @override
  Solana get cryptoCurrency => info.coin as Solana;
  @override
  Future<FeeObject> get fees async => _fees;
  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async => _fee;
}

class _SolTokenWallet extends Fake implements SolanaTokenWallet {
  _SolTokenWallet(this.solContract, this.info);
  @override
  final SolContract solContract;
  @override
  final WalletInfo info;
  @override
  String get walletId => info.walletId;
  @override
  CryptoCurrency get cryptoCurrency => info.coin;
  @override
  String get tokenMint => solContract.address;
  @override
  String get tokenSymbol => solContract.symbol;
  @override
  int get tokenDecimals => solContract.decimals;
  @override
  Future<FeeObject> get fees async => _fees;
  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async => _fee;

  TxData? captured;
  @override
  Future<TxData> prepareSend({required TxData txData, String? assetId}) async {
    captured = txData;
    throw StateError('capture');
  }
}

void main() {
  const walletId = 'sol-locale';
  const mint = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

  Future<(_Locale, _SolTokenWallet)> mount(
    WidgetTester tester, {
    required bool desktop,
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
    final coin = Solana(CryptoCurrencyNetwork.main);
    final contract = SolContract(
      address: mint,
      name: 'USD Coin',
      symbol: 'USDC',
      decimals: 6,
    );
    final info = WalletInfo(
      walletId: walletId,
      name: 'Sol test',
      mainAddressType: AddressType.solana,
      coinName: coin.identifier,
    );
    final locale = _Locale();
    final tokenWallet = _SolTokenWallet(contract, info);
    final zero = Amount.zeroWith(fractionDigits: contract.decimals);
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    final container = ProviderContainer(
      overrides: [
        pWallets.overrideWithValue(ConfirmationWallets(_ParentWallet(info))),
        pCurrentSolanaTokenWallet.overrideWithValue(tokenWallet),
        pWalletInfo(walletId).overrideWithValue(info),
        pWalletCoin(walletId).overrideWithValue(coin),
        pWalletName(walletId).overrideWithValue(info.name),
        pWalletBalance(walletId).overrideWithValue(info.cachedBalance),
        pSolanaTokenBalance((walletId: walletId, tokenMint: mint))
            .overrideWithValue(
              Balance(
                total: zero,
                spendable: zero,
                blockedTotal: zero,
                pendingSpendable: zero,
              ),
            ),
        prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
        localeServiceChangeNotifierProvider.overrideWithValue(locale),
        priceAnd24hChangeNotifierProvider.overrideWithValue(_Price()),
        themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
        coinIconProvider(coin).overrideWithValue(
          File('test/sample_data/light/assets/dummy.svg').absolute.path,
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: desktop
              ? const Scaffold(
                  body: SingleChildScrollView(
                    child: DesktopSolTokenSend(walletId: walletId),
                  ),
                )
              : const SolTokenSendView(walletId: walletId, tokenMint: mint),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return (locale, tokenWallet);
  }

  testWidgets(
    'SOL token send survives a locale change while the fee is pending',
    (tester) async {
      final (locale, _) = await mount(tester, desktop: false);
      expect(find.textContaining('~0.000005'), findsOneWidget);

      final fiat = find.byKey(const Key('solAmountInputFieldFiatTextFieldKey'));
      final crypto = find.byKey(
        const Key('solAmountInputFieldCryptoTextFieldKey'),
      );
      String cryptoText() => tester.widget<TextField>(crypto).controller!.text;

      // Each fiat edit schedules a fee recalculation half a second later. A
      // 600 ms pump fires that timer and renders the pending fee row, so the
      // fee row is not subscribed to the amount formatter when the locale
      // changes below. The locale change then has to refresh the formatter
      // lazily, which must not happen from inside the fee row's build.
      await tester.enterText(fiat, '1');
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(cryptoText(), '1');

      await tester.enterText(fiat, '');
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(cryptoText(), '');

      locale.change('de_DE');
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('~0,000005'), findsOneWidget);

      locale.change('fr_FR');
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('~0,000005'), findsOneWidget);
      expect(cryptoText(), '');
    },
  );

  for (final desktop in [false, true]) {
    testWidgets(
      'SOL token locale display preserves the next send desktop=$desktop',
      (tester) async {
        final (locale, tokenWallet) = await mount(tester, desktop: desktop);
        final crypto = find.byKey(
          Key(
            desktop
                ? 'amountInputFieldCryptoTextFieldKey'
                : 'solAmountInputFieldCryptoTextFieldKey',
          ),
        );
        final fiat = find.byKey(
          Key(
            desktop
                ? 'amountInputFieldFiatTextFieldKey'
                : 'solAmountInputFieldFiatTextFieldKey',
          ),
        );
        final controller = tester.widget<TextField>(crypto).controller!;
        await tester.enterText(crypto, '1.250001');
        await tester.pump(const Duration(milliseconds: 600));
        controller.selection = const TextSelection.collapsed(offset: 3);

        locale.change('de_DE');
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(controller.text, '1,250001');
        expect(controller.selection, const TextSelection.collapsed(offset: 3));
        expect(tester.widget<TextField>(fiat).controller!.text, '1,25');

        // A real edit after relocalization must still update the send amount.
        await tester.enterText(crypto, '2,500002');
        await tester.pump(const Duration(milliseconds: 600));
        locale.change('en_US');
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(controller.text, '2.500002');

        await tester.enterText(
          find.byKey(
            Key(
              desktop
                  ? 'sendViewAddressFieldKey'
                  : 'solTokenSendViewAddressFieldKey',
            ),
          ),
          mint,
        );
        await tester.pump();
        if (desktop) {
          final preview = tester.widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'Preview send'),
          );
          expect(preview.enabled, isTrue);
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
          Amount(rawValue: BigInt.from(2500002), fractionDigits: 6),
        );
      },
    );
  }
}
