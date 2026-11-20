import 'dart:async';

import '../wallets/wallet/impl/zcash_wallet.dart';
import 'zcash_sapling_parameter_service.dart';

typedef ZcashRestoreParameterRunner = Future<bool> Function(
  SaplingParameterTask Function() taskFactory,
);

({String label, double? progress}) zcashRestoreParameterActivity(
  SaplingParameterState state,
) => switch (state) {
  SaplingParametersChecking() => (
    label: 'Checking existing Zcash data',
    progress: null,
  ),
  SaplingParametersDownloading(
    :final totalReceivedBytes,
    :final totalExpectedBytes,
  ) =>
    (
      label: 'Downloading Zcash data',
      progress: totalExpectedBytes == 0
          ? 0.0
          : (totalReceivedBytes / totalExpectedBytes).clamp(0.0, 1.0),
    ),
  SaplingParametersVerifying() => (
    label: 'Verifying Zcash data',
    progress: null,
  ),
  SaplingParametersReady() => (label: 'Zcash data ready', progress: 1.0),
  SaplingParametersFailed() => (
    label: 'Zcash data unavailable',
    progress: null,
  ),
};

/// Owns the cancellable scan-then-parameter-acquisition portion of a restored
/// Zcash wallet. Wallet shutdown and deletion remain the caller's lifecycle
/// responsibility.
final class ZcashRestoredWalletOperation {
  factory ZcashRestoredWalletOperation({
    required Future<void> Function() scan,
    required bool Function() shouldAcquireParameters,
    required Future<void> Function() cancelScan,
    SaplingParameterTask Function()? parameterTaskFactory,
  }) => ZcashRestoredWalletOperation._(
    scan,
    shouldAcquireParameters,
    cancelScan,
    parameterTaskFactory ??
        () => ZcashSaplingParameterService.instance.resolve(
          access: SaplingParameterAccess.downloadIfMissing,
        ),
  );

  ZcashRestoredWalletOperation._(
    this._scan,
    this._shouldAcquireParameters,
    this._cancelScan,
    this._parameterTaskFactory,
  );

  factory ZcashRestoredWalletOperation.forWallet(
    ZcashWallet wallet, {
    bool isRescan = false,
    SaplingParameterTask Function()? parameterTaskFactory,
  }) => ZcashRestoredWalletOperation(
    scan: () => wallet.recover(isRescan: isRescan),
    shouldAcquireParameters: () => wallet.needsSaplingParametersAfterRestore,
    cancelScan: wallet.cancelRecovery,
    parameterTaskFactory: parameterTaskFactory,
  );

  final Future<void> Function() _scan;
  final bool Function() _shouldAcquireParameters;
  final Future<void> Function() _cancelScan;
  final SaplingParameterTask Function() _parameterTaskFactory;

  SaplingParameterTask? _parameterTask;
  Future<bool>? _result;
  Future<void>? _cancellation;
  bool _cancelled = false;

  Future<bool> run({required ZcashRestoreParameterRunner acquireParameters}) =>
      _result ??= _run(acquireParameters);

  Future<bool> _run(ZcashRestoreParameterRunner acquireParameters) async {
    try {
      if (_cancelled) return false;
      await _scan();
      if (_cancelled) return false;
      if (!_shouldAcquireParameters()) return true;

      final acquired = await acquireParameters(() {
        if (_cancelled) throw const ZcashRestoreOperationCancelled();
        final task = _parameterTaskFactory();
        _parameterTask = task;
        if (_cancelled) {
          unawaited(task.cancel());
          throw const ZcashRestoreOperationCancelled();
        }
        return task;
      });
      return acquired && !_cancelled;
    } on Object {
      if (_cancelled) return false;
      rethrow;
    } finally {
      _parameterTask = null;
    }
  }

  Future<void> cancel() => _cancellation ??= _cancel();

  Future<void> _cancel() async {
    _cancelled = true;
    final task = _parameterTask;
    await Future.wait<void>([_cancelScan(), if (task != null) task.cancel()]);
  }
}

final class ZcashRestoreOperationCancelled implements Exception {
  const ZcashRestoreOperationCancelled();
}
