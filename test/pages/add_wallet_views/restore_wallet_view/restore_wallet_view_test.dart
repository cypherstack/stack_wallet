import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/confirm_recovery_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_wallet_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restore_failed_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restoring_dialog.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/wl_gen/interfaces/cs_monero_interface.dart';

import '../../../sample_data/theme_json.dart';
import '../../../screen_tests/onboarding/restore_wallet_view_screen_test.mocks.dart';

const _moneroMnemonic =
    "agreed aquarium wallets uptight karate wonders afoot guys itself "
    "nucleus reduce lamb fully fewest bimonthly dazed skulls magically "
    "mocked fugitive imbalance saga calamity dialect itself";

void main() {
  testWidgets("mnemonic errors use the custom field validation", (
    tester,
  ) async {
    final stackColors = await _pumpRestoreView(
      tester,
      coin: Bitcoin(CryptoCurrencyNetwork.main),
      seedWordsLength: 12,
    );

    final firstWordField = find.byType(TextFormField).first;
    await tester.enterText(firstWordField, "notaword");
    await tester.pump();

    expect(find.text("Invalid word"), findsNothing);
    expect(find.text("Please check spelling"), findsOneWidget);
    final errorText = tester.widget<Text>(find.text("Please check spelling"));
    expect(errorText.style?.color, stackColors.textError);

    await tester.enterText(firstWordField, "abandon");
    await tester.pump();
    expect(find.text("Please check spelling"), findsNothing);

    await tester.tap(find.widgetWithText(PrimaryButton, "Restore wallet"));
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmRecoveryDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, "Restore"));
    await tester.pump();

    expect(
      find.text("Expected 12 words but got 1. Please fill in all fields."),
      findsOneWidget,
    );
  });

  testWidgets("legacy Monero words and multiline paste are accepted", (
    tester,
  ) async {
    final words = _moneroMnemonic.split(" ")..first = "agr";
    final clipboard = FakeClipboard();
    await clipboard.setData(
      ClipboardData(
        text:
            "${words.take(12).join(" ")}\n\t"
            "${words.skip(12).join("  ")}",
      ),
    );

    await _pumpRestoreView(
      tester,
      coin: Monero(CryptoCurrencyNetwork.main),
      seedWordsLength: 25,
      clipboard: clipboard,
    );

    await tester.tap(find.widgetWithText(TextButton, "Paste"));
    await tester.pump();

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList(growable: false);
    expect(fields, hasLength(25));
    expect(fields.map((field) => field.controller!.text), orderedEquals(words));
    expect(find.text("Please check spelling"), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, "zzzz");
    await tester.pump();
    expect(find.text("Please check spelling"), findsOneWidget);
  });

  testWidgets("restore revalidates every mnemonic field", (tester) async {
    final clipboard = FakeClipboard();
    await clipboard.setData(
      const ClipboardData(
        text:
            "abandon abandon abandon abandon abandon abandon abandon abandon "
            "abandon abandon abandon about",
      ),
    );
    await _pumpRestoreView(
      tester,
      coin: Bitcoin(CryptoCurrencyNetwork.main),
      seedWordsLength: 12,
      clipboard: clipboard,
    );
    await tester.tap(find.widgetWithText(TextButton, "Paste"));
    await tester.pump();
    expect(find.text("Please check spelling"), findsNothing);

    final firstField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    firstField.controller!.text = "zzzz";

    await tester.tap(find.widgetWithText(PrimaryButton, "Restore wallet"));
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, "Restore"));
    await tester.pump();

    expect(find.byType(RestoringDialog), findsNothing);
    expect(find.text("Please check spelling"), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(TextFormField).first,
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isFalse,
    );
  });

  testWidgets("legacy words from any CryptoNote language are accepted", (
    tester,
  ) async {
    // Spanish members of the Monero wordlist, none of which is an English word
    // or shares an English word's three letter prefix.
    const mnemonic =
        "abeja aldea arpa atar barco brecha capucha chico conejo cuento "
        "derrota escala fase fobia gozar hebra huir leyenda lujo marea "
        "minero nuera odio ombligo pez";
    final english = csMonero.getMoneroWordList("English");
    final englishPrefixes = english.map((word) => word.substring(0, 3)).toSet();
    for (final word in mnemonic.split(" ")) {
      expect(csMonero.getMoneroWordList("Spanish"), contains(word));
      expect(english, isNot(contains(word)));
      expect(englishPrefixes, isNot(contains(word.substring(0, 3))));
    }

    final clipboard = FakeClipboard();
    await clipboard.setData(const ClipboardData(text: mnemonic));
    await _pumpRestoreView(
      tester,
      coin: Monero(CryptoCurrencyNetwork.main),
      seedWordsLength: 25,
      clipboard: clipboard,
    );

    await tester.tap(find.widgetWithText(TextButton, "Paste"));
    await tester.pump();
    expect(find.text("Please check spelling"), findsNothing);

    await tester.tap(find.widgetWithText(PrimaryButton, "Restore wallet"));
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, "Restore"));
    await tester.pump();

    expect(find.text("Please check spelling"), findsNothing);
    // Validation passed and the restore started; what fails is Wallet.create,
    // which cannot run against a widget test's storage.
    expect(find.byType(RestoreFailedDialog), findsOneWidget);
  });

  testWidgets("an unknown legacy word still stops wallet creation", (
    tester,
  ) async {
    final words = _moneroMnemonic.split(" ")..[12] = "zzz";
    final clipboard = FakeClipboard();
    await clipboard.setData(ClipboardData(text: words.join(" ")));
    await _pumpRestoreView(
      tester,
      coin: Monero(CryptoCurrencyNetwork.main),
      seedWordsLength: 25,
      clipboard: clipboard,
    );

    await tester.tap(find.widgetWithText(TextButton, "Paste"));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, "Restore wallet"));
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, "Restore"));
    await tester.pump();

    expect(find.text("Please check spelling"), findsOneWidget);
    expect(find.byType(RestoringDialog), findsNothing);
    expect(find.byType(RestoreFailedDialog), findsNothing);
  });

  testWidgets("a rejected seed phrase stays readable", (tester) async {
    // Every word is in the BIP39 list but the checksum does not match.
    final clipboard = FakeClipboard();
    await clipboard.setData(
      ClipboardData(text: List.filled(12, "abandon").join(" ")),
    );
    await _pumpRestoreView(
      tester,
      coin: Bitcoin(CryptoCurrencyNetwork.main),
      seedWordsLength: 12,
      clipboard: clipboard,
    );

    await tester.tap(find.widgetWithText(TextButton, "Paste"));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, "Restore wallet"));
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, "Restore"));
    await tester.pump();

    expect(find.text("Invalid seed phrase!"), findsOneWidget);
    expect(find.byType(RestoringDialog), findsNothing);
    expect(find.byType(RestoreFailedDialog), findsNothing);
    for (var i = 0; i < 12; i++) {
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byType(TextFormField).at(i),
                matching: find.byType(EditableText),
              ),
            )
            .obscureText,
        isFalse,
        reason: "field $i must stay readable so the user can correct it",
      );
    }
  });

  testWidgets("a whitespace only paste leaves the fields untouched", (
    tester,
  ) async {
    final clipboard = FakeClipboard();
    await clipboard.setData(const ClipboardData(text: "   \n\t  "));
    await _pumpRestoreView(
      tester,
      coin: Bitcoin(CryptoCurrencyNetwork.main),
      seedWordsLength: 12,
      clipboard: clipboard,
    );

    await tester.tap(find.widgetWithText(TextButton, "Paste"));
    await tester.pump();

    final first = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(first.controller!.text, isEmpty);
    expect(find.text("Please check spelling"), findsNothing);
  });
}

Future<StackColors> _pumpRestoreView(
  WidgetTester tester, {
  required CryptoCurrency coin,
  required int seedWordsLength,
  ClipboardInterface clipboard = const ClipboardWrapper(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 1000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final nodeService = MockNodeService();
  when(
    nodeService.getPrimaryNodeFor(currency: anyNamed("currency")),
  ).thenReturn(null);

  final stackTheme = StackTheme.fromJson(json: lightThemeJsonMap);
  final stackColors = StackColors.fromStackColorTheme(stackTheme);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeProvider.overrideWithValue(StateController(stackTheme)),
        nodeServiceChangeNotifierProvider.overrideWithValue(nodeService),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [stackColors]),
        home: RestoreWalletView(
          walletName: "Test wallet",
          coin: coin,
          seedWordsLength: seedWordsLength,
          mnemonicPassphrase: "",
          restoreBlockHeight: 0,
          clipboard: clipboard,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return stackColors;
}
