import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/sub_widgets/unlock_wallet_keys_desktop.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class WalletKeysButton extends StatelessWidget {
  const WalletKeysButton({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => UnlockWalletKeysDesktop(
            walletId: walletId,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.key,
              width: 20,
              height: 20,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextSecondary,
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              "Wallet keys",
              style: STextStyles.desktopMenuItemSelected(context),
            )
          ],
        ),
      ),
    );
  }
}
