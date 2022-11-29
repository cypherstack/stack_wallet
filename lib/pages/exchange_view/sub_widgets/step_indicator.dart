import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';

enum StepIndicatorStatus { current, completed, incomplete }

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    Key? key,
    required this.step,
    required this.status,
    this.size = 16,
  }) : super(key: key);

  final int step;
  final StepIndicatorStatus status;

  final double size;

  Color background(BuildContext context) {
    switch (status) {
      case StepIndicatorStatus.current:
        return Theme.of(context)
            .extension<StackColors>()!
            .stepIndicatorBGNumber;
      case StepIndicatorStatus.completed:
        return Theme.of(context).extension<StackColors>()!.stepIndicatorBGCheck;
      case StepIndicatorStatus.incomplete:
        return Theme.of(context)
            .extension<StackColors>()!
            .stepIndicatorBGInactive;
    }
  }

  Widget centered(BuildContext context) {
    switch (status) {
      case StepIndicatorStatus.current:
        return Text(
          step.toString(),
          style: STextStyles.stepIndicator(context).copyWith(
            color: Theme.of(context)
                .extension<StackColors>()!
                .stepIndicatorIconNumber,
          ),
        );
      case StepIndicatorStatus.completed:
        return SvgPicture.asset(
          Assets.svg.check,
          color:
              Theme.of(context).extension<StackColors>()!.stepIndicatorIconText,
          width: 10,
        );
      case StepIndicatorStatus.incomplete:
        return Text(
          step.toString(),
          style: STextStyles.stepIndicator(context).copyWith(
            color: Theme.of(context)
                .extension<StackColors>()!
                .stepIndicatorIconInactive,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: background(context),
      ),
      child: Center(
        child: centered(context),
      ),
    );
  }
}
