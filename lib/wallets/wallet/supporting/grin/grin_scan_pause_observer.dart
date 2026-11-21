import 'package:flutter/widgets.dart';

/// Cancels a running Grin scan when the app goes to the background.
///
/// Modelled on the grin_native example's GrinLifecycleObserver. The scan
/// stops after its current batch and resumes from the stored height on the
/// next refresh.
class GrinScanPauseObserver {
  GrinScanPauseObserver({
    required this._cancelScan,
    required this._resumeScan,
  }) {
    _listener = AppLifecycleListener(onStateChange: onStateChange);
    final state = WidgetsBinding.instance.lifecycleState;
    _paused =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
  }

  /// Without a listener, for tests.
  @visibleForTesting
  GrinScanPauseObserver.detached({
    required this._cancelScan,
    required this._resumeScan,
  });

  final void Function() _cancelScan;
  final void Function() _resumeScan;
  AppLifecycleListener? _listener;
  bool _paused = false;

  bool get isPaused => _paused;

  @visibleForTesting
  void onStateChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wasPaused = _paused;
      _paused = false;
      if (wasPaused) _resumeScan();
      return;
    }
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    _paused = true;
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
