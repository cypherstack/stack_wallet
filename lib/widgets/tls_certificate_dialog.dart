import 'dart:io';

import 'package:flutter/material.dart';

import '../utilities/connection_check/electrum_connection_check.dart';
import '../utilities/tls_certificate.dart';
import 'desktop/primary_button.dart';
import 'desktop/secondary_button.dart';
import 'stack_dialog.dart';

Future<bool> showBadX509CertificateDialog(
  X509Certificate cert,
  String host,
  int port,
  BuildContext context,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StackDialog(
      title: 'Untrusted TLS certificate',
      width: 520,
      message:
          'Server: $host:$port\n\n'
          'Subject: ${cert.subject}\n'
          'Issuer: ${cert.issuer}\n\n'
          'Valid from: ${cert.startValidity.toUtc()}\n'
          'Valid until: ${cert.endValidity.toUtc()}\n\n'
          'SHA-256:\n${certificateFingerprint(cert.der)}',
      leftButton: SecondaryButton(
        label: 'Cancel',
        onPressed: () => Navigator.of(context).pop(false),
      ),
      rightButton: PrimaryButton(
        label: 'Trust',
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ),
  );
  return result ?? false;
}

/// Explain a retry that failed after its certificate was approved.
Future<void> showTrustedCertificateFailedDialog(
  Object? error,
  String host,
  int port,
  BuildContext context,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StackDialog(
      title: 'Connection still failed',
      width: 520,
      message:
          'Connecting to $host:$port with the trusted certificate still '
          'failed.\n\n'
          'Reason: ${describeConnectionError(error)}',
      rightButton: PrimaryButton(
        label: 'OK',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
  );
}
