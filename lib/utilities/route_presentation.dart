import 'dart:async';

import 'package:flutter/material.dart';

/// A dialog route that can wait until a newer route, such as the app lock
/// screen, has been dismissed. Results must not be pushed above a lock route.
class CurrentAwareDialogRoute<T> extends DialogRoute<T> {
  CurrentAwareDialogRoute({
    required super.context,
    required super.builder,
    super.barrierDismissible,
    super.useSafeArea,
    super.themes,
  });

  final List<Completer<void>> _currentWaiters = [];

  void _completeCurrentWaiters() {
    for (final waiter in _currentWaiters.toList()) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  Future<void> waitUntilCurrent() async {
    if (!isActive || isCurrent) return;
    final waiter = Completer<void>();
    _currentWaiters.add(waiter);
    await Future.any([waiter.future, popped]);
    _currentWaiters.remove(waiter);
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    if (nextRoute == null) {
      _completeCurrentWaiters();
    }
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    _completeCurrentWaiters();
  }

  @override
  void dispose() {
    _completeCurrentWaiters();
    _currentWaiters.clear();
    super.dispose();
  }
}

/// Dismisses [route] only after routes above it (notably the app lock) leave.
///
/// Returns false when the route was removed while waiting, so callers do not
/// present a result dialog above whatever replaced it.
Future<bool> dismissCurrentAwareDialogRoute({
  required NavigatorState navigator,
  required CurrentAwareDialogRoute<void> route,
}) async {
  await route.waitUntilCurrent();
  if (!navigator.mounted || !route.isActive || !route.isCurrent) return false;
  navigator.pop();
  return true;
}

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
