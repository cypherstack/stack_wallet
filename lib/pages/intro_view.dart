import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class IntroView extends StatefulWidget {
  const IntroView({Key? key}) : super(key: key);

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");
    return Scaffold(
      body: Container(
        color: CFColors.almostWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 47,
                  right: 47,
                  top: 67,
                  bottom: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(
                      flex: 2,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                      ),
                      child: Image(
                        image: AssetImage(
                          Assets.png.stack,
                        ),
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                    Text(
                      "Stack Wallet",
                      textAlign: TextAlign.center,
                      style: STextStyles.pageTitleH1,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      "An open-source, multicoin wallet for everyone",
                      textAlign: TextAlign.center,
                      style: STextStyles.subtitle,
                    ),
                    // Center(child: Text("for everyone")),
                    const Spacer(
                      flex: 4,
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: STextStyles.label,
                        children: [
                          const TextSpan(
                              text: "By using Stack Wallet, you agree to the "),
                          TextSpan(
                            text: "Terms of service",
                            style: STextStyles.richLink,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(
                                  Uri.parse(
                                      "https://stackwallet.com/terms-of-service.html"),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy policy",
                            style: STextStyles.richLink,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(
                                  Uri.parse(
                                      "https://stackwallet.com/privacy-policy.html"),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: TextButton(
                style: Theme.of(context).textButtonTheme.style?.copyWith(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        CFColors.stackAccent,
                      ),
                    ),
                onPressed: () {
                  // // TODO do global password/pin creation
                  // Navigator.of(context).pushNamed(HomeView.routeName);

                  Navigator.of(context).pushNamed(CreatePinView.routeName);
                },
                child: Text(
                  "Get started",
                  style: STextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
