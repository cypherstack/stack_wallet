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
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
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
    passwordController.dispose();
    passwordRepeatController.dispose();

    passwordFocusNode.dispose();
    passwordRepeatFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
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
              style: STextStyles.navBarTitle(context),
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
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "Choose file location",
                  style: STextStyles.desktopTextExtraExtraSmall(context)
                      .copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark3),
                ),
              ),
              child,
            ],
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!Platform.isAndroid)
              Consumer(builder: (context, ref, __) {
                return Container(
                  color: Colors.transparent,
                  child: TextField(
                    autocorrect: Util.isDesktop ? false : true,
                    enableSuggestions: Util.isDesktop ? false : true,
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
                    key:
                        const Key("createBackupSaveToFileLocationTextFieldKey"),
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
              SizedBox(
                height: !isDesktop ? 8 : 24,
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  "Create a passphrase",
                  style: STextStyles.desktopTextExtraExtraSmall(context)
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
                focusNode: passwordFocusNode,
                controller: passwordController,
                style: STextStyles.field(context),
                obscureText: hidePassword,
                enableSuggestions: false,
                autocorrect: false,
                decoration: standardInputDecoration(
                  "Create passphrase",
                  passwordFocusNode,
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
                            hidePassword ? Assets.svg.eye : Assets.svg.eyeSlash,
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
                        style: STextStyles.infoSmall(context),
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
                  percent: passwordStrength < 0.25 ? 0.03 : passwordStrength,
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
                style: STextStyles.field(context),
                obscureText: hidePassword,
                enableSuggestions: false,
                autocorrect: false,
                decoration: standardInputDecoration(
                  "Confirm passphrase",
                  passwordRepeatFocusNode,
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
                            hidePassword ? Assets.svg.eye : Assets.svg.eyeSlash,
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
            const SizedBox(
              height: 16,
            ),
            if (!isDesktop) const Spacer(),
            !isDesktop
                ? TextButton(
                    style: shouldEnableCreate
                        ? Theme.of(context)
                            .extension<StackColors>()!
                            .getPrimaryEnabledButtonColor(context)
                        : Theme.of(context)
                            .extension<StackColors>()!
                            .getPrimaryDisabledButtonColor(context),
                    onPressed: !shouldEnableCreate
                        ? null
                        : () async {
                            final String pathToSave =
                                fileLocationController.text;
                            final String passphrase = passwordController.text;
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

                            final backup = await SWB.createStackWalletJSON();

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
                                  builder: (_) => Platform.isAndroid
                                      ? StackOkDialog(
                                          title: "Backup saved to:",
                                          message: fileToSave,
                                        )
                                      : const StackOkDialog(
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
                      style: STextStyles.button(context),
                    ),
                  )
                : Row(
                    children: [
                      PrimaryButton(
                        width: 183,
                        desktopMed: true,
                        label: "Create backup",
                        enabled: shouldEnableCreate,
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
                                      builder: (_) => Platform.isAndroid
                                          ? StackOkDialog(
                                              title: "Backup saved to:",
                                              message: fileToSave,
                                            )
                                          : const StackOkDialog(
                                              title:
                                                  "Backup creation succeeded"),
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
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      SecondaryButton(
                        width: 183,
                        desktopMed: true,
                        label: "Cancel",
                        onPressed: () {},
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
