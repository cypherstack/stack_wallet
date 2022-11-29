import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';

class CurrencySettings extends ConsumerStatefulWidget {
  const CurrencySettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuCurrency";

  @override
  ConsumerState<CurrencySettings> createState() => _CurrencySettings();
}

class _CurrencySettings extends ConsumerState<CurrencySettings> {
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
                  Assets.svg.circleDollarSign,
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
                            text: "Currency",
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
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(
                        10,
                      ),
                      child: NewPasswordButton(),
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
  Future<void> chooseCurrency(BuildContext context) async {
    // await showDialog<dynamic>(
    //   context: context,
    //   useSafeArea: false,
    //   barrierDismissible: true,
    //   builder: (context) {
    //     return CurrencyDialog();
    //   },
    // );
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return DesktopDialog(
          maxHeight: 800,
          maxWidth: 600,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      "Select currency",
                      style: STextStyles.desktopH3(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const DesktopDialogCloseButton(),
                ],
              ),
              const Expanded(
                child: BaseCurrencySettingsView(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 200,
      height: 48,
      child: TextButton(
        style: Theme.of(context)
            .extension<StackColors>()!
            .getPrimaryEnabledButtonColor(context),
        onPressed: () {
          chooseCurrency(context);
        },
        child: Text(
          "Change currency",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
