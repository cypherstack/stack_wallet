import 'package:flutter/material.dart';

class Messages extends StatefulWidget {
  const Messages({Key? key, required this.child}) : super(key: key);

  final Widget child;

  static MessagesState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedMessagesState>()!
        .data;
  }

  @override
  State<Messages> createState() => MessagesState();
}

class MessagesState extends State<Messages>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> animation;

  Future<void> show({
    required BuildContext context,
    required Widget widget,
    double radius = 8,
    Duration duration = const Duration(seconds: 2),
  }) async {
    OverlayState overlayState = Overlay.of(context)!;
    OverlayEntry entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 16,
          top: MediaQuery.of(context).viewPadding.top + 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: animation,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: widget,
                ),
              ),
            ),
          ),
        );
      },
    );

    animationController.addListener(() {
      overlayState.setState(() {});
    });

    overlayState.insert(entry);

    await animationController.forward();

    await Future<void>.delayed(duration);

    await animationController.reverse();
    entry.remove();
  }

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    animation = CurveTween(
      curve: Curves.bounceInOut,
    ).animate(animationController);

    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedMessagesState(
      this,
      child: widget.child,
    );
  }
}

class _InheritedMessagesState extends InheritedWidget {
  const _InheritedMessagesState(this.data, {required super.child});

  final MessagesState data;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is _InheritedMessagesState) {
      return oldWidget.data == data;
    }
    return false;
  }
}
