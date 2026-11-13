import 'hardware_account_data.dart';
import 'hardware_wallet_device.dart';
import 'hardware_wallet_service.dart';

/// Monero external signing stub.
///
/// Monero external signing requires a UR (Uniform Resources) QR-based
/// air-gapped protocol that is fundamentally different from the single-step
/// USB/BLE hardware wallet model used by Bitcoin-family coins.
///
/// The cs_monero v3.2.0 FFI bindings already expose the low-level primitives:
///   - `MONERO_Wallet_exportOutputsUR`
///   - `MONERO_PendingTransaction_commitUR`
///   - `MONERO_Wallet_submitTransactionUR`
///   - `MONERO_Wallet_importKeyImagesUR`
///
/// 5-phase expansion path to full UR QR air-gapped Monero signing:
///   1. cs_monero UR Dart wrappers -- thin async Dart APIs over the FFI
///      bindings listed above.
///   2. CsMoneroInterface UR extensions -- integrate the Dart wrappers into
///      the existing CsMoneroInterface so wallet logic can call them.
///   3. Air-gapped signer abstraction with `HardwareWalletDeviceFamily.cupcake`
/// -- model the cold-device round-trip (export outputs -> sign on cold
///      device -> import signed tx) as a `HardwareWalletService` flow.
///   4. Animated QR UI -- camera-based UR QR scanner and animated QR
///      display for large payloads (fountain codes).
///   5. Integration with view-only wallet creation and send flow -- wire the
///      signer into the existing wallet creation and transaction send pages.
///
/// Cake Wallet's Monero UR signing implementation serves as proven prior art
/// for this expansion path.
class MoneroExternalSignerService implements HardwareWalletService {
  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({
    required HardwareWalletDevice device,
    required String derivationPath,
  }) {
    throw UnsupportedError(
      'Monero external signing via UR QR exchange is not yet implemented. '
      'The cs_monero FFI bindings for exportOutputsUR, importKeyImagesUR, '
      'commitUR, and submitTransactionUR exist but need higher-level Dart '
      'wrappers.',
    );
  }

  @override
  Future<Map<String, dynamic>> signTransaction({
    required HardwareWalletDevice device,
    required Map<String, dynamic> payload,
  }) {
    throw UnsupportedError(
      'Monero signing requires a multi-step air-gapped UR protocol '
      '(export outputs -> sign on cold device -> import signed tx), '
      'which differs from the single-step USB/BLE model. See class '
      'documentation for the expansion path.',
    );
  }
}
