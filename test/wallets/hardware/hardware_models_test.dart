import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/hardware/hardware.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

void main() {
  group("HardwareWalletDeviceFamily", () {
    test("has expected values", () {
      expect(HardwareWalletDeviceFamily.values.length, 3);
      expect(HardwareWalletDeviceFamily.ledger.name, "ledger");
      expect(HardwareWalletDeviceFamily.trezor.name, "trezor");
      expect(HardwareWalletDeviceFamily.foundation.name, "foundation");
    });
  });

  group("HardwareWalletConnectionType", () {
    test("has expected values", () {
      expect(HardwareWalletConnectionType.values.length, 2);
      expect(HardwareWalletConnectionType.usb.name, "usb");
      expect(HardwareWalletConnectionType.ble.name, "ble");
    });
  });

  group("HardwareSessionState", () {
    test("has expected values", () {
      expect(HardwareSessionState.values.length, 9);
      expect(HardwareSessionState.idle.name, "idle");
      expect(HardwareSessionState.scanning.name, "scanning");
      expect(HardwareSessionState.deviceFound.name, "deviceFound");
      expect(HardwareSessionState.connecting.name, "connecting");
      expect(HardwareSessionState.connected.name, "connected");
      expect(HardwareSessionState.approvalPending.name, "approvalPending");
      expect(HardwareSessionState.disconnected.name, "disconnected");
      expect(HardwareSessionState.error.name, "error");
      expect(HardwareSessionState.timeout.name, "timeout");
    });
  });

  group("HardwareAccountData", () {
    test("construction with required fields", () {
      final data = HardwareAccountData(
        address: "bc1qtest",
        accountIndex: 0,
        derivationPath: "m/84'/0'/0'",
        masterFingerprint: "aabbccdd",
        xpub: "xpub6ABC123",
      );

      expect(data.address, "bc1qtest");
      expect(data.accountIndex, 0);
      expect(data.derivationPath, "m/84'/0'/0'");
      expect(data.masterFingerprint, "aabbccdd");
      expect(data.xpub, "xpub6ABC123");
    });
  });

  group("WalletInfoKeys hardware constants", () {
    test("hardware keys exist and have expected values", () {
      expect(WalletInfoKeys.isHardwareWalletKey, "isHardwareWalletKey");
      expect(
        WalletInfoKeys.hardwareDeviceFamilyKey,
        "hardwareDeviceFamilyKey",
      );
      expect(WalletInfoKeys.hardwareDeviceModelKey, "hardwareDeviceModelKey");
      expect(
        WalletInfoKeys.hardwareDerivationPathKey,
        "hardwareDerivationPathKey",
      );
      expect(WalletInfoKeys.hardwareXpubKey, "hardwareXpubKey");
      expect(
        WalletInfoKeys.hardwareMasterFingerprintKey,
        "hardwareMasterFingerprintKey",
      );
    });
  });
}
