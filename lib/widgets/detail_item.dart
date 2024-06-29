import 'package:flutter/material.dart';
import '../themes/stack_colors.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import 'conditional_parent.dart';
import 'rounded_white_container.dart';

class DetailItem extends StatelessWidget {
  const DetailItem({
    super.key,
    required this.title,
    required this.detail,
    this.button,
    this.overrideDetailTextColor,
    this.showEmptyDetail = true,
    this.horizontal = false,
    this.disableSelectableText = false,
  });

  final String title;
  final String detail;
  final Widget? button;
  final bool showEmptyDetail;
  final bool horizontal;
  final bool disableSelectableText;
  final Color? overrideDetailTextColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle detailStyle;
    if (overrideDetailTextColor != null) {
      detailStyle = STextStyles.w500_14(context).copyWith(
        color: overrideDetailTextColor,
      );
    } else {
      detailStyle = STextStyles.w500_14(context);
    }

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
        child: horizontal
            ? Row(
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
                  disableSelectableText
                      ? Text(
                          detail,
                          style: detailStyle,
                        )
                      : SelectableText(
                          detail,
                          style: detailStyle,
                        ),
                ],
              )
            : Column(
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
                              style: detailStyle,
                            )
                          : SelectableText(
                              detail,
                              style: detailStyle,
                            ),
                ],
              ),
      ),
    );
  }
}
