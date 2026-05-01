import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;

import '../hardware_wallet_connection_type.dart';
import '../hardware_wallet_device.dart';
import '../hardware_wallet_device_family.dart';

class LedgerHardwareWalletDevice extends HardwareWalletDevice {
  final ledger.LedgerDevice rawDevice;

  LedgerHardwareWalletDevice({
    required this.rawDevice,
    required super.connectionType,
  }) : super(
          name: rawDevice.name,
          family: HardwareWalletDeviceFamily.ledger,
          model: rawDevice.name,
        );

  factory LedgerHardwareWalletDevice.fromUsbDevice(
    ledger.LedgerDevice device,
  ) {
    return LedgerHardwareWalletDevice(
      rawDevice: device,
      connectionType: HardwareWalletConnectionType.usb,
    );
  }
}
