import 'package:flutter/material.dart';

class ConditionalParent extends StatelessWidget {
  const ConditionalParent({
    Key? key,
    required this.condition,
    required this.child,
    required this.builder,
  }) : super(key: key);

  final bool condition;
  final Widget child;
  final Widget Function(Widget) builder;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return builder(child);
    } else {
      return child;
    }
  }
}
