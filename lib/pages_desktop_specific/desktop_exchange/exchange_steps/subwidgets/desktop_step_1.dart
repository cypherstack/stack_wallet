import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_item.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopStep1 extends ConsumerWidget {
  const DesktopStep1({
    Key? key,
    required this.model,
  }) : super(key: key);

  final IncompleteExchangeModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              DesktopStepItem(
                label: "Exchange",
                value: ref.watch(currentExchangeNameStateProvider.state).state,
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "You send",
                value:
                    "${model.sendAmount.toStringAsFixed(8)} ${model.sendTicker.toUpperCase()}",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "You receive",
                value:
                    "~${model.receiveAmount.toStringAsFixed(8)} ${model.receiveTicker.toUpperCase()}",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: model.rateType == ExchangeRateType.estimated
                    ? "Estimated rate"
                    : "Fixed rate",
                value: model.rateInfo,
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
