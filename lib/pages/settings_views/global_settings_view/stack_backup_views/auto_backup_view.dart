import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_auto_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/edit_auto_backup_view.dart';
import 'package:stackwallet/providers/global/auto_swb_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class AutoBackupView extends ConsumerStatefulWidget {
  const AutoBackupView({Key? key}) : super(key: key);

  static const String routeName = "/stackAutoBackup";

  @override
  ConsumerState<AutoBackupView> createState() => _AutoBackupViewState();
}

class _AutoBackupViewState extends ConsumerState<AutoBackupView> {
  late bool _toggle;
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
              ref.read(localeServiceChangeNotifierProvider).locale)
          .format(time);
    }

    if (value == 1) {
      postfix = postfix.substring(0, postfix.length - 1);
    }

    return "$value $postfix ago";
  }

  Future<void> attemptEnable() async {
    final result = await showDialog<bool?>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return StackDialog(
          title: "Enable Auto Backup",
          message: "To enable Auto Backup, you need to create a backup file.",
          leftButton: TextButton(
            style: Theme.of(context)
                .extension<StackColors>()!
                .getSecondaryEnabledButtonStyle(context),
            child: Text(
              "Back",
              style: STextStyles.button(context).copyWith(
                color:
                    Theme.of(context).extension<StackColors>()!.accentColorDark,
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
              "Continue",
              style: STextStyles.button(context),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        );
      },
    );
    if (mounted) {
      if (result is bool && result) {
        Navigator.of(context)
            .pushNamed(CreateAutoBackupView.routeName)
            .then((_) {
          // set toggle to correct state
          if (_toggle !=
              ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled) {
            toggleController.activate?.call();
          }
        });
      } else {
        toggleController.activate?.call();
      }
    }
  }

  Future<void> attemptDisable() async {
    final result = await showDialog<bool?>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return StackDialog(
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
                color:
                    Theme.of(context).extension<StackColors>()!.accentColorDark,
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
              Navigator.of(context).pop(true);
            },
          ),
        );
      },
    );
    if (mounted) {
      if (result is bool && result) {
        ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled = false;
        Navigator.of(context)
            .popUntil(ModalRoute.withName(AutoBackupView.routeName));
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

    _toggle = ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled;
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
            "Auto Backup",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoundedWhiteContainer(
                padding: const EdgeInsets.all(0),
                child: RawMaterialButton(
                  // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  onPressed: null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Auto Backup",
                          style: STextStyles.titleBold12(context),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(
                          height: 20,
                          width: 40,
                          child: DraggableSwitchButton(
                            key: const Key("autoBackupToggleButtonKey"),
                            isOn: _toggle,
                            controller: toggleController,
                            onValueChanged: (newValue) async {
                              _toggle = newValue;

                              if (_toggle) {
                                attemptEnable();
                              } else {
                                attemptDisable();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              if (!isEnabledAutoBackup)
                RoundedWhiteContainer(
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: STextStyles.label(context),
                      children: [
                        const TextSpan(
                            text:
                                "Auto Backup is a custom Stack Wallet feature that offers a convenient backup of your data.\n\nTo ensure maximum security, we recommend using a unique password that you haven't used anywhere else on the internet before. Your password is not stored.\n\nFor more information, please see our website "),
                        TextSpan(
                          text: "stackwallet.com.",
                          style: STextStyles.richLink(context),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launchUrl(
                                Uri.parse("https://stackwallet.com"),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              if (isEnabledAutoBackup)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RoundedWhiteContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomTextButton(
                            text: "Back up now",
                            onTap: () {
                              ref.read(autoSWBServiceProvider).doBackup();
                            },
                          ),
                          Text(
                            "Backed up ${prettySinceLastBackupString(ref.watch(prefsChangeNotifierProvider.select((value) => value.lastAutoBackup)))}",
                            style: STextStyles.itemSubtitle(context),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Text(
                      "Auto Backup file",
                      style: STextStyles.smallMed12(context),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                      child: TextField(
                        key: const Key("backupSavedToFileLocationTextFieldKey"),
                        focusNode: fileLocationFocusNode,
                        controller: fileLocationController,
                        enabled: false,
                        style: STextStyles.field(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark
                              .withOpacity(0.5),
                        ),
                        readOnly: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        toolbarOptions: const ToolbarOptions(
                          copy: true,
                          cut: false,
                          paste: false,
                          selectAll: true,
                        ),
                        decoration: standardInputDecoration(
                          "Saved to",
                          fileLocationFocusNode,
                          context,
                        ),
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
                        key: const Key("backupPasswordFieldKey"),
                        focusNode: passwordFocusNode,
                        controller: passwordController,
                        enabled: false,
                        style: STextStyles.field(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark
                              .withOpacity(0.5),
                        ),
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        toolbarOptions: const ToolbarOptions(
                          copy: true,
                          cut: false,
                          paste: false,
                          selectAll: true,
                        ),
                        decoration: standardInputDecoration(
                          "Passphrase",
                          passwordFocusNode,
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      "Auto Backup frequency",
                      style: STextStyles.smallMed12(context),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      autocorrect: Util.isDesktop ? false : true,
                      enableSuggestions: Util.isDesktop ? false : true,
                      key: const Key("backupFrequencyFieldKey"),
                      controller: frequencyController,
                      enabled: false,
                      style: STextStyles.field(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark
                            .withOpacity(0.5),
                      ),
                      toolbarOptions: const ToolbarOptions(
                        copy: true,
                        cut: false,
                        paste: false,
                        selectAll: true,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: CustomTextButton(
                        text: "Edit Auto Backup",
                        onTap: () async {
                          Navigator.of(context)
                              .pushNamed(EditAutoBackupView.routeName);
                        },
                      ),
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
