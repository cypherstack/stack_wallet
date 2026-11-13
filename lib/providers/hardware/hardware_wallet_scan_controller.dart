import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/global/prefs_provider.dart';
import '../../wallets/hardware/hardware_session_state.dart';
import '../../wallets/hardware/hardware_wallet_adapter.dart';
import '../../wallets/hardware/hardware_wallet_device.dart';
import '../../wallets/hardware/hardware_wallet_device_family.dart';
import '../../wallets/hardware/mock_hardware_wallet_service.dart';
import 'hardware_wallet_provider.dart';

class HardwareWalletScanController {
  static const Duration scanTimeout = Duration(seconds: 10);

  final WidgetRef _ref;
  Timer? _timeoutTimer;
  bool _disposed = false;

  HardwareWalletScanController(this._ref);

  HardwareWalletAdapter? _adapterForFamily(HardwareWalletDeviceFamily family) {
    return _ref.read(hardwareAdapterProvider(family));
  }

  Future<void> startScan(HardwareWalletDeviceFamily family) async {
    if (_disposed) return;

    final useMock = _ref
        .read(prefsChangeNotifierProvider)
        .enableMockHardwareAutoSigner;

    final HardwareWalletAdapter adapter;
    if (useMock) {
      adapter = MockHardwareWalletAdapter(family: family);
      debugPrint(
        '[HardwareWalletScanController] Using mock adapter for $family',
      );
    } else {
      final realAdapter = _adapterForFamily(family);
      if (realAdapter == null) {
        debugPrint(
          '[HardwareWalletScanController] No adapter for $family',
        );
        _ref.read(hardwareSessionStateProvider.notifier).state =
            HardwareSessionState.error;
        return;
      }
      adapter = realAdapter;
    }

    _ref.read(selectedHardwareFamilyProvider.notifier).state = family;
    _ref.read(hardwareSessionStateProvider.notifier).state =
        HardwareSessionState.scanning;
    _ref.read(hardwareDevicesProvider.notifier).state = [];

    debugPrint('[HardwareWalletScanController] Scan started for $family');

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(scanTimeout, () {
      if (_disposed) return;
      final currentState = _ref.read(hardwareSessionStateProvider);
      if (currentState == HardwareSessionState.scanning) {
        debugPrint(
          '[HardwareWalletScanController] Scan timed out after '
          '${scanTimeout.inSeconds}s',
        );
        _ref.read(hardwareSessionStateProvider.notifier).state =
            HardwareSessionState.timeout;
      }
    });

    try {
      final devices = await adapter.scanForDevices();
      if (_disposed) return;

      _timeoutTimer?.cancel();
      _ref.read(hardwareDevicesProvider.notifier).state = devices;

      if (devices.isNotEmpty) {
        debugPrint(
          '[HardwareWalletScanController] Found ${devices.length} device(s)',
        );
        if (useMock) {
          await connectToDevice(devices.first);
          return;
        }
        _ref.read(hardwareSessionStateProvider.notifier).state =
            HardwareSessionState.deviceFound;
      } else {
        final currentState = _ref.read(hardwareSessionStateProvider);
        if (currentState == HardwareSessionState.scanning) {
          _ref.read(hardwareSessionStateProvider.notifier).state =
              HardwareSessionState.timeout;
        }
      }
    } catch (e) {
      if (_disposed) return;
      _timeoutTimer?.cancel();
      debugPrint('[HardwareWalletScanController] Scan error: $e');
      _ref.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.error;
    }
  }

  void stopScan() {
    _timeoutTimer?.cancel();
    if (!_disposed) {
      final currentState = _ref.read(hardwareSessionStateProvider);
      if (currentState == HardwareSessionState.scanning) {
        _ref.read(hardwareSessionStateProvider.notifier).state =
            HardwareSessionState.idle;
      }
    }
    debugPrint('[HardwareWalletScanController] Scan stopped');
  }

  Future<void> connectToDevice(HardwareWalletDevice device) async {
    if (_disposed) return;

    final useMock = _ref
        .read(prefsChangeNotifierProvider)
        .enableMockHardwareAutoSigner;

    final family =
        _ref.read(selectedHardwareFamilyProvider) ?? device.family;

    final HardwareWalletAdapter adapter;
    if (useMock) {
      adapter = MockHardwareWalletAdapter(family: family);
    } else {
      final realAdapter = _adapterForFamily(family);
      if (realAdapter == null) {
        _ref.read(hardwareSessionStateProvider.notifier).state =
            HardwareSessionState.error;
        return;
      }
      adapter = realAdapter;
    }

    _ref.read(hardwareSessionStateProvider.notifier).state =
        HardwareSessionState.connecting;
    _ref.read(selectedHardwareDeviceProvider.notifier).state = device;

    debugPrint(
      '[HardwareWalletScanController] Connecting to ${device.name}',
    );

    try {
      await adapter.connectDevice(device);
      if (_disposed) return;
      _ref.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.connected;
      debugPrint(
        '[HardwareWalletScanController] Connected to ${device.name}',
      );
    } catch (e) {
      if (_disposed) return;
      debugPrint(
        '[HardwareWalletScanController] Connection error: $e',
      );
      _ref.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.error;
    }
  }

  Future<void> disconnect() async {
    if (_disposed) return;

    final device = _ref.read(selectedHardwareDeviceProvider);
    if (device == null) return;

    final family =
        _ref.read(selectedHardwareFamilyProvider) ?? device.family;
    final adapter = _adapterForFamily(family);
    if (adapter == null) return;

    debugPrint(
      '[HardwareWalletScanController] Disconnecting from ${device.name}',
    );

    try {
      await adapter.disconnect();
    } catch (e) {
      debugPrint(
        '[HardwareWalletScanController] Disconnect error: $e',
      );
    }

    if (!_disposed) {
      _ref.read(hardwareSessionStateProvider.notifier).state =
          HardwareSessionState.disconnected;
      _ref.read(selectedHardwareDeviceProvider.notifier).state = null;
    }
  }

  Future<void> refresh() async {
    final family = _ref.read(selectedHardwareFamilyProvider);
    if (family == null) return;

    _ref.read(hardwareSessionStateProvider.notifier).state =
        HardwareSessionState.idle;
    _ref.read(hardwareDevicesProvider.notifier).state = [];
    _ref.read(selectedHardwareDeviceProvider.notifier).state = null;

    await startScan(family);
  }

  void dispose() {
    _disposed = true;
    _timeoutTimer?.cancel();
    debugPrint('[HardwareWalletScanController] Disposed');
  }
}
