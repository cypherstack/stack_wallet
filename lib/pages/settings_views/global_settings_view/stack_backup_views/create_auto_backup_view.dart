import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stack_wallet_backup/stack_wallet_backup.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/auto_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/swb_file_system.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_views/backup_frequency_type_select_sheet.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/progress_bar.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:zxcvbn/zxcvbn.dart';

class CreateAutoBackupView extends ConsumerStatefulWidget {
  const CreateAutoBackupView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/createAutoBackup";

  @override
  ConsumerState<CreateAutoBackupView> createState() =>
      _EnableAutoBackupViewState();
}

class _EnableAutoBackupViewState extends ConsumerState<CreateAutoBackupView> {
  late final SecureStorageInterface secureStore;

  late final TextEditingController fileLocationController;
  late final TextEditingController passwordController;
  late final TextEditingController passwordRepeatController;

  late final FocusNode passwordFocusNode;
  late final FocusNode passwordRepeatFocusNode;
  late final SWBFileSystem stackFileSystem;
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
    secureStore = ref.read(secureStoreProvider);
    stackFileSystem = SWBFileSystem();
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
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Create Auto Backup",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Create your backup file",
                        style: STextStyles.smallMed12(context),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (!Platform.isAndroid)
                        TextField(
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
                          key: const Key(
                              "createBackupSaveToFileLocationTextFieldKey"),
                          readOnly: true,
                          toolbarOptions: const ToolbarOptions(
                            copy: true,
                            cut: false,
                            paste: false,
                            selectAll: false,
                          ),
                          onChanged: (newValue) {},
                        ),
                      if (!Platform.isAndroid)
                        const SizedBox(
                          height: 10,
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
                          style: STextStyles.field(context),
                          obscureText: hidePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: standardInputDecoration(
                            "Confirm passphrase",
                            passwordRepeatFocusNode,
                            context,
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
                        height: 32,
                      ),
                      Text(
                        "Auto Backup frequency",
                        style: STextStyles.smallMed12(context),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Stack(
                        children: [
                          TextField(
                            autocorrect: Util.isDesktop ? false : true,
                            enableSuggestions: Util.isDesktop ? false : true,
                            readOnly: true,
                            textInputAction: TextInputAction.none,
                          ),
                          Positioned.fill(
                            child: RawMaterialButton(
                              splashColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .highlight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                              onPressed: () {
                                showModalBottomSheet<dynamic>(
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) =>
                                      const BackupFrequencyTypeSelectSheet(),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Format.prettyFrequencyType(ref.watch(
                                          prefsChangeNotifierProvider.select(
                                              (value) =>
                                                  value.backupFrequencyType))),
                                      style:
                                          STextStyles.itemSubtitle12(context),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4.0),
                                      child: SvgPicture.asset(
                                        Assets.svg.chevronDown,
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textSubtitle2,
                                        width: 12,
                                        height: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(
                        height: 10,
                      ),
                      TextButton(
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
                                final String passphrase =
                                    passwordController.text;
                                final String repeatPassphrase =
                                    passwordRepeatController.text;

                                if (pathToSave.isEmpty) {
                                  showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Directory not chosen",
                                    context: context,
                                  );
                                  return;
                                }
                                if (!(await Directory(pathToSave).exists())) {
                                  showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Directory does not exist",
                                    context: context,
                                  );
                                  return;
                                }
                                if (passphrase.isEmpty) {
                                  showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "A passphrase is required",
                                    context: context,
                                  );
                                  return;
                                }
                                if (passphrase != repeatPassphrase) {
                                  showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "Passphrase does not match",
                                    context: context,
                                  );
                                  return;
                                }

                                showDialog<dynamic>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const StackDialog(
                                    title: "Encrypting initial backup",
                                    message: "This shouldn't take long",
                                  ),
                                );

                                // make sure the dialog is able to be displayed for at least some time
                                final fut = Future<void>.delayed(
                                    const Duration(milliseconds: 300));

                                String adkString;
                                int adkVersion;
                                try {
                                  final adk =
                                      await compute(generateAdk, passphrase);
                                  adkString =
                                      Format.uint8listToString(adk.item2);
                                  adkVersion = adk.item1;
                                } on Exception catch (e, s) {
                                  String err =
                                      getErrorMessageFromSWBException(e);
                                  Logging.instance
                                      .log("$err\n$s", level: LogLevel.Error);
                                  // pop encryption progress dialog
                                  Navigator.of(context).pop();
                                  showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: err,
                                    context: context,
                                  );
                                  return;
                                } catch (e, s) {
                                  Logging.instance
                                      .log("$e\n$s", level: LogLevel.Error);
                                  // pop encryption progress dialog
                                  Navigator.of(context).pop();
                                  showFloatingFlushBar(
                                    type: FlushBarType.warning,
                                    message: "$e",
                                    context: context,
                                  );
                                  return;
                                }

                                await secureStore.write(
                                    key: "auto_adk_string", value: adkString);
                                await secureStore.write(
                                    key: "auto_adk_version_string",
                                    value: adkVersion.toString());

                                final DateTime now = DateTime.now();
                                final String fileToSave =
                                    createAutoBackupFilename(pathToSave, now);

                                final backup = await SWB.createStackWalletJSON(
                                  secureStorage: secureStore,
                                );

                                bool result =
                                    await SWB.encryptStackWalletWithADK(
                                  fileToSave,
                                  adkString,
                                  jsonEncode(backup),
                                  adkVersion,
                                );

                                // this future should already be complete unless there was an error encrypting
                                await Future.wait([fut]);

                                if (mounted) {
                                  // pop encryption progress dialog
                                  Navigator.of(context).pop();

                                  if (result) {
                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .autoBackupLocation = pathToSave;
                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .lastAutoBackup = now;

                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .isAutoBackupEnabled = true;

                                    await showDialog<dynamic>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => Platform.isAndroid
                                          ? StackOkDialog(
                                              title:
                                                  "Stack Auto Backup enabled and saved to:",
                                              message: fileToSave,
                                            )
                                          : const StackOkDialog(
                                              title:
                                                  "Stack Auto Backup enabled!"),
                                    );
                                    if (mounted) {
                                      passwordController.text = "";
                                      passwordRepeatController.text = "";

                                      Navigator.of(context).popUntil(
                                          ModalRoute.withName(
                                              AutoBackupView.routeName));
                                    }
                                  } else {
                                    await showDialog<dynamic>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const StackOkDialog(
                                          title:
                                              "Failed to enable Auto Backup"),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          "Enable Auto Backup",
                          style: STextStyles.button(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
