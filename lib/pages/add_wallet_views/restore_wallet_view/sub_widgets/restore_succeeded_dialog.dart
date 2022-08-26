import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
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
        color: CFColors.stackGreen,
      ),
      rightButton: TextButton(
        style: Theme.of(context).textButtonTheme.style?.copyWith(
              backgroundColor: MaterialStateProperty.all<Color>(
                CFColors.buttonGray,
              ),
            ),
        child: Text(
          "Ok",
          style: STextStyles.itemSubtitle12,
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
