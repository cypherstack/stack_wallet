import 'package:flutter_test/flutter_test.dart';
import 'package:grin/grin.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_transport.dart';

GrinTransport resolve({
  bool feature = true,
  bool useTor = true,
  TorConnectionStatus status = TorConnectionStatus.connected,
  bool killSwitch = true,
  TorPlainNetworkOption option = TorPlainNetworkOption.both,
  bool onion = false,
  String? proxy = '127.0.0.1:9050',
}) {
  var proxyReads = 0;
  final result = resolveGrinTransport(
    torFeature: feature,
    useTor: useTor,
    torStatus: status,
    killSwitch: killSwitch,
    nodeNetOption: option,
    nodeIsOnion: onion,
    proxyAddress: () {
      proxyReads++;
      return proxy;
    },
  );
  if (status != TorConnectionStatus.connected) {
    expect(proxyReads, 0, reason: 'proxy read without being used');
  }
  return result;
}

void main() {
  const torOnlyOff = GrinBlocked(GrinBlockedReason.torOnlyNodeTorOff);
  const clearOn = GrinBlocked(GrinBlockedReason.clearnetNodeTorOn);
  const torDown = GrinBlocked(GrinBlockedReason.torDown);

  group('Tor off or not compiled in', () {
    for (final feature in [true, false]) {
      for (final useTor in [true, false]) {
        if (feature && useTor) continue;
        test('feature $feature, useTor $useTor', () {
          for (final status in TorConnectionStatus.values) {
            for (final killSwitch in [true, false]) {
              GrinTransport r(TorPlainNetworkOption o, {bool onion = false}) =>
                  resolve(
                    feature: feature,
                    useTor: useTor,
                    status: status,
                    killSwitch: killSwitch,
                    option: o,
                    onion: onion,
                  );
              expect(r(TorPlainNetworkOption.tor), torOnlyOff);
              expect(r(TorPlainNetworkOption.both, onion: true), torOnlyOff);
              expect(r(TorPlainNetworkOption.clear), const GrinDirect());
              expect(r(TorPlainNetworkOption.both), const GrinDirect());
            }
          }
        });
      }
    }
  });

  group('Tor on', () {
    test('a clearnet-only node is blocked whatever the status', () {
      for (final status in TorConnectionStatus.values) {
        expect(
          resolve(status: status, option: TorPlainNetworkOption.clear),
          clearOn,
        );
      }
    });

    test('connected uses the proxy, read at resolve time', () {
      expect(resolve(), const GrinProxy('127.0.0.1:9050'));
      expect(resolve(proxy: '127.0.0.1:9150'), const GrinProxy('127.0.0.1:9150'));
      expect(resolve(option: TorPlainNetworkOption.tor, onion: true),
          const GrinProxy('127.0.0.1:9050'));
      expect(resolve(proxy: null), torDown);
    });

    test('connecting holds', () {
      expect(resolve(status: TorConnectionStatus.connecting),
          const GrinHold());
    });

    test('disconnected with the kill switch is blocked', () {
      for (final option in [
        TorPlainNetworkOption.tor,
        TorPlainNetworkOption.both,
      ]) {
        expect(
          resolve(status: TorConnectionStatus.disconnected, option: option),
          torDown,
        );
      }
    });

    test('disconnected without the kill switch falls back for both only', () {
      GrinTransport r(TorPlainNetworkOption o, {bool onion = false}) => resolve(
        status: TorConnectionStatus.disconnected,
        killSwitch: false,
        option: o,
        onion: onion,
      );
      expect(r(TorPlainNetworkOption.both), const GrinDirect());
      expect(r(TorPlainNetworkOption.tor), torDown);
      expect(r(TorPlainNetworkOption.both, onion: true), torDown);
    });
  });

  group('HTTP send policy', () {
    GrinSendRefusal? refusal({
      GrinTransport transport = const GrinProxy('127.0.0.1:9050'),
      bool torWanted = true,
      GrinAddressKind? kind = GrinAddressKind.http,
      bool plain = false,
      bool clearnetAck = false,
      bool plaintextAck = false,
    }) => grinHttpSendRefusal(
      transport: transport,
      torWanted: torWanted,
      kind: kind,
      isPlainHttp: plain,
      clearnetAcknowledged: clearnetAck,
      plaintextAcknowledged: plaintextAck,
    );

    test('grin1 and onion targets need a connected proxy', () {
      for (final kind in [GrinAddressKind.slatepack, GrinAddressKind.onion]) {
        expect(refusal(kind: kind), isNull);
        expect(
          refusal(kind: kind, transport: const GrinDirect(), torWanted: false),
          GrinSendRefusal.torRequired,
        );
        expect(
          refusal(kind: kind, transport: const GrinDirect()),
          GrinSendRefusal.torDown,
        );
        expect(refusal(kind: kind, transport: const GrinHold()),
            GrinSendRefusal.torDown);
        expect(refusal(kind: kind, transport: clearOn),
            GrinSendRefusal.blocked);
      }
    });

    test('a clearnet target with Tor off needs the IP disclosure accepted', () {
      expect(
        refusal(transport: const GrinDirect(), torWanted: false),
        GrinSendRefusal.clearnetNotAcknowledged,
      );
      expect(
        refusal(
          transport: const GrinDirect(),
          torWanted: false,
          clearnetAck: true,
        ),
        isNull,
      );
    });

    test('Tor wanted but down refuses even an acknowledged clearnet send', () {
      expect(
        refusal(transport: const GrinDirect(), clearnetAck: true),
        GrinSendRefusal.torDown,
      );
      expect(refusal(transport: torDown, clearnetAck: true),
          GrinSendRefusal.blocked);
    });

    test('http:// needs the plaintext warning, even over Tor', () {
      expect(refusal(plain: true), GrinSendRefusal.plaintextNotAcknowledged);
      expect(refusal(plain: true, plaintextAck: true), isNull);
      expect(
        refusal(
          plain: true,
          transport: const GrinDirect(),
          torWanted: false,
          clearnetAck: true,
        ),
        GrinSendRefusal.plaintextNotAcknowledged,
      );
    });

    test('unknown targets are refused', () {
      expect(refusal(kind: null), GrinSendRefusal.unsupportedTarget);
      expect(refusal(kind: GrinAddressKind.unknown),
          GrinSendRefusal.unsupportedTarget);
    });
  });
}
