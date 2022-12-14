import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class DesktopExchangeStepsIndicator extends StatelessWidget {
  const DesktopExchangeStepsIndicator({Key? key, required this.currentStep})
      : super(key: key);

  final int currentStep;

  Color getColor(BuildContext context, int step) {
    if (currentStep > step) {
      return Theme.of(context)
          .extension<StackColors>()!
          .accentColorBlue
          .withOpacity(0.5);
    } else if (currentStep < step) {
      return Theme.of(context).extension<StackColors>()!.textSubtitle3;
    } else {
      return Theme.of(context).extension<StackColors>()!.accentColorBlue;
    }
  }

  static const double verticalSpacing = 6;
  static const double horizontalSpacing = 16;
  static const double barHeight = 4;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                "Confirm amount",
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: getColor(context, 1),
                ),
              ),
              const SizedBox(
                height: verticalSpacing,
              ),
              RoundedContainer(
                color: getColor(context, 1),
                height: barHeight,
                width: double.infinity,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: horizontalSpacing,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                "Enter details",
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: getColor(context, 2),
                ),
              ),
              const SizedBox(
                height: verticalSpacing,
              ),
              RoundedContainer(
                color: getColor(context, 2),
                height: barHeight,
                width: double.infinity,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: horizontalSpacing,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                "Confirm details",
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: getColor(context, 3),
                ),
              ),
              const SizedBox(
                height: verticalSpacing,
              ),
              RoundedContainer(
                color: getColor(context, 3),
                height: barHeight,
                width: double.infinity,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: horizontalSpacing,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                "Complete exchange",
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: getColor(context, 4),
                ),
              ),
              const SizedBox(
                height: verticalSpacing,
              ),
              RoundedContainer(
                color: getColor(context, 4),
                height: barHeight,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
