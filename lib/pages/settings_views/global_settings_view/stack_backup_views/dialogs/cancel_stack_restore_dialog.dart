import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class CancelStackRestoreDialog extends StatelessWidget {
  const CancelStackRestoreDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: StackDialog(
        title: "Cancel restore process",
        message:
            "Cancelling will revert any changes that may have been applied",
        leftButton: TextButton(
          style: StackTheme.instance.getSecondaryEnabledButtonColor(context),
          child: Text(
            "Back",
            style: STextStyles.itemSubtitle12(context),
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        rightButton: TextButton(
          style: StackTheme.instance.getPrimaryEnabledButtonColor(context),
          child: Text(
            "Yes, cancel",
            style: STextStyles.itemSubtitle12(context).copyWith(
              color: StackTheme.instance.color.buttonTextPrimary,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
  }
}
