import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/zcash_regtest/zcash_migration_matrix.dart';
import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';

void main() {
  test('matrix exposes all production migration paths', () {
    expect(zcashStagedMigrationMatrix.map((entry) => entry.name), [
      'sapling-to-ironwood',
      'orchard-to-ironwood',
      'transparent-to-ironwood',
    ]);
    expect(
      zcashStagedMigrationMatrix.every((entry) => entry.isProductionSupported),
      isTrue,
    );
    expect(zcashStagedMigrationMatrix[1].sourcePool, ZcashRegtestPool.orchard);
    expect(
      zcashStagedMigrationMatrix.last.sourcePool,
      ZcashRegtestPool.transparent,
    );
    expect(() {
      for (final migrationCase in zcashStagedMigrationMatrix) {
        migrationCase.requireProductionSupport();
      }
    }, returnsNormally);
  });
}
