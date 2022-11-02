import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

import 'currency_dialog.dart';

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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> chooseCurrency() async {
      await showDialog<dynamic>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) {
          return CurrencyDialog();
        },
      );
    }

    return SizedBox(
      width: 200,
      height: 48,
      child: TextButton(
        style: Theme.of(context)
            .extension<StackColors>()!
            .getPrimaryEnabledButtonColor(context),
        onPressed: () {
          chooseCurrency();
        },
        child: Text(
          "Change currency",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
