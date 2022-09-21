import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

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

  Color get background {
    switch (status) {
      case StepIndicatorStatus.current:
        return CFColors.selection;
      case StepIndicatorStatus.completed:
        return CFColors.selection;
      case StepIndicatorStatus.incomplete:
        return CFColors.stackAccent.withOpacity(0.2);
    }
  }

  Widget get centered {
    switch (status) {
      case StepIndicatorStatus.current:
        return Text(
          step.toString(),
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 8,
            color: StackTheme.instance.color.stepIndicatorIconNumber,
          ),
        );
      case StepIndicatorStatus.completed:
        return SvgPicture.asset(
          Assets.svg.check,
          color: StackTheme.instance.color.stepIndicatorIconText,
          width: 10,
        );
      case StepIndicatorStatus.incomplete:
        return Text(
          step.toString(),
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 8,
            color: StackTheme.instance.color.stepIndicatorIconInactive,
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
        color: background,
      ),
      child: Center(
        child: centered,
      ),
    );
  }
}
