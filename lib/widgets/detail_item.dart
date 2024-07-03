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
    TextStyle detailStyle = STextStyles.w500_14(context);
    String _detail = detail;
    if (overrideDetailTextColor != null) {
      detailStyle = STextStyles.w500_14(context).copyWith(
        color: overrideDetailTextColor,
      );
    }

    if (detail.isEmpty && showEmptyDetail) {
      _detail = "$title will appear here";
      detailStyle = detailStyle.copyWith(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle3,
      );
    }

    return DetailItemBase(
      horizontal: horizontal,
      title: disableSelectableText
          ? Text(
              title,
              style: STextStyles.itemSubtitle(context),
            )
          : SelectableText(
              title,
              style: STextStyles.itemSubtitle(context),
            ),
      detail: disableSelectableText
          ? Text(
              _detail,
              style: detailStyle,
            )
          : SelectableText(
              _detail,
              style: detailStyle,
            ),
    );
  }
}

class DetailItemBase extends StatelessWidget {
  const DetailItemBase({
    super.key,
    required this.title,
    required this.detail,
    this.button,
    this.horizontal = false,
  });

  final Widget title;
  final Widget detail;
  final Widget? button;
  final bool horizontal;

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
        child: horizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  title,
                  detail,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      title,
                      button ?? Container(),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  detail,
                ],
              ),
      ),
    );
  }
}
