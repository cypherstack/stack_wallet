import 'hardware_wallet_device.dart';

abstract class HardwareWalletAdapter {
  bool get isConnected;

  Future<List<HardwareWalletDevice>> scanForDevices();

  Future<void> connectDevice(HardwareWalletDevice device);

  Future<void> disconnect();
}
