import 'package:regtest_support/regtest_support.dart';

import 'zcash_stack_regtest_adapter.dart';

final class ZcashStagedMigrationCase {
  const ZcashStagedMigrationCase({
    required this.name,
    required this.sourcePool,
    required this.destinationPool,
    required this.expectedSelectedReceiver,
    required this.isProductionSupported,
  });

  final String name;
  final ZcashRegtestPool sourcePool;
  final ZcashRegtestPool destinationPool;
  final ZcashRegtestReceiver expectedSelectedReceiver;
  final bool isProductionSupported;

  void requireProductionSupport() {
    if (!isProductionSupported) {
      throw const ZcashStackCapabilityUnavailableException(
        'Orchard to Ironwood ZIP-318 migration',
      );
    }
  }
}

/// Production-backed migration cases. Unsupported rows remain in the matrix
/// so CI reports the capability gap instead of silently omitting a pool.
const zcashStagedMigrationMatrix = <ZcashStagedMigrationCase>[
  ZcashStagedMigrationCase(
    name: 'sapling-to-ironwood',
    sourcePool: ZcashRegtestPool.sapling,
    destinationPool: ZcashRegtestPool.ironwood,
    // ZIP 229 reuses the Orchard receiver bytes while consensus routes the
    // output into the Ironwood pool.
    expectedSelectedReceiver: ZcashRegtestReceiver.orchard,
    isProductionSupported: true,
  ),
  ZcashStagedMigrationCase(
    name: 'orchard-to-ironwood',
    sourcePool: ZcashRegtestPool.orchard,
    destinationPool: ZcashRegtestPool.ironwood,
    expectedSelectedReceiver: ZcashRegtestReceiver.orchard,
    isProductionSupported: false,
  ),
];

final class ZcashMigrationMatrixResult<Wallet> {
  const ZcashMigrationMatrixResult({
    required this.funded,
    required this.spendable,
    required this.activated,
    required this.prepared,
    required this.confirmed,
    required this.restarted,
    required this.restored,
  });

  final PreActivationFundingPhase<Wallet, ZcashRegtestPool, ZcashRegtestUpgrade>
  funded;
  final PoolSpendabilityPhase<Wallet, ZcashRegtestPool, ZcashRegtestUpgrade>
  spendable;
  final ActivatedMigrationPhase<Wallet, ZcashRegtestPool, ZcashRegtestUpgrade>
  activated;
  final PreparedMigrationPhase<
    Wallet,
    ZcashRegtestPool,
    ZcashStackPreparedTransfer
  >
  prepared;
  final ConfirmedMigrationPhase<
    Wallet,
    ZcashRegtestPool,
    ZcashStackPreparedTransfer
  >
  confirmed;
  final RestartedTransferPhase<Wallet, ZcashRegtestPool> restarted;
  final RestoredWalletPhase<Wallet, ZcashRegtestPool> restored;
}

/// Runs one staged case through the real typed scenario and checks each
/// independently observable boundary. The caller supplies a real spendability
/// probe because preparing a fake transaction would reserve wallet notes.
Future<ZcashMigrationMatrixResult<Wallet>>
runZcashMigrationCase<Wallet, Endpoint>({
  required PoolMigrationScenario<
    Wallet,
    Endpoint,
    ZcashRegtestPool,
    ZcashRegtestUpgrade,
    ZcashStackPreparedTransfer
  >
  scenario,
  required ZcashStagedMigrationCase migrationCase,
  required BigInt fundingValue,
  required BigInt migrationValue,
  required SpendabilityProbe<Wallet, ZcashRegtestPool> spendabilityProbe,
  required String restoreName,
  required String recoveryMaterial,
}) async {
  migrationCase.requireProductionSupport();
  final funded = await scenario.fundBeforeActivation(
    upgrade: ZcashRegtestUpgrade.nu63,
    value: fundingValue,
    sourcePool: migrationCase.sourcePool,
  );
  _require(
    funded.funded.receipt.address.isNotEmpty &&
        funded.funded.receipt.pool == migrationCase.sourcePool &&
        funded.funded.receipt.value == fundingValue,
    'preactivation funding did not preserve encoded receiver, pool, and value',
  );
  final spendable = await scenario.verifyOldPoolSpendability(
    upgrade: ZcashRegtestUpgrade.nu63,
    pool: migrationCase.sourcePool,
    probe: spendabilityProbe,
  );
  await scenario.advanceToPreActivation(ZcashRegtestUpgrade.nu63);
  final activated = await scenario.crossActivation(ZcashRegtestUpgrade.nu63);
  final prepared = await scenario.prepareMigration(
    value: migrationValue,
    sourcePool: migrationCase.sourcePool,
    destinationPool: migrationCase.destinationPool,
  );
  final native = prepared.transfer.prepared.native;
  _require(
    prepared.requestedReceiver == native.encodedAddress,
    'Stack review artifact changed the encoded destination address',
  );
  _require(
    prepared.requestedPool == migrationCase.destinationPool,
    'requested destination pool was not retained',
  );
  _require(
    native.selectedReceiver == migrationCase.expectedSelectedReceiver &&
        native.selectedReceiverAddress.isNotEmpty,
    'selected receiver does not match the staged routing policy',
  );
  _require(
    native.actualOutputPool == migrationCase.destinationPool,
    'prepared actual output pool differs from requested migration pool',
  );
  prepared.transfer.prepared.requireValueConserved();

  final confirmed = await scenario.confirmMigration(prepared);
  confirmed.confirmed.receipt.requireValueConserved();
  confirmed.confirmed.transaction.requireValueConserved();
  confirmed.requireActualDestinationPool(migrationCase.destinationPool);
  _require(
    confirmed.confirmed.receipt.fee == prepared.transfer.prepared.fee &&
        confirmed.confirmed.transaction.fee == prepared.transfer.prepared.fee,
    'prepared, wallet, and chain fee observations differ',
  );
  final sourceIds = {
    for (final source in prepared.transfer.prepared.sources) source.id,
  };
  _require(
    confirmed.confirmed.sourceAfter.spentIds.containsAll(sourceIds),
    'confirmed wallet state did not consume every prepared source',
  );
  final chainDestinations = confirmed.confirmed.transaction.outputs.where(
    (output) =>
        output.pool == migrationCase.destinationPool &&
        output.value == migrationValue,
  );
  _require(
    chainDestinations.isNotEmpty,
    'chain transaction did not confirm the requested value in the actual pool',
  );
  _require(
    confirmed.confirmed.destinationAfter.values.any(
      (value) =>
          value.txid == confirmed.confirmed.receipt.txid &&
          value.pool == migrationCase.destinationPool &&
          value.value == migrationValue &&
          value.state == ObservedValueState.available,
    ),
    'destination wallet did not discover the confirmed actual-pool output',
  );
  for (final change in confirmed.confirmed.receipt.changeOutputs) {
    _require(
      confirmed.confirmed.sourceAfter.values.any(
        (value) =>
            value.txid == confirmed.confirmed.receipt.txid &&
            value.pool == change.pool &&
            value.value == change.value &&
            value.state == ObservedValueState.available &&
            value.isChange,
      ),
      'wallet did not observe confirmed change in ${change.pool}',
    );
  }

  final restarted = await scenario.restartAndObserve();
  _requireEquivalentState(
    confirmed.confirmed.sourceAfter,
    restarted.source,
    context: 'restart',
  );
  final restored = await scenario.restoreAndObserve(
    name: restoreName,
    recoveryMaterial: recoveryMaterial,
  );
  _requireEquivalentState(
    restarted.source,
    restored.observation,
    context: 'restore',
  );
  return ZcashMigrationMatrixResult(
    funded: funded,
    spendable: spendable,
    activated: activated,
    prepared: prepared,
    confirmed: confirmed,
    restarted: restarted,
    restored: restored,
  );
}

void _requireEquivalentState(
  WalletObservation<ZcashRegtestPool> expected,
  WalletObservation<ZcashRegtestPool> actual, {
  required String context,
}) {
  _require(
    actual.balances.length == expected.balances.length,
    '$context pools',
  );
  for (final entry in expected.balances.entries) {
    _require(actual.balanceOf(entry.key) == entry.value, '$context balance');
  }
  final expectedValues = {
    for (final value in expected.values)
      (value.id, value.pool, value.value, value.state, value.isChange),
  };
  final actualValues = {
    for (final value in actual.values)
      (value.id, value.pool, value.value, value.state, value.isChange),
  };
  _require(
    actualValues.length == expectedValues.length &&
        actualValues.containsAll(expectedValues),
    '$context did not preserve value identities and states',
  );
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
