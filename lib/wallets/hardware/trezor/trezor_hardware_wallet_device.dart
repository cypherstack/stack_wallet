import '../hardware_wallet_connection_type.dart';
import '../hardware_wallet_device.dart';
import '../hardware_wallet_device_family.dart';

class TrezorHardwareWalletDevice extends HardwareWalletDevice {
  TrezorHardwareWalletDevice({
    required super.name,
    required super.connectionType,
    required super.model,
  }) : super(family: HardwareWalletDeviceFamily.trezor);
}
