import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/restore_options_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_from_date_picker.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_options_next_button.dart';
import 'package:stackwallet/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../sample_data/theme_json.dart';

void main() {
  testWidgets("stagenet offers explicit height instead of mainnet dates", (
    tester,
  ) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    final container = ProviderContainer(
      overrides: [themeProvider.overrideWithValue(StateController(theme))],
    );
    addTearDown(container.dispose);
    Util.screenWidth = 400;
    addTearDown(() => Util.screenWidth = null);
    container.read(mnemonicWordCountStateProvider.state).state = 25;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: RestoreOptionsView(
            walletName: "stagenet",
            coin: Monero(CryptoCurrencyNetwork.stage),
          ),
        ),
      ),
    );

    expect(find.byType(RestoreFromDatePicker), findsNothing);
    expect(find.text("Block height"), findsOneWidget);
    expect(
      tester
          .widget<RestoreOptionsNextButton>(
            find.byType(RestoreOptionsNextButton),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).first, "0");
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RestoreOptionsNextButton>(
            find.byType(RestoreOptionsNextButton),
          )
          .onPressed,
      isNotNull,
    );
  });
}
