import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

Uint8List certificateDer(String pem) {
  final match = RegExp(
    r'^\s*-----BEGIN CERTIFICATE-----\s*([A-Za-z0-9+/=\s]+)-----END CERTIFICATE-----\s*$',
  ).firstMatch(pem);
  if (match == null || match.end != pem.length) {
    throw const FormatException('Expected one PEM certificate');
  }
  return base64Decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
}

String certificateFingerprint(List<int> der) {
  final hex = sha256.convert(der).toString().toUpperCase();
  return [for (int i = 0; i < hex.length; i += 2) hex.substring(i, i + 2)]
      .join(':');
}

String? certificatePemFingerprint(String pem) {
  try {
    return certificateFingerprint(certificateDer(pem));
  } on FormatException {
    return null;
  }
}

/// The check a TLS connection runs when the platform rejects the server's
/// certificate. It accepts exactly the certificate approved for the node,
/// whatever its hostname or validity, because the approval pins that
/// certificate. Null when nothing is approved, so the platform's verdict
/// stands. Throws a [FormatException] for a damaged PEM before connecting.
bool Function(X509Certificate)? trustedCertificateCheck(
  String? certificatePem,
) {
  if (certificatePem == null) return null;
  final trusted = certificateFingerprint(certificateDer(certificatePem));
  return (certificate) => certificateFingerprint(certificate.der) == trusted;
}
