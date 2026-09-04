import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/delete_trade_confirmation_dialog.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/dialogs/s_dialog.dart';

import '../sample_data/theme_json.dart';

void main() {
  tearDown(() => Util.screenWidth = null);

  testWidgets("confirmation closes only its own route", (tester) async {
    bool? result;

    await tester.pumpWidget(
      _TestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: Builder(
                        builder: (detailsContext) => Column(
                          children: [
                            const Text("Trade details route"),
                            TextButton(
                              onPressed: () async {
                                result =
                                    await showDeleteTradeConfirmationDialog(
                                      context: detailsContext,
                                      isTerminalStatus: true,
                                    );
                              },
                              child: const Text("Delete trade"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text("Open trade details"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Open trade details"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Delete trade"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("confirmDeleteTradeButton")));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text("Trade details route"), findsOneWidget);
    expect(find.byType(DeleteTradeConfirmationDialog), findsNothing);
  });

  testWidgets("cancel returns false", (tester) async {
    bool? result;

    await tester.pumpWidget(
      _TestApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDeleteTradeConfirmationDialog(
                context: context,
                isTerminalStatus: false,
              );
            },
            child: const Text("Open"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    expect(find.text("Delete an active trade?"), findsOneWidget);
    await tester.tap(find.byKey(const Key("cancelDeleteTradeButton")));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets("uses a scrollable content-sized dialog on a narrow screen", (
    tester,
  ) async {
    Util.screenWidth = 320;
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const _TestApp(
        textScaleFactor: 2,
        home: DeleteTradeConfirmationDialog(isTerminalStatus: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SDialog), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.home, this.textScaleFactor = 1});

  final Widget home;
  final double textScaleFactor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          StackColors.fromStackColorTheme(
            StackTheme.fromJson(json: lightThemeJsonMap),
          ),
        ],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
        child: child!,
      ),
      home: home,
    );
  }
}
