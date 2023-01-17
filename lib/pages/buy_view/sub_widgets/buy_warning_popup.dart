import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/services/buy/simplex/simplex_api.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class BuyWarningPopup extends StatelessWidget {
  const BuyWarningPopup({
    Key? key,
    required this.quote,
  }) : super(key: key);

  final SimplexQuote quote;

  void newOrder(SimplexQuote quote) {
    final response = SimplexAPI.instance.newOrder(quote);
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
        onPressed: Navigator.of(context).pop,
      ),
      rightButton: PrimaryButton(
        label: "Continue",
        onPressed: () async {
          SimplexAPI.instance.newOrder(quote);
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
