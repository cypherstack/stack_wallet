import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_receive.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/qr.dart';

import '../../sample_data/theme_json.dart';

const _walletId = 'desktop-slatepack-wallet';
const _address = 'esZrAddressThatMustNotAppearInSlatepackMode';

class _Wallet extends EpiccashWallet {
  _Wallet(this._info) : super(CryptoCurrencyNetwork.main);

  final WalletInfo _info;

  @override
  String get walletId => _info.walletId;

  @override
  WalletInfo get info => _info;
}

class _Wallets extends Fake implements Wallets {
  _Wallets(this.wallet);

  final Wallet wallet;

  @override
  Wallet getWallet(String walletId) => wallet;
}

void main() {
  testWidgets('slatepack mode replaces the desktop address and QR', (
    tester,
  ) async {
    final previousPlatform = Util.layoutPlatform;
    final previousWidth = Util.screenWidth;
    Util.layoutPlatform = platform.FakePlatform(operatingSystem: 'linux');
    Util.screenWidth = 1400;
    addTearDown(() {
      Util.layoutPlatform = previousPlatform;
      Util.screenWidth = previousWidth;
    });

    final info = WalletInfo.createNew(
      coin: Epiccash(CryptoCurrencyNetwork.main),
      name: 'Epic Cash',
      walletIdOverride: _walletId,
    ).copyWith(cachedReceivingAddress: _address);
    final wallet = _Wallet(info);
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(_Wallets(wallet)),
          pWalletInfo(_walletId).overrideWithValue(info),
          pWalletReceivingAddress(_walletId).overrideWithValue(_address),
          pSelectedSlatepackMethod(_walletId).overrideWithProvider(
            StateProvider<SlatepackMethod?>((ref) => SlatepackMethod.slatepack),
          ),
          themeProvider.overrideWithProvider(
            StateProvider<StackTheme>((ref) => theme),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 520,
              child: DesktopReceive(walletId: _walletId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Import Slate'), findsNWidgets(2));
    expect(find.text('Enter Slate JSON'), findsOneWidget);
    expect(find.text(_address), findsNothing);
    expect(find.text('Create new QR code'), findsNothing);
    expect(find.byType(QR), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
