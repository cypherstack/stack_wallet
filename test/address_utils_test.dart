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

  test("parse uri with malformed amount rejects the whole uri", () {
    // Payment URI amounts are machine-format plain decimals (BIP21 style):
    // no signs, no exponents, no grouping or locale separators, no units.
    const malformed = [
      "-5",
      "%2B5", // literal "+5"; a raw "+" is query-encoding for a space
      "1e3",
      "1E3",
      "1e-3",
      "1.2.3",
      "5%20BTC",
      "1,220.0", // grouped
      "1,5", // comma decimal
      "1.220,00", // European format
      "1%20220.0", // space grouped
      "5.", // trailing separator
      "5,",
      ".",
      "", // explicitly present but empty
      "0x10",
      "NaN",
      "Infinity",
      "abc",
    ];
    for (final amount in malformed) {
      expect(
        AddressUtils.parsePaymentUri("bitcoin:$firoAddress?amount=$amount"),
        isNull,
        reason: "amount=$amount",
      );
    }
  });

  test("parse uri with valid amount preserves it verbatim", () {
    const valid = [
      "5",
      "007",
      "1220.0",
      "1.220",
      "0.5",
      ".5",
      "0.00000001",
      "123456789.123456789",
    ];
    for (final amount in valid) {
      final result = AddressUtils.parsePaymentUri(
        "bitcoin:$firoAddress?amount=$amount",
      );
      expect(result?.amount, amount, reason: "amount=$amount");
    }

    // Surrounding whitespace is trimmed, not rejected.
    final padded = AddressUtils.parsePaymentUri(
      "bitcoin:$firoAddress?amount=%201.5%20",
    );
    expect(padded?.amount, "1.5");

    // A raw "+" in a query decodes to a space, so "+5" arrives as " 5" and
    // trims to a valid "5". A literal plus sign (%2B5) is rejected above.
    final plusAsSpace = AddressUtils.parsePaymentUri(
      "bitcoin:$firoAddress?amount=+5",
    );
    expect(plusAsSpace?.amount, "5");
  });

  test("parse query parameters exactly once", () {
    const uri = "bitcoin:$firoAddress?label=Save%25&amount=1.5";
    final result = AddressUtils.parsePaymentUri(uri);
    expect(result!.label, "Save%");
    expect(result.amount, "1.5");
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

  test("distinguish CashAddr payment URIs from prefixed addresses", () {
    const address = "qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a";

    for (final scheme in ["bitcoincash", "bchtest", "ecash", "ectest"]) {
      expect(AddressUtils.parsePaymentUri("$scheme:$address"), isNull);

      final result = AddressUtils.parsePaymentUri(
        "$scheme:$address?amount=1.25",
      );
      expect(result?.scheme, scheme);
      expect(result?.address, "$scheme:$address");
      expect(result?.amount, "1.25");
    }

    final uppercase = AddressUtils.parsePaymentUri(
      "BITCOINCASH:${address.toUpperCase()}?amount=1.25",
    );
    expect(uppercase?.address, "bitcoincash:$address");

    expect(AddressUtils.parsePaymentUri("xel:$address?amount=1.25"), isNull);

    final xelis = AddressUtils.parsePaymentUri(
      "xelis:xel:$address?amount=1.25",
    );
    expect((xelis?.address, xelis?.amount), ("xel:$address", "1.25"));
  });

  test("parse payment URI memo and destination-tag aliases", () {
    const aliases = {
      "tx_payment_id": "payment-id",
      "memo": "memo-value",
      "dt": "12345",
      "destination_tag": "destination-tag",
    };

    for (final entry in aliases.entries) {
      final result = AddressUtils.parsePaymentUri(
        "ripple:$firoAddress?${entry.key}=${entry.value}",
      );
      expect(result?.memo, entry.value, reason: entry.key);
    }

    final fallback = AddressUtils.parsePaymentUri(
      "ripple:$firoAddress?memo=&dt=54321",
    );
    expect(fallback?.memo, "54321");

    // Memo and amount combine.
    final combined = AddressUtils.parsePaymentUri(
      "ripple:$firoAddress?amount=1.5&dt=12345",
    );
    expect((combined?.amount, combined?.memo), ("1.5", "12345"));

    // A malformed amount rejects the whole URI; the memo does not survive.
    expect(
      AddressUtils.parsePaymentUri("ripple:$firoAddress?amount=1,5&dt=12345"),
      isNull,
    );
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

  test("build a standard payment URI", () {
    expect(
      AddressUtils.buildPaymentUriString(
        scheme: "firo",
        address: firoAddress,
        amount: "10.0123",
        message: "Some kind of message!",
      ),
      "firo:$firoAddress?amount=10.0123&message=Some+kind+of+message%21",
    );
  });

  test("build Monero-family payment URIs with standard query parameters", () {
    for (final scheme in ["monero", "wownero"]) {
      final uri = AddressUtils.buildPaymentUriString(
        scheme: scheme,
        address: firoAddress,
        amount: "1.25",
        message: "Some kind of message!",
      );

      expect(
        uri,
        "$scheme:$firoAddress?tx_amount=1.25&"
        "tx_description=Some+kind+of+message%21",
      );
      expect(uri, isNot(contains("#")));

      final parsed = AddressUtils.parsePaymentUri(uri);
      expect(parsed?.amount, "1.25");
      expect(parsed?.message, "Some kind of message!");
    }
  });

  group("Monero multi-recipient payment URIs", () {
    const addressA = "4AdUndXHHZ6cfufTMvppY6JwXNouMBzSkbLYfpAV5Usx";
    const addressB = "8BnERTpvL5MbCLtj5n9No7J5oE5hHiB3tVCK5cjSvCsx";

    test("parses addresses, amounts, and names per recipient", () {
      final result = AddressUtils.parsePaymentUri(
        "monero:$addressA;$addressB?tx_amount=1.5;0.25"
        "&recipient_name=Alice;Bob&tx_description=Dinner",
        allowMultipleRecipients: true,
      );

      expect(result, isNotNull);
      expect(result!.isMultiRecipient, isTrue);
      expect(result.recipients.map((e) => e.address), [addressA, addressB]);
      expect(result.recipients.map((e) => e.amount), ["1.5", "0.25"]);
      expect(result.recipients.map((e) => e.label), ["Alice", "Bob"]);
      expect(result.message, "Dinner");
      expect(result.address, addressA);
      expect(result.amount, "1.5");
    });

    test("names are optional", () {
      final result = AddressUtils.parsePaymentUri(
        "monero:$addressA;$addressB?tx_amount=1;2",
        allowMultipleRecipients: true,
      );

      expect(result!.recipients.map((e) => e.label), [null, null]);
    });

    test("parses percent-encoded lists", () {
      final result = AddressUtils.parsePaymentUri(
        "monero:$addressA;$addressB?recipient_name=Page%3BTips"
        "&tx_amount=0.09%3B0.01&tx_description=Great%20stream",
        allowMultipleRecipients: true,
      );

      expect(result!.recipients.map((e) => e.address), [addressA, addressB]);
      expect(result.recipients.map((e) => e.amount), ["0.09", "0.01"]);
      expect(result.recipients.map((e) => e.label), ["Page", "Tips"]);
      expect(result.message, "Great stream");
    });

    test("parses more than two recipients", () {
      const addressC = "4C7oeS1rq4w7TxjdBdz2Z6rxDBsJtUpDjN9X8fKCnQsx";
      final result = AddressUtils.parsePaymentUri(
        "monero:$addressA;$addressB;$addressC?tx_amount=1;.5;0.000000000001"
        "&recipient_name=Alice;;Carol",
        allowMultipleRecipients: true,
      );

      expect(result!.recipients.map((e) => e.address), [
        addressA,
        addressB,
        addressC,
      ]);
      expect(result.recipients.map((e) => e.amount), [
        "1",
        ".5",
        "0.000000000001",
      ]);
      expect(result.recipients.map((e) => e.label), ["Alice", null, "Carol"]);
    });

    test("is rejected unless multiple recipients are allowed", () {
      expect(
        AddressUtils.parsePaymentUri(
          "monero:$addressA;$addressB?tx_amount=1;2",
        ),
        isNull,
      );
    });

    test("rejects malformed recipient lists", () {
      for (final uri in [
        "monero:$addressA;$addressB",
        "monero:$addressA;$addressB?tx_amount=1",
        "monero:$addressA;$addressB?tx_amount=1;2;3",
        "monero:$addressA;$addressB?tx_amount=1;abc",
        "monero:$addressA;$addressB?tx_amount=1;",
        "monero:$addressA;$addressB?tx_amount=1;2&recipient_name=Alice",
        "monero:$addressA;?tx_amount=1;2",
        "monero:$addressA?tx_amount=1;2",
      ]) {
        expect(
          AddressUtils.parsePaymentUri(uri, allowMultipleRecipients: true),
          isNull,
          reason: uri,
        );
      }
    });

    test("single recipient URIs are unchanged", () {
      final result = AddressUtils.parsePaymentUri(
        "monero:$addressA?tx_amount=1.5&recipient_name=Alice;Co",
        allowMultipleRecipients: true,
      );

      expect(result!.isMultiRecipient, isFalse);
      expect(result.address, addressA);
      expect(result.amount, "1.5");
      expect(result.label, "Alice;Co");
    });

    test("other schemes do not split recipients", () {
      expect(
        AddressUtils.parsePaymentUri(
          "wownero:$addressA;$addressB?tx_amount=1;2",
          allowMultipleRecipients: true,
        ),
        isNull,
      );
    });
  });
}
