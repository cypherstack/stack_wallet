import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';

class CreateAutoBackup extends StatefulWidget {
  const CreateAutoBackup({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CreateAutoBackup();
}

class _CreateAutoBackup extends State<CreateAutoBackup> {
  late final TextEditingController fileLocationController;
  late final TextEditingController passphraseController;
  late final TextEditingController passphraseRepeatController;

  late final FocusNode chooseFileLocation;
  late final FocusNode passphraseFocusNode;
  late final FocusNode passphraseRepeatFocusNode;

  bool shouldShowPasswordHint = true;
  bool hidePassword = true;

  bool get fieldsMatch =>
      passphraseController.text == passphraseRepeatController.text;

  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = [
      DropdownMenuItem(
          child: Text("Every 10 minutes"), value: "Every 10 minutes"),
    ];
    return menuItems;
  }

  @override
  void initState() {
    fileLocationController = TextEditingController();
    passphraseController = TextEditingController();
    passphraseRepeatController = TextEditingController();

    chooseFileLocation = FocusNode();
    passphraseFocusNode = FocusNode();
    passphraseRepeatFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    passphraseController.dispose();
    passphraseRepeatController.dispose();

    chooseFileLocation.dispose();
    passphraseFocusNode.dispose();
    passphraseRepeatFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");

    String? selectedItem = "Every 10 minutes";

    return DesktopDialog(
      maxHeight: 650,
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
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("backupChooseFileLocation"),
                focusNode: chooseFileLocation,
                controller: fileLocationController,
                style: STextStyles.desktopTextMedium(context).copyWith(
                  height: 2,
                ),
                textAlign: TextAlign.left,
                enableSuggestions: false,
                autocorrect: false,
                decoration: standardInputDecoration(
                  "Save to...",
                  chooseFileLocation,
                  context,
                ).copyWith(
                  labelStyle:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                  suffixIcon: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(1000),
                    ),
                    height: 32,
                    width: 32,
                    child: Center(
                      child: SvgPicture.asset(
                        Assets.svg.folder,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                        width: 20,
                        height: 17.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 24,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 32),
            child: Text(
              "Create a passphrase",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 32,
              right: 32,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("createBackupPassphrase"),
                focusNode: passphraseFocusNode,
                controller: passphraseController,
                style: STextStyles.desktopTextMedium(context).copyWith(
                  height: 2,
                ),
                obscureText: hidePassword,
                enableSuggestions: false,
                autocorrect: false,
                decoration: standardInputDecoration(
                  "Create passphrase",
                  passphraseFocusNode,
                  context,
                ).copyWith(
                  labelStyle:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                  suffixIcon: UnconstrainedBox(
                    child: GestureDetector(
                      key: const Key(
                          "createDesktopAutoBackupShowPassphraseButton1"),
                      onTap: () async {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(1000),
                        ),
                        height: 32,
                        width: 32,
                        child: Center(
                          child: SvgPicture.asset(
                            hidePassword ? Assets.svg.eye : Assets.svg.eyeSlash,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3,
                            width: 20,
                            height: 17.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("createBackupPassphrase"),
                focusNode: passphraseRepeatFocusNode,
                controller: passphraseRepeatController,
                style: STextStyles.desktopTextMedium(context).copyWith(
                  height: 2,
                ),
                obscureText: hidePassword,
                enableSuggestions: false,
                autocorrect: false,
                decoration: standardInputDecoration(
                  "Confirm passphrase",
                  passphraseRepeatFocusNode,
                  context,
                ).copyWith(
                  labelStyle:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                  suffixIcon: UnconstrainedBox(
                    child: GestureDetector(
                      key: const Key(
                          "createDesktopAutoBackupShowPassphraseButton2"),
                      onTap: () async {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(1000),
                        ),
                        height: 32,
                        width: 32,
                        child: Center(
                          child: SvgPicture.asset(
                            hidePassword ? Assets.svg.eye : Assets.svg.eyeSlash,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3,
                            width: 20,
                            height: 17.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              "Auto Backup frequency",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          // DropdownButton(
          //   value: dropdownItems,
          //   items: dropdownItems,
          //   onChanged: null,
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
                    enabled: false,
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
