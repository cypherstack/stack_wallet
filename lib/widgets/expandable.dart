import 'package:flutter/material.dart';

enum ExpandableState {
  expanded,
  collapsed,
}

class Expandable extends StatefulWidget {
  const Expandable({
    Key? key,
    required this.header,
    required this.body,
    this.animationController,
    this.animation,
    this.animationDurationMultiplier = 1.0,
    this.onExpandChanged,
  }) : super(key: key);

  final Widget header;
  final Widget body;
  final AnimationController? animationController;
  final Animation<double>? animation;
  final double animationDurationMultiplier;
  final void Function(ExpandableState)? onExpandChanged;

  @override
  State<Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<Expandable> with TickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> animation;
  late final Duration duration;

  Future<void> toggle() async {
    if (animation.isDismissed) {
      await animationController.forward();
      widget.onExpandChanged?.call(ExpandableState.collapsed);
    } else if (animation.isCompleted) {
      await animationController.reverse();
      widget.onExpandChanged?.call(ExpandableState.expanded);
    }
  }

  @override
  void initState() {
    duration = Duration(
      milliseconds: (500 * widget.animationDurationMultiplier).toInt(),
    );
    animationController = widget.animationController ??
        AnimationController(
          vsync: this,
          duration: duration,
        );
    animation = widget.animation ??
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            curve: Curves.easeInOut,
            parent: animationController,
          ),
        );
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: toggle,
          child: Container(
            color: Colors.transparent,
            child: widget.header,
          ),
        ),
        SizeTransition(
          sizeFactor: animation,
          axisAlignment: 1.0,
          child: widget.body,
        ),
      ],
    );
  }
}
