import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/edit_auto_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_file_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/backup_and_restore/create_auto_backup.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/backup_and_restore/enable_backup_dialog.dart';
import 'package:stackwallet/providers/global/auto_swb_service_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupRestoreSettings extends ConsumerStatefulWidget {
  const BackupRestoreSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuBackupRestore";

  @override
  ConsumerState<BackupRestoreSettings> createState() =>
      _BackupRestoreSettings();
}

class _BackupRestoreSettings extends ConsumerState<BackupRestoreSettings> {
  late bool createBackup = false;
  late bool restoreBackup = false;

  final toggleController = DSBController();

  late final TextEditingController fileLocationController;
  late final TextEditingController passwordController;
  late final TextEditingController frequencyController;

  late final FocusNode fileLocationFocusNode;
  late final FocusNode passwordFocusNode;

  String prettySinceLastBackupString(DateTime? time) {
    if (time == null) {
      return "-";
    }
    final difference = DateTime.now().difference(time);
    int value;
    String postfix;
    if (difference < const Duration(seconds: 60)) {
      value = difference.inSeconds;
      postfix = "seconds";
    } else if (difference < const Duration(minutes: 60)) {
      value = difference.inMinutes;
      postfix = "minutes";
    } else if (difference < const Duration(hours: 24)) {
      value = difference.inHours;
      postfix = "hours";
    } else if (difference.inDays < 8) {
      value = difference.inDays;
      postfix = "days";
    } else {
      // if greater than a week return the actual date
      return DateFormat.yMMMMd(
        // en_CA locale breaks things?
        // ref.read(localeServiceChangeNotifierProvider).locale,
        "en_US",
      ).format(time);
    }

    if (value == 1) {
      postfix = postfix.substring(0, postfix.length - 1);
    }

    return "$value $postfix ago";
  }

  Future<void> enableAutoBackup(BuildContext context) async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return const EnableBackupDialog();
      },
    );
  }

  Future<void> createAutoBackup() async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return const CreateAutoBackup();
      },
    );
  }

  Future<void> editAutoBackup() async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) => DesktopDialog(
        maxWidth: 580,
        maxHeight: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Edit auto backup",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: 32,
              ),
              child: EditAutoBackupView(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> attemptDisable() async {
    final result = await showDialog<bool?>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return !Util.isDesktop
            ? StackDialog(
                title: "Disable Auto Backup",
                message:
                    "You are turning off Auto Backup. You can turn it back on at any time. Your previous Auto Backup file will not be deleted. Remember to backup your wallets manually so you don't lose important information.",
                leftButton: TextButton(
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getSecondaryEnabledButtonStyle(context),
                  child: Text(
                    "Back",
                    style: STextStyles.button(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                    ),
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
                    "Disable",
                    style: STextStyles.button(context),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      ref
                          .watch(prefsChangeNotifierProvider)
                          .isAutoBackupEnabled = false;
                    });
                  },
                ),
              )
            : DesktopDialog(
                maxHeight: double.infinity,
                maxWidth: 580,
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
                            "Disable Auto Backup",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        const DesktopDialogCloseButton(),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32,
                        right: 32,
                        bottom: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 600,
                            child: Text(
                              "You are turning off Auto Backup. You can turn it back on at any time. Your previous Auto Backup file will not be deleted. Remember to backup your wallets manually so you don't lose important information.",
                              style: STextStyles.desktopTextSmall(context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark3,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 48,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  buttonHeight: ButtonHeight.l,
                                  label: "Cancel",
                                  onPressed: Navigator.of(context).pop,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: PrimaryButton(
                                  buttonHeight: ButtonHeight.l,
                                  label: "Disable",
                                  onPressed: () {
                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .isAutoBackupEnabled = false;
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
      },
    );
    if (mounted) {
      if (result is bool && result) {
        ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled = false;
        Navigator.of(context).pop();
      } else {
        toggleController.activate?.call();
      }
    }
  }

  @override
  void initState() {
    fileLocationController = TextEditingController();
    passwordController = TextEditingController();
    frequencyController = TextEditingController();

    passwordController.text = "---------------";
    fileLocationController.text =
        ref.read(prefsChangeNotifierProvider).autoBackupLocation ?? " ";
    frequencyController.text = Format.prettyFrequencyType(
        ref.read(prefsChangeNotifierProvider).backupFrequencyType);

    fileLocationFocusNode = FocusNode();
    passwordFocusNode = FocusNode();

    // _toggle = ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled;
    super.initState();
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    passwordController.dispose();
    frequencyController.dispose();

    fileLocationFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    bool isEnabledAutoBackup = ref.watch(prefsChangeNotifierProvider
        .select((value) => value.isAutoBackupEnabled));

    ref.listen(
        prefsChangeNotifierProvider
            .select((value) => value.backupFrequencyType),
        (previous, BackupFrequencyType next) {
      frequencyController.text = Format.prettyFrequencyType(next);
    });

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 30,
                    ),
                    child: RoundedWhiteContainer(
                      radiusMultiplier: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SvgPicture.asset(
                                  Assets.svg.backupAuto,
                                  width: 48,
                                  height: 48,
                                ),
                                isEnabledAutoBackup
                                    ? SvgPicture.asset(
                                        Assets.svg.enableButton,
                                      )
                                    : SvgPicture.asset(
                                        Assets.svg.disableButton,
                                      ),
                              ],
                            ),
                          ),
                          Center(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: RichText(
                                      textAlign: TextAlign.start,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Auto Backup",
                                            style: STextStyles.desktopTextSmall(
                                                context),
                                          ),
                                          TextSpan(
                                            text:
                                                "\n\nAuto backup is a custom Stack Wallet feature that offers a convenient backup of your data."
                                                "To ensure maximum security, we recommend using a unique password that you haven't used anywhere "
                                                "else on the internet before. Your password is not stored.",
                                            style: STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context),
                                          ),
                                          TextSpan(
                                            text:
                                                "\n\nFor more information, please see our website ",
                                            style: STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context),
                                          ),
                                          TextSpan(
                                            text: "stackwallet.com",
                                            style: STextStyles.richLink(context)
                                                .copyWith(fontSize: 14),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                launchUrl(
                                                  Uri.parse(
                                                      "https://stackwallet.com/"),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: !isEnabledAutoBackup
                                    ? PrimaryButton(
                                        buttonHeight: ButtonHeight.m,
                                        width: 200,
                                        label: "Enable auto backup",
                                        onPressed: () {
                                          enableAutoBackup(context);
                                        },
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RoundedContainer(
                                            width: 403,
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .background,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Backed up ${prettySinceLastBackupString(ref.watch(prefsChangeNotifierProvider.select((value) => value.lastAutoBackup)))}",
                                                  style:
                                                      STextStyles.itemSubtitle(
                                                          context),
                                                ),
                                                CustomTextButton(
                                                  text: "Back up now",
                                                  onTap: () {
                                                    ref
                                                        .read(
                                                            autoSWBServiceProvider)
                                                        .doBackup();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          Row(
                                            children: [
                                              PrimaryButton(
                                                buttonHeight: ButtonHeight.m,
                                                width: 190,
                                                label: "Disable auto backup",
                                                onPressed: () {
                                                  attemptDisable();
                                                },
                                              ),
                                              const SizedBox(width: 16),
                                              SecondaryButton(
                                                buttonHeight: ButtonHeight.m,
                                                width: 190,
                                                label: "Edit auto backup",
                                                onPressed: () {
                                                  editAutoBackup();
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 30,
                    ),
                    child: RoundedWhiteContainer(
                      radiusMultiplier: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              Assets.svg.backupAdd,
                              width: 48,
                              height: 48,
                              alignment: Alignment.topLeft,
                            ),
                          ),
                          Center(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: RichText(
                                      textAlign: TextAlign.start,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Manual Backup",
                                            style: STextStyles.desktopTextSmall(
                                                context),
                                          ),
                                          TextSpan(
                                            text:
                                                "\n\nCreate manual backup to easily transfer your data between devices. "
                                                "You will create a backup file that can be later used in the Restore option. "
                                                "Use a strong password to encrypt your data.",
                                            style: STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(
                                  10,
                                ),
                                child: createBackup
                                    ? const SizedBox(
                                        width: 512,
                                        child: CreateBackupView(),
                                      )
                                    : PrimaryButton(
                                        buttonHeight: ButtonHeight.m,
                                        width: 200,
                                        label: "Create manual backup",
                                        onPressed: () {
                                          setState(() {
                                            createBackup = true;
                                          });
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 30,
                      bottom: 40,
                    ),
                    child: RoundedWhiteContainer(
                      radiusMultiplier: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              Assets.svg.backupRestore,
                              width: 48,
                              height: 48,
                              alignment: Alignment.topLeft,
                            ),
                          ),
                          Center(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: RichText(
                                      textAlign: TextAlign.start,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Restore Backup",
                                            style: STextStyles.desktopTextSmall(
                                                context),
                                          ),
                                          TextSpan(
                                            text:
                                                "\n\nUse your Stack Wallet backup file to restore your wallets, address book "
                                                "and wallet preferences.",
                                            style: STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(
                                  10,
                                ),
                                child: restoreBackup
                                    ? const SizedBox(
                                        width: 512,
                                        child: RestoreFromFileView(),
                                      )
                                    : PrimaryButton(
                                        buttonHeight: ButtonHeight.m,
                                        width: 200,
                                        label: "Restore backup",
                                        onPressed: () {
                                          setState(() {
                                            restoreBackup = true;
                                          });
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
    });
  }
}
