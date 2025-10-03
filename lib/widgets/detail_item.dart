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
    this.borderColor,
    this.expandDetail = false,
  });

  final String title;
  final String detail;
  final Widget? button;
  final bool showEmptyDetail;
  final bool horizontal;
  final bool disableSelectableText;
  final Color? overrideDetailTextColor;
  final Color? borderColor;
  final bool expandDetail;

  @override
  Widget build(BuildContext context) {
    TextStyle detailStyle = STextStyles.w500_14(context);
    String _detail = detail;
    if (overrideDetailTextColor != null) {
      detailStyle = STextStyles.w500_14(
        context,
      ).copyWith(color: overrideDetailTextColor);
    }

    if (detail.isEmpty && showEmptyDetail) {
      _detail = "$title will appear here";
      detailStyle = detailStyle.copyWith(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle3,
      );
    }

    return DetailItemBase(
      horizontal: horizontal,
      borderColor: borderColor,
      expandDetail: expandDetail,
      title:
          disableSelectableText
              ? Text(title, style: STextStyles.itemSubtitle(context))
              : SelectableText(title, style: STextStyles.itemSubtitle(context)),
      detail:
          disableSelectableText
              ? Text(_detail, style: detailStyle)
              : SelectableText(_detail, style: detailStyle),
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
    this.borderColor,
    this.expandDetail = false,
  });

  final Widget title;
  final Widget detail;
  final Widget? button;
  final bool horizontal;
  final Color? borderColor;
  final bool expandDetail;

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !Util.isDesktop || borderColor != null,
      builder:
          (child) => RoundedWhiteContainer(
            padding:
                Util.isDesktop
                    ? const EdgeInsets.all(16)
                    : const EdgeInsets.all(12),
            borderColor: borderColor,
            child: child,
          ),
      child: ConditionalParent(
        condition: Util.isDesktop && borderColor == null,
        builder:
            (child) => Padding(padding: const EdgeInsets.all(16), child: child),
        child:
            horizontal
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    title,
                    if (expandDetail) const SizedBox(width: 16),
                    ConditionalParent(
                      condition: expandDetail,
                      builder: (child) => Expanded(child: child),
                      child: detail,
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [title, button ?? Container()],
                    ),
                    const SizedBox(height: 5),
                    ConditionalParent(
                      condition: expandDetail,
                      builder: (child) => Expanded(child: child),
                      child: detail,
                    ),
                  ],
                ),
      ),
    );
  }
}

class DetailDivider extends StatelessWidget {
  const DetailDivider({super.key});

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return Container(
        height: 1,
        color: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
      );
    } else {
      return const SizedBox(height: 12);
    }
  }
}
