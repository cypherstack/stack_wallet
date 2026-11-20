enum ZcashMigrationRoute {
  transparentToIronwood,
  saplingToIronwood,
  ironwoodToTransparent,
}

class ZcashMigrationOverview {
  const ZcashMigrationOverview({
    required this.chainHeight,
    required this.transparentSpendableZatoshis,
    required this.saplingSpendableZatoshis,
    required this.orchardMigratableZatoshis,
    required this.ironwoodSpendableZatoshis,
  });

  final int chainHeight;
  final int transparentSpendableZatoshis;
  final int saplingSpendableZatoshis;
  final int orchardMigratableZatoshis;
  final int ironwoodSpendableZatoshis;

  Set<ZcashMigrationRoute> get availableRoutes => {
    if (transparentSpendableZatoshis > 0)
      ZcashMigrationRoute.transparentToIronwood,
    if (saplingSpendableZatoshis > 0) ZcashMigrationRoute.saplingToIronwood,
    // This is availability-only. The native ZIP 317 quote and positive
    // Ironwood-change requirement are enforced during exact preparation.
    if (ironwoodSpendableZatoshis > 0)
      ZcashMigrationRoute.ironwoodToTransparent,
  };

  bool get orchardIsScheduledOnly => orchardMigratableZatoshis > 0;
}
