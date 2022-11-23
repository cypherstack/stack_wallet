import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';

import '../../../../../notifications/show_flush_bar.dart';
import '../../../../../widgets/loading_indicator.dart';

class DesktopAuthSend extends ConsumerStatefulWidget {
  const DesktopAuthSend({Key? key}) : super(key: key);

  @override
  ConsumerState<DesktopAuthSend> createState() => _DesktopAuthSendState();
}

class _DesktopAuthSendState extends ConsumerState<DesktopAuthSend> {
  late final TextEditingController passwordController;
  late final FocusNode passwordFocusNode;

  bool hidePassword = true;

  bool _confirmEnabled = false;

  Future<bool> verifyPassphrase() async {
    return await ref
        .read(storageCryptoHandlerProvider)
        .verifyPassphrase(passwordController.text);
  }

  @override
  void initState() {
    passwordController = TextEditingController();
    passwordFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          Assets.svg.keys,
          width: 100,
        ),
        const SizedBox(
          height: 56,
        ),
        Text(
          "Confirm transaction",
          style: STextStyles.desktopH3(context),
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          "Enter your wallet password to send BTC",
          style: STextStyles.desktopTextMedium(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark3,
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
          child: TextField(
            key: const Key("desktopLoginPasswordFieldKey"),
            focusNode: passwordFocusNode,
            controller: passwordController,
            style: STextStyles.desktopTextMedium(context).copyWith(
              height: 2,
            ),
            obscureText: hidePassword,
            enableSuggestions: false,
            autocorrect: false,
            decoration: standardInputDecoration(
              "Enter password",
              passwordFocusNode,
              context,
            ).copyWith(
              suffixIcon: UnconstrainedBox(
                child: SizedBox(
                  height: 70,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                      ),
                      GestureDetector(
                        key: const Key(
                            "restoreFromFilePasswordFieldShowPasswordButtonKey"),
                        onTap: () async {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                        child: SvgPicture.asset(
                          hidePassword ? Assets.svg.eye : Assets.svg.eyeSlash,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark3,
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            onChanged: (newValue) {
              setState(() {
                _confirmEnabled = passwordController.text.isNotEmpty;
              });
            },
          ),
        ),
        const SizedBox(
          height: 48,
        ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: "Cancel",
                buttonHeight: ButtonHeight.l,
                onPressed: Navigator.of(context).pop,
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: PrimaryButton(
                enabled: _confirmEnabled,
                label: "Confirm",
                buttonHeight: ButtonHeight.l,
                onPressed: () async {
                  unawaited(
                    showDialog<void>(
                      context: context,
                      builder: (context) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          LoadingIndicator(
                            width: 200,
                            height: 200,
                          ),
                        ],
                      ),
                    ),
                  );

                  await Future<void>.delayed(const Duration(seconds: 1));

                  final passwordIsValid = await verifyPassphrase();

                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop(passwordIsValid);
                    await Future<void>.delayed(const Duration(
                      milliseconds: 100,
                    ));
                  }
                },
              ),
            ),
          ],
        )
      ],
    );
  }
}
