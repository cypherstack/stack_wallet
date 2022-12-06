import 'package:flutter/material.dart';

const double kDesktopAppBarHeight = 96.0;
const double kDesktopAppBarHeightCompact = 82.0;

class DesktopAppBar extends StatelessWidget {
  const DesktopAppBar({
    Key? key,
    this.leading,
    this.center,
    this.trailing,
    this.background = Colors.transparent,
    required this.isCompactHeight,
    this.useSpacers = true,
  }) : super(key: key);

  final Widget? leading;
  final Widget? center;
  final Widget? trailing;
  final Color background;
  final bool isCompactHeight;
  final bool useSpacers;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    if (leading != null) {
      items.add(leading!);
    }

    if (useSpacers) {
      items.add(const Spacer());
    }

    if (center != null) {
      items.add(center!);
      if (useSpacers) {
        items.add(const Spacer());
      }
    }

    if (trailing != null) {
      items.add(trailing!);
    }

    return Container(
      decoration: BoxDecoration(
        color: background,
      ),
      height:
          isCompactHeight ? kDesktopAppBarHeightCompact : kDesktopAppBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: items,
      ),
    );
  }
}
