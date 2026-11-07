import 'package:grin/grin.dart' show GrinAddressKind;

import '../../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../../utilities/tor_plain_net_option_enum.dart';

/// How node and HTTP traffic of a Grin wallet leaves the device.
sealed class GrinTransport {
  const GrinTransport();
}

/// No proxy.
final class GrinDirect extends GrinTransport {
  const GrinDirect();

  @override
  bool operator ==(Object other) => other is GrinDirect;

  @override
  int get hashCode => (GrinDirect).hashCode;

  @override
  String toString() => "GrinDirect";
}

/// Through the SOCKS proxy at [address] (`host:port`).
final class GrinProxy extends GrinTransport {
  const GrinProxy(this.address);

  final String address;

  @override
  bool operator ==(Object other) =>
      other is GrinProxy && other.address == address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => "GrinProxy($address)";
}

enum GrinBlockedReason {
  torOnlyNodeTorOff,
  clearnetNodeTorOn,
  torDown,
  invalidNode,
}

/// No network at all.
final class GrinBlocked extends GrinTransport {
  const GrinBlocked(this.reason);

  final GrinBlockedReason reason;

  @override
  bool operator ==(Object other) =>
      other is GrinBlocked && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => "GrinBlocked(${reason.name})";
}

/// Tor is connecting. Node calls wait and the applied transport stays.
final class GrinHold extends GrinTransport {
  const GrinHold();

  @override
  bool operator ==(Object other) => other is GrinHold;

  @override
  int get hashCode => (GrinHold).hashCode;

  @override
  String toString() => "GrinHold";
}

/// Whether [host] (with or without scheme, port and path) is an onion host.
bool isOnionHost(String host) {
  var rest = host.trim().toLowerCase();
  final scheme = rest.indexOf("://");
  if (scheme >= 0) rest = rest.substring(scheme + 3);
  final end = rest.indexOf(RegExp(r"[/:?#]"));
  if (end >= 0) rest = rest.substring(0, end);
  return rest.endsWith(".onion");
}

/// The transport policy for Grin node traffic.
///
/// Read every input at the moment the transport is applied, never from the
/// event that triggered it: Tor events arrive before the preference they
/// belong to changes. [proxyAddress] is read only when a proxy is used, so
/// the port is always current; null means the proxy is not available.
GrinTransport resolveGrinTransport({
  required bool torFeature,
  required bool useTor,
  required TorConnectionStatus torStatus,
  required bool killSwitch,
  required TorPlainNetworkOption nodeNetOption,
  required bool nodeIsOnion,
  required String? Function() proxyAddress,
}) {
  final torOnlyNode = nodeNetOption == TorPlainNetworkOption.tor || nodeIsOnion;

  if (!(torFeature && useTor)) {
    return torOnlyNode
        ? const GrinBlocked(GrinBlockedReason.torOnlyNodeTorOff)
        : const GrinDirect();
  }

  if (nodeNetOption == TorPlainNetworkOption.clear) {
    return const GrinBlocked(GrinBlockedReason.clearnetNodeTorOn);
  }

  switch (torStatus) {
    case TorConnectionStatus.connected:
      final address = proxyAddress();
      return address == null
          ? const GrinBlocked(GrinBlockedReason.torDown)
          : GrinProxy(address);

    case TorConnectionStatus.connecting:
      return const GrinHold();

    case TorConnectionStatus.disconnected:
      if (!killSwitch && !torOnlyNode) {
        // Clearnet fallback for node calls only. HTTP sends stay refused.
        return const GrinDirect();
      }
      return const GrinBlocked(GrinBlockedReason.torDown);
  }
}

enum GrinSendRefusal {
  /// The network is blocked for this wallet.
  blocked,

  /// The target needs Tor and Tor is off.
  torRequired,

  /// Tor is wanted but not connected.
  torDown,

  /// A clearnet target with Tor off needs the IP disclosure accepted.
  clearnetNotAcknowledged,

  /// An `http://` target needs the plaintext warning accepted.
  plaintextNotAcknowledged,

  /// Not something an HTTP send can reach.
  unsupportedTarget,
}

/// Why an HTTP send to a target of [kind] must not start under [transport],
/// or null when it may.
///
/// [torWanted] is the Tor feature and preference together. [isPlainHttp]
/// is an `http://` clearnet URL.
GrinSendRefusal? grinHttpSendRefusal({
  required GrinTransport transport,
  required bool torWanted,
  required GrinAddressKind? kind,
  required bool isPlainHttp,
  required bool clearnetAcknowledged,
  required bool plaintextAcknowledged,
}) {
  if (kind == null || kind == GrinAddressKind.unknown) {
    return GrinSendRefusal.unsupportedTarget;
  }
  if (transport is GrinBlocked) return GrinSendRefusal.blocked;
  if (transport is GrinHold) return GrinSendRefusal.torDown;

  final viaTor = transport is GrinProxy;
  if (torWanted && !viaTor) return GrinSendRefusal.torDown;

  switch (kind) {
    case GrinAddressKind.slatepack:
    case GrinAddressKind.onion:
      return viaTor ? null : GrinSendRefusal.torRequired;

    case GrinAddressKind.http:
      if (!viaTor && !clearnetAcknowledged) {
        return GrinSendRefusal.clearnetNotAcknowledged;
      }
      if (isPlainHttp && !plaintextAcknowledged) {
        return GrinSendRefusal.plaintextNotAcknowledged;
      }
      return null;

    case GrinAddressKind.unknown:
      return GrinSendRefusal.unsupportedTarget;
  }
}
