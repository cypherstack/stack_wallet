import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/order.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/pages/buy_view/buy_order_invoice.dart';
import 'package:stackwallet/services/buy/buy_response.dart';
import 'package:stackwallet/services/buy/simplex/simplex_api.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class BuyWarningPopup extends StatelessWidget {
  BuyWarningPopup({
    Key? key,
    required this.quote,
    this.order,
  }) : super(key: key);

  final SimplexQuote quote;
  SimplexOrder? order;

  Future<BuyResponse<SimplexOrder>> newOrder(SimplexQuote quote) async {
    return SimplexAPI.instance.newOrder(quote);
  }

  Future<BuyResponse<bool>> redirect(SimplexOrder order) async {
    return SimplexAPI.instance.redirect(order);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    Future<void> _buyInvoice() async {
      await showDialog<void>(
        context: context,
        builder: (context) => BuyOrderInvoiceView(
          order: order as SimplexOrder,
        ),
      );
    }

    return StackDialog(
      title: "Buy ${quote.crypto.ticker}",
      message: "This purchase is provided and fulfilled by Simplex by nuvei "
          "(a third party). You will be taken to their website. Please follow "
          "their instructions.",
      leftButton: SecondaryButton(
        label: "Cancel",
        onPressed: Navigator.of(context, rootNavigator: isDesktop).pop,
      ),
      rightButton: PrimaryButton(
        label: "Continue",
        onPressed: () async {
          BuyResponse<SimplexOrder> order = await newOrder(quote);
          await redirect(order.value as SimplexOrder).then((_response) async {
            this.order = order.value as SimplexOrder;
            Navigator.of(context, rootNavigator: isDesktop).pop();
            Navigator.of(context, rootNavigator: isDesktop).pop();
            await _buyInvoice();
          });
          // BuyResponse<bool> response =
          //     await redirect(order.value as SimplexOrder).then((order) {
          //   // How would I correctly popUntil here?
          //   // TODO save order
          //   // TODO show order confirmation page
          //   return order;
          // });
        },
      ),
      icon: SizedBox(
        width: 64,
        height: 32,
        child: SvgPicture.asset(
          Assets.buy.simplexLogo(context),
        ),
      ),
    );
  }
}
