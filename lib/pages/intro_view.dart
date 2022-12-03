import 'package:epicmobile/pages/add_wallet_views/create_restore_wallet_view.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IntroView extends StatefulWidget {
  const IntroView({Key? key}) : super(key: key);

  static const String routeName = "/introView";

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  late final bool isDesktop;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(
                flex: 5,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                  ),
                  child: Image(
                    image: AssetImage(
                      Assets.gif.epicPlain,
                    ),
                  ),
                ),
              ),
              const Spacer(
                flex: 3,
              ),
              const AppNameText(),
              const SizedBox(
                height: 32,
              ),
              // todo add screen swipe text
              const SizedBox(
                height: 118,
              ),
              Row(
                children: const [
                  Expanded(
                    child: GetStartedButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppNameText extends StatelessWidget {
  const AppNameText({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      "Everyday \nfinancial \nprivacy",
      textAlign: TextAlign.left,
      style: STextStyles.pageTitleH1(context).copyWith(fontSize: 40),
    );
  }
}

class PrivacyAndTOSText extends StatelessWidget {
  const PrivacyAndTOSText({Key? key, required this.isDesktop})
      : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final fontSize = isDesktop ? 18.0 : 12.0;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: STextStyles.label(context).copyWith(fontSize: fontSize),
        children: [
          const TextSpan(text: "By using Stack Wallet, you agree to the "),
          TextSpan(
            text: "Terms of service",
            style: STextStyles.richLink(context).copyWith(fontSize: fontSize),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://epicmobile.com/terms-of-service.html"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
          const TextSpan(text: " and "),
          TextSpan(
            text: "Privacy policy",
            style: STextStyles.richLink(context).copyWith(fontSize: fontSize),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://epicmobile.com/privacy-policy.html"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
        ],
      ),
    );
  }
}

class GetStartedButton extends StatelessWidget {
  const GetStartedButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: Theme.of(context)
          .extension<StackColors>()!
          .getPrimaryEnabledButtonColor(context),
      onPressed: () {
        Navigator.of(context).pushNamed(CreateRestoreWalletView.routeName);
      },
      child: Text(
        "Get started",
        style: STextStyles.button(context),
      ),
    );
  }
}
