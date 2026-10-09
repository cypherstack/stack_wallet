import 'dart:async';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_2_view.dart';
import 'package:stackwallet/providers/exchange/exchange_form_state_provider.dart';
import 'package:stackwallet/providers/exchange/exchange_send_from_wallet_id_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_exchange.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/enums/exchange_rate_type_enum.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:tuple/tuple.dart';

import '../../sample_data/theme_json.dart';

void main() {
  for (final closeBeforeAddress in [false, true]) {
    testWidgets(
      closeBeforeAddress
          ? 'recipient prefill is ignored after the view closes'
          : 'recipient prefill enables Next when no refund is required',
      (tester) async {
        final previousThemesDir = StackFileSystem.themesDir;
        final previousPlatform = Util.layoutPlatform;
        final previousIsIpad = Util.isIpad;
        addTearDown(() {
          StackFileSystem.themesDir = previousThemesDir;
          Util.layoutPlatform = previousPlatform;
          Util.isIpad = previousIsIpad;
        });
        StackFileSystem.themesDir = Directory('test/sample_data').absolute;
        Util.layoutPlatform = platform.FakePlatform(operatingSystem: 'android');
        Util.isIpad = false;
        await tester.binding.setSurfaceSize(const Size(1200, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final theme = StackTheme.fromJson(json: lightThemeJsonMap);
        final wallet = _FiroWallet();
        final model = IncompleteExchangeModel(
          sendCurrency: _currency('rsFIRO'),
          receiveCurrency: _currency('FIRO'),
          rateInfo: '',
          sendAmount: Decimal.one,
          receiveAmount: Decimal.one,
          rateType: ExchangeRateType.estimated,
          reversed: false,
          walletInitiated: true,
        );
        addTearDown(model.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pWallets.overrideWithValue(_Wallets(wallet)),
              efExchangeProvider.overrideWithValue(
                StateController(RosenExchange.instance),
              ),
              exchangeSendFromWalletIdStateProvider.overrideWithValue(
                StateController(Tuple2('test', wallet.cryptoCurrency)),
              ),
              themeProvider.overrideWithValue(StateController(theme)),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [StackColors.fromStackColorTheme(theme)],
              ),
              home: Step2View(model: model),
            ),
          ),
        );
        final next = find.byWidgetPredicate(
          (widget) => widget is PrimaryButton && widget.label == 'Next',
        );
        expect(tester.widget<PrimaryButton>(next).enabled, isFalse);
        if (closeBeforeAddress) {
          await tester.pumpWidget(const SizedBox.shrink());
        }
        wallet.address.complete(
          Address(
            walletId: 'test',
            value: _address,
            publicKey: [],
            derivationIndex: 0,
            derivationPath: null,
            type: wallet.cryptoCurrency.defaultAddressType,
            subType: AddressSubType.receiving,
          ),
        );
        await tester.pump();
        if (closeBeforeAddress) {
          expect(model.recipientAddress, isNull);
        } else {
          expect(model.recipientAddress, _address);
          expect(tester.widget<PrimaryButton>(next).enabled, isTrue);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

const _address = 'aEF6fyd5jjCPcbiEBZJ2g8583caUme8T7Y';

Currency _currency(String ticker) => Currency(
  exchangeName: RosenExchange.exchangeName,
  ticker: ticker,
  name: ticker,
  network: ticker.toLowerCase(),
  image: '',
  isFiat: false,
  rateType: SupportedRateType.estimated,
  isStackCoin: true,
  tokenContract: null,
);

class _FiroWallet extends FiroWallet {
  _FiroWallet() : super(CryptoCurrencyNetwork.main);

  final address = Completer<Address?>();

  @override
  Future<Address?> getCurrentReceivingAddress() => address.future;
}

class _Wallets extends Fake implements Wallets {
  _Wallets(this.wallet);

  final FiroWallet wallet;

  @override
  FiroWallet getWallet(String walletId) => wallet;
}
