import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/step_scaffold.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_4.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_exchange.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/qr.dart';

import '../../sample_data/theme_json.dart';

void main() {
  for (final fromFiro in [true, false]) {
    for (final hasWallet in [true, false]) {
      testWidgets('Rosen ${fromFiro ? 'FIRO' : 'rsFIRO'} instructions '
          '${hasWallet ? 'with' : 'without'} a funding wallet', (tester) async {
        final ticker = fromFiro ? 'FIRO' : 'rsFIRO';
        final colors = await _pumpStep(
          tester,
          _Trade(RosenExchange.exchangeName, ticker, 'Confirming'),
          hasWallet ? [fromFiro ? _FiroWallet() : _EthereumWallet()] : [],
        );
        expect(find.text('Send with Rosen Bridge'), findsOneWidget);
        expect(find.text('1.23456789 $ticker'), findsOneWidget);
        expect(
          find.textContaining(
            fromFiro ? 'transparent FIRO balance' : 'enough ETH',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Add a ${fromFiro ? 'FIRO' : 'Ethereum'} wallet to fund this swap.',
          ),
          hasWallet ? findsNothing : findsOneWidget,
        );
        expect(find.text('bridge-trade'), findsOneWidget);
        expect(find.text('deposit-address'), findsNothing);
        expect(find.text('deposit-memo'), findsNothing);
        expect(find.text('Memo'), findsNothing);
        expect(find.byType(SimpleCopyButton), findsNothing);
        expect(find.byType(QR), findsNothing);
        expect(
          tester.widget<Text>(find.text('Confirming')).style!.color,
          colors.colorForStatus('Confirming'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('ordinary provider keeps its address, memo and deposit warning', (
    tester,
  ) async {
    final colors = await _pumpStep(
      tester,
      _Trade('ChangeNOW', 'btc', 'Waiting'),
      [],
    );
    expect(find.text('Send BTC to the address below'), findsOneWidget);
    expect(find.text('Send BTC to this address'), findsOneWidget);
    expect(find.text('deposit-address'), findsOneWidget);
    expect(find.text('Memo'), findsOneWidget);
    expect(find.text('deposit-memo'), findsOneWidget);
    expect(find.byType(SimpleCopyButton), findsOneWidget);
    expect(find.text('1.23456789 BTC'), findsOneWidget);
    expect(
      find.textContaining(
        'You must send at least 1.23456789 btc.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Add a '), findsNothing);
    expect(
      tester.widget<Text>(find.text('Waiting for deposit')).style!.color,
      colors.colorForStatus('Waiting for deposit'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<StackColors> _pumpStep(
  WidgetTester tester,
  Trade trade,
  List<Wallet> wallets,
) async {
  final currency = Currency(
    exchangeName: trade.exchangeName,
    ticker: trade.payInCurrency,
    name: trade.payInCurrency,
    network: '',
    image: '',
    isFiat: false,
    rateType: SupportedRateType.estimated,
    isStackCoin: true,
    tokenContract: null,
  );
  final model = IncompleteExchangeModel(
    sendCurrency: currency,
    receiveCurrency: currency,
    rateInfo: '',
    sendAmount: Decimal.one,
    receiveAmount: Decimal.one,
    rateType: ExchangeRateType.estimated,
    reversed: false,
    walletInitiated: false,
  )..trade = trade;
  final colors = StackColors.fromStackColorTheme(
    StackTheme.fromJson(json: lightThemeJsonMap),
  );
  await tester.binding.setSurfaceSize(const Size(1000, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        desktopExchangeModelProvider.overrideWithValue(model),
        pWallets.overrideWithValue(_Wallets(wallets)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: const Scaffold(body: DesktopStep4()),
      ),
    ),
  );
  expect(tester.takeException(), isNull);
  return colors;
}

class _Trade extends Fake implements Trade {
  _Trade(this.exchangeName, this.payInCurrency, this.status);
  @override
  final String exchangeName;
  @override
  final String payInCurrency;
  @override
  final String status;
  @override
  String get payInAmount => '1.23456789';
  @override
  String get payInAddress => 'deposit-address';
  @override
  String get payInExtraId => 'deposit-memo';
  @override
  String get tradeId => 'bridge-trade';
}

class _Wallets extends Fake implements Wallets {
  _Wallets(this.wallets);
  @override
  final List<Wallet> wallets;
}

class _Info extends Fake implements WalletInfo {
  @override
  bool get isViewOnly => false;
}

class _FiroWallet extends Fake implements FiroWallet {
  @override
  final Firo cryptoCurrency = Firo(CryptoCurrencyNetwork.main);
  @override
  final WalletInfo info = _Info();
}

class _EthereumWallet extends Fake implements EthereumWallet {
  @override
  final Ethereum cryptoCurrency = Ethereum(CryptoCurrencyNetwork.main);
  @override
  final WalletInfo info = _Info();
}
