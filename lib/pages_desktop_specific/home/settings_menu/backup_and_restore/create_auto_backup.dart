import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/stack_text_field.dart';

class CreateAutoBackup extends StatelessWidget {
  // const CreateAutoBackup({Key? key, required this.chooseFileLocation})
  //     : super(key: key);

  late final TextEditingController fileLocationController;

  late final FocusNode chooseFileLocation;

  @override
  void initState() {
    fileLocationController = TextEditingController();
    // passwordRepeatController = TextEditingController();

    chooseFileLocation = FocusNode();
    // passwordRepeatFocusNode = FocusNode();

    // super.initState();
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    // passwordRepeatController.dispose();

    chooseFileLocation.dispose();
    // passwordRepeatFocusNode.dispose();

    // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: 600,
      maxWidth: 600,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Create auto backup",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: AppBarIconButton(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  size: 40,
                  icon: SvgPicture.asset(
                    Assets.svg.x,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                    width: 22,
                    height: 22,
                  ),
                  onPressed: () {
                    int count = 0;
                    Navigator.of(context).popUntil((_) => count++ >= 2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 32),
            child: Text(
              "Choose file location",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          TextField(
            key: const Key("backupChooseFileLocation"),
            style: STextStyles.desktopTextMedium(context).copyWith(
              height: 2,
            ),
            enableSuggestions: false,
            autocorrect: false,
            decoration: standardInputDecoration(
                "Save to...", chooseFileLocation, context),
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
                      int count = 0;
                      Navigator.of(context).popUntil((_) => count++ >= 2);
                    },
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Enable Auto Backup",
                    onPressed: () {},
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
