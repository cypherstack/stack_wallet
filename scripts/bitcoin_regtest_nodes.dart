// Starts bitcoind and an Electrum server for the Bitcoin regtest integration
// tests and keeps them running until stdin closes (or, with --until-signal,
// until SIGINT or SIGTERM, or --stop-file PATH until that file exists).
// Used by scripts/test_bitcoin_regtest.sh for
// targets that cannot start processes themselves (the sandboxed macOS app,
// iOS and Android).
//
//   dart run scripts/bitcoin_regtest_nodes.dart \
//     --bitcoind PATH --indexer electrs|fulcrum --indexer-path PATH \
//     [--until-signal | --stop-file PATH]
//
// Once ready it prints one line, "REGTEST_READY <json>", with the RPC port,
// user and password and the Electrum port, all on 127.0.0.1.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../integration_test/bitcoin_regtest/regtest_nodes.dart';

Future<void> main(List<String> args) async {
  final untilSignal = args.contains('--until-signal');
  final rest = [...args]..remove('--until-signal');
  final options = <String, String>{};
  for (var i = 0; i + 1 < rest.length; i += 2) {
    if (!rest[i].startsWith('--')) break;
    options[rest[i].substring(2)] = rest[i + 1];
  }
  final bitcoind = options['bitcoind'];
  final indexer = options['indexer'] ?? 'electrs';
  final indexerPath = options['indexer-path'];
  final stopFile = options['stop-file'];
  if (bitcoind == null || indexerPath == null) {
    stderr.writeln(
      'usage: bitcoin_regtest_nodes.dart --bitcoind PATH '
      '--indexer electrs|fulcrum --indexer-path PATH '
      '[--until-signal | --stop-file PATH]',
    );
    exit(64);
  }

  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  if (!untilSignal && stopFile == null) {
    stdin.listen((_) {}, onDone: finish, onError: (_) => finish());
  }
  final stopTimer = stopFile == null
      ? null
      : Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (File(stopFile).existsSync()) finish();
        });
  final signals = [
    ProcessSignal.sigint,
    if (!Platform.isWindows) ProcessSignal.sigterm,
  ];
  final subscriptions = [
    for (final signal in signals) signal.watch().listen((_) => finish()),
  ];
  final RegtestNodes nodes;
  try {
    nodes = await RegtestNodes.start(
      bitcoind: bitcoind,
      indexer: indexer,
      indexerPath: indexerPath,
      cancellation: done.future,
    );
  } catch (e) {
    stopTimer?.cancel();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    if (!done.isCompleted) stderr.writeln('REGTEST_FAILED $e');
    exit(done.isCompleted ? 0 : 1);
  }
  final ready = {
    'rpcPort': nodes.rpcPort,
    'rpcUser': RegtestNodes.rpcUser,
    'rpcPassword': nodes.rpcPassword,
    'electrumPort': nodes.electrumPort,
    'indexer': indexer,
  };
  stdout.writeln('REGTEST_READY ${jsonEncode(ready)}');

  await done.future;
  stopTimer?.cancel();
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
  await nodes.stop();
  stderr.writeln(nodes.logTail.isEmpty ? '' : '--- node log\n${nodes.logTail}');
  exit(0);
}
