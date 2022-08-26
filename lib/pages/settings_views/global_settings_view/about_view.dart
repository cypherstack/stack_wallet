import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends ConsumerWidget {
  const AboutView({Key? key}) : super(key: key);

  static const String routeName = "/about";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "About",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder(
                        future: PackageInfo.fromPlatform(),
                        builder:
                            (context, AsyncSnapshot<PackageInfo> snapshot) {
                          String version = "";
                          String signature = "";
                          String appName = "";
                          String build = "";

                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            version = snapshot.data!.version;
                            build = snapshot.data!.buildNumber;
                            signature = snapshot.data!.buildSignature;
                            appName = snapshot.data!.appName;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Text(
                                  appName,
                                  style: STextStyles.pageTitleH2,
                                ),
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              RoundedWhiteContainer(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Version",
                                      style: STextStyles.titleBold12,
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    SelectableText(
                                      version,
                                      style: STextStyles.itemSubtitle,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              RoundedWhiteContainer(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Build number",
                                      style: STextStyles.titleBold12,
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    SelectableText(
                                      build,
                                      style: STextStyles.itemSubtitle,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              RoundedWhiteContainer(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Build signature",
                                      style: STextStyles.titleBold12,
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    SelectableText(
                                      signature,
                                      style: STextStyles.itemSubtitle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      RoundedWhiteContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Website",
                              style: STextStyles.titleBold12,
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            BlueTextButton(
                              text: "https://stackwallet.com",
                              onTap: () {
                                launchUrl(
                                  Uri.parse("https://stackwallet.com"),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Spacer(),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: STextStyles.label,
                          children: [
                            const TextSpan(
                                text:
                                    "By using Stack Wallet, you agree to the "),
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
            );
          },
        ),
      ),
    );
  }
}
