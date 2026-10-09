import 'package:dnssec_resolver/dnssec_resolver.dart';
import 'package:doh_resolver/doh_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Flutter loads the native validator and dispatches its DNS query',
    () async {
      final transport = _Transport();
      await expectLater(
        DnssecResolver(transport: transport).lookupTxt('alice.example'),
        throwsA(
          isA<DnsException>().having((e) => e.code, 'code', DnsError.transport),
        ),
      );
      expect(transport.calls, 1);
    },
  );
}

class _Transport implements DohWireTransport {
  int calls = 0;
  @override
  DnsOperation<DohHttpResponse> startWire(
    Uri uri,
    List<int> query, {
    required int maxResponseBytes,
  }) {
    calls++;
    throw const DnsException(
      DnsError.transport,
      'Expected test transport failure',
    );
  }
}
