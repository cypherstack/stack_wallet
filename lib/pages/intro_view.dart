import 'dart:io';

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
  late final bool isDesktop;

  @override
  void initState() {
    isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      body: Center(
        child: !isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(
                    flex: 2,
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
                          Assets.png.stack,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(
                    flex: 1,
                  ),
                  AppNameText(
                    isDesktop: isDesktop,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                    ),
                    child: IntroAboutText(
                      isDesktop: isDesktop,
                    ),
                  ),
                  const Spacer(
                    flex: 4,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                    ),
                    child: PrivacyAndTOSText(
                      isDesktop: isDesktop,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GetStartedButton(
                            isDesktop: isDesktop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: 350,
                height: 540,
                child: Column(
                  children: [
                    const Spacer(
                      flex: 2,
                    ),
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Image(
                        image: AssetImage(
                          Assets.png.splash,
                        ),
                      ),
                    ),
                    const Spacer(
                      flex: 42,
                    ),
                    AppNameText(
                      isDesktop: isDesktop,
                    ),
                    const Spacer(
                      flex: 24,
                    ),
                    IntroAboutText(
                      isDesktop: isDesktop,
                    ),
                    const Spacer(
                      flex: 42,
                    ),
                    GetStartedButton(
                      isDesktop: isDesktop,
                    ),
                    const Spacer(
                      flex: 65,
                    ),
                    PrivacyAndTOSText(
                      isDesktop: isDesktop,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class AppNameText extends StatelessWidget {
  const AppNameText({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      "Stack Wallet",
      textAlign: TextAlign.center,
      style: !isDesktop
          ? STextStyles.pageTitleH1
          : STextStyles.pageTitleH1.copyWith(
              fontSize: 40,
            ),
    );
  }
}

class IntroAboutText extends StatelessWidget {
  const IntroAboutText({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      "An open-source, multicoin wallet for everyone",
      textAlign: TextAlign.center,
      style: !isDesktop
          ? STextStyles.subtitle
          : STextStyles.subtitle.copyWith(
              fontSize: 24,
            ),
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
        style: STextStyles.label.copyWith(fontSize: fontSize),
        children: [
          const TextSpan(text: "By using Stack Wallet, you agree to the "),
          TextSpan(
            text: "Terms of service",
            style: STextStyles.richLink.copyWith(fontSize: fontSize),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://stackwallet.com/terms-of-service.html"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
          const TextSpan(text: " and "),
          TextSpan(
            text: "Privacy policy",
            style: STextStyles.richLink.copyWith(fontSize: fontSize),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://stackwallet.com/privacy-policy.html"),
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
  const GetStartedButton({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return !isDesktop
        ? TextButton(
            style: Theme.of(context).textButtonTheme.style?.copyWith(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    CFColors.stackAccent,
                  ),
                ),
            onPressed: () {
              Navigator.of(context).pushNamed(CreatePinView.routeName);
            },
            child: Text(
              "Get started",
              style: STextStyles.button,
            ),
          )
        : SizedBox(
            width: 328,
            height: 70,
            child: TextButton(
              style: Theme.of(context).textButtonTheme.style?.copyWith(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      CFColors.stackAccent,
                    ),
                  ),
              onPressed: () {
                // TODO: password setup flow
              },
              child: Text(
                "Get started",
                style: STextStyles.button.copyWith(fontSize: 20),
              ),
            ),
          );
  }
}
