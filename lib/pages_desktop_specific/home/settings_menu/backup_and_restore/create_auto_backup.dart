import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/stack_file_system.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/log_level_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/progress_bar.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:zxcvbn/zxcvbn.dart';

class CreateAutoBackup extends StatefulWidget {
  const CreateAutoBackup({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CreateAutoBackup();
}

class _CreateAutoBackup extends State<CreateAutoBackup> {
  late final TextEditingController fileLocationController;
  late final TextEditingController passphraseController;
  late final TextEditingController passphraseRepeatController;

  late final StackFileSystem stackFileSystem;
  late final FocusNode passphraseFocusNode;
  late final FocusNode passphraseRepeatFocusNode;
  final zxcvbn = Zxcvbn();

  bool shouldShowPasswordHint = true;
  bool hidePassword = true;

  String passwordFeedback =
      "Add another word or two. Uncommon words are better. Use a few words, avoid common phrases. No need for symbols, digits, or uppercase letters.";
  double passwordStrength = 0.0;

  bool get shouldEnableCreate {
    return fileLocationController.text.isNotEmpty &&
        passphraseController.text.isNotEmpty &&
        passphraseRepeatController.text.isNotEmpty;
  }

  bool get fieldsMatch =>
      passphraseController.text == passphraseRepeatController.text;

  String _currentDropDownValue = "Every 10 minutes";

  final List<String> _dropDownItems = [
    "Every 10 minutes",
    "Every 20 minutes",
    "Every 30 minutes",
  ];

  @override
  void initState() {
    stackFileSystem = StackFileSystem();

    fileLocationController = TextEditingController();
    passphraseController = TextEditingController();
    passphraseRepeatController = TextEditingController();

    passphraseFocusNode = FocusNode();
    passphraseRepeatFocusNode = FocusNode();

    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        final dir = await stackFileSystem.prepareStorage();
        if (mounted) {
          setState(() {
            fileLocationController.text = dir.path;
          });
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    passphraseController.dispose();
    passphraseRepeatController.dispose();

    passphraseFocusNode.dispose();
    passphraseRepeatFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");

    String? selectedItem = "Every 10 minutes";
    final isDesktop = Util.isDesktop;
    return DesktopDialog(
      maxHeight: 680,
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
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              "Choose file location",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!Platform.isAndroid)
                  Consumer(builder: (context, ref, __) {
                    return Container(
                      color: Colors.transparent,
                      child: TextField(
                        autocorrect: false,
                        enableSuggestions: false,
                        onTap: Platform.isAndroid
                            ? null
                            : () async {
                                try {
                                  await stackFileSystem.prepareStorage();

                                  if (mounted) {
                                    await stackFileSystem.pickDir(context);
                                  }

                                  if (mounted) {
                                    setState(() {
                                      fileLocationController.text =
                                          stackFileSystem.dirPath ?? "";
                                    });
                                  }
                                } catch (e, s) {
                                  Logging.instance
                                      .log("$e\n$s", level: LogLevel.Error);
                                }
                              },
                        controller: fileLocationController,
                        style: STextStyles.field(context),
                        decoration: InputDecoration(
                          hintText: "Save to...",
                          hintStyle: STextStyles.fieldLabel(context),
                          suffixIcon: UnconstrainedBox(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                ),
                                SvgPicture.asset(
                                  Assets.svg.folder,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark3,
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                        key: const Key(
                            "createBackupSaveToFileLocationTextFieldKey"),
                        readOnly: true,
                        toolbarOptions: const ToolbarOptions(
                          copy: true,
                          cut: false,
                          paste: false,
                          selectAll: false,
                        ),
                        onChanged: (newValue) {
                          // ref.read(addressEntryDataProvider(widget.id)).address = newValue;
                        },
                      ),
                    );
                  }),
                if (!Platform.isAndroid)
                  const SizedBox(
                    height: 24,
                  ),
                if (isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      "Create a passphrase",
                      style: STextStyles.desktopTextExtraSmall(context)
                          .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark3),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    key: const Key("createBackupPasswordFieldKey1"),
                    focusNode: passphraseFocusNode,
                    controller: passphraseController,
                    style: STextStyles.field(context),
                    obscureText: hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: standardInputDecoration(
                      "Create passphrase",
                      passphraseFocusNode,
                      context,
                    ).copyWith(
                      labelStyle:
                          isDesktop ? STextStyles.fieldLabel(context) : null,
                      suffixIcon: UnconstrainedBox(
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                            ),
                            GestureDetector(
                              key: const Key(
                                  "createBackupPasswordFieldShowPasswordButtonKey"),
                              onTap: () async {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              child: SvgPicture.asset(
                                hidePassword
                                    ? Assets.svg.eye
                                    : Assets.svg.eyeSlash,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark3,
                                width: 16,
                                height: 16,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      if (newValue.isEmpty) {
                        setState(() {
                          passwordFeedback = "";
                        });
                        return;
                      }
                      final result = zxcvbn.evaluate(newValue);
                      String suggestionsAndTips = "";
                      for (var sug in result.feedback.suggestions!.toSet()) {
                        suggestionsAndTips += "$sug\n";
                      }
                      suggestionsAndTips += result.feedback.warning!;
                      String feedback =
                          // "Password Strength: ${((result.score! / 4.0) * 100).toInt()}%\n"
                          suggestionsAndTips;

                      passwordStrength = result.score! / 4;

                      // hack fix to format back string returned from zxcvbn
                      if (feedback.contains("phrasesNo need")) {
                        feedback = feedback.replaceFirst(
                            "phrasesNo need", "phrases\nNo need");
                      }

                      if (feedback.endsWith("\n")) {
                        feedback = feedback.substring(0, feedback.length - 2);
                      }

                      setState(() {
                        passwordFeedback = feedback;
                      });
                    },
                  ),
                ),
                if (passphraseFocusNode.hasFocus ||
                    passphraseRepeatFocusNode.hasFocus ||
                    passphraseController.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: passwordFeedback.isNotEmpty ? 4 : 0,
                    ),
                    child: passwordFeedback.isNotEmpty
                        ? Text(
                            passwordFeedback,
                            style: STextStyles.infoSmall(context),
                          )
                        : null,
                  ),
                if (passphraseFocusNode.hasFocus ||
                    passphraseRepeatFocusNode.hasFocus ||
                    passphraseController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 10,
                    ),
                    child: ProgressBar(
                      key: const Key("createStackBackUpProgressBar"),
                      width: 510,
                      height: 5,
                      fillColor: passwordStrength < 0.51
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorRed
                          : passwordStrength < 1
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorYellow
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorGreen,
                      backgroundColor: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonBackSecondary,
                      percent:
                          passwordStrength < 0.25 ? 0.03 : passwordStrength,
                    ),
                  ),
                const SizedBox(
                  height: 10,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    key: const Key("createBackupPasswordFieldKey2"),
                    focusNode: passphraseRepeatFocusNode,
                    controller: passphraseRepeatController,
                    style: STextStyles.field(context),
                    obscureText: hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: standardInputDecoration(
                      "Confirm passphrase",
                      passphraseRepeatFocusNode,
                      context,
                    ).copyWith(
                      labelStyle: STextStyles.fieldLabel(context),
                      suffixIcon: UnconstrainedBox(
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                            ),
                            GestureDetector(
                              key: const Key(
                                  "createBackupPasswordFieldShowPasswordButtonKey"),
                              onTap: () async {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              child: SvgPicture.asset(
                                hidePassword
                                    ? Assets.svg.eye
                                    : Assets.svg.eyeSlash,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark3,
                                width: 16,
                                height: 16,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      setState(() {});
                      // TODO: ? check if passwords match?
                    },
                  ),
                ),
              ],
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
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
            ),
            child: DropdownButtonFormField(
              isExpanded: true,
              elevation: 0,
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark,
              ),
              icon: SvgPicture.asset(
                Assets.svg.chevronDown,
                width: 10,
                height: 5,
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
              dropdownColor:
                  Theme.of(context).extension<StackColors>()!.textFieldActiveBG,
              // focusColor: ,
              value: _currentDropDownValue,
              items: _dropDownItems
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value is String) {
                  setState(() {
                    _currentDropDownValue = value;
                  });
                }
              },
            ),
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
