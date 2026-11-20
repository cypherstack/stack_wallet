import 'package:stackwallet/widgets/date_picker/restore_from_date_picker.dart';
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

  testWidgets('remounting date mode retains the visible selection', (
    tester,
  ) async {
    final controller = StartHeightPickerController();
    final nav = GlobalKey<NavigatorState>();
    Widget app(bool visible) => MaterialApp(
      navigatorKey: nav,
      theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
      home: Scaffold(
        body: visible
            ? StartHeightPicker(coin: mwc, controller: controller)
            : const SizedBox(),
      ),
    );
    await tester.pumpWidget(app(true));
    tester
        .widget<RestoreFromDatePicker>(find.byType(RestoreFromDatePicker))
        .onTap();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    nav.currentState!.pop([DateTime(2024, 6, 1)]);
    await tester.pumpAndSettle();
    final selected = tester
        .widget<RestoreFromDatePicker>(find.byType(RestoreFromDatePicker))
        .controller
        .text;
    expect(selected, isNotEmpty);
    expect(controller.height, greaterThan(0));
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    expect(
      tester
          .widget<RestoreFromDatePicker>(find.byType(RestoreFromDatePicker))
          .controller
          .text,
      selected,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
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
    test("Epic Cash and Mimblewimblecoin count from their own genesis", () {
      final date = DateTime.utc(2024, 6, 1);
      final seconds = date.millisecondsSinceEpoch ~/ 1000;
      expect(
        StartHeightPicker.heightFromDate(epic, date),
        (seconds - Epiccash.genesisBlockTime) ~/ 61,
      );
      expect(
        StartHeightPicker.heightFromDate(mwc, date),
        (seconds - Mimblewimblecoin.genesisBlockTime) ~/ 61,
      );
    });

    test("a date before the MWC genesis maps to zero for MWC only", () {
      final date = DateTime.utc(2019, 9, 1);
      expect(StartHeightPicker.heightFromDate(mwc, date), 0);
      expect(StartHeightPicker.heightFromDate(epic, date), greaterThan(0));
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
