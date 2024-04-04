import 'package:flutter/material.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DetailItem extends StatelessWidget {
  const DetailItem({
    Key? key,
    required this.title,
    required this.detail,
    this.button,
    this.showEmptyDetail = true,
    this.disableSelectableText = false,
  }) : super(key: key);

  final String title;
  final String detail;
  final Widget? button;
  final bool showEmptyDetail;
  final bool disableSelectableText;

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => RoundedWhiteContainer(
        child: child,
      ),
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) => Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                disableSelectableText
                    ? Text(
                        title,
                        style: STextStyles.itemSubtitle(context),
                      )
                    : SelectableText(
                        title,
                        style: STextStyles.itemSubtitle(context),
                      ),
                button ?? Container(),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            detail.isEmpty && showEmptyDetail
                ? disableSelectableText
                    ? Text(
                        "$title will appear here",
                        style: STextStyles.w500_14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle3,
                        ),
                      )
                    : SelectableText(
                        "$title will appear here",
                        style: STextStyles.w500_14(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle3,
                        ),
                      )
                : disableSelectableText
                    ? Text(
                        detail,
                        style: STextStyles.w500_14(context),
                      )
                    : SelectableText(
                        detail,
                        style: STextStyles.w500_14(context),
                      ),
          ],
        ),
      ),
    );
  }
}
