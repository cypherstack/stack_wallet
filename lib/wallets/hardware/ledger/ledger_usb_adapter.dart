import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;

import '../hardware_wallet_adapter.dart';
import '../hardware_wallet_device.dart';
import 'ledger_hardware_wallet_device.dart';

class LedgerUsbAdapter implements HardwareWalletAdapter {
  static const Duration defaultScanTimeout = Duration(seconds: 10);

  ledger.LedgerInterface? _ledger;
  ledger.LedgerConnection? _connection;
  LedgerHardwareWalletDevice? _connectedDevice;

  LedgerUsbAdapter();

  ledger.LedgerInterface _ensureLedger() {
    _ledger ??= ledger.LedgerInterface.usb();
    return _ledger!;
  }

  ledger.LedgerConnection? get ledgerConnection => _connection;

  @override
  bool get isConnected => _connectedDevice != null;

  @override
  Future<List<HardwareWalletDevice>> scanForDevices() async {
    debugPrint('[LedgerUsbAdapter] USB scan started');

    final instance = _ensureLedger();
    final devices = <LedgerHardwareWalletDevice>[];

    try {
      final completer = Completer<List<LedgerHardwareWalletDevice>>();
      final subscription = instance.scan().listen(
        (device) {
          debugPrint(
            '[LedgerUsbAdapter] Device found: ${device.name}',
          );
          devices.add(LedgerHardwareWalletDevice.fromUsbDevice(device));
        },
        onError: (Object error) {
          debugPrint('[LedgerUsbAdapter] Scan error: $error');
          if (!completer.isCompleted) {
            completer.complete(devices);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(devices);
          }
        },
      );

      final result = await completer.future.timeout(
        defaultScanTimeout,
        onTimeout: () {
          debugPrint('[LedgerUsbAdapter] Scan timed out');
          return devices;
        },
      );

      await subscription.cancel();
      debugPrint('[LedgerUsbAdapter] USB scan complete: '
          '${result.length} device(s) found');
      return result;
    } catch (e) {
      debugPrint('[LedgerUsbAdapter] Scan failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> connectDevice(HardwareWalletDevice device) async {
    if (device is! LedgerHardwareWalletDevice) {
      throw ArgumentError(
        'LedgerUsbAdapter can only connect to LedgerHardwareWalletDevice',
      );
    }

    debugPrint('[LedgerUsbAdapter] Connecting to: ${device.name}');

    try {
      final instance = _ensureLedger();
      _connection = await instance.connect(device.rawDevice);
      _connectedDevice = device;
      debugPrint('[LedgerUsbAdapter] Connected to: ${device.name}');
    } catch (e) {
      debugPrint('[LedgerUsbAdapter] Connection failed: $e');
      _connection = null;
      _connectedDevice = null;
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDevice == null) {
      debugPrint('[LedgerUsbAdapter] No device connected -- nothing to do');
      return;
    }

    debugPrint(
      '[LedgerUsbAdapter] Disconnecting from: ${_connectedDevice!.name}',
    );

    try {
      await _connection?.disconnect();
      debugPrint('[LedgerUsbAdapter] Disconnected');
    } catch (e) {
      debugPrint('[LedgerUsbAdapter] Disconnect error: $e');
    } finally {
      _connection = null;
      _connectedDevice = null;
    }
  }

  LedgerHardwareWalletDevice? get connectedDevice => _connectedDevice;
}
