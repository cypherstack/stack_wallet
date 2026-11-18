import 'dart:async';

import 'package:flutter/widgets.dart';

/// Completes after [route] has finished appearing.
///
/// Some native wallet calls do synchronous work before returning their
/// Future. Waiting for the first frame is not enough for a transition route:
/// its contents can be built while the route opacity is still zero.
Future<void> waitForRoutePresentation(TransitionRoute<void> route) async {
  await WidgetsBinding.instance.endOfFrame;

  final animation = route.animation;
  if (animation == null) {
    return;
  }

  if (animation.status == AnimationStatus.completed) {
    await WidgetsBinding.instance.endOfFrame;
    return;
  }

  final completer = Completer<void>();
  void listener(AnimationStatus status) {
    if ((status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) &&
        !completer.isCompleted) {
      completer.complete();
    }
  }

  animation.addStatusListener(listener);
  try {
    final appeared = await Future.any([
      completer.future.then((_) => true),
      route.popped.then((_) => false),
    ]);
    if (appeared && animation.status == AnimationStatus.completed) {
      // Animation completion precedes the paint of its final frame.
      await WidgetsBinding.instance.endOfFrame;
    }
  } finally {
    animation.removeStatusListener(listener);
  }
}
