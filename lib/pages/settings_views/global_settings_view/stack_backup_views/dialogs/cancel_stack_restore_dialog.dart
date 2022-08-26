import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
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
          style: Theme.of(context).textButtonTheme.style?.copyWith(
                backgroundColor: MaterialStateProperty.all<Color>(
                  CFColors.buttonGray,
                ),
              ),
          child: Text(
            "Back",
            style: STextStyles.itemSubtitle12,
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        rightButton: TextButton(
          style: Theme.of(context).textButtonTheme.style?.copyWith(
                backgroundColor: MaterialStateProperty.all<Color>(
                  CFColors.stackAccent,
                ),
              ),
          child: Text(
            "Yes, cancel",
            style: STextStyles.itemSubtitle12.copyWith(
              color: CFColors.white,
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
