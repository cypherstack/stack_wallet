import "dart:convert";
import "dart:io";

import "package:decimal/decimal.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/models/isar/stack_theme.dart";
import "package:stackwallet/networking/http.dart";
import "package:stackwallet/services/ethereum/ethereum_api.dart";
import "package:stackwallet/themes/stack_colors.dart";
import "package:stackwallet/widgets/eth_fee_form.dart";

import "../sample_data/theme_json.dart";

class _GasOracleHttp extends HTTP {
  const _GasOracleHttp();

  @override
  Future<Response> get({
    required Uri url,
    Map<String, String>? headers,
    required ({InternetAddress host, int port})? proxyInfo,
    Duration? connectionTimeout,
  }) async => Response(const [], 500);
}

class _SingleSuccessGasOracleHttp extends HTTP {
  int requests = 0;

  @override
  Future<Response> get({
    required Uri url,
    Map<String, String>? headers,
    required ({InternetAddress host, int port})? proxyInfo,
    Duration? connectionTimeout,
  }) async {
    requests++;
    if (requests > 1) return Response(const [], 500);

    return Response(
      utf8.encode(
        '{"success":true,"result":{"result":{'
        '"FastGasPrice":"15.678",'
        '"ProposeGasPrice":"14",'
        '"SafeGasPrice":"13.456",'
        '"suggestBaseFee":"12.345",'
        '"LastBlock":"1"}}}',
      ),
      200,
    );
  }
}

void main() {
  testWidgets("rejects a priority fee above the max fee", (tester) async {
    final originalClient = EthereumAPI.client;
    EthereumAPI.client = const _GasOracleHttp();
    addTearDown(() => EthereumAPI.client = originalClient);

    final emittedFees = <EthEIP1559Fee?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: Scaffold(
          body: EthFeeForm(
            locale: "en_US",
            initialState: EthEIP1559Fee(
              maxFeePerGasGwei: Decimal.fromInt(10),
              maxPriorityFeePerGasGwei: Decimal.one,
              gasLimit: 21000,
            ),
            stateChanged: emittedFees.add,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Max fee per gas (GWEI)"), findsOneWidget);
    expect(find.text("Max priority fee per gas (GWEI)"), findsOneWidget);

    final maxFeeField = find.byKey(const Key("ethMaxFeePerGasField"));
    final maxPriorityFeeField = find.byKey(
      const Key("ethMaxPriorityFeePerGasField"),
    );
    await tester.enterText(maxPriorityFeeField, "11");
    await tester.pump();

    expect(emittedFees.last, isNull);
    expect(
      tester.widget<TextField>(maxPriorityFeeField).decoration!.errorText,
      isNull,
    );
    expect(
      find.text("Max priority fee must not exceed max fee"),
      findsOneWidget,
    );

    await tester.enterText(maxFeeField, "12");
    await tester.pump();

    expect(emittedFees.last?.maxFeePerGasGwei, Decimal.fromInt(12));
    expect(emittedFees.last?.maxPriorityFeePerGasGwei, Decimal.fromInt(11));
    expect(find.text("Max priority fee must not exceed max fee"), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets("gas limit preserves and rejects malformed integer text", (
    tester,
  ) async {
    final originalClient = EthereumAPI.client;
    EthereumAPI.client = const _GasOracleHttp();
    addTearDown(() => EthereumAPI.client = originalClient);

    final emittedFees = <EthEIP1559Fee?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: Scaffold(
          body: EthFeeForm(
            locale: "en_US",
            initialState: EthEIP1559Fee(
              maxFeePerGasGwei: Decimal.one,
              maxPriorityFeePerGasGwei: Decimal.one,
              gasLimit: 21000,
            ),
            stateChanged: emittedFees.add,
          ),
        ),
      ),
    );
    await tester.pump();

    final gasLimitField = find.byKey(const Key("ethFeeGasLimitField"));
    await tester.enterText(gasLimitField, "21000.5");
    await tester.pump();

    expect(tester.widget<TextField>(gasLimitField).controller!.text, "21000.5");
    expect(emittedFees, [isNull]);
    expect(
      tester.widget<TextField>(gasLimitField).decoration!.errorText,
      isNull,
    );
    expect(
      find.text("Enter a whole number from 21000 to 30000000"),
      findsOneWidget,
    );

    await tester.enterText(gasLimitField, "0x5208");
    await tester.pump();

    expect(tester.widget<TextField>(gasLimitField).controller!.text, "0x5208");
    expect(emittedFees.last, isNull);
    expect(
      tester.widget<TextField>(gasLimitField).decoration!.errorText,
      isNull,
    );
    expect(
      find.text("Enter a whole number from 21000 to 30000000"),
      findsOneWidget,
    );

    await tester.enterText(gasLimitField, "22000");
    await tester.pump();

    expect(emittedFees.last?.gasLimit, 22000);
    expect(
      tester.widget<TextField>(gasLimitField).decoration!.errorText,
      isNull,
    );
    expect(
      find.text("Enter a whole number from 21000 to 30000000"),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets("locale change preserves amount field selection", (tester) async {
    final originalClient = EthereumAPI.client;
    EthereumAPI.client = const _GasOracleHttp();
    addTearDown(() => EthereumAPI.client = originalClient);

    Widget form(String locale) => MaterialApp(
      theme: ThemeData(
        extensions: [
          StackColors.fromStackColorTheme(
            StackTheme.fromJson(json: lightThemeJsonMap),
          ),
        ],
      ),
      home: Scaffold(
        body: EthFeeForm(
          locale: locale,
          initialState: EthEIP1559Fee(
            maxFeePerGasGwei: Decimal.parse("12.34"),
            maxPriorityFeePerGasGwei: Decimal.one,
            gasLimit: 21000,
          ),
          stateChanged: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(form("en_US"));
    await tester.pump();

    final maxFeeField = find.byKey(const Key("ethMaxFeePerGasField"));
    await tester.tap(maxFeeField);
    await tester.pump();
    final controller = tester.widget<TextField>(maxFeeField).controller!;
    controller.selection = const TextSelection.collapsed(offset: 2);

    await tester.pumpWidget(form("de_DE"));
    await tester.pump();

    expect(controller.text, "12,34");
    expect(controller.selection, const TextSelection.collapsed(offset: 2));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets("locale change reformats cached gas oracle labels", (
    tester,
  ) async {
    final originalClient = EthereumAPI.client;
    final client = _SingleSuccessGasOracleHttp();
    EthereumAPI.client = client;
    addTearDown(() => EthereumAPI.client = originalClient);

    Widget form(String locale) => MaterialApp(
      theme: ThemeData(
        extensions: [
          StackColors.fromStackColorTheme(
            StackTheme.fromJson(json: lightThemeJsonMap),
          ),
        ],
      ),
      home: Scaffold(
        body: EthFeeForm(locale: locale, stateChanged: (_) {}),
      ),
    );

    await tester.pumpWidget(form("en_US"));
    await tester.pump();

    expect(find.text("Current: 12.345 GWEI"), findsOneWidget);
    expect(find.text("Current: 1.111 - 3.333 GWEI"), findsOneWidget);
    expect(client.requests, 1);

    await tester.pumpWidget(form("de_DE"));
    await tester.pump();

    expect(find.text("Current: 12,345 GWEI"), findsOneWidget);
    expect(find.text("Current: 1,111 - 3,333 GWEI"), findsOneWidget);
    expect(client.requests, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
