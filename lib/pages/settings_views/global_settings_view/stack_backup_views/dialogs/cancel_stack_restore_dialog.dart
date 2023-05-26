import 'package:flutter/material.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
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
      child: !Util.isDesktop
          ? StackDialog(
              title: "Cancel restore process",
              message:
                  "Cancelling will revert any changes that may have been applied",
              leftButton: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getSecondaryEnabledButtonStyle(context),
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
                    .getPrimaryEnabledButtonStyle(context),
                child: Text(
                  "Yes, cancel",
                  style: STextStyles.itemSubtitle12(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .buttonTextPrimary,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            )
          : DesktopDialog(
              maxHeight: 250,
              maxWidth: 600,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 20, left: 32, right: 32, bottom: 20),
                child: Column(
                  children: [
                    Text(
                      "Cancel Restore Process",
                      style: STextStyles.desktopH3(context),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 500,
                      child: RoundedContainer(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .snackBarBackError,
                        child: Text(
                          "If you cancel, the restore will not complete, and "
                          "the wallets will not appear in your Stack.",
                          style: STextStyles.desktopTextMedium(context),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SecondaryButton(
                          width: 248,
                          buttonHeight: ButtonHeight.l,
                          enabled: true,
                          label: "Keep restoring",
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        const SizedBox(width: 20),
                        PrimaryButton(
                          width: 248,
                          buttonHeight: ButtonHeight.l,
                          enabled: true,
                          label: "Cancel anyway",
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
