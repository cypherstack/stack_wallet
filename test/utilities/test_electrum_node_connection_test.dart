import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/node_form_data.dart';
import 'package:stackwallet/utilities/connection_check/electrum_connection_check.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';

import 'tls_test_server.dart';

void main() {
  late TlsElectrumServer server;
  late NodeFormData data;
  int approvals = 0;
  int successes = 0;

  setUp(() async {
    server = await TlsElectrumServer.start();
    data = NodeFormData()
      ..host = '127.0.0.1'
      ..port = server.port
      ..useSSL = true;
    approvals = 0;
    successes = 0;
  });
  tearDown(() => server.close());

  Future<bool> testNode({
    bool approve = true,
    Future<bool> Function()? approval,
    ElectrumNodeTester? tester,
    bool Function()? isActive,
  }) => testElectrumNodeConnection(
    data,
    isActive: isActive ?? () => true,
    onSuccess: (_) => successes++,
    requestTrust: (certificate, host, port) async {
      approvals++;
      expect(host, '127.0.0.1');
      expect(port, server.port);
      return approval == null ? approve : await approval();
    },
    testConnection:
        tester ??
        ({
          required host,
          required port,
          required useSSL,
          trustedCertificatePem,
        }) => testElectrumConnection(
          host: host,
          port: port,
          useSSL: useSSL,
          trustedCertificatePem: trustedCertificatePem,
          timeout: const Duration(seconds: 2),
        ),
  );

  test('Cancel leaves the form untrusted and sends no RPC', () async {
    expect(await testNode(approve: false), false);
    expect(data.trustedCertificatePem, null);
    expect(approvals, 1);
    expect(successes, 0);
    expect(server.requests, 0);
  });

  test(
    'Trust saves the reviewed certificate after a successful RPC retry',
    () async {
      expect(await testNode(), true);
      expect(
        data.trustedCertificatePem,
        TlsElectrumServer.certificate('node_a'),
      );
      expect(approvals, 1);
      expect(successes, 1);
      expect(server.requests, 1);
      expect(await testNode(), true);
      expect(approvals, 1);
      expect(successes, 2);
    },
  );

  test('a failed retry saves no approval', () async {
    final rejected = await testElectrumConnection(
      host: data.host!,
      port: data.port!,
      useSSL: true,
      timeout: const Duration(seconds: 2),
    );
    expect(
      await testNode(
        tester:
            ({
              required host,
              required port,
              required useSSL,
              trustedCertificatePem,
            }) async => trustedCertificatePem == null
            ? rejected
            : const ElectrumConnectionResult(
                success: false,
                error: 'still rejected',
              ),
      ),
      false,
    );
    expect(data.trustedCertificatePem, null);
    expect(successes, 0);
  });

  test('editing the endpoint during review cancels the retry', () async {
    expect(
      await testNode(
        approval: () async {
          data.host = 'another.example';
          return true;
        },
      ),
      false,
    );
    expect(data.trustedCertificatePem, null);
    expect(server.requests, 0);
  });

  test('leaving the screen during review cancels the retry', () async {
    bool active = true;
    expect(
      await testNode(
        isActive: () => active,
        approval: () async {
          active = false;
          return true;
        },
      ),
      false,
    );
    expect(data.trustedCertificatePem, null);
    expect(server.requests, 0);
  });

  test('changing the network option during review cancels approval', () async {
    expect(
      await testNode(
        approval: () async {
          data.netOption = TorPlainNetworkOption.tor;
          return true;
        },
      ),
      false,
    );
    expect(data.trustedCertificatePem, null);
    expect(server.requests, 0);
  });

  test('a late successful retry cannot trust a changed endpoint', () async {
    final retry = Completer<ElectrumConnectionResult>();
    final retryStarted = Completer<void>();
    final rejected = await testElectrumConnection(
      host: data.host!,
      port: data.port!,
      useSSL: true,
      timeout: const Duration(seconds: 2),
    );
    final result = testNode(
      tester:
          ({
            required host,
            required port,
            required useSSL,
            trustedCertificatePem,
          }) async {
            if (trustedCertificatePem == null) return rejected;
            retryStarted.complete();
            return retry.future;
          },
    );
    await retryStarted.future;
    data.port = data.port! + 1;
    retry.complete(const ElectrumConnectionResult(success: true));
    expect(await result, false);
    expect(data.trustedCertificatePem, null);
    expect(successes, 0);
  });
  for (final clearThenRestore in [false, true]) {
    test(
      'an intervening certificate decision cancels review ($clearThenRestore)',
      () async {
        final before = data.trustedCertificatePem;
        expect(
          await testNode(
            approval: () async {
              data.forgetCertificate();
              if (clearThenRestore) data.trustedCertificatePem = before;
              return true;
            },
          ),
          false,
        );
        expect(data.trustedCertificatePem, null);
        expect(server.requests, 0);
        expect(successes, 0);
      },
    );
  }
}
