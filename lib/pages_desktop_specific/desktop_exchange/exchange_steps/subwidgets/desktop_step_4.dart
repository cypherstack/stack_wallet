import 'package:flutter/material.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/step_one_item.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopStep4 extends StatelessWidget {
  const DesktopStep4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Confirm amount",
          style: STextStyles.desktopTextMedium(context),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          "Network fees and other exchange charges are included in the rate.",
          style: STextStyles.desktopTextExtraExtraSmall(context),
        ),
        const SizedBox(
          height: 20,
        ),
        RoundedWhiteContainer(
          borderColor: Theme.of(context).extension<StackColors>()!.background,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              const StepOneItem(
                label: "Exchange",
                value: "lol",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              const StepOneItem(
                label: "You send",
                value: "lol",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              const StepOneItem(
                label: "You receive",
                value: "lol",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              const StepOneItem(
                label: "Rate",
                value: "lol",
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 32,
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Send from Stack Wallet",
                  buttonHeight: ButtonHeight.l,
                  onPressed: Navigator.of(context).pop,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: PrimaryButton(
                  label: "Show QR code",
                  buttonHeight: ButtonHeight.l,
                  onPressed: () {
                    // todo
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
