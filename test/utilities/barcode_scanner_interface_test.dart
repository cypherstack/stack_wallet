import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/widgets/desktop/qr_code_scanner_dialog.dart';
import 'package:stackwallet/widgets/qr_scanner.dart';

void main() {
  testWidgets(
    "Android and iOS open the Scan QR code page",
    (tester) async {
      expect(const BarcodeScannerWrapper().scanner, isA<QrScanner>());
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets("Linux, macOS and Windows open the Scan QR code dialog", (
    tester,
  ) async {
    expect(const BarcodeScannerWrapper().scanner, isA<QrCodeScannerDialog>());
  }, variant: TargetPlatformVariant.desktop());
}
