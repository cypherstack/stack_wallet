import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class StepOneItem extends StatelessWidget {
  const StepOneItem({
    Key? key,
    required this.label,
    required this.value,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  final String label;
  final String value;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: STextStyles.desktopTextExtraExtraSmall(context),
          ),
          Text(
            value,
            style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
