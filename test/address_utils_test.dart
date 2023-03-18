import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/address_utils.dart';

void main() {
  test("parse an invalid uri string", () {
    const uri = ":::  8 \\ %23";
    expect(AddressUtils.parseUri(uri), {});
  });

  test("encode a list of (mnemonic) words/strings as a json object", () {
    final List<String> list = [
      "hello",
      "word",
      "something",
      "who",
      "green",
      "seven"
    ];
    final result = AddressUtils.encodeQRSeedData(list);
    expect(result,
        '{"mnemonic":["hello","word","something","who","green","seven"]}');
  });

  test("decode a valid json string to Map<String, dynamic>", () {
    const jsonString =
        '{"mnemonic":["hello","word","something","who","green","seven"]}';
    final result = AddressUtils.decodeQRSeedData(jsonString);
    expect(result, {
      "mnemonic": ["hello", "word", "something", "who", "green", "seven"]
    });
  });

  test("decode an invalid json string to Map<String, dynamic>", () {
    const jsonString =
        '{"mnemonic":"hello","word","something","who","green","seven"]}';

    expect(AddressUtils.decodeQRSeedData(jsonString), {});
  });
}
