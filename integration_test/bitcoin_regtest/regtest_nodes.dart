import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

// Plain dart:io, no Flutter: scripts/bitcoin_regtest_nodes.dart runs this on
// the host for test targets that cannot start processes themselves (the
// sandboxed macOS app, iOS and Android).

/// bitcoind JSON-RPC with a user name and password.
class RegtestRpc {
  RegtestRpc({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
  });

  final String host;
  final int port;
  final String user;
  final String password;
  final _http = HttpClient();
  int _id = 0;

  /// One call, against [wallet] when given.
  Future<dynamic> call(
    String method, [
    List<dynamic> params = const [],
    String? wallet,
  ]) async {
    final path = wallet == null ? '/' : '/wallet/$wallet';
    final request = await _http.post(host, port, path);
    request.headers
      ..set(
        HttpHeaders.authorizationHeader,
        'Basic ${base64.encode(utf8.encode('$user:$password'))}',
      )
      ..contentType = ContentType.json;
    request.write(
      jsonEncode({
        'jsonrpc': '1.0',
        'id': ++_id,
        'method': method,
        'params': params,
      }),
    );
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (text.isEmpty) {
      throw StateError('bitcoind $method: HTTP ${response.statusCode}');
    }
    final body = jsonDecode(text) as Map;
    if (body['error'] != null) {
      throw StateError('bitcoind $method: ${body['error']}');
    }
    return body['result'];
  }

  void close() => _http.close(force: true);
}

/// One Electrum protocol call on a fresh connection.
Future<dynamic> electrumCall(
  String host,
  int port,
  String method, [
  List<dynamic> params = const [],
]) async {
  final socket = await Socket.connect(
    host,
    port,
    timeout: const Duration(seconds: 10),
  );
  try {
    final request = {
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': params,
    };
    socket.write('${jsonEncode(request)}\n');
    await socket.flush();
    final line = await socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(line) as Map;
    if (body['error'] != null) {
      throw StateError('electrum $method: ${body['error']}');
    }
    return body['result'];
  } finally {
    socket.destroy();
  }
}

/// Polls [check] until it returns true. [failed] can end the wait early with
/// a reason, such as a process that exited.
Future<void> pollUntil(
  String what,
  Future<bool> Function() check, {
  Future<String?> Function()? failed,
  String Function()? context,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (!await check()) {
    final reason = await failed?.call();
    if (reason != null) {
      throw StateError('$reason waiting for $what\n${context?.call() ?? ''}');
    }
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException(
        'Timed out waiting for $what\n${context?.call() ?? ''}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

/// bitcoind and an Electrum server ("electrs" 0.10 or "fulcrum") on free
/// loopback ports under a temp dir. The indexer authenticates with bitcoind's
/// cookie; clients use [rpcUser] and [rpcPassword], so they need no access to
/// the data dir.
class RegtestNodes {
  RegtestNodes._(this.root, this.indexer, this._ports, this.rpcPassword);

  final Directory root;
  final String indexer;
  final List<int> _ports;
  int get rpcPort => _ports[0];
  int get p2pPort => _ports[1];
  int get electrumPort => _ports[2];
  int get _monitoringPort => _ports[3];

  static const rpcUser = 'stackregtest';
  final String rpcPassword;

  late final rpc = RegtestRpc(
    host: '127.0.0.1',
    port: rpcPort,
    user: rpcUser,
    password: rpcPassword,
  );

  Process? _bitcoind;
  Process? _indexer;
  final _log = <String>[];

  static Future<RegtestNodes> start({
    required String bitcoind,
    required String indexer,
    required String indexerPath,
  }) async {
    if (indexer != 'electrs' && indexer != 'fulcrum') {
      throw ArgumentError.value(indexer, 'indexer', 'electrs or fulcrum');
    }
    for (final path in [bitcoind, indexerPath]) {
      if (path.isEmpty || !File(path).existsSync()) {
        throw StateError('No executable at "$path".');
      }
    }
    final random = Random.secure();
    final password = base64Url.encode(
      List.generate(18, (_) => random.nextInt(256)),
    );
    final root = await Directory.systemTemp.createTemp('stack_btc_regtest_');
    final nodes = RegtestNodes._(root, indexer, await _freePorts(4), password);
    try {
      await nodes._startBitcoind(bitcoind);
      // Indexers wait while bitcoind is in initial block download, which a
      // new regtest chain only leaves once it has a block. Mine the miner
      // wallet's coinbase to maturity first.
      await nodes.rpc.call('createwallet', ['miner']);
      final address = await nodes.rpc.call('getnewaddress', [], 'miner');
      await nodes.rpc.call('generatetoaddress', [101, address]);
      if (indexer == 'fulcrum') {
        await nodes._startFulcrum(indexerPath);
      } else {
        await nodes._startElectrs(indexerPath);
      }
      await nodes.waitForIndexer();
    } catch (_) {
      await nodes.stop();
      rethrow;
    }
    return nodes;
  }

  /// bitcoind's -rpcauth value: user:salt$hex(HMAC-SHA256(salt, password)).
  String get _rpcAuth {
    final random = Random.secure();
    final salt = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final hash = Hmac(
      sha256,
      utf8.encode(salt),
    ).convert(utf8.encode(rpcPassword));
    return '$rpcUser:$salt\$$hash';
  }

  Future<void> _startBitcoind(String path) async {
    final data = Directory('${root.path}/bitcoind')..createSync();
    _bitcoind = await Process.start(path, [
      '-regtest',
      '-datadir=${data.path}',
      '-server',
      '-txindex',
      '-listen',
      '-bind=127.0.0.1:$p2pPort',
      '-rpcbind=127.0.0.1:$rpcPort',
      '-rpcallowip=127.0.0.1',
      '-rpcport=$rpcPort',
      // -rpcauth leaves cookie auth on for the indexer.
      '-rpcauth=$_rpcAuth',
      '-fallbackfee=0.0002',
      '-dnsseed=0',
      '-fixedseeds=0',
      '-printtoconsole',
    ]);
    _capture('bitcoind', _bitcoind!);
    final cookie = File('${data.path}/regtest/.cookie');
    await _until('bitcoind RPC', () async {
      if (!cookie.existsSync()) return false;
      try {
        await rpc.call('getblockchaininfo');
        return true;
      } on Object {
        return false;
      }
    });
  }

  Future<void> _startElectrs(String path) async {
    _indexer = await Process.start(path, [
      '--skip-default-conf-files',
      '--network=regtest',
      '--db-dir=${root.path}/electrs',
      '--daemon-dir=${root.path}/bitcoind',
      '--cookie-file=${root.path}/bitcoind/regtest/.cookie',
      '--daemon-rpc-addr=127.0.0.1:$rpcPort',
      '--daemon-p2p-addr=127.0.0.1:$p2pPort',
      '--electrum-rpc-addr=127.0.0.1:$electrumPort',
      '--monitoring-addr=127.0.0.1:$_monitoringPort',
      '--wait-duration-secs=1',
      '--log-filters=INFO',
    ]);
    _capture('electrs', _indexer!);
  }

  /// Fulcrum takes most settings from a config file. Peering is off so it
  /// never contacts public servers.
  Future<void> _startFulcrum(String path) async {
    final config = File('${root.path}/fulcrum.conf');
    await config.writeAsString(
      [
        'datadir = ${root.path}/fulcrum',
        'bitcoind = 127.0.0.1:$rpcPort',
        'rpccookie = ${root.path}/bitcoind/regtest/.cookie',
        'tcp = 127.0.0.1:$electrumPort',
        'stats = 127.0.0.1:$_monitoringPort',
        'peering = false',
        'announce = false',
        'polltime = 0.5',
      ].join('\n'),
    );
    _indexer = await Process.start(path, [config.path]);
    _capture('fulcrum', _indexer!);
  }

  void _capture(String name, Process process) {
    for (final stream in [process.stdout, process.stderr]) {
      stream.transform(utf8.decoder).transform(const LineSplitter()).listen((
        line,
      ) {
        _log.add('$name: $line');
        if (_log.length > 400) _log.removeAt(0);
      });
    }
  }

  /// The last lines both processes printed, for failure messages.
  String get logTail =>
      _log.skip(_log.length > 60 ? _log.length - 60 : 0).join('\n');

  /// Waits until the indexer serves the same tip as bitcoind.
  Future<void> waitForIndexer() async {
    final target = await rpc.call('getblockcount') as int;
    await _until('$indexer at height $target', () async {
      try {
        final header = await electrumCall(
          '127.0.0.1',
          electrumPort,
          'blockchain.headers.subscribe',
        ) as Map;
        return header['height'] == target;
      } on Object {
        return false;
      }
    });
  }

  Future<void> _until(String what, Future<bool> Function() check) => pollUntil(
    what,
    check,
    context: () => logTail,
    failed: () async {
      for (final (name, process) in [
        ('bitcoind', _bitcoind),
        (indexer, _indexer),
      ]) {
        final code = await process?.exitCode.timeout(
          Duration.zero,
          onTimeout: () => -1,
        );
        if (code != null && code != -1) return '$name exited with $code';
      }
      return null;
    },
  );

  Future<void> stop() async {
    _indexer?.kill();
    if (_bitcoind != null) {
      try {
        await rpc.call('stop');
      } on Object {
        _bitcoind!.kill();
      }
    }
    for (final process in [_indexer, _bitcoind]) {
      await process?.exitCode.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
    rpc.close();
    if (root.existsSync()) await root.delete(recursive: true);
  }
}

Future<List<int>> _freePorts(int count) async {
  final sockets = <ServerSocket>[];
  for (var i = 0; i < count; i++) {
    sockets.add(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));
  }
  final ports = sockets.map((e) => e.port).toList();
  for (final socket in sockets) {
    await socket.close();
  }
  return ports;
}
