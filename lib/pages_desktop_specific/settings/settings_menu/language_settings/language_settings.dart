import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/language_settings/language_dialog.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class LanguageOptionSettings extends ConsumerStatefulWidget {
  const LanguageOptionSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuLanguage";

  @override
  ConsumerState<LanguageOptionSettings> createState() =>
      _LanguageOptionSettings();
}

Future<void> chooseLanguage(BuildContext context) async {
  await showDialog<dynamic>(
    context: context,
    useSafeArea: false,
    barrierDismissible: true,
    builder: (context) {
      return const LanguageDialog();
    },
  );
}

class _LanguageOptionSettings extends ConsumerState<LanguageOptionSettings> {
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
            radiusMultiplier: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    Assets.svg.circleLanguage,
                    width: 48,
                    height: 48,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Language",
                              style: STextStyles.desktopTextSmall(context),
                            ),
                            TextSpan(
                              text:
                                  "\n\nSelect the language of your wallet. We use your system language by default.",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(
                        10,
                      ),
                      child: PrimaryButton(
                        width: 200,
                        buttonHeight: ButtonHeight.m,
                        enabled: true,
                        label: "Change language",
                        onPressed: () {
                          chooseLanguage(context);
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
