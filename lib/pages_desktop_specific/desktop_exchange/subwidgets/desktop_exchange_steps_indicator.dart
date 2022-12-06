import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class DesktopExchangeStepsIndicator extends StatelessWidget {
  const DesktopExchangeStepsIndicator({Key? key, required this.currentStep})
      : super(key: key);

  final int currentStep;

  Color getColor(BuildContext context, int step) {
    if (currentStep >= step) {
      return Theme.of(context)
          .extension<StackColors>()!
          .accentColorBlue
          .withOpacity(0.5);
    } else {
      return Theme.of(context).extension<StackColors>()!.textSubtitle3;
    }
  }

  static const double verticalSpacing = 6;
  static const double horizontalSpacing = 16;
  static const double barHeight = 4;
  static const double width = 152;
  static const double barWidth = 146;

  static const Duration duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final double step = double.parse(currentStep.toString());
    final double dy = (step - 4) - (-(step - 4) * (horizontalSpacing / width));
    return Row(
      children: [
        SizedBox(
          width: width,
          child: Column(
            children: [
              AnimatedCrossFade(
                firstChild: Text(
                  "Confirm amount",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorBlue,
                  ),
                ),
                secondChild: Text(
                  "Confirm amount",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorBlue
                        .withOpacity(0.5),
                  ),
                ),
                crossFadeState: currentStep == 1
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: duration,
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
        SizedBox(
          width: width,
          child: Column(
            children: [
              AnimatedCrossFade(
                firstChild: Text(
                  "Enter details",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle3,
                  ),
                ),
                secondChild: AnimatedCrossFade(
                  firstChild: Text(
                    "Enter details",
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue,
                    ),
                  ),
                  secondChild: Text(
                    "Enter details",
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                          .withOpacity(0.5),
                    ),
                  ),
                  crossFadeState: currentStep == 2 && currentStep > 1
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: duration,
                ),
                crossFadeState: currentStep < 2
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: duration,
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
        SizedBox(
          width: width,
          child: Column(
            children: [
              AnimatedCrossFade(
                firstChild: Text(
                  "Confirm details",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle3,
                  ),
                ),
                secondChild: AnimatedCrossFade(
                  firstChild: Text(
                    "Confirm details",
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue,
                    ),
                  ),
                  secondChild: Text(
                    "Confirm details",
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue
                          .withOpacity(0.5),
                    ),
                  ),
                  crossFadeState: currentStep == 3 && currentStep > 2
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: duration,
                ),
                crossFadeState: currentStep < 3
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: duration,
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
        SizedBox(
          width: width,
          child: Column(
            children: [
              AnimatedCrossFade(
                firstChild: Text(
                  "Complete exchange",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle3,
                  ),
                ),
                secondChild: Text(
                  "Complete exchange",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorBlue,
                  ),
                ),
                crossFadeState: currentStep < 4
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: duration,
              ),
              const SizedBox(
                height: verticalSpacing,
              ),
              Stack(
                children: [
                  RoundedContainer(
                    color: getColor(context, 4),
                    height: barHeight,
                    width: double.infinity,
                  ),
                  AnimatedSlide(
                    offset: Offset(dy, 0),
                    duration: duration,
                    child: RoundedContainer(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorBlue,
                      height: barHeight,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
