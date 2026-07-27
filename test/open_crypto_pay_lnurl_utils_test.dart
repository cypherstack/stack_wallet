import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/open_crypto_pay/lnurl_utils.dart';

void main() {
  test("detects raw LNURL payloads", () {
    expect(LnurlUtils.extractLnurl("LNURL1TEST"), "LNURL1TEST");
    expect(LnurlUtils.isOpenCryptoPayUrl("lnurl1test"), true);
  });

  test("detects lightning-scheme LNURL payloads", () {
    expect(LnurlUtils.extractLnurl("lightning:LNURL1TEST"), "LNURL1TEST");
    expect(LnurlUtils.isOpenCryptoPayUrl("LIGHTNING:lnurl1test"), true);
  });

  test("detects LNURL in lightning query parameter", () {
    const payload = "https://example.com/pay?lightning=LNURL1TEST";

    expect(LnurlUtils.extractLnurl(payload), "LNURL1TEST");
    expect(LnurlUtils.isOpenCryptoPayUrl(payload), true);
  });

  test("ignores URLs without an LNURL payload", () {
    expect(LnurlUtils.extractLnurl("https://example.com/pay"), isNull);
    expect(LnurlUtils.isOpenCryptoPayUrl("https://example.com/pay"), false);
  });
}
