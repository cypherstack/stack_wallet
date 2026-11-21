import '../hardware_wallet_adapter.dart';
import '../hardware_wallet_device.dart';

class TrezorAdapterStub implements HardwareWalletAdapter {
  @override
  bool get isConnected =>
      throw UnimplementedError('Trezor support is planned for S04');

  @override
  Future<List<HardwareWalletDevice>> scanForDevices() =>
      throw UnimplementedError('Trezor support is planned for S04');

  @override
  Future<void> connectDevice(HardwareWalletDevice device) =>
      throw UnimplementedError('Trezor support is planned for S04');

  @override
  Future<void> disconnect() =>
      throw UnimplementedError('Trezor support is planned for S04');
}
