import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/widgets/trade_card.dart';

import '../sample_data/theme_json.dart';
import 'trade_card_test.mocks.dart';

@GenerateMocks([
  ThemeService,
])
void main() {
  testWidgets("Test Trade card builds", (widgetTester) async {
    final mockThemeService = MockThemeService();
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
        applicationThemesDirectoryPath: "test",
      ),
    );
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
        overrides: [
          pThemeService.overrideWithValue(mockThemeService),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                  applicationThemesDirectoryPath: "test/sample_data",
                ),
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
