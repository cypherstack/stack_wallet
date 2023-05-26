import 'dart:async';

import 'package:flutter/cupertino.dart';

class AnimatedText extends StatefulWidget {
  const AnimatedText({
    Key? key,
    required this.stringsToLoopThrough,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
  }) : super(key: key);

  final List<String> stringsToLoopThrough;
  final TextStyle style;
  final Duration duration;

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  Timer? _timer;
  late String _text;
  late final List<String> _strings;
  int _currentIndex = 0;

  void update() {
    if (_currentIndex < _strings.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = 0;
    }
    setState(() {
      _text = _strings[_currentIndex];
    });
  }

  @override
  void initState() {
    _strings = widget.stringsToLoopThrough;
    _text = _strings[0];

    _timer = Timer.periodic(widget.duration, (_) {
      update();
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: widget.style,
    );
  }
}
