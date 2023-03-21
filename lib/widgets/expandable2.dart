import 'package:flutter/material.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';

enum Expandable2State {
  collapsed,
  expanded,
}

class Expandable2Controller {
  VoidCallback? toggle;
  Expandable2State state = Expandable2State.collapsed;
}

class Expandable2 extends StatefulWidget {
  const Expandable2({
    Key? key,
    required this.header,
    required this.children,
    this.background = Colors.white,
    this.border = Colors.black,
    this.animationController,
    this.animation,
    this.animationDurationMultiplier = 1.0,
    this.onExpandWillChange,
    this.onExpandChanged,
    this.controller,
    this.expandOverride,
  }) : super(key: key);

  final Widget header;
  final List<Widget> children;
  final Color background;
  final Color border;
  final AnimationController? animationController;
  final Animation<double>? animation;
  final double animationDurationMultiplier;
  final void Function(Expandable2State)? onExpandWillChange;
  final void Function(Expandable2State)? onExpandChanged;
  final Expandable2Controller? controller;
  final VoidCallback? expandOverride;

  @override
  State<Expandable2> createState() => _Expandable2State();
}

class _Expandable2State extends State<Expandable2>
    with TickerProviderStateMixin {
  final _key = GlobalKey();

  late final AnimationController animationController;
  late final Animation<double> animation;
  late final Duration duration;
  late final Expandable2Controller? controller;

  Expandable2State _toggleState = Expandable2State.collapsed;

  void toggle() {
    if (animation.isDismissed) {
      _toggleState = Expandable2State.expanded;
      widget.onExpandWillChange?.call(_toggleState);
      animationController
          .forward()
          .then((_) => widget.onExpandChanged?.call(_toggleState));
    } else if (animation.isCompleted) {
      _toggleState = Expandable2State.collapsed;
      widget.onExpandWillChange?.call(_toggleState);
      animationController
          .reverse()
          .then((_) => widget.onExpandChanged?.call(_toggleState));
    }
    controller?.state = _toggleState;
    setState(() {});
  }

  @override
  void initState() {
    controller = widget.controller;
    controller?.toggle = toggle;

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

  double _top = 0;

  void getHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_key.currentContext?.size?.height != null &&
          _top != _key.currentContext!.size!.height) {
        setState(() {
          _top = _key.currentContext!.size!.height;
        });
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    getHeaderHeight();

    return AnimatedContainer(
      duration: duration,
      decoration: _toggleState == Expandable2State.expanded
          ? BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              border: Border.all(color: widget.border),
              boxShadow: [
                Theme.of(context).extension<StackColors>()!.standardBoxShadow,
              ],
            )
          : BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              border: Border.all(color: widget.border),
            ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: _top),
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: 1.0,
              child: Column(
                children: widget.children
                    .map(
                      (e) => Column(
                        children: [
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: widget.border,
                          ),
                          e,
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          MouseRegion(
            key: _key,
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.expandOverride ?? toggle,
              child: Container(
                color: Colors.transparent,
                child: widget.header,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
