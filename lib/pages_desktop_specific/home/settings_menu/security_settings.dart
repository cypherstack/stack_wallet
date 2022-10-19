import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class SecuritySettings extends ConsumerStatefulWidget {
  const SecuritySettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuSecurity";

  @override
  ConsumerState<SecuritySettings> createState() => _SecuritySettings();
}

class _SecuritySettings extends ConsumerState<SecuritySettings> {
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
        onPressed: () {},
        child: Text(
          "Set up new password",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
