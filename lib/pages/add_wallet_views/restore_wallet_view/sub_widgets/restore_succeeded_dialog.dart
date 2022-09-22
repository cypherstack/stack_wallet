import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class RestoreSucceededDialog extends StatelessWidget {
  const RestoreSucceededDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            .getSecondaryEnabledButtonColor(context),
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
