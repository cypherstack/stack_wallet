import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:epicmobile/pages_desktop_specific/home/settings_menu/backup_and_restore/enable_backup_dialog.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';

class SecuritySettings extends ConsumerStatefulWidget {
  const SecuritySettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuSecurity";

  @override
  ConsumerState<SecuritySettings> createState() => _SecuritySettings();
}

class _SecuritySettings extends ConsumerState<SecuritySettings> {
  Future<void> enableAutoBackup() async {
    // wait for keyboard to disappear
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return EnableBackupDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
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
                  Assets.svg.circleLock,
                  width: 48,
                  height: 48,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Change Password",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                          TextSpan(
                            text:
                                "\n\nProtect your Stack Wallet with a strong password. Stack Wallet does not store "
                                "your password, and is therefore NOT able to restore it. Keep your password safe and secure.",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
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
                      child: NewPasswordButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NewPasswordButton extends ConsumerWidget {
  const NewPasswordButton({
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
        onPressed: () {
          // Expandable(
          //   header: Row(
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     children: [
          //       NewPasswordButton(),
          //     ],
          //   ),
          //   body: Column(
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     children: [
          //       Text(
          //         "Current Password",
          //         style: STextStyles.desktopTextExtraSmall(context).copyWith(
          //           color:
          //               Theme.of(context).extension<StackColors>()!.textDark3,
          //         ),
          //         textAlign: TextAlign.left,
          //       ),
          //     ],
          //   ),
          // );
        },
        child: Text(
          "Set up new password",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
