import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/global/prefs_provider.dart';
import '../../../providers/hardware/hardware_wallet_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../wallets/hardware/hardware_session_state.dart';
import '../../../wallets/hardware/hardware_wallet_device.dart';
import '../../../wallets/hardware/hardware_wallet_service.dart';
import '../../../wallets/hardware/mock_hardware_wallet_service.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';

class HardwareConfirmDialog extends ConsumerStatefulWidget {
  const HardwareConfirmDialog({
    super.key,
    required this.walletId,
    required this.service,
    required this.device,
    required this.payload,
  });

  final String walletId;
  final HardwareWalletService service;
  final HardwareWalletDevice device;
  final Map<String, dynamic> payload;

  @override
  ConsumerState<HardwareConfirmDialog> createState() =>
      _HardwareConfirmDialogState();
}

class _HardwareConfirmDialogState
    extends ConsumerState<HardwareConfirmDialog> {
  bool _hasScheduledPop = false;

  @override
  void initState() {
    super.initState();
    _startSigning();
  }

  void _startSigning() {
    Future.microtask(() async {
      final isMock = widget.service is MockHardwareWalletService;
      if (!isMock) {
        ref.read(hardwareSigningStateProvider.notifier).state =
            HardwareSessionState.approvalPending;
      }
      try {
        final result = await widget.service.signTransaction(
          device: widget.device,
          payload: widget.payload,
        );
        ref.read(hardwareSigningResultProvider.notifier).state = result;
        if (!isMock) {
          ref.read(hardwareSigningStateProvider.notifier).state =
              HardwareSessionState.connected;
        }
      } catch (e) {
        if (!isMock) {
          ref.read(hardwareSigningStateProvider.notifier).state =
              HardwareSessionState.error;
        }
      }
    });
  }

  void _retry() {
    ref.read(hardwareSigningStateProvider.notifier).state =
        HardwareSessionState.idle;
    ref.read(hardwareSigningResultProvider.notifier).state = null;
    setState(() {
      _hasScheduledPop = false;
    });
    _startSigning();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hardwareSigningStateProvider);
    final colors = Theme.of(context).extension<StackColors>()!;

    if (state == HardwareSessionState.connected && !_hasScheduledPop) {
      _hasScheduledPop = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }

    return DesktopDialog(
      maxHeight: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesktopDialogCloseButton(
              onPressedOverride: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
            _buildStateContent(state, colors),
            const SizedBox(height: 24),
            _buildActions(state, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent(
    HardwareSessionState state,
    StackColors colors,
  ) {
    switch (state) {
      case HardwareSessionState.approvalPending:
      case HardwareSessionState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: colors.accentColorBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Confirm transaction on your device',
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: colors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case HardwareSessionState.connected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: colors.accentColorGreen,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Transaction approved',
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: colors.accentColorGreen,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case HardwareSessionState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.accentColorRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Transaction rejected on device',
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: colors.accentColorRed,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case HardwareSessionState.disconnected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.usb_off,
              color: colors.textSubtitle1,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Device disconnected',
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: colors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case HardwareSessionState.timeout:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off,
              color: colors.textSubtitle1,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Device not responding',
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: colors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions(
    HardwareSessionState state,
    StackColors colors,
  ) {
    final children = <Widget>[];

    if (state == HardwareSessionState.error ||
        state == HardwareSessionState.disconnected ||
        state == HardwareSessionState.timeout) {
      children.add(
        PrimaryButton(
          label: 'Retry',
          onPressed: _retry,
        ),
      );
    }

    final mockService = widget.service is MockHardwareWalletService
        ? widget.service as MockHardwareWalletService
        : null;
    if (mockService != null &&
        (state == HardwareSessionState.approvalPending ||
            state == HardwareSessionState.idle) &&
        !ref.read(prefsChangeNotifierProvider).enableMockHardwareAutoSigner) {
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => mockService.simulateApproval(),
              child: Text(
                'Approve',
                style: STextStyles.desktopTextSmall(context).copyWith(
                  color: colors.accentColorGreen,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => mockService.simulateRejection(),
              child: Text(
                'Reject',
                style: STextStyles.desktopTextSmall(context).copyWith(
                  color: colors.accentColorRed,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => mockService.simulateDisconnect(),
              child: Text(
                'Disconnect',
                style: STextStyles.desktopTextSmall(context).copyWith(
                  color: colors.textSubtitle1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
