import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/coins/bitcoincash/bch_utils.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';

void main() {
  test("script pub key check for SLP is true", () {
    expect(
      BchUtils.isSLP(
          "6a04534c500001010747454e45534953044d5430320f4d757461626c652054657374"
                  "2030321668747470733a2f2f46756c6c537461636b2e63617368200e9a18"
                  "8911ec0f2ac10cc9425b457d10ba14151a64eb4640f95ed7dab9e8f62601"
                  "004c00080000000000000001"
              .toUint8ListFromHex),
      true,
    );
  });

  test("script pub key check for SLP is not true", () {
    expect(
      BchUtils.isSLP("76a914a78bb9aa1b54c859b5fe72e6f6f576248b3231c888ac"
          .toUint8ListFromHex),
      false,
    );
  });

  test("script pub key check for fuze is true", () {
    expect(
      BchUtils.isFUZE("6a0446555a00204d662fb69f34dc23434a61c7bbb65c9f99a247f9c8"
              "b377cb4de3cadf7542f8f0"
          .toUint8ListFromHex),
      true,
    );
  });

  test("script pub key check for fuze is not true", () {
    expect(
      BchUtils.isFUZE(
          "6a04534c500001010747454e45534953044d5430320f4d757461626c652054657374"
                  "2030321668747470733a2f2f46756c6c537461636b2e63617368200e9a18"
                  "8911ec0f2ac10cc9425b457d10ba14151a64eb4640f95ed7dab9e8f62601"
                  "004c00080000000000000001"
              .toUint8ListFromHex),
      false,
    );
  });
}
