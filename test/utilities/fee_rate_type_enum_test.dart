import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';

void main() {
  group("FeeRateTypeExt.customSatsPerVByte", () {
    test("returns the selected rate for a custom fee", () {
      expect(FeeRateType.custom.customSatsPerVByte(7), 7);
    });

    test("returns null for preset fees", () {
      for (final feeRateType in [
        FeeRateType.fast,
        FeeRateType.average,
        FeeRateType.slow,
      ]) {
        expect(feeRateType.customSatsPerVByte(7), isNull);
      }
    });
  });
}
