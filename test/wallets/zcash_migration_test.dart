import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_migration.dart';

void main() {
  test('overview exposes only production-safe migration routes', () {
    const overview = ZcashMigrationOverview(
      chainHeight: 42,
      transparentSpendableZatoshis: 100000,
      saplingSpendableZatoshis: 200000,
      orchardMigratableZatoshis: 300000,
      ironwoodSpendableZatoshis: 400000,
    );

    expect(overview.availableRoutes, {
      ZcashMigrationRoute.transparentToIronwood,
      ZcashMigrationRoute.saplingToIronwood,
      ZcashMigrationRoute.ironwoodToTransparent,
    });
    expect(overview.orchardIsScheduledOnly, isTrue);
  });
}
