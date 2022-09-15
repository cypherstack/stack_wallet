import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/stack_file_system.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/progress_bar.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:zxcvbn/zxcvbn.dart';

class CreateBackupView extends StatefulWidget {
  const CreateBackupView({Key? key}) : super(key: key);

  static const String routeName = "/createBackup";

  @override
  State<CreateBackupView> createState() => _RestoreFromFileViewState();
}

class _RestoreFromFileViewState extends State<CreateBackupView> {
  late final TextEditingController fileLocationController;
  late final TextEditingController passwordController;
  late final TextEditingController passwordRepeatController;

  late final FocusNode passwordFocusNode;
  late final FocusNode passwordRepeatFocusNode;
  late final StackFileSystem stackFileSystem;
  final zxcvbn = Zxcvbn();

  String passwordFeedback =
      "Add another word or two. Uncommon words are better. Use a few words, avoid common phrases. No need for symbols, digits, or uppercase letters.";

  bool shouldShowPasswordHint = true;

  bool hidePassword = true;

  double passwordStrength = 0.0;

  bool get shouldEnableCreate {
    return fileLocationController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        passwordRepeatController.text.isNotEmpty;
  }

  @override
  void initState() {
    stackFileSystem = StackFileSystem();
    fileLocationController = TextEditingController();
    passwordController = TextEditingController();
    passwordRepeatController = TextEditingController();

    passwordFocusNode = FocusNode();
    passwordRepeatFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    passwordController.dispose();
    passwordRepeatController.dispose();

    passwordFocusNode.dispose();
    passwordRepeatFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Create backup",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Consumer(builder: (context, ref, __) {
                        return Container(
                          color: Colors.transparent,
                          child: TextField(
                            onTap: () async {
                              try {
                                await stackFileSystem.prepareStorage();
                                // ref
                                //     .read(
                                //         shouldShowLockscreenOnResumeStateProvider
                                //             .state)
                                //     .state = false;
                                if (mounted) {
                                  await stackFileSystem.pickDir(context);
                                }

                                // Future<void>.delayed(
                                //   const Duration(seconds: 2),
                                //   () => ref
                                //       .read(
                                //           shouldShowLockscreenOnResumeStateProvider
                                //               .state)
                                //       .state = true,
                                // );

                                setState(() {
                                  fileLocationController.text =
                                      stackFileSystem.dirPath ?? "";
                                });
                              } catch (e, s) {
                                // ref
                                //     .read(
                                //         shouldShowLockscreenOnResumeStateProvider
                                //             .state)
                                //     .state = true;
                                Logging.instance
                                    .log("$e\n$s", level: LogLevel.Error);
                              }
                            },
                            controller: fileLocationController,
                            style: STextStyles.field,
                            decoration: InputDecoration(
                              hintText: "Save to...",
                              suffixIcon: UnconstrainedBox(
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                    ),
                                    SvgPicture.asset(
                                      Assets.svg.folder,
                                      color: CFColors.neutral50,
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
                      const SizedBox(
                        height: 8,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                        child: TextField(
                          key: const Key("createBackupPasswordFieldKey1"),
                          focusNode: passwordFocusNode,
                          controller: passwordController,
                          style: STextStyles.field,
                          obscureText: hidePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: standardInputDecoration(
                            "Create passphrase",
                            passwordFocusNode,
                          ).copyWith(
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
                                      color: CFColors.neutral50,
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
                            for (var sug
                                in result.feedback.suggestions!.toSet()) {
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
                              feedback =
                                  feedback.substring(0, feedback.length - 2);
                            }

                            setState(() {
                              passwordFeedback = feedback;
                            });
                          },
                        ),
                      ),
                      if (passwordFocusNode.hasFocus ||
                          passwordRepeatFocusNode.hasFocus ||
                          passwordController.text.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: passwordFeedback.isNotEmpty ? 4 : 0,
                          ),
                          child: passwordFeedback.isNotEmpty
                              ? Text(
                                  passwordFeedback,
                                  style: STextStyles.infoSmall,
                                )
                              : null,
                        ),
                      if (passwordFocusNode.hasFocus ||
                          passwordRepeatFocusNode.hasFocus ||
                          passwordController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: 10,
                          ),
                          child: ProgressBar(
                            key: const Key("createStackBackUpProgressBar"),
                            width: MediaQuery.of(context).size.width - 32 - 24,
                            height: 5,
                            fillColor: passwordStrength < 0.51
                                ? CFColors.stackRed
                                : passwordStrength < 1
                                    ? CFColors.stackYellow
                                    : CFColors.stackGreen,
                            backgroundColor: CFColors.buttonGray,
                            percent: passwordStrength < 0.25
                                ? 0.03
                                : passwordStrength,
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
                          focusNode: passwordRepeatFocusNode,
                          controller: passwordRepeatController,
                          style: STextStyles.field,
                          obscureText: hidePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: standardInputDecoration(
                            "Confirm passphrase",
                            passwordRepeatFocusNode,
                          ).copyWith(
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
                                      color: CFColors.neutral50,
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
                      const SizedBox(
                        height: 16,
                      ),
                      const Spacer(),
                      TextButton(
                        style: Theme.of(context)
                            .textButtonTheme
                            .style
                            ?.copyWith(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                shouldEnableCreate
                                    ? CFColors.stackAccent
                                    : CFColors.disabledButton,
                              ),
                            ),
                        onPressed: !shouldEnableCreate
                            ? null
                            : () async {
                                final String pathToSave =
                                    fileLocationController.text;
                                final String passphrase =
                                    passwordController.text;
                                final String repeatPassphrase =
                                    passwordRepeatController.text;

                                if (pathToSave.isEmpty) {
                                  unawaited(showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Directory not chosen",
                                    context: context,
                                  ));
                                  return;
                                }
                                if (!(await Directory(pathToSave).exists())) {
                                  unawaited(showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Directory does not exist",
                                    context: context,
                                  ));
                                  return;
                                }
                                if (passphrase.isEmpty) {
                                  unawaited(showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "A passphrase is required",
                                    context: context,
                                  ));
                                  return;
                                }
                                if (passphrase != repeatPassphrase) {
                                  unawaited(showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Passphrase does not match",
                                    context: context,
                                  ));
                                  return;
                                }

                                unawaited(showDialog<dynamic>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const StackDialog(
                                    title: "Encrypting backup",
                                    message: "This shouldn't take long",
                                  ),
                                ));
                                // make sure the dialog is able to be displayed for at least 1 second
                                await Future<void>.delayed(
                                    const Duration(seconds: 1));

                                final DateTime now = DateTime.now();
                                final String fileToSave =
                                    "$pathToSave/stackbackup_${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}_${now.second}.swb";

                                final backup =
                                    await SWB.createStackWalletJSON();

                                bool result =
                                    await SWB.encryptStackWalletWithPassphrase(
                                  fileToSave,
                                  passphrase,
                                  jsonEncode(backup),
                                );

                                if (mounted) {
                                  // pop encryption progress dialog
                                  Navigator.of(context).pop();

                                  if (result) {
                                    await showDialog<dynamic>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const StackOkDialog(
                                          title: "Backup creation succeeded"),
                                    );
                                    passwordController.text = "";
                                    passwordRepeatController.text = "";
                                    setState(() {});
                                  } else {
                                    await showDialog<dynamic>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const StackOkDialog(
                                          title: "Backup creation failed"),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          "Create backup",
                          style: STextStyles.button,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
