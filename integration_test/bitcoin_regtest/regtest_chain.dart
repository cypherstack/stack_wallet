import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

const _bitcoindPath = String.fromEnvironment('BITCOIND');
const _indexerName = String.fromEnvironment('INDEXER', defaultValue: 'electrs');
const _indexerPaths = {
  'electrs': String.fromEnvironment('ELECTRS'),
  'fulcrum': String.fromEnvironment('FULCRUM'),
};

/// A private bitcoind regtest chain with an Electrum server in front of it, on
/// free loopback ports under a temp dir. --dart-define=INDEXER picks electrs
/// (0.10, the default) or fulcrum; BITCOIND, ELECTRS and FULCRUM name the
/// binaries.
///
/// The node's own wallet ("miner") holds the coinbase coins and pays the
/// Stack wallets.
class RegtestChain {
  RegtestChain._(this.root, this._ports);

  final Directory root;
  final List<int> _ports;
  int get rpcPort => _ports[0];
  int get p2pPort => _ports[1];
  int get electrumPort => _ports[2];
  int get _monitoringPort => _ports[3];

  Process? _bitcoind;
  Process? _indexer;

  /// The Electrum server in use: "electrs" or "fulcrum".
  String get indexer => _indexerName;
  final _log = <String>[];
  String _auth = '';
  late final String minerAddress;
  final _http = HttpClient();
  int _id = 0;

  static Future<RegtestChain> start() async {
    if (!_indexerPaths.containsKey(_indexerName)) {
      throw StateError('INDEXER must be one of ${_indexerPaths.keys}.');
    }
    for (final (name, path) in [
      ('BITCOIND', _bitcoindPath),
      (_indexerName.toUpperCase(), _indexerPaths[_indexerName]!),
    ]) {
      if (path.isEmpty || !File(path).existsSync()) {
        throw StateError('Pass --dart-define=$name=<path to the binary>.');
      }
    }
    final root = await Directory.systemTemp.createTemp('stack_btc_regtest_');
    final chain = RegtestChain._(root, await _freePorts(4));
    try {
      await chain._startBitcoind();
      await chain.rpc('createwallet', ['miner']);
      chain.minerAddress =
          await chain.rpc('getnewaddress', [], 'miner') as String;
      await chain.rpc('generatetoaddress', [101, chain.minerAddress]);
      await (_indexerName == 'fulcrum'
          ? chain._startFulcrum()
          : chain._startElectrs());
      await chain.waitForIndexer();
    } catch (_) {
      await chain.stop();
      rethrow;
    }
    return chain;
  }

  Future<void> _startBitcoind() async {
    final data = Directory('${root.path}/bitcoind')..createSync();
    _bitcoind = await Process.start(_bitcoindPath, [
      '-regtest',
      '-datadir=${data.path}',
      '-server',
      '-txindex',
      '-listen',
      '-bind=127.0.0.1:$p2pPort',
      '-rpcbind=127.0.0.1:$rpcPort',
      '-rpcallowip=127.0.0.1',
      '-rpcport=$rpcPort',
      '-fallbackfee=0.0002',
      '-dnsseed=0',
      '-fixedseeds=0',
      '-printtoconsole',
    ]);
    _capture('bitcoind', _bitcoind!);
    final cookie = File('${data.path}/regtest/.cookie');
    await _until('bitcoind RPC', () async {
      if (!cookie.existsSync()) return false;
      _auth = 'Basic ${base64.encode(utf8.encode(cookie.readAsStringSync()))}';
      try {
        await rpc('getblockchaininfo');
        return true;
      } on Object {
        return false;
      }
    });
  }

  Future<void> _startElectrs() async {
    _indexer = await Process.start(_indexerPaths['electrs']!, [
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
  Future<void> _startFulcrum() async {
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
    _indexer = await Process.start(_indexerPaths['fulcrum']!, [config.path]);
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

  /// A bitcoind JSON-RPC call, against [wallet] when given.
  Future<dynamic> rpc(
    String method, [
    List<dynamic> params = const [],
    String? wallet,
  ]) async {
    final path = wallet == null ? '/' : '/wallet/$wallet';
    final request = await _http.post('127.0.0.1', rpcPort, path);
    request.headers
      ..set(HttpHeaders.authorizationHeader, _auth)
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
    final body = jsonDecode(await response.transform(utf8.decoder).join());
    final error = (body as Map)['error'];
    if (error != null) {
      throw StateError('bitcoind $method: $error');
    }
    return body['result'];
  }

  Future<int> height() async => await rpc('getblockcount') as int;

  /// Mines [blocks] to the miner wallet and waits for the indexer.
  Future<void> mine(int blocks) async {
    await rpc('generatetoaddress', [blocks, minerAddress]);
    await waitForIndexer();
  }

  /// Pays [btc] from the miner wallet to [address]; returns the txid.
  Future<String> pay(String address, String btc) async =>
      await rpc('sendtoaddress', [address, btc], 'miner') as String;

  Future<List<String>> mempool() async =>
      List<String>.from(await rpc('getrawmempool') as List);

  /// The node's decoded view of [txid] (it runs with -txindex).
  Future<Map<String, dynamic>> transaction(String txid) async =>
      Map<String, dynamic>.from(
        await rpc('getrawtransaction', [txid, true]) as Map,
      );

  /// Waits until the indexer serves the same tip as bitcoind.
  Future<void> waitForIndexer() async {
    final target = await height();
    await _until('$indexer at height $target', () async {
      try {
        final header = await electrum('blockchain.headers.subscribe') as Map;
        return header['height'] == target;
      } on Object {
        return false;
      }
    });
  }

  /// Waits until the indexer lists [txid] in the history of [address], and no
  /// longer lists [replaced]. electrs can serve a replaced tx for a moment
  /// after its replacement appears.
  Future<void> waitForHistory(
    String address,
    String txid, {
    required coinlib.Network network,
    String? replaced,
  }) async {
    final script = coinlib.Address.fromString(address, network).program.script;
    final hash = coinlib.sha256Hash(script.compiled).reversed.toList();
    final scripthash = coinlib.bytesToHex(Uint8List.fromList(hash));
    await _until('$indexer history of $address to list $txid', () async {
      final history = await electrum('blockchain.scripthash.get_history', [
        scripthash,
      ]) as List;
      final txids = history.map((e) => (e as Map)['tx_hash']).toSet();
      return txids.contains(txid) && !txids.contains(replaced);
    });
  }

  /// One Electrum protocol call on a fresh connection.
  Future<dynamic> electrum(
    String method, [
    List<dynamic> params = const [],
  ]) async {
    final socket = await Socket.connect('127.0.0.1', electrumPort);
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
        throw StateError('$indexer $method: ${body['error']}');
      }
      return body['result'];
    } finally {
      socket.destroy();
    }
  }

  Future<void> _until(
    String what,
    Future<bool> Function() check, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final end = DateTime.now().add(timeout);
    while (!await check()) {
      for (final (name, process) in [
        ('bitcoind', _bitcoind),
        (_indexerName, _indexer),
      ]) {
        final code = await process?.exitCode.timeout(
          Duration.zero,
          onTimeout: () => -1,
        );
        if (code != null && code != -1) {
          throw StateError(
            '$name exited with $code waiting for $what\n$logTail',
          );
        }
      }
      if (DateTime.now().isAfter(end)) {
        throw TimeoutException('Timed out waiting for $what\n$logTail');
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> stop() async {
    _indexer?.kill();
    if (_bitcoind != null) {
      try {
        await rpc('stop');
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
    _http.close(force: true);
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
