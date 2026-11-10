// Starts bitcoind and an Electrum server for the Bitcoin regtest integration
// tests and keeps them running until stdin closes or the process is told to
// stop. Used by scripts/test_bitcoin_regtest.sh for targets that cannot start
// processes themselves (the sandboxed macOS app, iOS and Android).
//
//   dart run scripts/bitcoin_regtest_nodes.dart \
//     --bitcoind PATH --indexer electrs|fulcrum --indexer-path PATH
//
// Once ready it prints one line, "REGTEST_READY <json>", with the RPC port,
// user and password and the Electrum port, all on 127.0.0.1.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../integration_test/bitcoin_regtest/regtest_nodes.dart';

Future<void> main(List<String> args) async {
  final options = <String, String>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    if (!args[i].startsWith('--')) break;
    options[args[i].substring(2)] = args[i + 1];
  }
  final bitcoind = options['bitcoind'];
  final indexer = options['indexer'] ?? 'electrs';
  final indexerPath = options['indexer-path'];
  if (bitcoind == null || indexerPath == null) {
    stderr.writeln(
      'usage: bitcoin_regtest_nodes.dart --bitcoind PATH '
      '--indexer electrs|fulcrum --indexer-path PATH',
    );
    exit(64);
  }

  final RegtestNodes nodes;
  try {
    nodes = await RegtestNodes.start(
      bitcoind: bitcoind,
      indexer: indexer,
      indexerPath: indexerPath,
    );
  } catch (e) {
    stderr.writeln('REGTEST_FAILED $e');
    exit(1);
  }
  final ready = {
    'rpcPort': nodes.rpcPort,
    'rpcUser': RegtestNodes.rpcUser,
    'rpcPassword': nodes.rpcPassword,
    'electrumPort': nodes.electrumPort,
    'indexer': indexer,
  };
  stdout.writeln('REGTEST_READY ${jsonEncode(ready)}');

  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  stdin.listen((_) {}, onDone: finish, onError: (_) => finish());
  final signals = [
    ProcessSignal.sigint,
    if (!Platform.isWindows) ProcessSignal.sigterm,
  ];
  final subscriptions = [
    for (final signal in signals) signal.watch().listen((_) => finish()),
  ];
  await done.future;
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
  await nodes.stop();
  stderr.writeln(nodes.logTail.isEmpty ? '' : '--- node log\n${nodes.logTail}');
  exit(0);
}
