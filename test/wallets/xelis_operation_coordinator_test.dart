import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/wallets/wallet/intermediate/xelis_operation_coordinator.dart';

void main() {
  test('concurrent refresh callers join one operation', () async {
    final coordinator = XelisOperationCoordinator(Mutex());
    final releaseRefresh = Completer<void>();
    int refreshCount = 0;

    final first = coordinator.refresh(() async {
      refreshCount++;
      await releaseRefresh.future;
    });
    final second = coordinator.refresh(() async {
      fail('the joined refresh operation must not run');
    });

    expect(identical(first, second), isTrue);
    await _flushMicrotasks();
    expect(refreshCount, 1);
    expect(coordinator.activeOperation, XelisOperation.refreshing);

    releaseRefresh.complete();
    await first;
    expect(coordinator.activeOperation, XelisOperation.idle);
  });

  test('refresh joins the latest queued synchronization', () async {
    final coordinator = XelisOperationCoordinator(Mutex());
    final releaseRefresh = Completer<void>();
    final releaseRescan = Completer<void>();
    final order = <String>[];

    final refresh = coordinator.refresh(() async {
      order.add('refresh:start');
      await releaseRefresh.future;
      order.add('refresh:end');
    });
    await _flushMicrotasks();

    final rescan = coordinator.rescan(() async {
      order.add('rescan:start');
      await releaseRescan.future;
      order.add('rescan:end');
    });
    final joined = coordinator.refresh(() async {
      fail('refresh must join the queued rescan');
    });

    expect(identical(joined, rescan), isTrue);
    releaseRefresh.complete();
    await refresh;
    await _flushMicrotasks();
    expect(order, ['refresh:start', 'refresh:end', 'rescan:start']);

    releaseRescan.complete();
    await rescan;
    expect(order, [
      'refresh:start',
      'refresh:end',
      'rescan:start',
      'rescan:end',
    ]);
  });

  test('distinct rescans retain their requested order', () async {
    final coordinator = XelisOperationCoordinator(Mutex());
    final releaseFirst = Completer<void>();
    final order = <String>[];

    final first = coordinator.rescan(() async {
      order.add('first:start');
      await releaseFirst.future;
      order.add('first:end');
    });
    await _flushMicrotasks();

    final second = coordinator.rescan(() async {
      order.add('second');
    });
    final joined = coordinator.refresh(() async {
      fail('refresh must join the most recently queued rescan');
    });

    expect(identical(first, second), isFalse);
    expect(identical(joined, second), isTrue);
    releaseFirst.complete();
    await Future.wait([first, second]);
    expect(order, ['first:start', 'first:end', 'second']);
  });

  test('connect, exit, connect intent is preserved without polling', () async {
    final coordinator = XelisOperationCoordinator(Mutex());
    final releaseFirstConnect = Completer<void>();
    final releaseSecondConnect = Completer<void>();
    final order = <String>[];

    final firstConnect = coordinator.connect(() async {
      order.add('connect 1:start');
      await releaseFirstConnect.future;
      order.add('connect 1:end');
    });
    await _flushMicrotasks();

    final exit = coordinator.exit(() async {
      order.add('exit');
    });
    final secondConnect = coordinator.connect(() async {
      order.add('connect 2:start');
      await releaseSecondConnect.future;
      order.add('connect 2:end');
    });
    final joinedConnect = coordinator.connect(() async {
      fail('matching connect calls must join');
    });
    final joinedRefresh = coordinator.refresh(() async {
      fail('refresh must join the connect queued after exit');
    });
    bool staleEventRan = false;
    await coordinator.processEvent(() async {
      staleEventRan = true;
    });
    bool staleSyncEventRan = false;
    await coordinator.processSyncEvent(() async {
      staleSyncEventRan = true;
    });

    unawaited(joinedRefresh.then((_) => order.add('joined refresh done')));

    expect(identical(firstConnect, secondConnect), isFalse);
    expect(identical(secondConnect, joinedConnect), isTrue);
    expect(staleEventRan, isFalse);
    expect(staleSyncEventRan, isFalse);

    releaseFirstConnect.complete();
    await firstConnect;
    await _flushMicrotasks();
    expect(order, [
      'connect 1:start',
      'connect 1:end',
      'exit',
      'connect 2:start',
    ]);

    releaseSecondConnect.complete();
    await Future.wait([exit, secondConnect, joinedRefresh]);
    await _flushMicrotasks();
    expect(order.sublist(order.length - 2), [
      'connect 2:end',
      'joined refresh done',
    ]);
  });

  test('a reconnect can retain its distinct node-change intent', () async {
    final coordinator = XelisOperationCoordinator(Mutex());
    final releaseFirstConnect = Completer<void>();
    final order = <String>[];

    final firstConnect = coordinator.connect(() async {
      order.add('connect');
      await releaseFirstConnect.future;
    });
    await _flushMicrotasks();

    final reconnect = coordinator.connect(() async {
      order.add('reconnect');
    }, joinExisting: false);

    expect(identical(firstConnect, reconnect), isFalse);
    releaseFirstConnect.complete();
    await Future.wait([firstConnect, reconnect]);
    expect(order, ['connect', 'reconnect']);
  });

  test(
    'exit suppresses new updates and releases the queue for later work',
    () async {
      final coordinator = XelisOperationCoordinator(Mutex());
      final releaseEvent = Completer<void>();
      final order = <String>[];

      final event = coordinator.processEvent(() async {
        order.add('event:start');
        await releaseEvent.future;
        order.add('event:end');
      });
      await _flushMicrotasks();

      final exit = coordinator.exit(() async {
        order.add('exit');
      });
      await expectLater(
        coordinator.rescan(() async {
          fail('rescans scheduled while exiting must not run');
        }),
        throwsStateError,
      );
      await coordinator.processEvent(() async {
        fail('events scheduled while exiting must be ignored');
      });
      await coordinator.refresh(() async {
        fail('refreshes scheduled while exiting must be ignored');
      });

      releaseEvent.complete();
      await Future.wait([event, exit]);

      await coordinator.refresh(() async {
        order.add('refresh');
      });
      expect(order, ['event:start', 'event:end', 'exit', 'refresh']);
    },
  );

  test(
    'refresh callers joining a failing connect see the same error',
    () async {
      final coordinator = XelisOperationCoordinator(Mutex());
      final failure = StateError('connect failed');
      final releaseConnect = Completer<void>();

      final connect = coordinator.connect(() async {
        await releaseConnect.future;
        throw failure;
      });
      await _flushMicrotasks();

      final joined = coordinator.refresh(() async {
        fail('refresh must join the in-flight connect');
      });
      expect(identical(joined, connect), isTrue);

      final connectExpectation = expectLater(connect, throwsA(same(failure)));
      final joinedExpectation = expectLater(joined, throwsA(same(failure)));
      releaseConnect.complete();
      await Future.wait([connectExpectation, joinedExpectation]);

      bool nextRefreshRan = false;
      await coordinator.refresh(() async {
        nextRefreshRan = true;
      });
      expect(nextRefreshRan, isTrue);
    },
  );

  test('connect-time sync events complete before exit', () async {
    final coordinator = XelisOperationCoordinator(Mutex());
    const timeout = Duration(seconds: 5);
    final order = <String>[];
    late Future<void> onlineEvent;
    late Future<void> historySyncedEvent;

    final connect = coordinator.connect(() async {
      order.add('connect');
      onlineEvent = coordinator.processSyncEvent(() async {
        fail('the online event must join connect');
      });
      historySyncedEvent = coordinator.processSyncEvent(() async {
        fail('the history synced event must join connect');
      });
    });
    await connect.timeout(timeout);
    await Future.wait([onlineEvent, historySyncedEvent]).timeout(timeout);
    await coordinator
        .exit(() async {
          order.add('exit');
        })
        .timeout(timeout);

    expect(order, ['connect', 'exit']);
  });

  test('a failed operation does not latch the queue or join state', () async {
    final coordinator = XelisOperationCoordinator(Mutex());
    final failure = StateError('refresh failed');

    await expectLater(
      coordinator.refresh(() async {
        throw failure;
      }),
      throwsA(same(failure)),
    );

    bool nextRefreshRan = false;
    await coordinator.refresh(() async {
      nextRefreshRan = true;
    });

    expect(nextRefreshRan, isTrue);
    expect(coordinator.activeOperation, XelisOperation.idle);
  });
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);
