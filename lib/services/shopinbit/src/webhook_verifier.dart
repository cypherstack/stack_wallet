import 'dart:convert';

import 'package:crypto/crypto.dart';

class WebhookVerifier {
  /// Verify a webhook delivery from ShopInBit.
  ///
  /// [body] is the raw request body.
  /// [signatureHeader] is the `X-Concierge-Signature` header value,
  /// formatted as `t=<unix_timestamp>,v1=<hex_hmac>`.
  /// [secret] is the subscription secret.
  /// [toleranceSeconds] is the max age of the timestamp (default 300 = 5 min).
  static bool verify(
    String body,
    String signatureHeader,
    String secret, {
    int toleranceSeconds = 300,
  }) {
    final parts = <String, String>{};
    for (final segment in signatureHeader.split(',')) {
      final idx = segment.indexOf('=');
      if (idx == -1) continue;
      parts[segment.substring(0, idx)] = segment.substring(idx + 1);
    }

    final timestampStr = parts['t'];
    final v1 = parts['v1'];
    if (timestampStr == null || v1 == null) return false;

    final timestamp = int.tryParse(timestampStr);
    if (timestamp == null) return false;

    // Check timestamp freshness.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if ((now - timestamp).abs() > toleranceSeconds) return false;

    // Compute HMAC-SHA256 of "<timestamp>.<body>".
    final payload = '$timestampStr.$body';
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    final expected = digest.toString();

    // Constant-time comparison.
    if (expected.length != v1.length) return false;
    var result = 0;
    for (var i = 0; i < expected.length; i++) {
      result |= expected.codeUnitAt(i) ^ v1.codeUnitAt(i);
    }
    return result == 0;
  }
}
