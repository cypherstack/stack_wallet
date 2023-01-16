import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class BuyWarningPopup extends StatelessWidget {
  const BuyWarningPopup({
    Key? key,
    required this.ticker,
  }) : super(key: key);

  final String ticker;

  @override
  Widget build(BuildContext context) {
    return StackDialog(
      title: "Buy $ticker",
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
          // todo open simplex page in external browser
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
