import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hardware_account_data.dart';
import 'hardware_session_state.dart';
import 'hardware_wallet_adapter.dart';
import 'hardware_wallet_connection_type.dart';
import 'hardware_wallet_device.dart';
import 'hardware_wallet_device_family.dart';
import 'hardware_wallet_service.dart';

class MockHardwareWalletDevice extends HardwareWalletDevice {
  MockHardwareWalletDevice({
    HardwareWalletDeviceFamily family = HardwareWalletDeviceFamily.trezor,
  }) : super(
          name: 'Mock Device',
          family: family,
          connectionType: HardwareWalletConnectionType.usb,
          model: 'Mock',
        );
}

class MockHardwareWalletAdapter implements HardwareWalletAdapter {
  final HardwareWalletDeviceFamily family;

  MockHardwareWalletAdapter({required this.family});

  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<List<HardwareWalletDevice>> scanForDevices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [MockHardwareWalletDevice(family: family)];
  }

  @override
  Future<void> connectDevice(HardwareWalletDevice device) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }
}

class MockHardwareWalletService implements HardwareWalletService {
  final StateController<HardwareSessionState> _signingStateController;
  final bool autoApprove;

  Completer<Map<String, dynamic>>? _pendingApproval;

  MockHardwareWalletService({
    required StateController<HardwareSessionState> signingStateController,
    required this.autoApprove,
  }) : _signingStateController = signingStateController;

  @override
  Future<Map<String, dynamic>> signTransaction({
    required HardwareWalletDevice device,
    required Map<String, dynamic> payload,
  }) async {
    _signingStateController.state = HardwareSessionState.approvalPending;

    if (autoApprove) {
      await Future.delayed(const Duration(milliseconds: 1500));
      _signingStateController.state = HardwareSessionState.connected;
      return {'approved': true};
    }

    _pendingApproval = Completer<Map<String, dynamic>>();
    return _pendingApproval!.future;
  }

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({
    required HardwareWalletDevice device,
    required String derivationPath,
  }) async {
    return [
      HardwareAccountData(
        address: 'mock-address-000',
        accountIndex: 0,
        derivationPath: derivationPath,
        masterFingerprint: 'DEADBEEF',
        xpub:
            'xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJ'
            'PMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5',
      ),
    ];
  }

  void simulateApproval() {
    _signingStateController.state = HardwareSessionState.connected;
    _pendingApproval?.complete({'approved': true});
  }

  void simulateRejection() {
    _signingStateController.state = HardwareSessionState.error;
    _pendingApproval?.complete({'approved': false, 'error': 'rejected'});
  }

  void simulateDisconnect() {
    _signingStateController.state = HardwareSessionState.disconnected;
    _pendingApproval?.complete({'approved': false, 'error': 'disconnected'});
  }
}
