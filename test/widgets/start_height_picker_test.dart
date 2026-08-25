import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/start_height_picker.dart';

import '../sample_data/theme_json.dart';

void main() {
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final mwc = Mimblewimblecoin(CryptoCurrencyNetwork.main);
  final epic = Epiccash(CryptoCurrencyNetwork.main);

  Widget testApp(Widget child) => MaterialApp(
    theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
    home: Scaffold(body: child),
  );

  setUp(() {
    Util.screenWidth = 400;
  });

  tearDown(() {
    Util.screenWidth = null;
  });

  group("StartHeightPicker.isSupported", () {
    test("covers exactly the coins whose rescan honours a start height", () {
      expect(
        StartHeightPicker.isSupported(Monero(CryptoCurrencyNetwork.main)),
        isTrue,
      );
      expect(
        StartHeightPicker.isSupported(Wownero(CryptoCurrencyNetwork.main)),
        isTrue,
      );
      expect(
        StartHeightPicker.isSupported(Salvium(CryptoCurrencyNetwork.main)),
        isTrue,
      );
      expect(StartHeightPicker.isSupported(epic), isTrue);
      expect(StartHeightPicker.isSupported(mwc), isTrue);
      expect(
        StartHeightPicker.isSupported(Bitcoin(CryptoCurrencyNetwork.main)),
        isFalse,
      );
    });
  });

  group("StartHeightPicker.heightFromDate", () {
    test("Mimblewimblecoin gets the same estimate Epic Cash does", () {
      final date = DateTime.utc(2024, 6, 1);
      final height = StartHeightPicker.heightFromDate(mwc, date);
      expect(height, isNotNull);
      expect(height, greaterThan(0));
      expect(height, StartHeightPicker.heightFromDate(epic, date));
    });

    test("clamps dates before the genesis block to zero", () {
      expect(StartHeightPicker.heightFromDate(mwc, DateTime.utc(2010)), 0);
    });

    test("returns null for a coin with no date to height mapping", () {
      expect(
        StartHeightPicker.heightFromDate(
          Bitcoin(CryptoCurrencyNetwork.main),
          DateTime.utc(2024),
        ),
        isNull,
      );
    });
  });

  group("StartHeightPickerController", () {
    test("reports no height until something is chosen", () {
      final controller = StartHeightPickerController();
      addTearDown(controller.dispose);

      expect(controller.height, isNull);
      expect(controller.isUsingDate, isTrue);
    });

    test("setHeight switches to block height mode", () {
      final controller = StartHeightPickerController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setHeight(3000000);

      expect(controller.height, 3000000);
      expect(controller.isUsingDate, isFalse);
      expect(notifications, 1);
    });
  });

  testWidgets("setHeight prefills a field the user can still edit", (
    tester,
  ) async {
    final controller = StartHeightPickerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testApp(StartHeightPicker(coin: mwc, controller: controller)),
    );

    controller.setHeight(3000000);
    await tester.pump();

    final field = find.byKey(const Key("startHeightPickerBlockHeightFieldKey"));
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, "3000000");

    await tester.enterText(field, "2500000");
    await tester.pump();

    expect(controller.height, 2500000);
  });

  testWidgets("an empty block height field reports no height", (tester) async {
    final controller = StartHeightPickerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testApp(StartHeightPicker(coin: mwc, controller: controller)),
    );

    // The mode toggle renders as a RichText span, so drive its callback.
    tester.widget<CustomTextButton>(find.byType(CustomTextButton)).onTap!();
    await tester.pump();

    expect(controller.isUsingDate, isFalse);
    expect(controller.height, isNull);
  });
}
