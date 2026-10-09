import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/wl_gen/generated/tor_service_impl.dart';
import 'package:tor_ffi_plugin/tor_ffi_plugin.dart';

class _Tor extends Fake implements Tor {
  final disabled = Completer<void>();
  var stopCalls = 0;

  @override
  Future<void> start({required String torDataDirPath}) async {}

  @override
  Future<void> disable() => disabled.future;

  @override
  Future<void> stop() async => stopCalls++;
}

void main() {
  test(
    'disable waits for native teardown before reporting disconnected',
    () async {
      final tor = _Tor();
      final service = torService;
      // The generated implementation exposes the existing test injection hook.
      (service as dynamic).init(
        torDataDirPath: 'unused',
        mockableOverride: tor,
      );
      await service.start();
      expect(service.status, TorConnectionStatus.connected);

      var completed = false;
      final disabling = service.disable().then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(service.status, TorConnectionStatus.connected);

      tor.disabled.complete();
      await disabling;
      expect(service.status, TorConnectionStatus.disconnected);
      expect(tor.stopCalls, 0, reason: 'disable() owns native teardown');
    },
  );
}
