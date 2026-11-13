import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/zcash_regtest/zcash_migration_matrix.dart';
import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';

void main() {
  test('matrix exposes both production migration paths', () {
    expect(zcashStagedMigrationMatrix.map((entry) => entry.name), [
      'sapling-to-ironwood',
      'orchard-to-ironwood',
    ]);
    expect(zcashStagedMigrationMatrix.first.isProductionSupported, isTrue);
    expect(zcashStagedMigrationMatrix.last.isProductionSupported, isTrue);
    expect(
      zcashStagedMigrationMatrix.last.sourcePool,
      ZcashRegtestPool.orchard,
    );
    expect(
      zcashStagedMigrationMatrix.last.requireProductionSupport,
      returnsNormally,
    );
  });
}
