import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';

void main() {
  test("strips keys and addresses", () {
    final uri = Uri.https("api.cyphergoat.com", "/swap", {
      "coin1": "btc",
      "address": "bc1qreceive",
      "API_Key": "SUPERSECRET",
    });

    expect(
      uri.redacted.toString(),
      "https://api.cyphergoat.com/swap?coin1=btc",
    );
  });

  test("leaves other uris alone", () {
    final uri = Uri.https("api.cyphergoat.com", "/transaction", {"id": "abc"});

    expect(uri.redacted, uri);
  });
}
