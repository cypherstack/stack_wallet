import 'package:flutter/material.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/util.dart';
import '../conditional_parent.dart';

class SDialog extends StatelessWidget {
  const SDialog({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.contentCanScroll = true,
    this.margin,
    this.background,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
  });

  final Widget child;
  final bool contentCanScroll;
  final Color? background;
  final EdgeInsets? margin;
  final EdgeInsets padding;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.all(Util.isDesktop ? 32 : 16),
      child: Column(
        mainAxisAlignment: mainAxisAlignment ??
            (Util.isDesktop ? MainAxisAlignment.center : MainAxisAlignment.end),
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Material(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: background ??
                      Theme.of(context).extension<StackColors>()!.popupBG,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: ConditionalParent(
                  condition: contentCanScroll,
                  builder: (child) => SingleChildScrollView(
                    child: child,
                  ),
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
