import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupRestore extends ConsumerStatefulWidget {
  const BackupRestore({Key? key}) : super(key: key);

  static const String routeName = "/backupRestore";

  @override
  ConsumerState<BackupRestore> createState() => _BackupRestore();
}

class _BackupRestore extends ConsumerState<BackupRestore> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return ListView(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
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
                  alignment: Alignment.topLeft,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Auto Backup",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                          TextSpan(
                            text:
                                "\n\nAuto Backup is a custom Stack Wallet feature that offers a convenient backup of your data."
                                "To ensure maximum security, we recommend using a unique password that you haven't used anywhere "
                                "else on the internet before. Your password is not stored.",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
                          ),
                          TextSpan(
                            text:
                                "\n\nFor more information, please see our website ",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
                          ),
                          TextSpan(
                            text: "stackwallet.com",
                            style: STextStyles.richLink(context)
                                .copyWith(fontSize: 14),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(
                                  Uri.parse("https://stackwallet.com/"),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(
                        10,
                      ),
                      child: EnableBackupButton(),
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
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Manual Backup",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                          TextSpan(
                            text:
                                "\n\nCreate Manual backup to easily transfer your data between devices. "
                                "You will create a backup file that can be later used in the Restore option. "
                                "Use a strong password to encrypt your data.",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EnableBackupButton extends ConsumerWidget {
  const EnableBackupButton({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 200,
      height: 48,
      child: TextButton(
        style: Theme.of(context)
            .extension<StackColors>()!
            .getPrimaryEnabledButtonColor(context),
        onPressed: () {},
        child: Text(
          "Enable Auto Backup",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
