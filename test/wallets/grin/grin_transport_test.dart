import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_status_changed_event.dart';
import 'package:stackwallet/utilities/amount/amount.dart';

import '../support/grin_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create(restoreHeight: 10);
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Future<void> settle() => pumpEventQueue(times: 50);

  test('the config carries the transport resolved at open', () async {
    h.prefs.tor = true;
    h.tor.current = TorConnectionStatus.connected;
    await h.wallet.init();
    final config = h.backend.creates.single.config;
    expect(config.socksProxy, '127.0.0.1:9050');
    expect(config.networkEnabled, isTrue);
    expect(config.nodeUrl, 'https://grinnode.live:3413');
  });

  test(
    'blocked at open means network disabled, never a direct socket',
    () async {
      h.prefs.tor = true;
      h.tor.current = TorConnectionStatus.disconnected;
      await h.wallet.init();
      final config = h.backend.creates.single.config;
      expect(config.networkEnabled, isFalse);
      expect(config.socksProxy, isNull);
    },
  );

  test('enabling Tor: events arrive before the preference flips', () async {
    await h.wallet.init();
    final api = h.backend.api;

    // connectTor fires connecting and connected while useTor is still false.
    h.tor.current = TorConnectionStatus.connecting;
    h.bus.fire(
      TorConnectionStatusChangedEvent(TorConnectionStatus.connecting, ''),
    );
    h.tor.current = TorConnectionStatus.connected;
    h.bus.fire(
      TorConnectionStatusChangedEvent(TorConnectionStatus.connected, ''),
    );
    await settle();
    expect(api.networkUpdates, isEmpty, reason: 'still direct');

    h.prefs.tor = true;
    h.bus.fire(TorPreferenceChangedEvent(status: TorStatus.enabled));
    await settle();
    expect(api.networkUpdates.single.socksProxy, '127.0.0.1:9050');
    expect(api.networkUpdates.single.networkEnabled, isTrue);
  });

  test(
    'disabling Tor: disconnected arrives while useTor is still true',
    () async {
      h.prefs.tor = true;
      h.tor.current = TorConnectionStatus.connected;
      await h.wallet.init();
      final api = h.backend.api;

      h.tor.current = TorConnectionStatus.disconnected;
      h.bus.fire(
        TorConnectionStatusChangedEvent(TorConnectionStatus.disconnected, ''),
      );
      await settle();
      // Kill switch on: blocked until the preference catches up.
      expect(api.networkUpdates.single.networkEnabled, isFalse);

      h.prefs.tor = false;
      h.bus.fire(TorPreferenceChangedEvent(status: TorStatus.disabled));
      await settle();
      expect(api.networkUpdates, hasLength(2));
      expect(api.networkUpdates.last.networkEnabled, isTrue);
      expect(api.networkUpdates.last.socksProxy, isNull);
    },
  );

  test('every blocked update disables the network', () async {
    await h.wallet.init();
    final api = h.backend.api;
    h.wallet.node = grinNode(tor: true, clear: false);
    await h.wallet.updateNode();
    h.prefs.tor = true;
    h.wallet.node = grinNode(tor: false, clear: true);
    await h.wallet.updateNode();
    h.wallet.node = grinNode();
    h.tor.current = TorConnectionStatus.disconnected;
    await h.wallet.updateNode();
    expect(api.networkUpdates, hasLength(3), reason: 'three blocked reasons');
    for (final update in api.networkUpdates) {
      expect(update.networkEnabled, isFalse);
    }
  });

  test('a node change cancels a running scan before updateNetwork', () async {
    h.backend.scanBlocks = true;
    await h.wallet.init(isRestore: true);
    await h.wallet.recover(isRescan: false);
    await settle();
    final api = h.backend.api;
    expect(api.scanRunning, isTrue);

    h.wallet.node = grinNode(host: 'https://other.node', secret: 'secret');
    await h.wallet.updateNode();
    final cancel = api.calls.indexOf('cancelScan');
    final update = api.calls.indexOf('updateNetwork');
    expect(cancel, greaterThanOrEqualTo(0));
    expect(update, greaterThan(cancel));
    expect(api.networkUpdates.single.nodeUrl, 'https://other.node:3413');
    expect(api.networkUpdates.single.apiSecret, 'secret');
  });

  test('node calls are refused while blocked', () async {
    await h.wallet.init();
    h.prefs.tor = true;
    h.tor.current = TorConnectionStatus.disconnected;
    await expectLater(h.wallet.updateChainHeight(), throwsException);
    await expectLater(
      h.wallet.estimateFeeFor(
        Amount(rawValue: BigInt.from(5), fractionDigits: 9),
        BigInt.one,
      ),
      throwsException,
    );
    expect(await h.wallet.pingCheck(), isFalse);
    expect(h.backend.nodeTests, isEmpty);
    expect(h.backend.api.calls, isNot(contains('estimateFee')));
  });

  test('the chain height comes from a stateless node test through the '
      'proxy', () async {
    h.prefs.tor = true;
    h.tor.current = TorConnectionStatus.connected;
    h.tor.port = 9150;
    await h.wallet.init();
    await h.wallet.updateChainHeight();
    expect(h.backend.nodeTests.single.socksProxy, '127.0.0.1:9150');
    expect(h.wallet.info.cachedChainHeight, 4096748);
  });
}
