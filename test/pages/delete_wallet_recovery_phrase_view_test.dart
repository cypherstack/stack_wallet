import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/keys/cw_key_data.dart';
import 'package:stackwallet/models/keys/wallet_recovery_material.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_backup_views/cn_wallet_keys.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_backup_views/wallet_backup_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/delete_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/delete_wallet_keys_popup.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';

import '../sample_data/theme_json.dart';

void main() {
  const walletId = "wallet-id";
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final keyData = CWKeyData(
    walletId: walletId,
    privateSpendKey: "private-spend",
    privateViewKey: "private-view",
    publicSpendKey: "public-spend",
    publicViewKey: "public-view",
  );

  tearDown(() => Util.screenWidth = null);

  Widget testApp(Widget view) {
    return ProviderScope(
      overrides: [
        themeProvider.overrideWithValue(StateController(theme)),
        pWalletName(walletId).overrideWithValue("wallet"),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: view,
      ),
    );
  }

  testWidgets("shows private-key recovery material", (tester) async {
    Util.screenWidth = 400;
    await tester.pumpWidget(
      testApp(
        DeleteWalletRecoveryPhraseView(
          recoveryMaterial: PrivateKeyWalletRecoveryMaterial(
            walletId: walletId,
            keyData: keyData,
          ),
        ),
      ),
    );

    expect(find.byType(CNWalletKeys), findsOneWidget);
    expect(find.byType(MnemonicTable), findsNothing);
    expect(find.text("Wallet Keys"), findsOneWidget);
  });

  testWidgets("shows keys directly in wallet backup", (tester) async {
    Util.screenWidth = 400;
    await tester.pumpWidget(
      testApp(
        WalletBackupView(
          recoveryMaterial: PrivateKeyWalletRecoveryMaterial(
            walletId: walletId,
            keyData: keyData,
          ),
        ),
      ),
    );

    expect(find.byType(CNWalletKeys), findsOneWidget);
    expect(find.byType(MnemonicTable), findsNothing);
  });

  testWidgets("shows keys in desktop wallet deletion", (tester) async {
    await tester.pumpWidget(
      testApp(
        DeleteWalletKeysPopup(
          recoveryMaterial: PrivateKeyWalletRecoveryMaterial(
            walletId: walletId,
            keyData: keyData,
          ),
        ),
      ),
    );

    expect(find.byType(CNWalletKeys), findsOneWidget);
    expect(find.byType(MnemonicTable), findsNothing);
  });

  testWidgets("keeps mnemonic desktop deletion", (tester) async {
    await tester.pumpWidget(
      testApp(
        DeleteWalletKeysPopup(
          recoveryMaterial: MnemonicWalletRecoveryMaterial(
            walletId: walletId,
            words: const ["one", "two"],
          ),
        ),
      ),
    );

    expect(find.byType(MnemonicTable), findsOneWidget);
    expect(find.byType(CNWalletKeys), findsNothing);
  });

  testWidgets("shows FROST data in desktop deletion", (tester) async {
    await tester.pumpWidget(
      testApp(
        const DeleteWalletKeysPopup(
          recoveryMaterial: FrostWalletRecoveryMaterial(
            walletId: walletId,
            data: (
              myName: "name",
              config: "config",
              keys: "keys",
              prevGen: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text("config"), findsOneWidget);
    expect(find.text("keys"), findsOneWidget);
    expect(find.byType(MnemonicTable), findsNothing);
  });
}
