import 'package:epicmobile/models/exchange/response_objects/trade.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/trade_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("Test Trade card builds", (widgetTester) async {
    final trade = Trade(
        uuid: "uuid",
        tradeId: "trade id",
        rateType: "Estimate rate",
        direction: "",
        timestamp: DateTime.parse("1662544771"),
        updatedAt: DateTime.parse("1662544771"),
        payInCurrency: "BTC",
        payInAmount: "10",
        payInAddress: "btc address",
        payInNetwork: "",
        payInExtraId: "",
        payInTxid: "",
        payOutCurrency: "xmr",
        payOutAmount: "10",
        payOutAddress: "xmr address",
        payOutNetwork: "",
        payOutExtraId: "",
        payOutTxid: "",
        refundAddress: "refund address",
        refundExtraId: "",
        status: "Failed",
        exchangeName: "Some Exchange");

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: TradeCard(trade: trade, onTap: () {}),
        ),
      ),
    );

    expect(find.byType(TradeCard), findsOneWidget);
    expect(find.text("BTC → XMR"), findsOneWidget);
    expect(find.text("Some Exchange"), findsOneWidget);
  });
}
