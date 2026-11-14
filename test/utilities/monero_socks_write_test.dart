import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/test_monero_node_connection.dart';

class _Reader {
  _Reader(Socket socket) : input = StreamQueue(socket);
  final StreamQueue<List<int>> input;
  final bytes = <int>[];
  Future<List<int>> take(int count) async {
    while (bytes.length < count) {
      bytes.addAll(await input.next);
    }
    final result = bytes.sublist(0, count);
    bytes.removeRange(0, count);
    return result;
  }
}

void main() {
  test('Monero handles SOCKS resets without uncaught write errors', () async {
    final logs = await Directory.systemTemp.createTemp(
      'monero_dependency_probe',
    );
    await Logging.instance.initialize(logs.path, level: Level.off);
    final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final peers = <Socket>[];
    final handlers = <Future<void>>[];
    var accepted = 0;
    final subscription = proxy.listen((socket) {
      peers.add(socket);
      final ordinal = accepted++;
      final handler = () async {
        final reader = _Reader(socket);
        try {
          final greeting = await reader.take(2);
          await reader.take(greeting[1]);
          socket.add([5, 0]);
          final connect = await reader.take(4);
          if (connect[3] == 3) {
            await reader.take((await reader.take(1)).single);
          } else {
            await reader.take(4);
          }
          await reader.take(2);
          socket.add([5, 0, 0, 1, 127, 0, 0, 1, 0, 0]);
          await socket.flush();
          if (ordinal % 3 != 0) {
            await Future<void>.delayed(Duration(milliseconds: ordinal % 3));
          }
          final linger = Int32List.fromList([1, 0]);
          socket.setRawOption(
            RawSocketOption(
              RawSocketOption.levelSocket,
              Platform.isMacOS ? 0x0080 : 13,
              linger.buffer.asUint8List(),
            ),
          );
          socket.destroy();
        } catch (_) {
          socket.destroy();
        } finally {
          await reader.input.cancel();
        }
      }();
      handlers.add(handler);
    });
    addTearDown(() async {
      for (final peer in peers) {
        peer.destroy();
      }
      await subscription.cancel();
      await proxy.close();
      await Future.wait(handlers);
      await logs.delete(recursive: true);
    });

    final results = <Map<String, Object?>>[];
    for (var i = 0; i < 15; i++) {
      final uncaught = <String>[];
      final completed = Completer<Map<String, Object?>>();
      runZonedGuarded(
        () async {
          Object? outcome;
          try {
            outcome = (await testMoneroNodeConnection(
              Uri.parse('http://node.example.onion:18081/json_rpc'),
              null,
              null,
              false,
              proxyInfo: (host: InternetAddress.loopbackIPv4, port: proxy.port),
            ).timeout(const Duration(milliseconds: 500))).success;
          } catch (error) {
            outcome = error.runtimeType.toString();
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
          completed.complete({'outcome': outcome, 'uncaught': uncaught});
        },
        (Object error, StackTrace stack) {
          uncaught.add('${error.runtimeType}: $error');
        },
      );
      results.add(await completed.future.timeout(const Duration(seconds: 2)));
    }
    expect(results, hasLength(15));
    expect(
      results.expand((result) => result['uncaught'] as List<String>),
      isEmpty,
    );
  });
}
