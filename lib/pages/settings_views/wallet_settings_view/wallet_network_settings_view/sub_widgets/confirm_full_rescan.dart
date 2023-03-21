import 'package:flutter/material.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';
import 'package:stackduo/widgets/stack_dialog.dart';

class ConfirmFullRescanDialog extends StatelessWidget {
  const ConfirmFullRescanDialog({Key? key, required this.onConfirm})
      : super(key: key);

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        maxWidth: 576,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                  ),
                  child: Text(
                    "Rescan blockchain",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                left: 32,
                right: 32,
                bottom: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Warning! It may take a while. If you exit before completion, you will have to redo the process.",
                    style: STextStyles.desktopTextSmall(context),
                  ),
                  const SizedBox(
                    height: 43,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          buttonHeight: ButtonHeight.l,
                          onPressed: Navigator.of(context).pop,
                          label: "Cancel",
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: PrimaryButton(
                          buttonHeight: ButtonHeight.l,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm.call();
                          },
                          label: "Rescan",
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: StackDialog(
          title: "Rescan blockchain",
          message:
              "Warning! It may take a while. If you exit before completion, you will have to redo the process.",
          leftButton: TextButton(
            style: Theme.of(context)
                .extension<StackColors>()!
                .getSecondaryEnabledButtonStyle(context),
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
                .getPrimaryEnabledButtonStyle(context),
            child: Text(
              "Rescan",
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
}
