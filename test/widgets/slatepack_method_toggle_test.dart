import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import 'package:stackwallet/widgets/slatepack_method_toggle.dart';
import 'package:stackwallet/widgets/toggle.dart';

import '../wallets/support/xelis_test_fakes.dart';

class _SlatepackOnlyWallet extends MimblewimblecoinWallet {
  _SlatepackOnlyWallet() : super(CryptoCurrencyNetwork.main);

  @override
  List<SlatepackMethod> get supportedMethods => const [
    SlatepackMethod.slatepack,
  ];
}

void main() {
  test('a slatepack-only wallet reports no method toggle', () {
    expect(_SlatepackOnlyWallet().hasSlatepackMethodToggle, isFalse);
  });

  testWidgets('a slatepack-only wallet has no method toggle', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(
            ConfirmationWallets(_SlatepackOnlyWallet()),
          ),
        ],
        child: const MaterialApp(
          home: SlatepackMethodToggle(walletId: 'wallet'),
        ),
      ),
    );

    expect(find.byType(Toggle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
