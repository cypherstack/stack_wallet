import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_file_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/settings_menu/backup_and_restore/enable_backup_dialog.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
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

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            Assets.svg.backupAuto,
                            width: 48,
                            height: 48,
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
                                padding: EdgeInsets.all(
                                  10,
                                ),
                                child: PrimaryButton(
                                  desktopMed: true,
                                  width: 200,
                                  label: "Enable auto backup",
                                  onPressed: () {
                                    enableAutoBackup(context);
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
                    ),
                    child: RoundedWhiteContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            Assets.svg.backupAdd,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topLeft,
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
                                        desktopMed: true,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            Assets.svg.backupRestore,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topLeft,
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
                                        desktopMed: true,
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
