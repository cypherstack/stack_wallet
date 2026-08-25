import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/restore_options_view.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/restore_options_view/sub_widgets/restore_options_next_button.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restoring_dialog.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/options.dart';
import 'package:stackwallet/widgets/start_height_picker.dart';
import 'package:tuple/tuple.dart';

import '../sample_data/theme_json.dart';

void main() {
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final coin = Monero(CryptoCurrencyNetwork.main);

  Widget testApp(Widget child) => ProviderScope(
    overrides: [themeProvider.overrideWithValue(StateController(theme))],
    child: MaterialApp(
      theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
      home: Scaffold(body: child),
    ),
  );

  setUp(() {
    Util.screenWidth = 400;
  });

  tearDown(() {
    Util.screenWidth = null;
  });

  testWidgets("clears parsed URI state after changing restore modes", (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(RestoreOptionsView(walletName: "wallet", coin: coin)),
    );

    Future<void> selectOption(double horizontalFraction) async {
      final rect = tester.getRect(find.byType(Options));
      await tester.tapAt(
        Offset(rect.left + rect.width * horizontalFraction, rect.center.dy),
      );
      await tester.pumpAndSettle();
    }

    await selectOption(5 / 6);
    await tester.enterText(
      find.byType(TextField).first,
      "monero_wallet:?seed=alpha%20beta",
    );
    await tester.pump();

    expect(
      tester
          .widget<RestoreOptionsNextButton>(
            find.byType(RestoreOptionsNextButton),
          )
          .onPressed,
      isNotNull,
    );

    await selectOption(1 / 6);
    await selectOption(5 / 6);

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(
      tester
          .widget<RestoreOptionsNextButton>(
            find.byType(RestoreOptionsNextButton),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets("shows URI validation errors", (tester) async {
    final heightController = StartHeightPickerController();
    addTearDown(heightController.dispose);

    WalletUriData? parsed;
    await tester.pumpWidget(
      testApp(
        UriRestoreOption(
          coin: coin,
          heightController: heightController,
          onParsed: (value) => parsed = value,
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      "monero_wallet:?seed=alpha%20beta&height=-1",
    );
    await tester.pump();

    expect(parsed, isNull);
    expect(find.text("Invalid restore height."), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, "");
    await tester.pump();

    expect(find.text("Invalid restore height."), findsNothing);
  });

  testWidgets("a URI height does not leak into a mode with no picker", (
    tester,
  ) async {
    RouteSettings? pushed;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themeProvider.overrideWithValue(StateController(theme))],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          onGenerateRoute: (settings) {
            pushed = settings;
            return MaterialPageRoute<void>(
              builder: (_) => const SizedBox.shrink(),
            );
          },
          home: Scaffold(
            body: RestoreOptionsView(walletName: "wallet", coin: coin),
          ),
        ),
      ),
    );

    Future<void> selectOption(double horizontalFraction) async {
      final rect = tester.getRect(find.byType(Options));
      await tester.tapAt(
        Offset(rect.left + rect.width * horizontalFraction, rect.center.dy),
      );
      await tester.pumpAndSettle();
    }

    await selectOption(5 / 6);
    await tester.enterText(
      find.byType(TextField).first,
      "monero_wallet:?seed=alpha%20beta&height=3000000",
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key("startHeightPickerBlockHeightFieldKey")),
          )
          .controller!
          .text,
      "3000000",
    );

    // Monero's default 16 word seed restore shows no height control at all, so
    // the height chosen in URI mode must not follow the user over to it.
    await selectOption(1 / 6);
    expect(
      find.byKey(const Key("startHeightPickerBlockHeightFieldKey")),
      findsNothing,
    );

    tester
        .widget<RestoreOptionsNextButton>(find.byType(RestoreOptionsNextButton))
        .onPressed!();
    await tester.pumpAndSettle();

    expect(pushed?.arguments, isA<Tuple5<String, dynamic, int, int, String>>());
    expect(
      (pushed!.arguments! as Tuple5<String, dynamic, int, int, String>).item4,
      0,
    );
  });

  testWidgets("a URI for another coin is refused on this page", (tester) async {
    final heightController = StartHeightPickerController();
    addTearDown(heightController.dispose);

    WalletUriData? parsed;
    var parsedCalls = 0;
    await tester.pumpWidget(
      testApp(
        UriRestoreOption(
          coin: coin,
          heightController: heightController,
          onParsed: (value) {
            parsed = value;
            parsedCalls++;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      "wownero_wallet:?seed=alpha%20beta",
    );
    await tester.pump();

    expect(parsedCalls, greaterThan(0));
    expect(parsed, isNull);
    expect(find.text("This is a Wownero wallet URI."), findsOneWidget);
  });

  testWidgets("a URI height prefills a field the user still controls", (
    tester,
  ) async {
    final heightController = StartHeightPickerController();
    addTearDown(heightController.dispose);

    await tester.pumpWidget(
      testApp(
        UriRestoreOption(
          coin: coin,
          heightController: heightController,
          onParsed: (_) {},
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      "monero_wallet:?seed=alpha%20beta&height=3000000",
    );
    await tester.pumpAndSettle();

    expect(heightController.height, 3000000);

    await tester.enterText(
      find.byKey(const Key("startHeightPickerBlockHeightFieldKey")),
      "2500000",
    );
    await tester.pumpAndSettle();

    expect(heightController.height, 2500000);
  });

  testWidgets("key restore progress cannot be cancelled", (tester) async {
    await tester.pumpWidget(testApp(const RestoringDialog()));

    expect(find.text("Restoring wallet"), findsOneWidget);
    expect(find.text("Cancel"), findsNothing);
  });
}
