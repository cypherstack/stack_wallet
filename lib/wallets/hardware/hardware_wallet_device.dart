import 'hardware_wallet_connection_type.dart';
import 'hardware_wallet_device_family.dart';

abstract class HardwareWalletDevice {
  final String name;
  final HardwareWalletDeviceFamily family;
  final HardwareWalletConnectionType connectionType;
  final String model;

  HardwareWalletDevice({
    required this.name,
    required this.family,
    required this.connectionType,
    required this.model,
  });
}
