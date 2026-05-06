import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallets/hardware/hardware_session_state.dart';
import '../../wallets/hardware/hardware_wallet_adapter.dart';
import '../../wallets/hardware/hardware_wallet_device.dart';
import '../../wallets/hardware/hardware_wallet_device_family.dart';
import '../../wallets/hardware/ledger/ledger_usb_adapter.dart';
import '../../wallets/hardware/trezor/trezor_adapter_stub.dart';

final hardwareSessionStateProvider =
    StateProvider<HardwareSessionState>((ref) => HardwareSessionState.idle);

final hardwareDevicesProvider =
    StateProvider<List<HardwareWalletDevice>>((ref) => []);

final selectedHardwareFamilyProvider =
    StateProvider<HardwareWalletDeviceFamily?>((ref) => null);

final selectedHardwareDeviceProvider =
    StateProvider<HardwareWalletDevice?>((ref) => null);

final hardwareSigningStateProvider =
    StateProvider<HardwareSessionState>((ref) => HardwareSessionState.idle);

final hardwareSigningResultProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

final _adapters = <HardwareWalletDeviceFamily, HardwareWalletAdapter>{};

final hardwareAdapterProvider =
    Provider.family<HardwareWalletAdapter?, HardwareWalletDeviceFamily>(
        (ref, family) {
  switch (family) {
    case HardwareWalletDeviceFamily.ledger:
      return _adapters.putIfAbsent(family, LedgerUsbAdapter.new);
    case HardwareWalletDeviceFamily.trezor:
      return _adapters.putIfAbsent(family, TrezorAdapterStub.new);
    case HardwareWalletDeviceFamily.foundation:
      return null;
  }
});
