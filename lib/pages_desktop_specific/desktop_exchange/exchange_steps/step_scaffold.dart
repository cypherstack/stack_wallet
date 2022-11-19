import 'package:flutter/material.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/subwidgets/desktop_exchange_steps_indicator.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class StepScaffold extends StatefulWidget {
  const StepScaffold({Key? key, required this.step}) : super(key: key);

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
      children: [
        Row(
          children: [
            const AppBarBackButton(
              isCompact: true,
            ),
            Text(
              "Exchange XXX to XXX",
              style: STextStyles.desktopH3(context),
            ),
          ],
        ),
        const SizedBox(
          height: 32,
        ),
        DesktopExchangeStepsIndicator(
          currentStep: currentStep,
        ),
        const SizedBox(
          height: 32,
        ),
        Container(
          height: 200,
          color: Colors.red,
        ),
      ],
    );
  }
}
