import 'package:flutter/material.dart';

const double kDesktopAppBarHeight = 96.0;
const double kDesktopAppBarHeightCompact = 82.0;

class DesktopAppBar extends StatefulWidget {
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
  State<DesktopAppBar> createState() => _DesktopAppBarState();
}

class _DesktopAppBarState extends State<DesktopAppBar> {
  late final List<Widget> items;

  @override
  void initState() {
    items = [];
    if (widget.leading != null) {
      items.add(widget.leading!);
    }

    if (widget.useSpacers) {
      items.add(const Spacer());
    }

    if (widget.center != null) {
      items.add(widget.center!);
      if (widget.useSpacers) {
        items.add(const Spacer());
      }
    }

    if (widget.trailing != null) {
      items.add(widget.trailing!);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.background,
      ),
      height: widget.isCompactHeight
          ? kDesktopAppBarHeightCompact
          : kDesktopAppBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: items,
      ),
    );
  }
}
