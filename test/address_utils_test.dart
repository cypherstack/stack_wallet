import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  const String firoAddress = "a6ESWKz7szru5syLtYAPRhHLdKvMq3Yt1j";

  test("condense address", () {
    final condensedAddress = AddressUtils.condenseAddress(firoAddress);
    expect(condensedAddress, "a6ESW...3Yt1j");
  });

  test("parse a valid uri string A", () {
    const uri = "dogecoin:$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parsePaymentUri(uri);
    expect(result, isNotNull);
    expect(result!.scheme, "dogecoin");
    expect(result.address, firoAddress);
    expect(result.amount, "50");
    expect(result.label, "eggs");
  });

  test("parse a valid uri string B", () {
    const uri = "firo:$firoAddress?amount=50&message=eggs+are+good";
    final result = AddressUtils.parsePaymentUri(uri);
    expect(result, isNotNull);
    expect(result!.scheme, "firo");
    expect(result.address, firoAddress);
    expect(result.amount, "50");
    expect(result.message, "eggs are good");
  });

  test("parse a valid uri string C", () {
    const uri = "bitcoin:$firoAddress?amount=50.1&message=eggs%20are%20good%21";
    final result = AddressUtils.parsePaymentUri(uri);
    expect(result, isNotNull);
    expect(result!.scheme, "bitcoin");
    expect(result.address, firoAddress);
    expect(result.amount, "50.1");
    expect(result.message, "eggs are good!");
  });

  test("parse an invalid uri string", () {
    const uri = "firo$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parsePaymentUri(uri);
    expect(result, isNull);
  });

  test("parse an invalid string", () {
    const uri = "$firoAddress?amount=50&label=eggs";
    final result = AddressUtils.parsePaymentUri(uri);
    expect(result, isNull);
  });

  test("parse an invalid uri string", () {
    const uri = ":::  8 \\ %23";
    expect(AddressUtils.parsePaymentUri(uri), isNull);
  });

  test("parse double prefix type address", () {
    const uri =
        "bitcoin:xel:$firoAddress?amount=50.1&message=eggs%20are%20good%21";
    final result = AddressUtils.parsePaymentUri(uri);
    expect(result, isNotNull);
    expect(result!.scheme, "bitcoin");
    expect(result.address, "xel:$firoAddress");
    expect(result.amount, "50.1");
    expect(result.message, "eggs are good!");
  });

  test("encode a list of (mnemonic) words/strings as a json object", () {
    final List<String> list = [
      "hello",
      "word",
      "something",
      "who",
      "green",
      "seven",
    ];
    final result = AddressUtils.encodeQRSeedData(list);
    expect(
      result,
      '{"mnemonic":["hello","word","something","who","green","seven"]}',
    );
  });

  test("decode a valid json string to Map<String, dynamic>", () {
    const jsonString =
        '{"mnemonic":["hello","word","something","who","green","seven"]}';
    final result = AddressUtils.decodeQRSeedData(jsonString);
    expect(result, {
      "mnemonic": ["hello", "word", "something", "who", "green", "seven"],
    });
  });

  test("decode an invalid json string to Map<String, dynamic>", () {
    const jsonString =
        '{"mnemonic":"hello","word","something","who","green","seven"]}';

    expect(AddressUtils.decodeQRSeedData(jsonString), {});
  });

  test("build a uri string with empty params", () {
    expect(
      AddressUtils.buildUriString(
        Firo(CryptoCurrencyNetwork.main).uriScheme,
        firoAddress,
        {},
      ),
      "firo:$firoAddress",
    );
  });

  test("build a uri string with one param", () {
    expect(
      AddressUtils.buildUriString(
        Firo(CryptoCurrencyNetwork.main).uriScheme,
        firoAddress,
        {"amount": "10.0123"},
      ),
      "firo:$firoAddress?amount=10.0123",
    );
  });

  test("build a uri string with some params", () {
    expect(
      AddressUtils.buildUriString(
        Firo(CryptoCurrencyNetwork.main).uriScheme,
        firoAddress,
        {"amount": "10.0123", "message": "Some kind of message!"},
      ),
      "firo:$firoAddress?amount=10.0123&message=Some+kind+of+message%21",
    );
  });

  // Monero URI Tests.
  group('Monero URI Tests', () {
    const String moneroAddress = "46BeWrHpwXmHDpDEUmZBWZfoQpdc6HaERCNmx1pEYL2rAcuwufPN9rXHHtyUA4QVy66qeFQkn6sfK8aHYjA3jk3o1Bv16em";
    const String moneroAddress2 = "888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H";

    test("parse single recipient Monero URI with amount and description", () {
      const uri = "monero:${moneroAddress}?tx_amount=239.39014&tx_description=donation";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      expect(result!.scheme, "monero");
      expect(result.addresses, [moneroAddress]);
      expect(result.amounts, ["239.39014"]);
      expect(result.message, "donation");
      // Test backward compatibility.
      expect(result.address, moneroAddress);
      expect(result.amount, "239.39014");
    });

    test("parse single recipient Monero URI with fragment description", () {
      const uri = "monero:${moneroAddress}?tx_amount=239.39014#donation";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      expect(result!.scheme, "monero");
      expect(result.addresses, [moneroAddress]);
      expect(result.amounts, ["239.39014"]);
      expect(result.message, "donation");
    });

    test("parse multi-recipient Monero URI with matching amounts", () {
      const uri = "monero:${moneroAddress};${moneroAddress2}?tx_amount=239.39014;132.44&tx_description=donations";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      expect(result!.scheme, "monero");
      expect(result.addresses, [moneroAddress, moneroAddress2]);
      expect(result.amounts, ["239.39014", "132.44"]);
      expect(result.message, "donations");
      // Test backward compatibility - should return first values.
      expect(result.address, moneroAddress);
      expect(result.amount, "239.39014");
    });

    test("parse multi-recipient Monero URI with recipient names", () {
      const uri = "monero:${moneroAddress};${moneroAddress2}?tx_amount=239.39014;132.44&recipient_name=Alice;Bob";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      expect(result!.scheme, "monero");
      expect(result.addresses, [moneroAddress, moneroAddress2]);
      expect(result.amounts, ["239.39014", "132.44"]);
      expect(result.labels, ["Alice", "Bob"]);
      expect(result.label, "Alice");  // Backward compatibility.
    });

    test("reject multi-recipient Monero URI with mismatched amounts", () {
      const uri = "monero:${moneroAddress};${moneroAddress2}?tx_amount=239.39014";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNull);  // Should be null due to validation failure.
    });

    test("parse multi-recipient Monero URI without amounts", () {
      const uri = "monero:${moneroAddress};${moneroAddress2}?tx_description=donations";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      expect(result!.scheme, "monero");
      expect(result.addresses, [moneroAddress, moneroAddress2]);
      expect(result.amounts, isNull);
      expect(result.message, "donations");
    });

    test("reject URI with deprecated tx_payment_id", () {
      const uri = "monero:${moneroAddress}?tx_amount=239.39014&tx_payment_id=1234567890abcdef";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      // tx_payment_id should no longer be recognized or stored.
      expect(result!.additionalParams.containsKey('tx_payment_id'), false);
    });

    test("build single recipient Monero URI", () {
      final uri = AddressUtils.buildUriString(
        "monero",
        moneroAddress,
        {"tx_amount": "239.39014", "tx_description": "donation"},
      );
      expect(uri, "monero:${moneroAddress}?tx_amount=239.39014#donation");
    });

    test("build multi-recipient Monero URI", () {
      final uri = AddressUtils.buildMoneroMultiUriString(
        [moneroAddress, moneroAddress2],
        ["239.39014", "132.44"],
        ["Alice", "Bob"],
        "donations",
      );
      expect(uri, "monero:${moneroAddress};${moneroAddress2}?tx_amount=239.39014%3B132.44&recipient_name=Alice%3BBob#donations");
    });

    test("build multi-recipient Monero URI without amounts", () {
      final uri = AddressUtils.buildMoneroMultiUriString(
        [moneroAddress, moneroAddress2],
        null,
        null,
        "donations",
      );
      expect(uri, "monero:${moneroAddress};${moneroAddress2}#donations");
    });

    test("reject multi-recipient URI builder with mismatched amounts", () {
      expect(
        () => AddressUtils.buildMoneroMultiUriString(
          [moneroAddress, moneroAddress2],
          ["239.39014"],  // Only one amount for two addresses.
          null,
          null,
        ),
        throwsArgumentError,
      );
    });

    test("reject multi-recipient URI builder with empty addresses", () {
      expect(
        () => AddressUtils.buildMoneroMultiUriString(
          [],  // Empty addresses.
          null,
          null,
          null,
        ),
        throwsArgumentError,
      );
    });

    test("parse Monero URI with special characters in description", () {
      const uri = "monero:${moneroAddress}?tx_amount=239.39014#Donation%20for%20charity%21";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      expect(result!.message, "Donation for charity!");
    });

    test("parse Monero URI with URL encoded parameters", () {
      const uri = "monero:${moneroAddress}?tx_amount=239.39014&recipient_name=Alice%20Smith";
      final result = AddressUtils.parsePaymentUri(uri);
      expect(result, isNotNull);
      expect(result!.labels, ["Alice Smith"]);
      expect(result.label, "Alice Smith");
    });
  });
}
