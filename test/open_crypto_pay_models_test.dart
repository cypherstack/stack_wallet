import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/open_crypto_pay/models.dart';

void main() {
  test("parses quote payment id used for commit endpoint", () {
    final quote = OpenCryptoPayQuote.fromJson({
      "id": "quote-id",
      "payment": "payment-id",
      "expiration": "2026-04-28T12:00:00Z",
    });

    expect(quote.id, "quote-id");
    expect(quote.paymentId, "payment-id");
  });

  test("rejects quotes without a payment id", () {
    expect(
      () => OpenCryptoPayQuote.fromJson({
        "id": "quote-id",
        "expiration": "2026-04-28T12:00:00Z",
      }),
      throwsException,
    );
  });
}
