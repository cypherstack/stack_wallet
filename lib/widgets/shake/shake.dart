import 'package:flutter/cupertino.dart';

class Shake extends StatefulWidget {
  const Shake({
    Key? key,
    required this.child,
    required this.animationRange,
    required this.controller,
    required this.animationDuration,
  }) : super(key: key);

  final Widget child;
  final double animationRange;
  final ShakeController controller;
  final Duration animationDuration;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late double _left;
  late double _right;

  // must be an odd number
  final int nShakes = 3;

  void shake() async {
    final duration = widget.animationDuration ~/ ((nShakes * 2) + 1);
    final p = widget.animationRange;

    _left = p * 0.75;
    _right = p * 1.25;
    setState(() {});
    await Future<void>.delayed(duration ~/ 2);

    _right = p * 0.5;
    _left = p * 1.5;
    setState(() {});
    await Future<void>.delayed(duration);
    _left = 0;
    _right = p * 2;
    setState(() {});
    await Future<void>.delayed(duration);

    _right = 0;
    _left = p * 2;
    setState(() {});
    await Future<void>.delayed(duration);
    _left = 0;
    _right = p * 2;
    setState(() {});
    await Future<void>.delayed(duration);

    _right = p * 0.5;
    _left = p * 2;
    setState(() {});
    await Future<void>.delayed(duration);
    _left = p * 0.5;
    _right = p * 1.5;
    setState(() {});
    await Future<void>.delayed(duration);

    _right = p;
    _left = p;
    setState(() {});
  }

  @override
  void initState() {
    _left = widget.animationRange;
    _right = widget.animationRange;
    widget.controller.state = this;

    super.initState();
  }

  @override
  void dispose() {
    widget.controller.state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: widget.animationDuration ~/ ((nShakes * 2) + 1),
      curve: Curves.easeInOut,
      padding: EdgeInsets.only(
        top: 0,
        bottom: 0,
        left: _left,
        right: _right,
      ),
      child: widget.child,
    );
  }
}

class ShakeController {
  _ShakeState? state;

  Future<void> shake() async {
    state?.shake();
  }
}

//
//
// class Shake extends StatefulWidget {
//   const Shake({
//     Key? key,
//     required this.child,
//     required this.horizontalPadding,
//     required this.animationRange,
//     required this.controller,
//     required this.animationDuration,
//   }) : super(key: key);
//
//   final Widget child;
//   final double horizontalPadding;
//   final double animationRange;
//   final ShakeController controller;
//   final Duration animationDuration;
//
//   @override
//   State<Shake> createState() => _ShakeState();
// }
//
// class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
//   late final AnimationController animationController;
//
//   @override
//   void initState() {
//     animationController = AnimationController(
//       duration: widget.animationDuration,
//       vsync: this,
//     );
//     widget.controller.animationController = animationController;
//
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Animation<double> offsetAnimation =
//     Tween(begin: 0.0, end: widget.animationRange)
//         .chain(CurveTween(curve: Curves.elasticIn))
//         .animate(animationController)
//       ..addStatusListener((status) {
//         if (status == AnimationStatus.completed) {
//           animationController.reverse();
//         }
//       });
//
//     return AnimatedBuilder(
//       animation: offsetAnimation,
//       builder: (context, child) {
//         return Container(
//           margin: EdgeInsets.symmetric(horizontal: widget.animationRange),
//           padding: EdgeInsets.only(
//               left: offsetAnimation.value + widget.horizontalPadding,
//               right: widget.horizontalPadding - offsetAnimation.value),
//           child: widget.child,
//         );
//       },
//     );
//   }
// }
//
// class ShakeController {
//   AnimationController? animationController;
//
//   Future<void> shake() async {
//     animationController?.forward(from: 0.0);
//   }
//
//   void dispose() {
//     animationController = null;
//   }
// }
