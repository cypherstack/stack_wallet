/// Stack-owned projections. These types keep non-XEL builds independent of the
/// optional native package and keep atomic values exact up to persistence/UI.
final class XelisTransfer {
  const XelisTransfer({
    required this.destination,
    required this.amountAtomic,
    required this.asset,
  });

  final String destination;
  final BigInt amountAtomic;
  final String asset;
}

final class XelisPreparedTransfer {
  const XelisPreparedTransfer({
    required this.destination,
    required this.amountAtomic,
    required this.asset,
    required this.hasExtraData,
  });

  final String destination;
  final BigInt amountAtomic;
  final String asset;
  final bool hasExtraData;
}

/// Retained only in memory. The value is the exact authored XWF object, never
/// reconstructed from a hash, serialized TxData or a displayed projection.
final class XelisPreparedTransaction {
  XelisPreparedTransaction({
    required Object handle,
    required this.hash,
    required this.feeAtomic,
    required List<XelisPreparedTransfer> transfers,
  }) : _handle = handle,
       transfers = List.unmodifiable(transfers);

  final Object _handle;
  final String hash;
  final BigInt feeAtomic;
  final List<XelisPreparedTransfer> transfers;

  T handle<T>() => _handle as T;
}

enum XelisBroadcastDisposition {
  submitted,
  retryable,
  rejected,
  localFailure,
  submittedNeedsResync,
}

final class XelisBroadcastOutcome {
  const XelisBroadcastOutcome(this.disposition, {this.failure});

  final XelisBroadcastDisposition disposition;

  /// The original structured package failure, including its original XWF ID.
  final Object? failure;

  bool get wasSubmitted =>
      disposition == XelisBroadcastDisposition.submitted ||
      disposition == XelisBroadcastDisposition.submittedNeedsResync;
}

final class XelisDaemonSnapshot {
  const XelisDaemonSnapshot({
    required this.topoheight,
    required this.stableTopoheight,
    required this.prunedTopoheight,
  });

  final BigInt topoheight;
  final BigInt stableTopoheight;
  final BigInt? prunedTopoheight;
}

/// Converts only at Stack's signed-64-bit persistence boundary. BigInt.toInt()
/// can clamp out-of-range values, so it must never be used unchecked here.
int xelisStorageInt(BigInt value) {
  if (value < BigInt.zero || value > BigInt.parse('9223372036854775807')) {
    throw RangeError('Xelis value does not fit Stack storage');
  }
  return value.toInt();
}

/// XWF accepts a credential-free origin; it appends its own RPC path.
String xelisDaemonOrigin({
  required String host,
  required int port,
  required bool useSSL,
}) {
  final normalizedHost = host.trim();
  if (normalizedHost.isEmpty ||
      normalizedHost.contains(RegExp(r'[\s/@?#]')) ||
      normalizedHost.contains('://') ||
      port < 1 ||
      port > 65535) {
    throw ArgumentError('Invalid Xelis daemon host or port');
  }
  return Uri(
    scheme: useSSL ? 'https' : 'http',
    host: normalizedHost,
    port: port,
  ).toString();
}
