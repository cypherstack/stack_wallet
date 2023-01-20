import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/order.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/services/buy/buy_response.dart';
import 'package:stackwallet/services/buy/simplex/simplex_api.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class BuyWarningPopup extends StatelessWidget {
  const BuyWarningPopup({
    Key? key,
    required this.quote,
  }) : super(key: key);

  final SimplexQuote quote;
  final isDesktop = Util.isDesktop;

  Future<BuyResponse<SimplexOrder>> newOrder(SimplexQuote quote) async {
    return SimplexAPI.instance.newOrder(quote);
  }

  Future<BuyResponse<bool>> redirect(SimplexOrder order) async {
    return SimplexAPI.instance.redirect(order);
  }

  @override
  Widget build(BuildContext context) {
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
          BuyResponse<bool> response =
              await redirect(order.value as SimplexOrder);
          // TODO save order and redirect
        },
      ),
      icon: SizedBox(
        width: 64,
        height: 32,
        child: SvgPicture.asset(
          Assets.buy.simplexLogo,
        ),
      ),
    );
  }
}
