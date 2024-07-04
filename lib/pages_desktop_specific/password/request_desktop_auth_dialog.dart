import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../notifications/show_flush_bar.dart';
import '../../providers/desktop/storage_crypto_handler_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_text_field.dart';

class RequestDesktopAuthDialog extends ConsumerStatefulWidget {
  const RequestDesktopAuthDialog({
    super.key,
    this.title,
  });

  final String? title;

  @override
  ConsumerState<RequestDesktopAuthDialog> createState() =>
      _RequestDesktopAuthDialogState();
}

class _RequestDesktopAuthDialogState
    extends ConsumerState<RequestDesktopAuthDialog> {
  late final TextEditingController passwordController;
  late final FocusNode passwordFocusNode;

  bool continueEnabled = false;
  bool hidePassword = true;

  bool _lock = false;
  Future<void> _auth() async {
    if (_lock) {
      return;
    }
    _lock = true;

    try {
      final verified = await showLoading(
        whileFuture: ref
            .read(storageCryptoHandlerProvider)
            .verifyPassphrase(passwordController.text),
        context: context,
        message: "Checking...",
        rootNavigator: true,
        delay: const Duration(milliseconds: 1000),
      );

      if (verified == true) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop("verified success");
        }
      } else {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();

          await Future<void>.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            unawaited(
              showFloatingFlushBar(
                type: FlushBarType.warning,
                message: "Invalid passphrase!",
                context: context,
              ),
            );
          }
        }
      }
    } finally {
      _lock = false;
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
          if (widget.title != null)
            Text(
              widget.title!,
              style: STextStyles.desktopH2(context),
            ),
          if (widget.title != null)
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
                autofocus: true,
                onSubmitted: (_) {
                  if (continueEnabled) {
                    _auth();
                  }
                },
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
                              "enterUnlockWalletKeysDesktopFieldShowPasswordButtonKey",
                            ),
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
                    onPressed: continueEnabled ? _auth : null,
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
