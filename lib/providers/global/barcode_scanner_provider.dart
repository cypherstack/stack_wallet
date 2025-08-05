import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utilities/barcode_scanner_interface.dart';

final pBarcodeScanner = Provider<BarcodeScannerInterface>(
  (ref) => const BarcodeScannerWrapper(),
);
