import 'dart:convert';

import 'package:bech32/bech32.dart';

/// LNURL (LUD-01) helpers scoped to Open CryptoPay QR handling.
///
/// Stack does not support Lightning in general; this lives under
/// `services/open_crypto_pay/` because OCP is currently the sole consumer.
/// If broader LNURL support is ever added, promote this to `utilities/`.
class LnurlUtils {
  /// Decodes a bech32-encoded LNURL string back to a URL.
  static String decodeLnurl(String lnurl) {
    final decoded = const Bech32Codec().decode(lnurl, lnurl.length);
    return utf8.decode(_fromBase32(decoded.data));
  }

  /// Returns true if [url] is an Open CryptoPay QR payload.
  static bool isOpenCryptoPayUrl(String url) {
    return extractLnurl(url)?.toUpperCase().startsWith('LNURL') ?? false;
  }

  /// Returns the encoded LNURL payload, if any.
  static String? extractLnurl(String url) {
    final trimmed = url.trim();
    if (trimmed.toUpperCase().startsWith('LNURL')) return trimmed;

    const lightningScheme = 'lightning:';
    if (trimmed.toLowerCase().startsWith(lightningScheme)) {
      final payload = trimmed.substring(lightningScheme.length);
      if (payload.toUpperCase().startsWith('LNURL')) return payload;
    }

    try {
      return Uri.parse(trimmed).queryParameters['lightning'];
    } catch (_) {
      return null;
    }
  }

  /// Regroups 5-bit bech32 data into 8-bit bytes.
  static List<int> _fromBase32(List<int> data) {
    int acc = 0;
    int bits = 0;
    final result = <int>[];
    for (final value in data) {
      if (value < 0 || (value >> 5) != 0) {
        throw const FormatException('Invalid bech32 data');
      }
      acc = (acc << 5) | value;
      bits += 5;
      while (bits >= 8) {
        bits -= 8;
        result.add((acc >> bits) & 0xff);
      }
    }
    if (bits >= 5 || ((acc << (8 - bits)) & 0xff) != 0) {
      throw const FormatException('Invalid bech32 padding');
    }
    return result;
  }
}
