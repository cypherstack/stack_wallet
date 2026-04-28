import 'package:convert/convert.dart';
import 'package:fusiondart/src/extensions/on_string.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:fusiondart/src/util.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

// https://github.com/Electron-Cash/Electron-Cash/blob/master/electroncash/tests/test_schnorr.py

void main() {
  test("schnorr sign", () {
    final privateKey =
        "12b004fff7f4b69ef8650e767f18f11ede158148b425660723b9f9a66e61f747"
            .toUint8ListFromHex;
    final publicKey =
        "030b4c866585dd868a9d62348a9cd008d6a312937048fff31670e7e920cfc7a744"
            .toUint8ListFromHex;
    final refSig = "2c56731ac2f7a7e7f11518fc7722a166b02438924ca9d8"
        "b4d111347b81d0717571846de67ad3d913a8fdf9d8f3f7"
        "3161a4c48ae81cb183b214765feb86e255ce";

    final msg = "Very deterministic message".toUint8ListFromUtf8;

    final msgHash = Utilities.sha256(Utilities.sha256(msg));

    expect(
      msgHash.toHex,
      "5255683da567900bfd3e786ed8836a4e7763c221bf1ac20ece2a5171b9199e8a",
    );

    // final sig = Utilities.schnorrSign(privateKey.toHex, msgHash.toHex, "");
    final sig = Utilities.schnorrSign(privateKey, msgHash);

    expect(
      hex.encode(sig),
      "2c56731ac2f7a7e7f11518fc7722a166b02438924ca9d8"
      "b4d111347b81d0717571846de67ad3d913a8fdf9d8f3f7"
      "3161a4c48ae81cb183b214765feb86e255ce",
    );
  });

  test("schnorr verify", () {
    final publicKey =
        "030b4c866585dd868a9d62348a9cd008d6a312937048fff31670e7e920cfc7a744"
            .toUint8ListFromHex;
    final refSig = "2c56731ac2f7a7e7f11518fc7722a166b02438924ca9d8"
        "b4d111347b81d0717571846de67ad3d913a8fdf9d8f3f7"
        "3161a4c48ae81cb183b214765feb86e255ce";

    final msg = "Very deterministic message".toUint8ListFromUtf8;
    final msgHash = Utilities.sha256(Utilities.sha256(msg));

    expect(
      msgHash.toHex,
      "5255683da567900bfd3e786ed8836a4e7763c221bf1ac20ece2a5171b9199e8a",
    );

    expect(
      Utilities.schnorrVerify(
        publicKey,
        refSig.toUint8ListFromHex,
        msgHash,
      ),
      true,
    );
  });
}
