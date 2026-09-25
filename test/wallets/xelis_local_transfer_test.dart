import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart' as xwf;

import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

// Devnet is a test fixture only.
class LocalTransferWallet extends XelisWallet {
  LocalTransferWallet(OpaqueXelisWallet handle)
    : super(CryptoCurrencyNetwork.test) {
    wallet = handle;
  }
  @override
  Future<void> refresh({int? topoheight}) async {}
}

class LocalRpcHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const executable = String.fromEnvironment('XELIS_LOCAL_DAEMON');
  test(
    'real normal and maximum transfers confirm reviewed hashes and balances',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'stack_xelis_local_transfer_',
      );
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();
      final endpoint = Uri.parse('http://127.0.0.1:$port/json_rpc');
      final client = LocalRpcHttp().createHttpClient(null)
        ..connectionTimeout = const Duration(seconds: 2);
      Process? daemon;
      final daemonTail = <String>[];
      final walletEvents = <String>[];
      String phase = 'daemon startup';
      final handles = <OpaqueXelisWallet>[];
      final subscriptions = <XelisEventSubscription>[];
      Future<dynamic> rpc(String method, [Map<String, dynamic>? params]) async {
        final request = await client.postUrl(endpoint);
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': method,
            if (params != null) 'params': params,
          }),
        );
        final response = await request.close();
        final result = jsonDecode(
          await utf8.decoder.bind(response).join(),
        ) as Map<String, dynamic>;
        if (result['error'] != null) {
          throw StateError('Local RPC $method failed: ${result['error']}');
        }
        return result['result'];
      }

      Future<void> eventually(Future<bool> Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 60));
        while (!await condition()) {
          if (DateTime.now().isAfter(deadline)) {
            throw TimeoutException(
              'Local wallet state did not converge: $phase',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      }

      try {
        daemon = await Process.start(File(executable).absolute.path, [
          '--network',
          'devnet',
          '--skip-pow-verification',
          '--disable-p2p-server',
          '--rpc-bind-address',
          '127.0.0.1:$port',
          '--dir-path',
          '${root.path}/chain/',
          '--disable-file-logging',
          '--disable-interactive-mode',
          '--disable-ascii-art',
          '--log-level',
          'debug',
        ], workingDirectory: root.path);
        void remember(String line) {
          daemonTail.add(line);
          if (daemonTail.length > 40) daemonTail.removeAt(0);
        }

        daemon.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(remember);
        daemon.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(remember);
        await eventually(() async {
          try {
            return (await rpc('get_info'))['network'] == 'devnet';
          } on SocketException {
            return false;
          }
        });
        await libXelis.initRustLib();
        final tablePath = '${root.path}/tables/';
        await Directory(tablePath).create();
        for (final name in ['sender', 'receiver', 'miner']) {
          final native = await xwf.XelisWalletFlutter.createWallet(
            walletPath: '${root.path}/$name',
            password: 'local-fixture-password',
            network: xwf.XelisNetwork.devnet,
            precomputedTableType: const xwf.XelisPrecomputedTableType.l1Low(),
            precomputedTablesPath: tablePath,
          );
          handles.add(OpaqueXelisWallet(native));
        }
        final sender = handles[0];
        final receiver = handles[1];
        final senderAddress = libXelis.getAddress(sender);
        final receiverAddress = libXelis.getAddress(receiver);
        final minerAddress = libXelis.getAddress(handles[2]);
        Future<void> mine(String address, int count) async {
          for (var i = 0; i < count; i++) {
            final template = await rpc('get_block_template', {
              'address': address,
            });
            await rpc('submit_block', {'block_template': template['template']});
          }
        }

        await mine(senderAddress, 1);
        // Mature the funding reward without adding new rewards to either party.
        await mine(minerAddress, 30);
        for (final handle in handles.take(2)) {
          final runtime = await libXelis.subscribeRuntimeEvents(handle);
          final business = await libXelis.subscribeBusinessEvents(handle);
          subscriptions.addAll([runtime, business]);
          void event(Event e) {
            walletEvents.add(
              e is XelisSyncIssue
                  ? 'sync issue: ${e.failure}'
                  : '${e.runtimeType}',
            );
            if (walletEvents.length > 40) walletEvents.removeAt(0);
          }

          runtime.events.listen(event);
          business.events.listen(event);
          await libXelis.onlineMode(
            handle,
            daemonAddress: 'http://127.0.0.1:$port',
          );
        }
        phase = 'sender funding';
        await eventually(
          () async =>
              (await libXelis.getXelisBalanceRaw(sender)) >
              BigInt.from(10000000),
        );
        final wallet = LocalTransferWallet(sender);
        final fundedBalance = await libXelis.getXelisBalanceRaw(sender);
        final reviewed = await wallet.prepareSend(
          txData: TxData(
            recipients: [
              TxRecipient(
                address: receiverAddress,
                amount: Amount(
                  rawValue: BigInt.from(10000000),
                  fractionDigits: 8,
                ),
                isChange: false,
                addressType: AddressType.xelis,
              ),
            ],
          ),
        );
        final prepared = reviewed.xelisPreparedTransaction!;
        expect(prepared.transfers.single.amountAtomic, BigInt.from(10000000));
        final sent = await wallet.confirmSend(txData: reviewed);
        expect(sent.txid, prepared.hash);
        await expectLater(
          wallet.confirmSend(txData: reviewed),
          throwsStateError,
        );
        await mine(minerAddress, 30);
        phase = 'receiver confirmation';
        await eventually(
          () async =>
              await libXelis.getXelisBalanceRaw(receiver) ==
              BigInt.from(10000000),
        );
        final received = (await libXelis.allHistory(receiver))
            .where((e) => e.hash == prepared.hash)
            .single;
        expect(received.topoheight, isNotNull);
        final outgoing = (await libXelis.allHistory(sender))
            .where((e) => e.hash == prepared.hash)
            .single;
        expect(outgoing.topoheight, isNotNull);
        expect(
          (outgoing.entryType as OutgoingEntryWrapper).fee,
          prepared.feeAtomic,
        );
        final remaining =
            fundedBalance - BigInt.from(10000000) - prepared.feeAtomic;
        phase = 'sender debit';
        await eventually(
          () async => await libXelis.getXelisBalanceRaw(sender) == remaining,
        );

        final maximum = await wallet.prepareSend(
          txData: TxData(
            recipients: [
              TxRecipient(
                address: receiverAddress,
                amount: Amount(rawValue: remaining, fractionDigits: 8),
                isChange: false,
                addressType: AddressType.xelis,
              ),
            ],
            xelisSendAll: true,
          ),
        );
        final maxPrepared = maximum.xelisPreparedTransaction!;
        final maxAmount = maxPrepared.transfers.single.amountAtomic;
        expect(maxAmount + maxPrepared.feeAtomic, remaining);
        expect(maximum.recipients!.single.amount.raw, maxAmount);
        expect(
          (await wallet.confirmSend(txData: maximum)).txid,
          maxPrepared.hash,
        );
        await mine(minerAddress, 30);
        phase = 'maximum confirmation';
        await eventually(
          () async =>
              await libXelis.getXelisBalanceRaw(sender) == BigInt.zero &&
              await libXelis.getXelisBalanceRaw(receiver) ==
                  BigInt.from(10000000) + maxAmount,
        );
        // A reconnection must replace the runtime channel while preserving
        // business events and the synchronized wallet state.
        phase = 'runtime channel rotation';
        final previousRuntime = subscriptions.first;
        await previousRuntime.cancel();
        subscriptions.remove(previousRuntime);
        await libXelis.offlineMode(sender);
        final replacement = await libXelis.subscribeRuntimeEvents(sender);
        subscriptions.add(replacement);
        final resynced = Completer<void>();
        replacement.events.listen((event) {
          if (event is HistorySynced && !resynced.isCompleted) {
            resynced.complete();
          }
        });
        await libXelis.onlineMode(
          sender,
          daemonAddress: 'http://127.0.0.1:$port',
        );
        await resynced.future.timeout(const Duration(seconds: 45));
        expect(await libXelis.isOnline(sender), isTrue);
        expect(await libXelis.getXelisBalanceRaw(sender), BigInt.zero);

        // Stop networking before reopening so persisted state, rather than
        // another synchronization, must satisfy the assertions.
        phase = 'offline reopen';
        while (subscriptions.isNotEmpty) {
          await subscriptions.last.cancel();
          subscriptions.removeLast();
        }
        while (handles.isNotEmpty) {
          await libXelis.closeWallet(handles.last);
          handles.removeLast();
        }
        daemon.kill();
        await daemon.exitCode;
        daemon = null;
        for (final name in ['sender', 'receiver']) {
          final reopened = await xwf.XelisWalletFlutter.openWallet(
            walletPath: '${root.path}/$name',
            password: 'local-fixture-password',
            network: xwf.XelisNetwork.devnet,
            precomputedTableType: const xwf.XelisPrecomputedTableType.l1Low(),
            precomputedTablesPath: tablePath,
          );
          handles.add(OpaqueXelisWallet(reopened));
        }
        expect(libXelis.getAddress(handles[0]), senderAddress);
        expect(libXelis.getAddress(handles[1]), receiverAddress);
        expect(await libXelis.getXelisBalanceRaw(handles[0]), BigInt.zero);
        expect(
          await libXelis.getXelisBalanceRaw(handles[1]),
          BigInt.from(10000000) + maxAmount,
        );
        for (final handle in handles) {
          final history = await libXelis.allHistory(handle);
          for (final transaction in [prepared, maxPrepared]) {
            final entry = history.singleWhere(
              (entry) => entry.hash == transaction.hash,
            );
            expect(entry.topoheight, isNotNull);
            if (identical(handle, handles[0])) {
              expect(
                (entry.entryType as OutgoingEntryWrapper).fee,
                transaction.feeAtomic,
              );
            }
          }
        }
      } catch (_) {
        // Only the isolated, synthetic chain is logged.
        printOnFailure(daemonTail.join('\n'));
        printOnFailure('Wallet events: $walletEvents');
        if (handles.length >= 2) {
          printOnFailure(
            'Sender raw balance: '
            '${await libXelis.getXelisBalanceRaw(handles[0])}',
          );
          printOnFailure(
            'Sender history entries: '
            '${(await libXelis.allHistory(handles[0])).length}',
          );
        }
        rethrow;
      } finally {
        try {
          await Future.wait(subscriptions.map((events) => events.cancel()));
        } finally {
          try {
            await Future.wait(handles.map(libXelis.closeWallet));
          } finally {
            client.close(force: true);
            daemon?.kill();
            await daemon?.exitCode;
            await root.delete(recursive: true);
          }
        }
      }
    },
    skip: executable.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
