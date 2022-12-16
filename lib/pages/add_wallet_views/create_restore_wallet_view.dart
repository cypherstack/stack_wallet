import 'dart:async';

import 'package:epicpay/pages/pinpad_views/create_pin_view.dart';
import 'package:epicpay/route_generator.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/desktop/secondary_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateRestoreWalletView extends StatefulWidget {
  const CreateRestoreWalletView({Key? key}) : super(key: key);

  static const String routeName = "/createRestoreWalletView";

  @override
  State<CreateRestoreWalletView> createState() => _CreateRestoreWalletView();
}

class _CreateRestoreWalletView extends State<CreateRestoreWalletView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");
    final width = MediaQuery.of(context).size.width;
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (buildContext, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(
                            flex: 5,
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: width,
                            ),
                            child: Image(
                              image: AssetImage(
                                Assets.png.epicWelcome,
                              ),
                              width: width,
                              height: width < 350
                                  ? MediaQuery.of(context).size.height / 3
                                  : 315,
                              alignment: Alignment.centerRight,
                            ),
                          ),
                          const Spacer(
                            flex: 3,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: width < 350 ? 24 : 40.0),
                            child: Text(
                              "Welcome"
                              "\nto Epic Cash",
                              textAlign: TextAlign.left,
                              style: width < 350
                                  ? STextStyles.titleH1(context).copyWith(
                                      fontSize: 32,
                                    )
                                  : STextStyles.titleH1(context),
                            ),
                          ),
                          if (width < 350)
                            const Spacer(
                              flex: 3,
                            ),
                          if (width >= 350)
                            const SizedBox(
                              height: 32,
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: width < 350 ? 24 : 40.0),
                            child: RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: STextStyles.label(context)
                                    .copyWith(fontSize: 14),
                                children: [
                                  const TextSpan(
                                      text: "By continuing, you agree to the "),
                                  TextSpan(
                                    text: "Privacy policy",
                                    style: STextStyles.richLink(context)
                                        .copyWith(fontSize: 14),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrl(
                                          Uri.parse(
                                              "https://cypherstack.com/epic-privacy-policy.html"),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (width < 350)
                            const Spacer(
                              flex: 3,
                            ),
                          if (width >= 350)
                            const SizedBox(
                              height: 64,
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: width < 350 ? 24 : 40.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    height: 56,
                                    label: "CREATE NEW WALLET",
                                    onPressed: () {
                                      unawaited(Navigator.of(context).push(
                                        RouteGenerator.getRoute(
                                          shouldUseMaterialRoute: RouteGenerator
                                              .useMaterialPageRoute,
                                          builder: (_) => const CreatePinView(
                                              isNewWallet: true),
                                          settings: const RouteSettings(
                                            name: CreatePinView.routeName,
                                          ),
                                        ),
                                      ));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: width < 350 ? 24 : 40.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SecondaryButton(
                                    height: 56,
                                    label: "RESTORE WALLET",
                                    onPressed: () {
                                      unawaited(Navigator.of(context).push(
                                        RouteGenerator.getRoute(
                                          shouldUseMaterialRoute: RouteGenerator
                                              .useMaterialPageRoute,
                                          builder: (_) => const CreatePinView(
                                              isNewWallet: false),
                                          settings: const RouteSettings(
                                            name: CreatePinView.routeName,
                                          ),
                                        ),
                                      ));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
