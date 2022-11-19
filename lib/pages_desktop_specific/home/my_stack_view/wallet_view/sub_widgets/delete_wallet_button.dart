import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';

class DeleteWalletButton extends ConsumerStatefulWidget {
  const DeleteWalletButton({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DeleteWalletButton> createState() => _DeleteWalletButton();
}

class _DeleteWalletButton extends ConsumerState<DeleteWalletButton> {
  late final TextEditingController passwordController;
  late final FocusNode passwordFocusNode;

  bool hidePassword = true;
  bool _continueEnabled = false;

  Future<void> attentionDelete() async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) => DesktopDialog(
        maxWidth: 580,
        maxHeight: 530,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                DesktopDialogCloseButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
              child: Column(
                children: [
                  Text(
                    "Attention!",
                    style: STextStyles.desktopH2(context),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  RoundedContainer(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .snackBarBackError,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "You are going to permanently delete you wallet.\n\nIf you delete your wallet, "
                        "the only way you can have access to your funds is by using your backup key."
                        "\n\nStack Wallet does not keep nor is able to restore your backup key or your wallet."
                        "\n\nPLEASE SAVE YOUR BACKUP KEY.",
                        style: STextStyles.desktopTextExtraExtraSmall(context)
                            .copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SecondaryButton(
                        width: 250,
                        buttonHeight: ButtonHeight.xl,
                        label: "Cancel",
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 16),
                      PrimaryButton(
                        width: 250,
                        buttonHeight: ButtonHeight.xl,
                        label: "View Backup Key",
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    return RawMaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1000),
      ),
      onPressed: () {
        showDialog<dynamic>(
          barrierDismissible: true,
          context: context,
          builder: (context) => DesktopDialog(
            maxHeight: 475,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    DesktopDialogCloseButton(),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
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
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark3,
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
                              _continueEnabled =
                                  passwordController.text.isNotEmpty;
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
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          const SizedBox(width: 16),
                          PrimaryButton(
                            width: 250,
                            buttonHeight: ButtonHeight.xl,
                            enabled: _continueEnabled,
                            label: "Continue",
                            onPressed: () {
                              Navigator.of(context).pop();

                              attentionDelete();
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 19,
          horizontal: 32,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.ellipsis,
              width: 20,
              height: 20,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
