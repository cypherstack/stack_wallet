import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class ConfirmRecoveryDialog extends StatelessWidget {
  const ConfirmRecoveryDialog({Key? key, required this.onConfirm})
      : super(key: key);

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: StackDialog(
        title: "Are you ready?",
        message:
            "Restoring your wallet may take a while. Please do not exit this screen once the process is started.",
        leftButton: TextButton(
          style: Theme.of(context)
              .extension<StackColors>()!
              .getSecondaryEnabledButtonColor(context),
          child: Text(
            "Cancel",
            style: STextStyles.itemSubtitle12(context),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        rightButton: TextButton(
          style: Theme.of(context)
              .extension<StackColors>()!
              .getPrimaryEnabledButtonColor(context),
          child: Text(
            "Restore",
            style: STextStyles.button(context),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm.call();
          },
        ),
      ),
    );
  }
}
