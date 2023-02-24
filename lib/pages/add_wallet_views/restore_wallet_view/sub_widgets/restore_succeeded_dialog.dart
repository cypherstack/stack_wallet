import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class RestoreSucceededDialog extends StatelessWidget {
  const RestoreSucceededDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        child: Column(
          children: [
            const DesktopDialogCloseButton(),
            const Spacer(
              flex: 1,
            ),
            SvgPicture.asset(
              Assets.svg.checkCircle,
              width: 40,
              height: 40,
              color:
                  Theme.of(context).extension<StackColors>()!.accentColorDark,
            ),
            const Spacer(
              flex: 2,
            ),
            Text(
              "Wallet restored",
              style: STextStyles.desktopH2(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "You can use your wallet now.",
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(
              flex: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: 32,
              ),
              child: PrimaryButton(
                width: 272.5,
                label: "OK",
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return StackDialog(
        title: "Wallet restored",
        message: "You can use your wallet now.",
        icon: SvgPicture.asset(
          Assets.svg.checkCircle,
          width: 24,
          height: 24,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        ),
        rightButton: TextButton(
          style: Theme.of(context)
              .extension<StackColors>()!
              .getSecondaryEnabledButtonStyle(context),
          child: Text(
            "Ok",
            style: STextStyles.itemSubtitle12(context),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }
}
