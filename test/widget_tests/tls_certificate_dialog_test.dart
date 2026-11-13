import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/node_form_data.dart';
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
  testWidgets('Trust resumes the test on its current route', (tester) async {
    final data = NodeFormData()
      ..host = 'node.example'
      ..port = 50002
      ..useSSL = true;
    bool? success;
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
              child: const Text('Test'),
              onPressed: () async {
                success = await testElectrumNodeConnection(
                  data,
                  isActive: () =>
                      context.mounted &&
                      ModalRoute.of(context)?.isCurrent != false,
                  requestTrust: (cert, host, port) =>
                      showBadX509CertificateDialog(cert, host, port, context),
                  testConnection:
                      ({
                        required host,
                        required port,
                        required useSSL,
                        trustedCertificatePem,
                      }) async => trustedCertificatePem == null
                      ? ElectrumConnectionResult(
                          success: false,
                          certificate: certificate,
                        )
                      : const ElectrumConnectionResult(success: true),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(success, null);
    await tester.tap(find.text('Trust'));
    await tester.pumpAndSettle();
    expect(success, true);
    expect(data.trustedCertificatePem, certificate.pem);
  });
}
