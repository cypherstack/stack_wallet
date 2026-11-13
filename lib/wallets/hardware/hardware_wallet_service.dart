import 'hardware_account_data.dart';
import 'hardware_wallet_device.dart';

abstract class HardwareWalletService {
  Future<List<HardwareAccountData>> getAvailableAccounts({
    required HardwareWalletDevice device,
    required String derivationPath,
  });

  Future<Map<String, dynamic>> signTransaction({
    required HardwareWalletDevice device,
    required Map<String, dynamic> payload,
  });
}
