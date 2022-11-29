import 'package:flutter/material.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';

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
          style: Theme.of(context)
              .extension<StackColors>()!
              .getSecondaryEnabledButtonColor(context),
          child: Text(
            "Back",
            style: STextStyles.itemSubtitle12(context),
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        rightButton: TextButton(
          style: Theme.of(context)
              .extension<StackColors>()!
              .getPrimaryEnabledButtonColor(context),
          child: Text(
            "Yes, cancel",
            style: STextStyles.itemSubtitle12(context).copyWith(
              color:
                  Theme.of(context).extension<StackColors>()!.buttonTextPrimary,
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
