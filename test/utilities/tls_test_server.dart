import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Certificates for the test servers, built in Dart so the tests need no
/// native tooling. The 'expired' certificate is a committed fixture; the
/// others are generated once per test process from the committed test keys.
final _certificates = <String, String>{};

String _keyPem(String name) =>
    File('test/fixtures/tls/$name.key.pem').readAsStringSync();

String _certificatePem(String name) {
  if (name == 'expired') {
    return File('test/fixtures/tls/expired.pem').readAsStringSync();
  }
  return _certificates[name] ??= generateServerCertificatePem(
    privateKeyPem: _keyPem(name),
    commonName: 'localhost',
    validity: const Duration(days: 1),
  );
}

/// A self-signed X.509 server certificate, SHA-256 with RSA, in PEM.
String generateServerCertificatePem({
  required String privateKeyPem,
  required String commonName,
  required Duration validity,
}) {
  final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
  final now = DateTime.now().toUtc();

  ASN1Sequence algorithm(String oid) => ASN1Sequence(
    elements: [ASN1ObjectIdentifier.fromIdentifierString(oid), ASN1Null()],
  );
  final name = ASN1Sequence(
    elements: [
      ASN1Set(
        elements: [
          ASN1Sequence(
            elements: [
              ASN1ObjectIdentifier.fromIdentifierString('2.5.4.3'),
              ASN1UTF8String(utf8StringValue: commonName),
            ],
          ),
        ],
      ),
    ],
  );
  final publicKeyInfo = ASN1Sequence(
    elements: [
      algorithm('1.2.840.113549.1.1.1'),
      ASN1BitString(
        stringValues: ASN1Sequence(
          elements: [
            ASN1Integer(privateKey.modulus!),
            ASN1Integer(privateKey.publicExponent!),
          ],
        ).encode(),
      ),
    ],
  );
  final random = Random.secure();
  final serial =
      (BigInt.from(random.nextInt(1 << 31)) << 32) +
      BigInt.from(random.nextInt(1 << 32));
  final tbsCertificate = ASN1Sequence(
    elements: [
      ASN1Integer(serial),
      algorithm('1.2.840.113549.1.1.11'),
      name,
      ASN1Sequence(
        elements: [
          ASN1UtcTime(now.subtract(const Duration(hours: 1))),
          ASN1UtcTime(now.add(validity)),
        ],
      ),
      name,
      publicKeyInfo,
    ],
  );
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final signature = signer.generateSignature(tbsCertificate.encode());
  final certificate = ASN1Sequence(
    elements: [
      tbsCertificate,
      algorithm('1.2.840.113549.1.1.11'),
      ASN1BitString(stringValues: signature.bytes),
    ],
  );
  final body = base64Encode(certificate.encode());
  final lines = [
    for (var i = 0; i < body.length; i += 64)
      body.substring(i, min(i + 64, body.length)),
  ];
  return '-----BEGIN CERTIFICATE-----\n${lines.join('\n')}\n'
      '-----END CERTIFICATE-----\n';
}

/// Loopback fixtures only; the private keys under fixtures/tls are test keys.
class TlsElectrumServer {
  TlsElectrumServer._(this._server);

  final ServerSocket _server;
  final _sockets = <Socket>[];
  late final StreamSubscription<Socket> _subscription;
  int requests = 0;
  final methods = <String>[];
  int disconnections = 0;
  int accepted = 0;
  int get port => _server.port;

  static String certificate(String name) => _certificatePem(name);

  /// With [versionError], server.version is answered with a JSON-RPC error,
  /// as a server that rejects the client would.
  static Future<TlsElectrumServer> start({
    String? certificateName = 'node_a',
    bool respond = true,
    bool versionError = false,
    bool stallHandshake = false,
  }) async {
    final server = TlsElectrumServer._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    final context = certificateName == null
        ? null
        : (SecurityContext()
            ..useCertificateChainBytes(
              utf8.encode(_certificatePem(certificateName)),
            )
            ..usePrivateKeyBytes(utf8.encode(_keyPem(certificateName))));
    server._subscription = server._server.listen((raw) async {
      server.accepted++;
      server._sockets.add(raw);
      raw.done.ignore();
      if (stallHandshake) {
        raw.listen(
          (_) {},
          onError: (Object _) {},
          onDone: () => server.disconnections++,
        );
        return;
      }
      try {
        final socket = context == null
            ? raw
            : await SecureSocket.secureServer(raw, context);
        server._sockets.add(socket);
        socket.done.ignore();
        socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                final request = jsonDecode(line) as Map<String, dynamic>;
                server.requests++;
                server.methods.add(request['method'] as String);
                if (!respond) return;
                if (versionError && request['method'] == 'server.version') {
                  socket.write(
                    '${jsonEncode({
                      'jsonrpc': '2.0',
                      'id': request['id'],
                      'error': {'code': -32601, 'message': 'unsupported'},
                    })}\n',
                  );
                  return;
                }
                final Object result;
                switch (request['method']) {
                  case 'server.version':
                    result = ['ElectrumX TLS test', '1.4'];
                  case 'blockchain.headers.subscribe':
                    result = {'height': 100, 'hex': '00' * 80};
                  case 'blockchain.transaction.get':
                    result = {'txid': request['params'][0], 'confirmations': 3};
                  default:
                    result = {};
                }
                final reply = {
                  'jsonrpc': '2.0',
                  'id': request['id'],
                  'result': result,
                };
                socket.write('${jsonEncode(reply)}\n');
              },
              onError: (Object _) {},
              onDone: () {
                server.disconnections++;
              },
            );
      } catch (_) {
        raw.destroy();
      }
    });
    return server;
  }

  void disconnectClients() {
    for (final socket in _sockets) {
      socket.destroy();
    }
    _sockets.clear();
  }

  Future<void> close() async {
    disconnectClients();
    await _subscription.cancel();
    await _server.close();
  }
}

/// A local SOCKS5 tunnel that records destination names without DNS lookups.
class TlsTestProxy {
  TlsTestProxy._(this._server, this.destinationPort, this.greetingDelay);

  final ServerSocket _server;
  final int destinationPort;
  final Duration greetingDelay;
  final destinations = <String>[];
  final _sockets = <Socket>[];
  late final StreamSubscription<Socket> _subscription;
  ({InternetAddress host, int port}) get info =>
      (host: InternetAddress.loopbackIPv4, port: _server.port);

  static Future<TlsTestProxy> start(
    int destinationPort, {
    Duration greetingDelay = Duration.zero,
  }) async {
    final proxy = TlsTestProxy._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
      destinationPort,
      greetingDelay,
    );
    proxy._subscription = proxy._server.listen(proxy._forward);
    return proxy;
  }

  Future<void> _forward(Socket client) async {
    _sockets.add(client);
    final input = _SocketReader(client);
    bool inputForwarded = false;
    try {
      final greeting = await input.read(2);
      await input.read(greeting[1]);
      if (greetingDelay != Duration.zero) {
        await Future<void>.delayed(greetingDelay);
      }
      client.add([5, 0]);
      final header = await input.read(4);
      final String host;
      switch (header[3]) {
        case 3:
          final length = (await input.read(1)).single;
          host = utf8.decode(await input.read(length));
        case 1:
          host = (await input.read(4)).join('.');
        default:
          throw StateError('Unexpected SOCKS destination type');
      }
      await input.read(2);
      destinations.add(host);
      final upstream = await Socket.connect(
        InternetAddress.loopbackIPv4,
        destinationPort,
      );
      _sockets.add(upstream);
      client.add([5, 0, 0, 1, 127, 0, 0, 1, 0, 0]);
      if (input.pending.isNotEmpty) upstream.add(input.pending);
      final remainingInput = input.queue.rest;
      inputForwarded = true;
      await Future.wait([
        remainingInput.pipe(upstream),
        upstream.cast<List<int>>().pipe(client),
      ]);
    } catch (_) {
      client.destroy();
      if (!inputForwarded) await input.queue.cancel();
    }
  }

  Future<void> close() async {
    for (final socket in _sockets) {
      socket.destroy();
    }
    await _subscription.cancel();
    await _server.close();
  }
}

class _SocketReader {
  _SocketReader(Socket socket) : queue = StreamQueue(socket.cast<List<int>>());
  final StreamQueue<List<int>> queue;
  List<int> pending = [];

  Future<List<int>> read(int count) async {
    while (pending.length < count) {
      pending.addAll(await queue.next);
    }
    final value = pending.sublist(0, count);
    pending = pending.sublist(count);
    return value;
  }
}
