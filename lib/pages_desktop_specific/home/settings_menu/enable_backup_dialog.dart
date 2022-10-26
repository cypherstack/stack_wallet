import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class EnableBackupDialog extends StatelessWidget {
  const EnableBackupDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Enable Auto Backup",
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
          Text(
            "To enable Auto Backup, you need to create a backup file.",
            style: STextStyles.desktopTextSmall(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark3,
            ),
            textAlign: TextAlign.center,
          ),
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
