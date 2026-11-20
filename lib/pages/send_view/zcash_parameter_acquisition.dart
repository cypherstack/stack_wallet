import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../services/zcash_sapling_parameter_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/custom_loading_overlay.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_dialog.dart';

Future<T?> prepareWithSaplingParameterAcquisition<T>({
  required Future<T> Function() prepare,
  required bool Function(Object error) isParametersRequired,
  required Future<bool> Function() acquire,
}) async {
  try {
    return await prepare();
  } catch (error) {
    if (!isParametersRequired(error)) rethrow;
  }

  if (!await acquire()) return null;
  return prepare();
}

Future<T?> prepareWithZcashSaplingParameterAcquisition<T>({
  required BuildContext context,
  required Future<T> Function() prepare,
  bool Function()? canAcquire,
  Future<void> Function()? beforeAcquisition,
  Future<void> Function()? afterAcquisition,
  Future<bool> Function()? acquireParameters,
}) => prepareWithSaplingParameterAcquisition<T>(
  prepare: prepare,
  isParametersRequired: (error) => error is ZcashSaplingParametersRequired,
  acquire: () async {
    if (!(canAcquire?.call() ?? true)) return false;
    await beforeAcquisition?.call();
    if (!context.mounted) return false;
    final acquired =
        await (acquireParameters?.call() ??
            acquireSaplingParameters(
              context: context,
              taskFactory: () => ZcashSaplingParameterService.instance.resolve(
                access: SaplingParameterAccess.downloadIfMissing,
              ),
            ));
    if (!acquired || !context.mounted) return false;
    await afterAcquisition?.call();
    return true;
  },
);

Future<bool> acquireSaplingParameters({
  required BuildContext context,
  required SaplingParameterTask Function() taskFactory,
}) async {
  final approved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StackDialog(
      title: 'Additional Zcash data required',
      message:
          'This transaction requires a one-time 49.2 MiB download. The '
          'downloaded files will be cryptographically verified and retained '
          'for future Zcash transactions.',
      leftButton: TextButton(
        style: Theme.of(dialogContext)
            .extension<StackColors>()!
            .getSecondaryEnabledButtonStyle(dialogContext),
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: Text('Cancel', style: STextStyles.button(dialogContext)),
      ),
      rightButton: TextButton(
        style: Theme.of(dialogContext)
            .extension<StackColors>()!
            .getPrimaryEnabledButtonStyle(dialogContext),
        onPressed: () => Navigator.of(dialogContext).pop(true),
        child: Text('Download', style: STextStyles.button(dialogContext)),
      ),
    ),
  );
  if (approved != true || !context.mounted) return false;

  return downloadSaplingParameters(context: context, taskFactory: taskFactory);
}

/// Acquires and verifies Sapling proving parameters without an additional
/// consent prompt. Restore flows call this only after scanning has found
/// spendable Sapling funds.
Future<bool> downloadSaplingParameters({
  required BuildContext context,
  required SaplingParameterTask Function() taskFactory,
}) async {
  late final SaplingParameterTask task;
  try {
    task = taskFactory();
  } catch (error) {
    Logging.instance.w(
      'Sapling parameter acquisition could not start (${error.runtimeType})',
    );
    if (context.mounted) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: 'Zcash data unavailable',
            message: _saplingParameterFailureMessage(error),
          ),
        ),
      );
    }
    return false;
  }
  final progressEvents = EventBus();
  final stage = ValueNotifier<String>('Checking existing Zcash data');
  var acceptingStates = true;
  void handleState(SaplingParameterState state) {
    if (!acceptingStates) return;
    stage.value = switch (state) {
      SaplingParametersChecking() => 'Checking existing Zcash data',
      SaplingParametersDownloading() => 'Downloading Zcash data',
      SaplingParametersVerifying() => 'Verifying Zcash data',
      SaplingParametersReady() => 'Zcash data ready',
      SaplingParametersFailed() => 'Zcash data unavailable',
    };
    if (state case SaplingParametersDownloading(
      :final totalReceivedBytes,
      :final totalExpectedBytes,
    )) {
      final fraction = totalExpectedBytes == 0
          ? 0.0
          : totalReceivedBytes / totalExpectedBytes;
      progressEvents.fire(fraction.clamp(0.0, 1.0));
    }
  }

  final stateSubscription = task.states.listen(handleState);
  if (task case SaplingParameterTaskStateSnapshot(:final currentState?)) {
    handleState(currentState);
  }

  BuildContext? progressDialogContext;
  final progressDialogShown = Completer<void>();
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        progressDialogContext = dialogContext;
        if (!progressDialogShown.isCompleted) {
          progressDialogShown.complete();
        }
        return PopScope(
          canPop: false,
          child: Container(
            color: Theme.of(dialogContext)
                .extension<StackColors>()!
                .overlay
                .withValues(alpha: 0.6),
            child: ValueListenableBuilder<String>(
              valueListenable: stage,
              builder: (context, message, _) => CustomLoadingOverlay(
                message: message,
                subMessage:
                    '49.2 MiB is stored once for future Sapling activity.',
                eventBus: progressEvents,
                actionButton: SecondaryButton(
                  buttonHeight: ButtonHeight.l,
                  label: 'Cancel',
                  onPressed: () => unawaited(task.cancel()),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Object? failure;
  try {
    await Future.wait<void>([
      task.result.then<void>((_) {}),
      progressDialogShown.future,
    ]);
    return true;
  } on ZcashSaplingParameterDownloadCancelled {
    return false;
  } catch (error) {
    failure = error;
    Logging.instance.w(
      'Sapling parameter acquisition failed (${error.runtimeType})',
    );
    return false;
  } finally {
    acceptingStates = false;
    unawaited(stateSubscription.cancel());
    final dialogContext = progressDialogContext;
    if (dialogContext != null && dialogContext.mounted) {
      final route = ModalRoute.of(dialogContext);
      if (route != null) {
        // PopScope intentionally rejects user-initiated back navigation, so
        // remove the completed route directly instead of asking it to pop.
        Navigator.of(dialogContext).removeRoute(route);
      }
    }
    stage.dispose();
    if (context.mounted && failure != null) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: 'Zcash data unavailable',
            message: _saplingParameterFailureMessage(failure!),
          ),
        ),
      );
    }
  }
}

String _saplingParameterFailureMessage(Object error) {
  if (error case zcash.SaplingParameterException(:final failure)) {
    return switch (failure) {
      zcash.SaplingParameterFailure.wrongHash ||
      zcash.SaplingParameterFailure.wrongSize =>
        'The downloaded Zcash data could not be verified. No unverified data '
            'was installed. Please try again later.',
      zcash.SaplingParameterFailure.storageFailure ||
      zcash.SaplingParameterFailure.publishFailed =>
        'The verified Zcash data could not be stored. Free at least 60 MiB '
            'of device storage and try again.',
      zcash.SaplingParameterFailure.untrustedCacheEntry =>
        'The existing Zcash data is not a trusted regular file. Remove the '
            'invalid data before trying again.',
      _ =>
        'The Zcash data could not be downloaded. Check your connection and '
            'try again.',
    };
  }
  return 'The Zcash data could not be downloaded and verified. Check your '
      'connection and try again.';
}
