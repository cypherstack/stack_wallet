import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class RestoreBackupDialog extends StatelessWidget {
  const RestoreBackupDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Restoring Stack Wallet",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
            ),
            child: Row(
              children: [
                Text(
                  "Settings",
                  style: STextStyles.desktopTextExtraSmall(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          // RoundedWhiteContainer(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(),
          //     ],
          //   ),
          // ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Cancel",
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Continue",
                    onPressed: () {
                      // Navigator.of(context).pop();
                      // onConfirm.call();
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
