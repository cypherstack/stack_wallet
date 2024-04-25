import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class FrostStepUserSteps extends StatelessWidget {
  const FrostStepUserSteps({super.key, required this.userSteps});

  final List<String> userSteps;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        children: [
          for (int i = 0; i < userSteps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${i + 1}.",
                  style: STextStyles.w500_12(context),
                ),
                const SizedBox(
                  width: 4,
                ),
                Expanded(
                  child: Text(
                    userSteps[i],
                    style: STextStyles.w500_12(context),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
