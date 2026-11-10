import 'dart:async';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import 'regtest_nodes.dart';

const _indexerName = String.fromEnvironment('INDEXER', defaultValue: 'electrs');

// Spawned by the test: binaries.
const _bitcoindPath = String.fromEnvironment('BITCOIND');
const _indexerPaths = {
  'electrs': String.fromEnvironment('ELECTRS'),
  'fulcrum': String.fromEnvironment('FULCRUM'),
};

// Run on the host by scripts/bitcoin_regtest_nodes.dart: where to reach them.
const _rpcHost = String.fromEnvironment('REGTEST_RPC_HOST');
const _rpcPort = int.fromEnvironment('REGTEST_RPC_PORT');
const _rpcUser = String.fromEnvironment('REGTEST_RPC_USER');
const _rpcPassword = String.fromEnvironment('REGTEST_RPC_PASSWORD');
const _electrumHost = String.fromEnvironment('REGTEST_ELECTRUM_HOST');
const _electrumPort = int.fromEnvironment('REGTEST_ELECTRUM_PORT');

/// A private bitcoind regtest chain with an Electrum server in front of it.
/// --dart-define=INDEXER picks electrs (0.10, the default) or fulcrum.
///
/// Either the test starts the nodes itself (BITCOIND plus ELECTRS or FULCRUM
/// name the binaries; Linux and Windows desktop), or the runner script starts
/// them on the host and passes REGTEST_RPC_* and REGTEST_ELECTRUM_* (macOS,
/// whose app sandbox cannot run them, and mobile targets).
///
/// The node's own wallet ("miner", created with the nodes) holds the coinbase
/// coins and pays the
/// Stack wallets.
class RegtestChain {
  RegtestChain._(this._rpc, this.electrumHost, this.electrumPort, this._nodes);

  final RegtestRpc _rpc;
  final RegtestNodes? _nodes;

  /// Where the wallet under test reaches the Electrum server.
  final String electrumHost;
  final int electrumPort;

  /// The Electrum server in use: "electrs" or "fulcrum".
  String get indexer => _indexerName;
  late final String minerAddress;

  static bool get _hostNodes => _rpcPort != 0;

  static Future<RegtestChain> start() async {
    final RegtestChain chain;
    if (_hostNodes) {
      if (_electrumPort == 0 || _rpcPassword.isEmpty) {
        throw StateError(
          'REGTEST_RPC_PORT is set but REGTEST_ELECTRUM_PORT or '
          'REGTEST_RPC_PASSWORD is not.',
        );
      }
      final host = _rpcHost.isEmpty ? '127.0.0.1' : _rpcHost;
      chain = RegtestChain._(
        RegtestRpc(
          host: host,
          port: _rpcPort,
          user: _rpcUser.isEmpty ? RegtestNodes.rpcUser : _rpcUser,
          password: _rpcPassword,
        ),
        _electrumHost.isEmpty ? host : _electrumHost,
        _electrumPort,
        null,
      );
    } else {
      final indexerPath = _indexerPaths[_indexerName];
      if (indexerPath == null) {
        throw StateError('INDEXER must be one of ${_indexerPaths.keys}.');
      }
      for (final (name, path) in [
        ('BITCOIND', _bitcoindPath),
        (_indexerName.toUpperCase(), indexerPath),
      ]) {
        if (path.isEmpty) {
          throw StateError(
            'Pass --dart-define=$name=<path>, or run the nodes on the host '
            'with scripts/test_bitcoin_regtest.sh.',
          );
        }
      }
      final nodes = await RegtestNodes.start(
        bitcoind: _bitcoindPath,
        indexer: _indexerName,
        indexerPath: indexerPath,
      );
      chain = RegtestChain._(nodes.rpc, '127.0.0.1', nodes.electrumPort, nodes);
    }
    try {
      await chain._setUpMiner();
    } catch (_) {
      await chain.stop();
      rethrow;
    }
    return chain;
  }

  Future<void> _setUpMiner() async {
    final wallets = List<String>.from(await rpc('listwallets') as List);
    if (!wallets.contains('miner')) {
      try {
        await rpc('loadwallet', ['miner']);
      } on StateError {
        await rpc('createwallet', ['miner']);
      }
    }
    minerAddress = await rpc('getnewaddress', [], 'miner') as String;
    final tip = await height();
    if (tip < 101) {
      await rpc('generatetoaddress', [101 - tip, minerAddress]);
    }
    await waitForIndexer();
  }

  /// The last lines the nodes printed, for failure messages.
  String get logTail =>
      _nodes?.logTail ?? '(the runner script started the nodes; see its log)';

  /// A bitcoind JSON-RPC call, against [wallet] when given.
  Future<dynamic> rpc(
    String method, [
    List<dynamic> params = const [],
    String? wallet,
  ]) => _rpc.call(method, params, wallet);

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

  /// One Electrum protocol call on a fresh connection.
  Future<dynamic> electrum(String method, [List<dynamic> params = const []]) =>
      electrumCall(electrumHost, electrumPort, method, params);

  /// Waits until the indexer serves the same tip as bitcoind.
  Future<void> waitForIndexer() async {
    final target = await height();
    await pollUntil('$indexer at height $target', () async {
      try {
        final header = await electrum('blockchain.headers.subscribe') as Map;
        return header['height'] == target;
      } on Object {
        return false;
      }
    }, context: () => logTail);
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
    await pollUntil('$indexer history of $address to list $txid', () async {
      final history = await electrum('blockchain.scripthash.get_history', [
        scripthash,
      ]) as List;
      final txids = history.map((e) => (e as Map)['tx_hash']).toSet();
      return txids.contains(txid) && !txids.contains(replaced);
    }, context: () => logTail);
  }

  /// Stops nodes this test started. Host-run nodes belong to the runner.
  Future<void> stop() async {
    if (_nodes != null) {
      await _nodes.stop();
    } else {
      _rpc.close();
    }
  }
}
