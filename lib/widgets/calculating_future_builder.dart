import 'package:flutter/widgets.dart';

import 'animated_text.dart';

/// Shows "Calculating" until [future] answers.
class CalculatingFutureBuilder<T extends Object> extends StatelessWidget {
  const CalculatingFutureBuilder({
    super.key,
    required this.future,
    required this.style,
    required this.builder,
    this.fallback,
  });

  final Future<T> future;
  final TextStyle style;
  final Widget Function(T answer) builder;

  /// Built with when [future] fails.
  final T? fallback;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: future,
    builder: (_, snapshot) {
      final answer = snapshot.connectionState == ConnectionState.done
          ? snapshot.data ?? fallback
          : null;
      return answer == null
          ? AnimatedText(
              stringsToLoopThrough: const [
                "Calculating",
                "Calculating.",
                "Calculating..",
                "Calculating...",
              ],
              style: style,
            )
          : builder(answer);
    },
  );
}
