import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

/// Public-key-only BIP-44 transparent receiver discovery.
///
/// Lightwalletd's transparent transaction RPC accepts one address at a time,
/// so discovery registers and queries bounded batches. A scope stops after
/// [gapLimit] consecutive child indexes without transaction activity. The
/// registered inventory is persisted by [ZcashWalletStateController], making
/// its highest contiguous child the durable discovery frontier.
final class ZcashTransparentReceiverDiscovery {
  ZcashTransparentReceiverDiscovery({
    required this.network,
    required this.viewingKeys,
    this.gapLimit = 20,
    this.hardChildLimit = 1000,
  }) {
    if (gapLimit < 1) {
      throw ArgumentError.value(gapLimit, 'gapLimit', 'must be positive');
    }
    if (hardChildLimit < gapLimit) {
      throw ArgumentError.value(
        hardChildLimit,
        'hardChildLimit',
        'must be at least the gap limit',
      );
    }
  }

  final zcash.ZcashNetwork network;
  final zcash.ZcashViewingKeys viewingKeys;
  final int gapLimit;

  /// Exclusive child-index ceiling. This bounds server queries, startup time,
  /// and the address linkage disclosed to one lightwalletd endpoint.
  final int hardChildLimit;

  List<zcash.ZcashTransparentReceiver> initialReceivers() => [
    ...deriveRange(zcash.ZcashTransparentReceiverScope.external, 0, gapLimit),
    ...deriveRange(zcash.ZcashTransparentReceiverScope.internal, 0, gapLimit),
  ];

  List<zcash.ZcashTransparentReceiver> deriveRange(
    zcash.ZcashTransparentReceiverScope scope,
    int start,
    int endExclusive,
  ) {
    if (start < 0 || endExclusive < start || endExclusive > hardChildLimit) {
      throw RangeError.range(
        endExclusive,
        start,
        hardChildLimit,
        'endExclusive',
      );
    }
    final transparent = viewingKeys.transparent;
    final viewingKey = switch (scope) {
      zcash.ZcashTransparentReceiverScope.external => transparent.externalIvk,
      zcash.ZcashTransparentReceiverScope.internal => transparent.internalIvk,
    };
    if (!transparent.available || viewingKey == null || viewingKey.isEmpty) {
      throw StateError(
        'Transparent receiver discovery requires public viewing material',
      );
    }
    final keyScope = switch (scope) {
      zcash.ZcashTransparentReceiverScope.external =>
        zcash.ZcashTransparentKeyScope.external,
      zcash.ZcashTransparentReceiverScope.internal =>
        zcash.ZcashTransparentKeyScope.internal,
    };
    return [
      for (var child = start; child < endExclusive; child++)
        zcash.ZcashTransparentReceiver(
          address: zcash.deriveNativeTransparentAddressFromViewingKey(
            viewingKeyHex: viewingKey,
            network: network,
            childIndex: child,
            scope: keyScope,
          ),
          scope: scope,
          childIndex: child,
        ),
    ];
  }
}
