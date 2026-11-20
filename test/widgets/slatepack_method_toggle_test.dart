import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import 'package:stackwallet/widgets/slatepack_method_toggle.dart';
import 'package:stackwallet/widgets/toggle.dart';

import '../sample_data/theme_json.dart';
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

  testWidgets('Epic labels its manual method Slate', (tester) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(
            ConfirmationWallets(EpiccashWallet(CryptoCurrencyNetwork.main)),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: const SlatepackMethodToggle(walletId: 'wallet'),
        ),
      ),
    );

    expect(find.text('Slate'), findsOneWidget);
    expect(find.text('Slatepack'), findsNothing);
  });
}
