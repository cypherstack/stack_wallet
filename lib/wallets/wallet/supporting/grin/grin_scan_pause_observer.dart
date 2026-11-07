import 'package:flutter/widgets.dart';

/// Cancels a running Grin scan when the app goes to the background.
///
/// Modelled on the grin_native example's GrinLifecycleObserver. The scan
/// stops after its current batch and resumes from the stored height on the
/// next refresh.
class GrinScanPauseObserver {
  GrinScanPauseObserver({required this._cancelScan}) {
    _listener = AppLifecycleListener(onStateChange: onStateChange);
  }

  /// Without a listener, for tests.
  @visibleForTesting
  GrinScanPauseObserver.detached({required this._cancelScan});

  final void Function() _cancelScan;
  AppLifecycleListener? _listener;

  @visibleForTesting
  void onStateChange(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    try {
      _cancelScan();
    } on StateError {
      // Closed; nothing to cancel.
    } catch (_) {}
  }

  void dispose() {
    _listener?.dispose();
    _listener = null;
  }
}
