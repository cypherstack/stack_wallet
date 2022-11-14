import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages_desktop_specific/forgot_password_desktop_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_home_view.dart';
import 'package:stackwallet/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';

class DesktopLoginView extends ConsumerStatefulWidget {
  const DesktopLoginView({
    Key? key,
    this.startupWalletId,
    this.load,
  }) : super(key: key);

  static const String routeName = "/desktopLogin";

  final String? startupWalletId;
  final Future<void> Function()? load;

  @override
  ConsumerState<DesktopLoginView> createState() => _DesktopLoginViewState();
}

class _DesktopLoginViewState extends ConsumerState<DesktopLoginView> {
  late final TextEditingController passwordController;

  late final FocusNode passwordFocusNode;

  bool hidePassword = true;
  bool _continueEnabled = false;

  Future<void> login() async {
    try {
      await ref
          .read(storageCryptoHandlerProvider)
          .initFromExisting(passwordController.text);

      await (ref.read(secureStoreProvider).store as DesktopSecureStore).init();

      await widget.load?.call();

      // if no errors passphrase is correct
      if (mounted) {
        unawaited(
          Navigator.of(context).pushNamedAndRemoveUntil(
            DesktopHomeView.routeName,
            (route) => false,
          ),
        );
      }
    } catch (e) {
      await showFloatingFlushBar(
        type: FlushBarType.warning,
        message: e.toString(),
        context: context,
      );
    }
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
    return DesktopScaffold(
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
                  Assets.svg.stackIcon(context),
                  width: 100,
                ),
                const SizedBox(
                  height: 42,
                ),
                Text(
                  "Stack Wallet",
                  style: STextStyles.desktopH1(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: 350,
                  child: Text(
                    "Open source multicoin wallet for everyone",
                    textAlign: TextAlign.center,
                    style: STextStyles.desktopSubtitleH1(context),
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
                                  hidePassword
                                      ? Assets.svg.eye
                                      : Assets.svg.eyeSlash,
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
                        _continueEnabled = passwordController.text.isNotEmpty;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                PrimaryButton(
                  label: "Continue",
                  enabled: _continueEnabled,
                  onPressed: login,
                ),
                const SizedBox(
                  height: 60,
                ),
                BlueTextButton(
                  text: "Forgot password?",
                  textSize: 20,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      ForgotPasswordDesktopView.routeName,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
