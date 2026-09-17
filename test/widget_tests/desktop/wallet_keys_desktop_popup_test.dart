import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/models/isar/stack_theme.dart";
import "package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart"
    show IconCopyButton;
import "package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/wallet_keys_desktop_popup.dart";
import "package:stackwallet/themes/stack_colors.dart";

import "../../sample_data/theme_json.dart";

void main() {
  testWidgets("shows and copies the previous FROST keys", (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          home: const Scaffold(
            body: WalletKeysDesktopPopup(
              words: [],
              walletId: "wallet",
              frostData: (
                myName: "name",
                keys: "current-keys",
                config: "current-config",
                prevGen: (keys: "previous-keys", config: "previous-config"),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((widget) => widget.data),
      ["current-keys", "current-config", "previous-keys", "previous-config"],
    );
    expect(
      tester
          .widgetList<IconCopyButton>(find.byType(IconCopyButton))
          .map((widget) => widget.data),
      ["current-keys", "current-config", "previous-keys", "previous-config"],
    );
  });
}
