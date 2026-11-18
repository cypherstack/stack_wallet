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
  if (animation == null || animation.status == AnimationStatus.completed) {
    return;
  }

  final completer = Completer<void>();
  void listener(AnimationStatus status) {
    if (status == AnimationStatus.completed && !completer.isCompleted) {
      completer.complete();
    }
  }

  animation.addStatusListener(listener);
  try {
    await completer.future;
  } finally {
    animation.removeStatusListener(listener);
  }
}
