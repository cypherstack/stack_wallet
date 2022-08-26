import 'package:barcode_scan2/barcode_scan2.dart';

abstract class BarcodeScannerInterface {
  Future<ScanResult> scan({ScanOptions options = const ScanOptions()});
}

class BarcodeScannerWrapper implements BarcodeScannerInterface {
  const BarcodeScannerWrapper();

  @override
  Future<ScanResult> scan({ScanOptions options = const ScanOptions()}) async {
    try {
      final result = await BarcodeScanner.scan(options: options);
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
