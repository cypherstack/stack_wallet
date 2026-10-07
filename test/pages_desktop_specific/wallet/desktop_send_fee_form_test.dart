import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send_fee_form.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/desktop_fee_providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/desktop/desktop_fee_dialog.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

const _walletId = "wallet id";
final _coin = Bitcoin(CryptoCurrencyNetwork.main);
final _info = WalletInfo(
  walletId: _walletId,
  name: "Bitcoin wallet",
  mainAddressType: AddressType.p2wpkh,
  coinName: _coin.identifier,
);

/// Bitcoin wallet counting its fee rate fetches, the first [failingFetches]
/// of which fail.
class _FeeWallet implements Wallet<Bitcoin> {
  _FeeWallet({this.failingFetches = 0});

  final int failingFetches;
  var feeFetches = 0;

  @override
  WalletInfo get info => _info;

  @override
  Future<FeeObject> get fees async {
    feeFetches++;
    if (feeFetches <= failingFetches) throw Exception("node unreachable");
    return FeeObject(
      numberOfBlocksFast: 1,
      numberOfBlocksAverage: 5,
      numberOfBlocksSlow: 20,
      fast: BigInt.from(20000),
      medium: BigInt.from(10000),
      slow: BigInt.from(5000),
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async =>
      Amount(rawValue: BigInt.from(1410), fractionDigits: 8);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pump the fee form for [wallet] and return its parent's setState.
Future<StateSetter> _pumpForm(WidgetTester tester, _FeeWallet wallet) async {
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  late StateSetter rebuild;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pWallets.overrideWithValue(ConfirmationWallets(wallet)),
        pWalletCoin(_walletId).overrideWithValue(_coin),
        pAmountFormatter(_coin).overrideWithValue(
          AmountFormatter(
            unit: AmountUnit.normal,
            locale: "en_US",
            coin: _coin,
            maxDecimals: 8,
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return DesktopSendFeeForm(
                walletId: _walletId,
                isToken: false,
                onCustomFeeSliderChanged: (_) {},
                onCustomFeeOptionChanged: () {},
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return rebuild;
}

void main() {
  testWidgets("a rebuild keeps the fee rates and the amount", (tester) async {
    final wallet = _FeeWallet();
    final rebuild = await _pumpForm(tester, wallet);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DesktopSendFeeForm)),
    );
    final amount = Amount(rawValue: BigInt.from(22000), fractionDigits: 8);
    container.read(sendAmountProvider.notifier).state = amount;
    await tester.pump();

    rebuild(() {});
    await tester.pump();
    await tester.pump();

    expect(wallet.feeFetches, 1);
    expect(container.read(sendAmountProvider), amount);
  });

  testWidgets("a rebuild fetches the fee rates again after a failure", (
    tester,
  ) async {
    final wallet = _FeeWallet(failingFetches: 1);
    final rebuild = await _pumpForm(tester, wallet);
    expect(find.byType(DesktopFeeItem), findsNothing);

    rebuild(() {});
    await tester.pump();
    await tester.pump();

    expect(wallet.feeFetches, 2);
    expect(find.byType(DesktopFeeItem), findsOneWidget);

    rebuild(() {});
    await tester.pump();

    expect(wallet.feeFetches, 2);
    expect(find.byType(DesktopFeeItem), findsOneWidget);
  });
}
