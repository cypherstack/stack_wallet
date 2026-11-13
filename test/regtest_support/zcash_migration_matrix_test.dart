import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/zcash_regtest/zcash_migration_matrix.dart';
import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';

void main() {
  test('matrix distinguishes production paths from ZIP-318 gap', () {
    expect(zcashStagedMigrationMatrix.map((entry) => entry.name), [
      'sapling-to-ironwood',
      'orchard-to-ironwood',
    ]);
    expect(zcashStagedMigrationMatrix.first.isProductionSupported, isTrue);
    expect(zcashStagedMigrationMatrix.last.isProductionSupported, isFalse);
    expect(
      zcashStagedMigrationMatrix.last.sourcePool,
      ZcashRegtestPool.orchard,
    );
    expect(
      () => zcashStagedMigrationMatrix.last.requireProductionSupport(),
      throwsA(
        isA<ZcashStackCapabilityUnavailableException>().having(
          (error) => error.capability,
          'capability',
          contains('ZIP-318'),
        ),
      ),
    );
  });
}
