import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/hardware/hardware_wallet_provider.dart';
import '../../providers/hardware/hardware_wallet_scan_controller.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/hardware/hardware_session_state.dart';
import '../../wallets/hardware/hardware_wallet_connection_type.dart';
import '../../wallets/hardware/hardware_wallet_device.dart';
import '../../wallets/hardware/hardware_wallet_device_family.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';

class HardwareReconnectDialog extends ConsumerStatefulWidget {
  const HardwareReconnectDialog({
    super.key,
    required this.family,
  });

  final HardwareWalletDeviceFamily family;

  static Future<bool?> show(
    BuildContext context,
    HardwareWalletDeviceFamily family,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HardwareReconnectDialog(family: family),
    );
  }

  @override
  ConsumerState<HardwareReconnectDialog> createState() =>
      _HardwareReconnectDialogState();
}

class _HardwareReconnectDialogState
    extends ConsumerState<HardwareReconnectDialog> {
  late final HardwareWalletScanController _scanController;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _scanController = HardwareWalletScanController(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scanController.startScan(widget.family);
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  void _scheduleAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(hardwareSessionStateProvider);
    final devices = ref.watch(hardwareDevicesProvider);
    final colors = Theme.of(context).extension<StackColors>()!;

    if (sessionState == HardwareSessionState.connected) {
      _scheduleAutoDismiss();
    }

    return DesktopDialog(
      maxWidth: 500,
      maxHeight: 400,
      child: Column(
        children: [
          DesktopDialogCloseButton(
            onPressedOverride: () => Navigator.of(context).pop(false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildStateContent(
                sessionState,
                devices,
                colors,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: _buildActions(sessionState),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent(
    HardwareSessionState state,
    List<HardwareWalletDevice> devices,
    StackColors colors,
  ) {
    switch (state) {
      case HardwareSessionState.idle:
      case HardwareSessionState.scanning:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: colors.accentColorBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Scanning for device...',
                style: STextStyles.desktopTextMedium(context).copyWith(
                  color: colors.textDark,
                ),
              ),
            ],
          ),
        );

      case HardwareSessionState.deviceFound:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Devices found',
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: colors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: colors.textFieldDefaultBG,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                style: STextStyles.desktopTextMedium(context)
                                    .copyWith(color: colors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${device.model} - ${device.connectionType == HardwareWalletConnectionType.usb ? 'USB' : 'BLE'}',
                                style: STextStyles.desktopTextSmall(context)
                                    .copyWith(color: colors.textSubtitle1),
                              ),
                            ],
                          ),
                        ),
                        PrimaryButton(
                          width: 100,
                          label: 'Connect',
                          onPressed: () =>
                              _scanController.connectToDevice(device),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case HardwareSessionState.connecting:
      case HardwareSessionState.approvalPending:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: colors.accentColorBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Connecting...',
                style: STextStyles.desktopTextMedium(context).copyWith(
                  color: colors.textDark,
                ),
              ),
            ],
          ),
        );

      case HardwareSessionState.connected:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: colors.accentColorGreen,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Device connected',
                style: STextStyles.desktopTextMedium(context).copyWith(
                  color: colors.accentColorGreen,
                ),
              ),
            ],
          ),
        );

      case HardwareSessionState.timeout:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_off,
                color: colors.textSubtitle1,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Scan timed out',
                style: STextStyles.desktopTextMedium(context).copyWith(
                  color: colors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check that your device is unlocked and connected via USB',
                style: STextStyles.desktopTextSmall(context).copyWith(
                  color: colors.textSubtitle1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case HardwareSessionState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: colors.accentColorRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Connection error',
                style: STextStyles.desktopTextMedium(context).copyWith(
                  color: colors.accentColorRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to connect to device. Please try again.',
                style: STextStyles.desktopTextSmall(context).copyWith(
                  color: colors.textSubtitle1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case HardwareSessionState.disconnected:
        return Center(
          child: Column(
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
              ),
            ],
          ),
        );
    }
  }

  Widget _buildActions(HardwareSessionState state) {
    switch (state) {
      case HardwareSessionState.connected:
        return const SizedBox.shrink();

      case HardwareSessionState.connecting:
      case HardwareSessionState.approvalPending:
        return SecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        );

      case HardwareSessionState.idle:
      case HardwareSessionState.scanning:
      case HardwareSessionState.deviceFound:
        return SecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        );

      case HardwareSessionState.timeout:
      case HardwareSessionState.error:
      case HardwareSessionState.disconnected:
        return Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: 'Retry',
                onPressed: () => _scanController.refresh(),
              ),
            ),
          ],
        );
    }
  }
}
