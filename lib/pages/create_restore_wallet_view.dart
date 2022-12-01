import 'package:epicmobile/pages/pinpad_views/create_pin_view.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/desktop/secondary_button.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(
              flex: 5,
            ),
            Text(
              "Welcome"
              "\nto Epic Cash"
              "\nWallet",
              textAlign: TextAlign.left,
              style: STextStyles.pageTitleH1(context).copyWith(fontSize: 40),
            ),
            const SizedBox(
              height: 32,
            ),
            RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: STextStyles.label(context).copyWith(fontSize: 14),
                children: [
                  const TextSpan(text: "By continuing, you agree to the "),
                  TextSpan(
                    text: "Terms of service",
                    style: STextStyles.richLink(context).copyWith(fontSize: 14),
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
                    style: STextStyles.richLink(context).copyWith(fontSize: 14),
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
            const SizedBox(
              height: 64,
            ),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    height: 56,
                    width: 330,
                    label: "CREATE NEW WALLET",
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        CreatePinView.routeName,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    height: 56,
                    width: 330,
                    label: "RESTORE WALLET",
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
