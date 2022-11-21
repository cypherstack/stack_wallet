import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/sub_widgets/desktop_attention_delete_wallet.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';

import '../../../../../providers/desktop/storage_crypto_handler_provider.dart';
import '../../../../../providers/global/wallets_provider.dart';

class DesktopDeleteWalletDialog extends ConsumerStatefulWidget {
  const DesktopDeleteWalletDialog({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const String routeName = "/desktopDeleteWalletDialog";

  @override
  ConsumerState<DesktopDeleteWalletDialog> createState() =>
      _DesktopDeleteWalletDialog();
}

class _DesktopDeleteWalletDialog
    extends ConsumerState<DesktopDeleteWalletDialog> {
  late final TextEditingController passwordController;
  late final FocusNode passwordFocusNode;

  bool hidePassword = true;
  bool _continueEnabled = false;

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
      maxWidth: 580,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  "Delete wallet",
                  style: STextStyles.desktopH2(context),
                ),
                const SizedBox(height: 16),
                Text(
                  "Enter your password",
                  style: STextStyles.desktopTextMedium(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    key: const Key("desktopDeleteWalletPasswordFieldKey"),
                    focusNode: passwordFocusNode,
                    controller: passwordController,
                    style: STextStyles.field(context),
                    obscureText: hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: standardInputDecoration(
                      "Enter password",
                      passwordFocusNode,
                      context,
                    ).copyWith(
                      labelStyle: STextStyles.fieldLabel(context),
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
                                    "desktopDeleteWalletShowPasswordButtonKey"),
                                onTap: () async {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
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
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SecondaryButton(
                      width: 250,
                      buttonHeight: ButtonHeight.xl,
                      label: "Cancel",
                      onPressed: Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pop,
                    ),
                    const SizedBox(width: 16),
                    PrimaryButton(
                      width: 250,
                      buttonHeight: ButtonHeight.xl,
                      enabled: _continueEnabled,
                      label: "Continue",
                      onPressed: _continueEnabled
                          ? () async {
                              // add loading indicator
                              unawaited(
                                showDialog(
                                  context: context,
                                  builder: (context) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                Navigator.of(context, rootNavigator: true)
                                    .pop();

                                final words = await ref
                                    .read(walletsChangeNotifierProvider)
                                    .getManager(widget.walletId)
                                    .mnemonic;

                                if (mounted) {
                                  Navigator.of(context).pop();

                                  unawaited(
                                    Navigator.of(context).pushNamed(
                                      DesktopAttentionDeleteWallet.routeName,
                                      arguments: widget.walletId,
                                    ),
                                  );
                                }
                              } else {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();

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
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
