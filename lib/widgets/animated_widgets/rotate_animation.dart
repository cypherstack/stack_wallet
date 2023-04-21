import 'package:flutter/widgets.dart';

class RotateAnimationController {
  VoidCallback? forward;
  VoidCallback? reset;
}

class RotateAnimation extends StatefulWidget {
  const RotateAnimation({
    Key? key,
    required this.lottie,
    required this.curve,
    this.controller,
  }) : super(key: key);

  final Widget lottie;
  final Curve curve;
  final RotateAnimationController? controller;

  @override
  State<RotateAnimation> createState() => _RotateAnimationState();
}

class _RotateAnimationState extends State<RotateAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> animation;
  late final Duration duration;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
    );
    animation = Tween<double>(
      begin: 0.0,
    ).animate(
      CurvedAnimation(
        curve: widget.curve,
        parent: animationController,
      ),
    );

    widget.controller?.forward = animationController.forward;
    widget.controller?.reset = animationController.reset;

    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    widget.controller?.forward = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: animation,
      child: widget.lottie,
    );
  }
}
