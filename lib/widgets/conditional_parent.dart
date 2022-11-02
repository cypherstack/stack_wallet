import 'package:flutter/material.dart';

class ConditionalParent extends StatelessWidget {
  const ConditionalParent({
    Key? key,
    required this.condition,
    required this.builder,
    required this.child,
  }) : super(key: key);

  final bool condition;
  final Widget Function(Widget) builder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return builder(child);
    } else {
      return child;
    }
  }
}
