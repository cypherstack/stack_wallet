import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wl_gen/interfaces/xelis_types.dart';

void main() {
  test(
    'Xelis persistence conversion preserves integers beyond double precision',
    () {
      final value = BigInt.parse('9007199254740993');
      expect(BigInt.from(xelisStorageInt(value)), value);
      expect(xelisStorageInt(BigInt.zero), 0);
      expect(
        BigInt.from(xelisStorageInt(BigInt.parse('9223372036854775807'))),
        BigInt.parse('9223372036854775807'),
      );
      expect(() => xelisStorageInt(BigInt.from(-1)), throwsRangeError);
      expect(
        () => xelisStorageInt(BigInt.parse('9223372036854775808')),
        throwsRangeError,
      );
    },
  );

  test('daemon origin preserves TLS and brackets IPv6', () {
    expect(
      xelisDaemonOrigin(host: 'node.example', port: 443, useSSL: true),
      'https://node.example',
    );
    expect(
      xelisDaemonOrigin(host: '::1', port: 8080, useSSL: false),
      'http://[::1]:8080',
    );
    for (final host in [
      'https://node.example',
      'user@host',
      'host/json_rpc',
      '',
    ]) {
      expect(
        () => xelisDaemonOrigin(host: host, port: 443, useSSL: true),
        throwsArgumentError,
      );
    }
  });
}
