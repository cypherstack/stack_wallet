import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_network_settings_view/sub_widgets/confirm_full_rescan.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

import '../sample_data/theme_json.dart';

void main() {
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  const blockHeightFieldKey = Key("startHeightPickerBlockHeightFieldKey");

  setUp(() {
    Util.screenWidth = 400;
  });

  tearDown(() {
    Util.screenWidth = null;
  });

  Future<void> openDialog(
    WidgetTester tester,
    CryptoCurrency coin,
    void Function(int?) onConfirm,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      ConfirmFullRescanDialog(coin: coin, onConfirm: onConfirm),
                ),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
  }

  testWidgets("a Mimblewimblecoin rescan height reaches the caller", (
    tester,
  ) async {
    int? got;
    var called = false;
    await openDialog(tester, Mimblewimblecoin(CryptoCurrencyNetwork.main), (
      height,
    ) {
      got = height;
      called = true;
    });

    tester.widget<CustomTextButton>(find.byType(CustomTextButton)).onTap!();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(blockHeightFieldKey), "12345");
    await tester.pumpAndSettle();

    await tester.tap(find.text("Rescan"));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(got, 12345);
  });

  testWidgets("Epic Cash is offered the height control", (tester) async {
    await openDialog(tester, Epiccash(CryptoCurrencyNetwork.main), (_) {});

    expect(find.text("Choose start date"), findsOneWidget);
  });

  testWidgets("a coin that cannot use a start height is not offered one", (
    tester,
  ) async {
    int? got = 1;
    var called = false;
    await openDialog(tester, Bitcoin(CryptoCurrencyNetwork.main), (height) {
      got = height;
      called = true;
    });

    expect(find.text("Choose start date"), findsNothing);
    expect(find.byKey(blockHeightFieldKey), findsNothing);

    await tester.tap(find.text("Rescan"));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(got, isNull);
  });

  testWidgets("the desktop dialog fits the height picker", (tester) async {
    // A Linux test host reports desktop unless a phone-sized width is set.
    Util.screenWidth = null;

    int? got;
    await openDialog(tester, Epiccash(CryptoCurrencyNetwork.main), (height) {
      got = height;
    });

    expect(find.text("Choose start date"), findsOneWidget);

    tester.widget<CustomTextButton>(find.byType(CustomTextButton)).onTap!();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(blockHeightFieldKey), "777");
    await tester.pumpAndSettle();

    await tester.tap(find.text("Rescan"));
    await tester.pumpAndSettle();

    expect(got, 777);
  });

  testWidgets("no height chosen leaves the stored restore height alone", (
    tester,
  ) async {
    int? got = 1;
    var called = false;
    await openDialog(tester, Mimblewimblecoin(CryptoCurrencyNetwork.main), (
      height,
    ) {
      got = height;
      called = true;
    });

    await tester.tap(find.text("Rescan"));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(got, isNull);
  });
}
