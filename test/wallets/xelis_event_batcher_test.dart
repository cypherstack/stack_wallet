import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/intermediate/xelis_event_batcher.dart';

const _interval = Duration(milliseconds: 20);
const _afterFlush = Duration(milliseconds: 60);

void main() {
  test('a burst of events flushes as one batch', () async {
    final batches = <XelisEventBatch<String>>[];
    final batcher = XelisEventBatcher<String>(
      flushInterval: _interval,
      flush: (batch) async => batches.add(batch),
    );

    batcher.queueTransaction('a');
    batcher.queueTransaction('b');
    batcher.queueTopoheightChanged();
    batcher.queueTopoheightChanged();
    batcher.queueBalanceChanged();

    expect(batches, isEmpty);
    await Future<void>.delayed(_afterFlush);

    expect(batches, hasLength(1));
    expect(batches.single.transactions, ['a', 'b']);
    expect(batches.single.topoheightChanged, isTrue);
    expect(batches.single.balanceChanged, isTrue);
  });

  test('events arriving after a flush start a new batch', () async {
    final batches = <XelisEventBatch<String>>[];
    final batcher = XelisEventBatcher<String>(
      flushInterval: _interval,
      flush: (batch) async => batches.add(batch),
    );

    batcher.queueTransaction('a');
    await Future<void>.delayed(_afterFlush);
    batcher.queueTransaction('b');
    await Future<void>.delayed(_afterFlush);

    expect(batches, hasLength(2));
    expect(batches[0].transactions, ['a']);
    expect(batches[1].transactions, ['b']);
    expect(batches[1].topoheightChanged, isFalse);
    expect(batches[1].balanceChanged, isFalse);
  });

  test('no flush runs while nothing is queued', () async {
    int flushCount = 0;
    XelisEventBatcher<String>(
      flushInterval: _interval,
      flush: (batch) async => flushCount++,
    );

    await Future<void>.delayed(_afterFlush);
    expect(flushCount, 0);
  });

  test('reset drops pending events and cancels the scheduled flush', () async {
    int flushCount = 0;
    final batcher = XelisEventBatcher<String>(
      flushInterval: _interval,
      flush: (batch) async => flushCount++,
    );

    batcher.queueTransaction('a');
    batcher.queueBalanceChanged();
    batcher.reset();

    await Future<void>.delayed(_afterFlush);
    expect(flushCount, 0);

    batcher.queueTransaction('b');
    await Future<void>.delayed(_afterFlush);
    expect(flushCount, 1);
  });

  test('delayed topoheight notifications read current height', () async {
    int daemonHeight = 100;
    int cachedHeight = 0;
    int liveHeightReads = 0;
    final batcher = XelisEventBatcher<void>(
      flushInterval: _interval,
      flush: (batch) async {
        if (batch.topoheightChanged) {
          liveHeightReads++;
          cachedHeight = daemonHeight;
        }
      },
    );

    batcher.queueTopoheightChanged();
    daemonHeight = 101;
    cachedHeight = daemonHeight;

    await Future<void>.delayed(_afterFlush);
    expect(cachedHeight, 101);
    expect(liveHeightReads, 1);
  });

  test('slow flush retains one trailing batch', () async {
    final releaseFirstFlush = Completer<void>();
    final batches = <XelisEventBatch<String>>[];
    final batcher = XelisEventBatcher<String>(
      flushInterval: _interval,
      flush: (batch) async {
        batches.add(batch);
        if (batches.length == 1) {
          await releaseFirstFlush.future;
        }
      },
    );

    batcher.queueTransaction('a');
    await Future<void>.delayed(_afterFlush);

    batcher.queueTransaction('b');
    batcher.queueTransaction('c');
    await Future<void>.delayed(_afterFlush);
    expect(batches, hasLength(1));

    releaseFirstFlush.complete();
    await Future<void>.delayed(_afterFlush);
    expect(batches, hasLength(2));
    expect(batches.last.transactions, ['b', 'c']);
  });
}
