import 'package:flutter/material.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/conditional_parent.dart';

class DesktopStepItem extends StatelessWidget {
  const DesktopStepItem(
      {Key? key,
      required this.label,
      required this.value,
      this.padding = const EdgeInsets.all(16),
      this.vertical = false})
      : super(key: key);

  final String label;
  final String value;
  final EdgeInsets padding;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ConditionalParent(
        condition: vertical,
        builder: (child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const SizedBox(
              height: 2,
            ),
            Text(
              value,
              style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark,
              ),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: STextStyles.desktopTextExtraExtraSmall(context),
            ),
            if (!vertical)
              Text(
                value,
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
