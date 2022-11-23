import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/sub_widgets/wallet_keys_desktop_popup.dart';
import 'package:stackwallet/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';

class UnlockWalletKeysDesktop extends ConsumerStatefulWidget {
  const UnlockWalletKeysDesktop({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const String routeName = "/desktopUnlockWalletKeys";

  @override
  ConsumerState<UnlockWalletKeysDesktop> createState() =>
      _UnlockWalletKeysDesktopState();
}

class _UnlockWalletKeysDesktopState
    extends ConsumerState<UnlockWalletKeysDesktop> {
  late final TextEditingController passwordController;

  late final FocusNode passwordFocusNode;

  bool continueEnabled = false;
  bool hidePassword = true;

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
    return DesktopDialog(
      maxWidth: 579,
      maxHeight: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DesktopDialogCloseButton(
                onPressedOverride: Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop,
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          SvgPicture.asset(
            Assets.svg.keys,
            width: 100,
            height: 58,
          ),
          const SizedBox(
            height: 55,
          ),
          Text(
            "Wallet keys",
            style: STextStyles.desktopH2(context),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            "Enter your password",
            style: STextStyles.desktopTextMedium(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark3,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("enterPasswordUnlockWalletKeysDesktopFieldKey"),
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
                          GestureDetector(
                            key: const Key(
                                "enterUnlockWalletKeysDesktopFieldShowPasswordButtonKey"),
                            onTap: () async {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              height: 32,
                              width: 32,
                              child: Center(
                                child: SvgPicture.asset(
                                  hidePassword
                                      ? Assets.svg.eye
                                      : Assets.svg.eyeSlash,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark3,
                                  width: 24,
                                  height: 19,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                onChanged: (newValue) {
                  setState(() {
                    continueEnabled = newValue.isNotEmpty;
                  });
                },
              ),
            ),
          ),
          const SizedBox(
            height: 55,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Cancel",
                    onPressed: Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop,
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Continue",
                    enabled: continueEnabled,
                    onPressed: continueEnabled
                        ? () async {
                            unawaited(
                              showDialog(
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

                            await Future<void>.delayed(
                                const Duration(seconds: 1));

                            final verified = await ref
                                .read(storageCryptoHandlerProvider)
                                .verifyPassphrase(passwordController.text);

                            if (verified) {
                              Navigator.of(context, rootNavigator: true).pop();

                              final words = await ref
                                  .read(walletsChangeNotifierProvider)
                                  .getManager(widget.walletId)
                                  .mnemonic;

                              if (mounted) {
                                await Navigator.of(context)
                                    .pushReplacementNamed(
                                  WalletKeysDesktopPopup.routeName,
                                  arguments: words,
                                );
                              }
                            } else {
                              Navigator.of(context, rootNavigator: true).pop();

                              await Future<void>.delayed(
                                  const Duration(milliseconds: 300));

                              unawaited(
                                showFloatingFlushBar(
                                  type: FlushBarType.warning,
                                  message: "Invalid passphrase!",
                                  context: context,
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      ),
    );
  }
}
