import 'dart:async';

import 'package:epicpay/pages/pinpad_views/create_pin_view.dart';
import 'package:epicpay/route_generator.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/desktop/secondary_button.dart';
import 'package:epicpay/widgets/stack_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(
              flex: 5,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: Image(
                image: AssetImage(
                  Assets.png.epicWelcome,
                ),
                width: MediaQuery.of(context).size.width,
                height: 315,
                alignment: Alignment.centerRight,
              ),
            ),
            const Spacer(
              flex: 3,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "Welcome"
                "\nto Epic Cash",
                textAlign: TextAlign.left,
                style: STextStyles.pageTitleH1(context).copyWith(fontSize: 40),
              ),
            ),
            const SizedBox(
              height: 32,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  style: STextStyles.label(context).copyWith(fontSize: 14),
                  children: [
                    const TextSpan(text: "By continuing, you agree to the "),
                    TextSpan(
                      text: "Terms of service",
                      style:
                          STextStyles.richLink(context).copyWith(fontSize: 14),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          showDialog<dynamic>(
                              context: context,
                              builder: (context) {
                                return const StackDialog(
                                  title: "Terms of Service",
                                  message: "terms will go here",
                                );
                              });
                        },
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy policy",
                      style:
                          STextStyles.richLink(context).copyWith(fontSize: 14),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          showDialog<dynamic>(
                              context: context,
                              builder: (context) {
                                return const StackDialog(
                                  title: "Privacy policy",
                                  message: "policy will go here",
                                );
                              });
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 64,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      height: 56,
                      label: "CREATE NEW WALLET",
                      onPressed: () {
                        unawaited(Navigator.of(context).push(
                          RouteGenerator.getRoute(
                            shouldUseMaterialRoute:
                                RouteGenerator.useMaterialPageRoute,
                            builder: (_) =>
                                const CreatePinView(isNewWallet: true),
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
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      height: 56,
                      label: "RESTORE WALLET",
                      onPressed: () {
                        unawaited(Navigator.of(context).push(
                          RouteGenerator.getRoute(
                            shouldUseMaterialRoute:
                                RouteGenerator.useMaterialPageRoute,
                            builder: (_) =>
                                const CreatePinView(isNewWallet: false),
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
    );
  }
}
