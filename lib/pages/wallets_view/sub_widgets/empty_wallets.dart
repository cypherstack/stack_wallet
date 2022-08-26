import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/add_wallet_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class EmptyWallets extends StatelessWidget {
  const EmptyWallets({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 43,
        ),
        child: Column(
          children: [
            const Spacer(
              flex: 2,
            ),
            Image(
              image: AssetImage(
                Assets.png.stack,
              ),
              width: MediaQuery.of(context).size.width / 3,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "You do not have any wallets yet. Start building your crypto Stack!",
              textAlign: TextAlign.center,
              style: STextStyles.subtitle.copyWith(
                color: CFColors.neutral60,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: Theme.of(context).textButtonTheme.style?.copyWith(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          CFColors.stackAccent,
                        ),
                      ),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AddWalletView.routeName);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          Assets.svg.plus,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          "Add Wallet",
                          style: STextStyles.button,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(
              flex: 5,
            ),
          ],
        ),
      ),
    );
  }
}
