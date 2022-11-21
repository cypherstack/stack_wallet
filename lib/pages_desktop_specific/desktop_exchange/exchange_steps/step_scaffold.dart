import 'package:flutter/material.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/subwidgets/desktop_exchange_steps_indicator.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class StepScaffold extends StatefulWidget {
  const StepScaffold({
    Key? key,
    required this.body,
    required this.step,
  }) : super(key: key);

  final Widget body;
  final int step;

  @override
  State<StepScaffold> createState() => _StepScaffoldState();
}

class _StepScaffoldState extends State<StepScaffold> {
  int currentStep = 0;

  @override
  void initState() {
    currentStep = widget.step;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppBarBackButton(
              isCompact: true,
              iconSize: 23,
            ),
            Text(
              "Exchange XXX to XXX",
              style: STextStyles.desktopH3(context),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: DesktopExchangeStepsIndicator(
            currentStep: currentStep,
          ),
        ),
        const SizedBox(
          height: 32,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: widget.body,
        ),
      ],
    );
  }
}
