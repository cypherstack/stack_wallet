import 'package:flutter/material.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class DesktopStep2 extends StatelessWidget {
  const DesktopStep2({
    Key? key,
    required this.model,
  }) : super(key: key);

  final IncompleteExchangeModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Enter exchange details",
          style: STextStyles.desktopTextMedium(context),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          "Enter your recipient and refund addresses",
          style: STextStyles.desktopTextExtraExtraSmall(context),
        ),
        const SizedBox(
          height: 20,
        ),
        //
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 32,
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Back",
                  buttonHeight: ButtonHeight.l,
                  onPressed: Navigator.of(context).pop,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: PrimaryButton(
                  label: "Next",
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
