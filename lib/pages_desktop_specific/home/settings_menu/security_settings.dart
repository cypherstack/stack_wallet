import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:zxcvbn/zxcvbn.dart';

class SecuritySettings extends ConsumerStatefulWidget {
  const SecuritySettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuSecurity";

  @override
  ConsumerState<SecuritySettings> createState() => _SecuritySettings();
}

class _SecuritySettings extends ConsumerState<SecuritySettings> {
  late bool changePassword = false;

  late final TextEditingController passwordCurrentController;
  late final TextEditingController passwordController;
  late final TextEditingController passwordRepeatController;

  late final FocusNode passwordCurrentFocusNode;
  late final FocusNode passwordFocusNode;
  late final FocusNode passwordRepeatFocusNode;
  final zxcvbn = Zxcvbn();

  bool hidePassword = true;
  bool shouldShowPasswordHint = true;

  double passwordStrength = 0.0;

  bool get shouldEnableSave {
    return passwordCurrentController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        passwordRepeatController.text.isNotEmpty;
  }

  String passwordFeedback =
      "Add another word or two. Uncommon words are better. Use a few words, avoid common phrases. No need for symbols, digits, or uppercase letters.";

  @override
  void initState() {
    passwordCurrentController = TextEditingController();
    passwordController = TextEditingController();
    passwordRepeatController = TextEditingController();

    passwordCurrentFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    passwordRepeatFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    passwordCurrentController.dispose();
    passwordController.dispose();
    passwordRepeatController.dispose();

    passwordCurrentFocusNode.dispose();
    passwordFocusNode.dispose();
    passwordRepeatFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  Assets.svg.circleLock,
                  width: 48,
                  height: 48,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Change Password",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                          TextSpan(
                            text:
                                "\n\nProtect your Stack Wallet with a strong password. Stack Wallet does not store "
                                "your password, and is therefore NOT able to restore it. Keep your password safe and secure.",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(
                        10,
                      ),
                      child: changePassword
                          ? SizedBox(
                              width: 512,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Current password",
                                    style:
                                        STextStyles.desktopTextExtraExtraSmall(
                                                context)
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark3),
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    child: TextField(
                                      key: const Key(
                                          "desktopSecurityRestoreFromFilePasswordFieldKey"),
                                      focusNode: passwordFocusNode,
                                      controller: passwordController,
                                      style: STextStyles.field(context),
                                      obscureText: hidePassword,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      decoration: standardInputDecoration(
                                        "Enter current password",
                                        passwordFocusNode,
                                        context,
                                      ).copyWith(
                                        labelStyle:
                                            STextStyles.fieldLabel(context),
                                        suffixIcon: UnconstrainedBox(
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 16,
                                              ),
                                              GestureDetector(
                                                key: const Key(
                                                    "desktopSecurityRestoreFromFilePasswordFieldShowPasswordButtonKey"),
                                                onTap: () async {
                                                  setState(() {
                                                    hidePassword =
                                                        !hidePassword;
                                                  });
                                                },
                                                child: SvgPicture.asset(
                                                  hidePassword
                                                      ? Assets.svg.eye
                                                      : Assets.svg.eyeSlash,
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textDark3,
                                                  width: 16,
                                                  height: 16,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      onChanged: (newValue) {},
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "New password",
                                    style:
                                        STextStyles.desktopTextExtraExtraSmall(
                                                context)
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark3),
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    child: TextField(
                                      key: const Key(
                                          "desktopSecurityCreateNewPasswordFieldKey1"),
                                      focusNode: passwordCurrentFocusNode,
                                      controller: passwordCurrentController,
                                      style: STextStyles.field(context),
                                      obscureText: hidePassword,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      decoration: standardInputDecoration(
                                        "Enter new password",
                                        passwordCurrentFocusNode,
                                        context,
                                      ).copyWith(
                                        labelStyle:
                                            STextStyles.fieldLabel(context),
                                        suffixIcon: UnconstrainedBox(
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 16,
                                              ),
                                              GestureDetector(
                                                key: const Key(
                                                    "desktopSecurityCreateNewPasswordButtonKey1"),
                                                onTap: () async {
                                                  setState(() {
                                                    hidePassword =
                                                        !hidePassword;
                                                  });
                                                },
                                                child: SvgPicture.asset(
                                                  hidePassword
                                                      ? Assets.svg.eye
                                                      : Assets.svg.eyeSlash,
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textDark3,
                                                  width: 16,
                                                  height: 16,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      onChanged: (newValue) {
                                        if (newValue.isEmpty) {
                                          setState(() {
                                            passwordFeedback = "";
                                          });
                                          return;
                                        }
                                        final result =
                                            zxcvbn.evaluate(newValue);
                                        String suggestionsAndTips = "";
                                        for (var sug in result
                                            .feedback.suggestions!
                                            .toSet()) {
                                          suggestionsAndTips += "$sug\n";
                                        }
                                        suggestionsAndTips +=
                                            result.feedback.warning!;
                                        String feedback =
                                            // "Password Strength: ${((result.score! / 4.0) * 100).toInt()}%\n"
                                            suggestionsAndTips;

                                        passwordStrength = result.score! / 4;

                                        // hack fix to format back string returned from zxcvbn
                                        if (feedback
                                            .contains("phrasesNo need")) {
                                          feedback = feedback.replaceFirst(
                                              "phrasesNo need",
                                              "phrases\nNo need");
                                        }

                                        if (feedback.endsWith("\n")) {
                                          feedback = feedback.substring(
                                              0, feedback.length - 2);
                                        }

                                        setState(() {
                                          passwordFeedback = feedback;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Confirm new password",
                                    style:
                                        STextStyles.desktopTextExtraExtraSmall(
                                                context)
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark3),
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Constants.size.circularBorderRadius,
                                    ),
                                    child: TextField(
                                      key: const Key(
                                          "desktopSecurityCreateNewPasswordFieldKey2"),
                                      focusNode: passwordRepeatFocusNode,
                                      controller: passwordRepeatController,
                                      style: STextStyles.field(context),
                                      obscureText: hidePassword,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      decoration: standardInputDecoration(
                                        "Confirm new password",
                                        passwordRepeatFocusNode,
                                        context,
                                      ).copyWith(
                                        labelStyle:
                                            STextStyles.fieldLabel(context),
                                        suffixIcon: UnconstrainedBox(
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 16,
                                              ),
                                              GestureDetector(
                                                key: const Key(
                                                    "desktopSecurityCreateNewPasswordButtonKey2"),
                                                onTap: () async {
                                                  setState(() {
                                                    hidePassword =
                                                        !hidePassword;
                                                  });
                                                },
                                                child: SvgPicture.asset(
                                                  hidePassword
                                                      ? Assets.svg.eye
                                                      : Assets.svg.eyeSlash,
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textDark3,
                                                  width: 16,
                                                  height: 16,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      onChanged: (newValue) {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  PrimaryButton(
                                    width: 142,
                                    desktopMed: true,
                                    enabled: shouldEnableSave,
                                    label: "Save changes",
                                    onPressed: () {
                                      setState(() {
                                        changePassword = false;
                                      });
                                    },
                                  )
                                ],
                              ),
                            )
                          : PrimaryButton(
                              width: 192,
                              desktopMed: true,
                              enabled: true,
                              label: "Set up new password",
                              onPressed: () {
                                setState(() {
                                  changePassword = true;
                                });
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NewPasswordButton extends ConsumerWidget {
  const NewPasswordButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 200,
      height: 48,
      child: TextButton(
        style: Theme.of(context)
            .extension<StackColors>()!
            .getPrimaryEnabledButtonColor(context),
        onPressed: () {},
        child: Text(
          "Set up new password",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
