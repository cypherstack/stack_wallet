import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/connection_check/electrum_connection_check.dart';
import 'package:stackwallet/utilities/tls_certificate.dart';
import 'package:stackwallet/widgets/tls_certificate_dialog.dart';

import '../sample_data/theme_json.dart';
import '../utilities/tls_test_server.dart';

void main() {
  late X509Certificate certificate;
  setUpAll(() async {
    final server = await TlsElectrumServer.start();
    try {
      certificate = (await testElectrumConnection(
        host: '127.0.0.1',
        port: server.port,
        useSSL: true,
        timeout: const Duration(seconds: 2),
      )).certificate!;
    } finally {
      await server.close();
    }
  });

  for (final choice in ['Cancel', 'Trust']) {
    testWidgets('shows certificate details and returns $choice', (
      tester,
    ) async {
      bool? approved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  approved = await showBadX509CertificateDialog(
                    certificate,
                    'node.example',
                    50002,
                    context,
                  );
                },
                child: const Text('Review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      final message = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((text) => text.data)
          .join('\n');
      expect(message, contains('node.example:50002'));
      expect(message, contains(certificate.subject));
      expect(message, contains(certificate.issuer));
      expect(message, contains('${certificate.endValidity.toUtc()}'));
      expect(message, contains(certificateFingerprint(certificate.der)));
      await tester.tap(find.text(choice));
      await tester.pumpAndSettle();
      expect(approved, choice == 'Trust');
    });
  }

  testWidgets('explains a connection that failed after trust', (tester) async {
    bool dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showTrustedCertificateFailedDialog(
                  const HandshakeException(
                    'Handshake error in client',
                    OSError('\n\tCERTIFICATE_VERIFY_FAILED: Hostname mismatch'),
                  ),
                  'node.example',
                  50002,
                  context,
                );
                dismissed = true;
              },
              child: const Text('Explain'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Explain'));
    await tester.pumpAndSettle();
    final message = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((text) => text.data)
        .join('\n');
    expect(message, contains('node.example:50002'));
    expect(message, contains('CERTIFICATE_VERIFY_FAILED: Hostname mismatch'));
    expect(message, isNot(contains('\t')));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(dismissed, true);
    expect(find.text('Connection still failed'), findsNothing);
  });
}
