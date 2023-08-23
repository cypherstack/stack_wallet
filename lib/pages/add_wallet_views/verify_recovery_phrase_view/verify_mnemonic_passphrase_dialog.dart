import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_options/new_wallet_options_view.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';

class VerifyMnemonicPassphraseDialog extends ConsumerStatefulWidget {
  const VerifyMnemonicPassphraseDialog({super.key});

  @override
  ConsumerState<VerifyMnemonicPassphraseDialog> createState() =>
      _VerifyMnemonicPassphraseDialogState();
}

class _VerifyMnemonicPassphraseDialogState
    extends ConsumerState<VerifyMnemonicPassphraseDialog> {
  late final FocusNode passwordFocusNode;
  late final TextEditingController passwordController;

  bool hidePassword = true;

  bool _verifyLock = false;

  void _verify() {
    if (_verifyLock) {
      return;
    }
    _verifyLock = true;

    if (passwordController.text ==
        ref.read(pNewWalletOptions.state).state!.mnemonicPassphrase) {
      Navigator.of(context, rootNavigator: Util.isDesktop).pop("verified");
    } else {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Passphrase does not match",
        context: context,
      );
    }

    _verifyLock = false;
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
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopDialog(
        maxHeight: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                  ),
                  child: Text(
                    "Verify mnemonic passphrase",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: 32,
              ),
              child: child,
            ),
          ],
        ),
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => StackDialogBase(
          keyboardPaddingAmount: MediaQuery.of(context).viewInsets.bottom,
          child: child,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!Util.isDesktop)
              Text(
                "Verify BIP39 passphrase",
                style: STextStyles.pageTitleH2(context),
              ),
            const SizedBox(
              height: 24,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                key: const Key("mnemonicPassphraseFieldKey1"),
                focusNode: passwordFocusNode,
                controller: passwordController,
                style: Util.isDesktop
                    ? STextStyles.desktopTextMedium(context).copyWith(
                        height: 2,
                      )
                    : STextStyles.field(context),
                obscureText: hidePassword,
                enableSuggestions: false,
                autocorrect: false,
                decoration: standardInputDecoration(
                  "Enter your BIP39 passphrase",
                  passwordFocusNode,
                  context,
                ).copyWith(
                  suffixIcon: UnconstrainedBox(
                    child: ConditionalParent(
                      condition: Util.isDesktop,
                      builder: (child) => SizedBox(
                        height: 70,
                        child: child,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: Util.isDesktop ? 24 : 16,
                          ),
                          GestureDetector(
                            key: const Key(
                                "mnemonicPassphraseFieldShowPasswordButtonKey"),
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
                              width: Util.isDesktop ? 24 : 16,
                              height: Util.isDesktop ? 24 : 16,
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
              ),
            ),
            SizedBox(
              height: Util.isDesktop ? 48 : 24,
            ),
            ConditionalParent(
              condition: !Util.isDesktop,
              builder: (child) => Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Cancel",
                      onPressed: Navigator.of(
                        context,
                        rootNavigator: Util.isDesktop,
                      ).pop,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: child,
                  ),
                ],
              ),
              child: PrimaryButton(
                label: "Verify",
                onPressed: _verify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
