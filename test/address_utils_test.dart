import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

void main() {
  const String firoAddress = "a6ESWKz7szru5syLtYAPRhHLdKvMq3Yt1j";

  test("generate scripthash from a firo address", () {
    final hash = AddressUtils.convertToScriptHash(firoAddress, firoNetwork);
    expect(hash,
        "77090cea08e2b5accb185fac3cdc799b2b1d109e18c19c723011f4af2c0e5f76");
  });

  test("condense address", () {
    final condensedAddress = AddressUtils.condenseAddress(firoAddress);
    expect(condensedAddress, "a6ESW...3Yt1j");
  });

  test("parse a valid uri string A", () {
    const uri = "dogecoin:$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parseUri(uri);
    expect(result, {
      "scheme": "dogecoin",
      "address": firoAddress,
      "amount": "50",
      "label": "eggs",
    });
  });

  test("parse a valid uri string B", () {
    const uri = "firo:$firoAddress?amount=50&message=eggs+are+good";
    final result = AddressUtils.parseUri(uri);
    expect(result, {
      "scheme": "firo",
      "address": firoAddress,
      "amount": "50",
      "message": "eggs are good",
    });
  });

  test("parse a valid uri string C", () {
    const uri = "bitcoin:$firoAddress?amount=50.1&message=eggs%20are%20good%21";
    final result = AddressUtils.parseUri(uri);
    expect(result, {
      "scheme": "bitcoin",
      "address": firoAddress,
      "amount": "50.1",
      "message": "eggs are good!"
    });
  });

  test("parse an invalid uri string", () {
    const uri = "firo$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parseUri(uri);
    expect(result, {});
  });

  test("parse an invalid string", () {
    const uri = "$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parseUri(uri);
    expect(result, {});
  });

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

  test("build a uri string with empty params", () {
    expect(AddressUtils.buildUriString(Coin.firo, firoAddress, {}),
        "firo:$firoAddress");
  });

  test("build a uri string with one param", () {
    expect(
        AddressUtils.buildUriString(
            Coin.firo, firoAddress, {"amount": "10.0123"}),
        "firo:$firoAddress?amount=10.0123");
  });

  test("build a uri string with some params", () {
    expect(
        AddressUtils.buildUriString(Coin.firo, firoAddress,
            {"amount": "10.0123", "message": "Some kind of message!"}),
        "firo:$firoAddress?amount=10.0123&message=Some+kind+of+message%21");
  });
}
