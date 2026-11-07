import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_node_url.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_transport.dart';

void main() {
  String url(String host, {int port = 3413, bool useSSL = true}) =>
      grinNodeUrl(host: host, port: port, useSSL: useSSL);

  test('the scheme comes from the host, else from useSSL', () {
    expect(url('https://grinnode.live'), 'https://grinnode.live:3413');
    expect(url('http://grinnode.live'), 'http://grinnode.live:3413');
    expect(url('grinnode.live'), 'https://grinnode.live:3413');
    expect(url('grinnode.live', useSSL: false), 'http://grinnode.live:3413');
  });

  test('the port field replaces a port in the host', () {
    expect(url('https://node.example:443', port: 3413),
        'https://node.example:3413');
    expect(url('https://node.example:443', port: 0), 'https://node.example');
    expect(url('http://127.0.0.1', port: 13413, useSSL: false),
        'http://127.0.0.1:13413');
  });

  test('trailing slashes go, a path stays', () {
    expect(url('https://node.example/'), 'https://node.example:3413');
    expect(url('https://node.example/grin//'), 'https://node.example:3413/grin');
  });

  test('onion nodes use http only', () {
    const onion =
        'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz234567.onion';
    expect(url(onion), 'http://$onion:3413');
    expect(url('http://$onion'), 'http://$onion:3413');
    expect(() => url('https://$onion'), throwsA(isA<GrinNodeUrlException>()));
    expect(isOnionHost('http://$onion:3413/v2'), isTrue);
    expect(isOnionHost('https://grinnode.live'), isFalse);
  });

  test('userinfo, queries and bad schemes are refused with a message', () {
    for (final host in [
      'https://user:hunter2@node.example',
      'https://node.example?x=1',
      'ftp://node.example',
      '',
      '   ',
    ]) {
      expect(
        () => url(host),
        throwsA(
          isA<GrinNodeUrlException>().having(
            (e) => e.message,
            'message',
            isNot(contains('hunter2')),
          ),
        ),
        reason: host,
      );
    }
  });
}
