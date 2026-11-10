import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  const String firoAddress = "a6ESWKz7szru5syLtYAPRhHLdKvMq3Yt1j";
  const moneroAddress =
      "4AeRgkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FHXDA6i1DnQTd6h8R3VU5AkbGcWSNhtSwNNPgaD48gp4nn";
  const privateKey =
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";

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

  group("wallet URI", () {
    test("parses a private-key restore", () {
      final result = WalletUriData.fromUriString(
        "monero_wallet:$moneroAddress"
        "?view_key=$privateKey&spend_key=$privateKey&height=123",
      );

      expect(result.address, moneroAddress);
      expect(result.viewKey, privateKey);
      expect(result.spendKey, privateKey);
      expect(result.height, 123);
      expect(result.isViewOnly, isFalse);
    });

    test("accepts the legacy mnemonic_seed parameter", () {
      final result = WalletUriData.fromUriString(
        "MONERO-WALLET:?mnemonic_seed=alpha%20beta",
      );

      expect(result.seed, "alpha beta");
    });

    test("requires an address for key-based restores", () {
      expect(
        () => WalletUriData.fromUriString(
          "monero_wallet:?view_key=$privateKey&spend_key=$privateKey",
        ),
        throwsFormatException,
      );
    });

    test("rejects a payment URI", () {
      expect(
        () => WalletUriData.fromUriString(
          "monero:$moneroAddress?view_key=$privateKey",
        ),
        throwsFormatException,
      );
    });

    test("requires a view key with a spend key", () {
      expect(
        () => WalletUriData.fromUriString(
          "monero_wallet:$moneroAddress?spend_key=$privateKey",
        ),
        throwsFormatException,
      );
    });

    test("rejects seed and private keys together", () {
      expect(
        () => WalletUriData.fromUriString(
          "monero_wallet:$moneroAddress"
          "?seed=alpha%20beta&view_key=$privateKey",
        ),
        throwsFormatException,
      );
    });

    test("uses the supplied address validator", () {
      expect(
        () => WalletUriData.fromUriString(
          "monero_wallet:$moneroAddress?view_key=$privateKey",
          addressValidator: (_) => false,
        ),
        throwsFormatException,
      );
    });

    test("rejects empty recovery material", () {
      expect(
        () => WalletUriData.fromUriString("monero_wallet:?seed="),
        throwsFormatException,
      );
    });

    test("rejects malformed private keys", () {
      expect(
        () => WalletUriData.fromUriString(
          "monero_wallet:$moneroAddress?view_key=not-a-key",
        ),
        throwsFormatException,
      );
    });

    test("rejects invalid restore heights", () {
      for (final height in ["abc", "-1"]) {
        expect(
          () => WalletUriData.fromUriString(
            "monero_wallet:?seed=alpha%20beta&height=$height",
          ),
          throwsFormatException,
        );
      }
    });

    test("accepts numeric restore heights from JSON", () {
      final result = WalletUriData.fromJson({
        "seed": "alpha beta",
        "height": 123,
      }, Monero(CryptoCurrencyNetwork.main));

      expect(result.height, 123);
    });

    test("rejects transaction-ID restores until they are implemented", () {
      expect(
        () => WalletUriData.fromUriString(
          "monero_wallet:?seed=alpha%20beta&txid=$privateKey",
        ),
        throwsUnsupportedError,
      );
    });

    test("does not expose secrets in diagnostics", () {
      final result = WalletUriData.fromUriString(
        "monero_wallet:$moneroAddress"
        "?view_key=$privateKey&spend_key=$privateKey",
      );

      expect(result.toString(), isNot(contains(privateKey)));
      expect(result.toString(), contains("redacted"));
    });
  });
}
