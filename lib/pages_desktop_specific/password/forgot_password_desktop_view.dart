import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/pages_desktop_specific/password/delete_password_warning_view.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/desktop/desktop_app_bar.dart';
import 'package:stackduo/widgets/desktop/desktop_scaffold.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';

class ForgotPasswordDesktopView extends StatefulWidget {
  const ForgotPasswordDesktopView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/forgotPasswordDesktop";

  @override
  State<ForgotPasswordDesktopView> createState() =>
      _ForgotPasswordDesktopViewState();
}

class _ForgotPasswordDesktopViewState extends State<ForgotPasswordDesktopView> {
  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        isCompactHeight: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  Assets.svg.stackDuoIcon(context),
                  width: 100,
                ),
                const SizedBox(
                  height: 42,
                ),
                Text(
                  "Stack Duo",
                  style: STextStyles.desktopH1(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: 400,
                  child: Text(
                    "Stack Duo does not store your password. Create new wallet or use a Stack backup file to restore your wallet.",
                    textAlign: TextAlign.center,
                    style: STextStyles.desktopTextSmall(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 48,
                ),
                PrimaryButton(
                  label: "Create new Stack",
                  onPressed: () {
                    const shouldCreateNew = true;
                    Navigator.of(context).pushNamed(
                      DeletePasswordWarningView.routeName,
                      arguments: shouldCreateNew,
                    );
                  },
                ),
                const SizedBox(
                  height: 24,
                ),
                SecondaryButton(
                  label: "Restore from Stack backup",
                  onPressed: () {
                    const shouldCreateNew = false;
                    Navigator.of(context).pushNamed(
                      DeletePasswordWarningView.routeName,
                      arguments: shouldCreateNew,
                    );
                  },
                ),
                const SizedBox(
                  height: kDesktopAppBarHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
