import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/cakepay/cakepay_order_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/global/cakepay_orders_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/cakepay/cakepay_orders_service.dart';
import 'package:stackwallet/services/cakepay/src/models/order.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';

import '../../sample_data/theme_json.dart';

class _OrdersService extends CakePayOrdersService {
  @override
  void startPolling(
    String orderId, {
    Duration interval = CakePayOrdersService.defaultPollInterval,
  }) {}
}

void main() {
  testWidgets("address copy button uses the visible address", (tester) async {
    const address = "bc1qpaymentaddress";
    final order = CakePayOrder(
      orderId: "order-id",
      status: CakePayOrderStatus.new_,
      paymentOptions: {
        "BTC": CakePayPaymentOption(
          ticker: "BTC",
          amountFrom: 1,
          address: address,
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pCakePayOrdersService.overrideWithValue(_OrdersService()),
          pWallets.overrideWithValue(Wallets.sharedInstance),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          home: CakePayOrderView(order: order),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is IconCopyButton && widget.data == address,
      ),
      findsOneWidget,
    );
  });
}
