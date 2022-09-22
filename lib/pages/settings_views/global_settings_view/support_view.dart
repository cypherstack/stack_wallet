import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportView extends StatelessWidget {
  const SupportView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/support";
  final double iconSize = 28;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Support",
          style: STextStyles.navBarTitle(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoundedWhiteContainer(
              child: Text(
                "If you need support or want to report a bug, reach out to us on any of our socials!",
                style: STextStyles.smallMed12(context),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: StackTheme.instance.color.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse("https://t.me/stackwallet"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.socials.telegram,
                        width: iconSize,
                        height: iconSize,
                        color: StackTheme.instance.color.accentColorDark,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Telegram",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: StackTheme.instance.color.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse("https://discord.gg/RZMG3yUm"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.socials.discord,
                        width: iconSize,
                        height: iconSize,
                        color: StackTheme.instance.color.accentColorDark,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Discord",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: StackTheme.instance.color.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse("https://www.reddit.com/r/stackwallet/"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.socials.reddit,
                        width: iconSize,
                        height: iconSize,
                        color: StackTheme.instance.color.accentColorDark,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Reddit",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: StackTheme.instance.color.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse("https://twitter.com/stack_wallet"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.socials.twitter,
                        width: iconSize,
                        height: iconSize,
                        color: StackTheme.instance.color.accentColorDark,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Twitter",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: StackTheme.instance.color.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse("mailto://support@stackwallet.com"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.envelope,
                        width: iconSize,
                        height: iconSize,
                        color: StackTheme.instance.color.accentColorDark,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Email",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
