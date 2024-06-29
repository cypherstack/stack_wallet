import 'package:flutter/material.dart';

class Breathing extends StatefulWidget {
  const Breathing({super.key, required this.child});

  final Widget child;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(
        () => _hovering = true,
      ),
      onExit: (_) => setState(
        () => _hovering = false,
      ),
      child: AnimatedScale(
        scale: _hovering ? 1.00 : 0.98,
        duration: const Duration(
          milliseconds: 200,
        ),
        child: widget.child,
      ),
    );
  }
}
