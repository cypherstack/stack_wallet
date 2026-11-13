import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';

import '../../integration_test/zcash_regtest/zcash_migration_matrix.dart';
import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';

void main() {
  test('supported matrix case checks activation, pool, conservation, change, '
      'restart, and restore', () async {
    final identity = zcashRegtestConsensusIdentity(
      genesisId: 'regtest-genesis',
      canonicalPolicy: 'fixture-nu6.3-5',
      nu63ActivationHeight: 5,
    );
    final chain = _Chain(identity);
    final wallets = _Wallets(chain, identity);

    final result =
        await TransferScenario.lifecycle<
          ZcashMigrationMatrixResult<_Wallet>,
          _Wallet,
          Uri,
          ZcashRegtestPool,
          ZcashStackPreparedTransfer
        >(
          startChain: () async => chain,
          startWalletDriver: () async => wallets,
          sourceName: 'alice',
          body: (transfer) => runZcashMigrationCase(
            scenario: transfer.migration<ZcashRegtestUpgrade>(),
            migrationCase: zcashStagedMigrationMatrix.first,
            fundingValue: BigInt.from(100000),
            migrationValue: BigInt.from(40000),
            spendabilityProbe: (wallet, pool, observation) async {
              expect(pool, ZcashRegtestPool.sapling);
              expect(
                observation.values.any(
                  (value) =>
                      value.id == 'source-note' &&
                      value.state == ObservedValueState.available,
                ),
                isTrue,
              );
            },
            restoreName: 'restored-alice',
            recoveryMaterial: 'test recovery material',
          ),
        );

    expect(result.funded.funded.observation.height, 2);
    expect(result.activated.crossing.height, 5);
    expect(result.confirmed.actualDestinationPools, {
      ZcashRegtestPool.ironwood,
    });
    expect(result.confirmed.confirmed.sourceAfter.spentIds, {'source-note'});
    expect(
      result.restarted.source.balanceOf(ZcashRegtestPool.ironwood),
      BigInt.from(40000),
    );
    expect(result.restored.observation.values, hasLength(3));
    expect(wallets.closedWallets, containsAll(['alice', 'restored-alice']));
    expect(chain.closed, isTrue);
  });
}

final class _Wallet {
  const _Wallet(this.name);

  final String name;

  @override
  String toString() => name;
}

final class _Chain
    implements
        StagedRegtestChainDriver<Uri, ZcashRegtestPool, ZcashRegtestUpgrade> {
  _Chain(this.consensusIdentity);

  var currentHeight = 1;
  var funded = false;
  var confirmed = false;
  var closed = false;

  @override
  final ConsensusIdentity<ZcashRegtestUpgrade> consensusIdentity;

  @override
  Uri get endpoint => Uri.parse('http://127.0.0.1:9067');

  @override
  String get name => 'fixture chain';

  @override
  Future<void> close() async => closed = true;

  @override
  String diagnostics({int maxLines = 100}) => 'height=$currentHeight';

  @override
  Future<FundingReceipt<ZcashRegtestPool>> fund({
    required String address,
    required BigInt value,
    required ZcashRegtestPool pool,
  }) async {
    funded = true;
    return FundingReceipt(
      txid: 'funding-tx',
      outputId: 'source-note',
      address: address,
      pool: pool,
      value: value,
    );
  }

  @override
  Future<int> height() async => currentHeight;

  @override
  Future<void> mine(int blocks) async => currentHeight += blocks;

  @override
  Future<ChainTransaction<ZcashRegtestPool>> transaction(String txid) async {
    if (!confirmed || txid != 'migration-tx') {
      throw StateError('transaction is not confirmed');
    }
    return ChainTransaction(
      txid: txid,
      confirmations: 1,
      sources: [
        TransferSource(
          id: 'source-note',
          pool: ZcashRegtestPool.sapling,
          value: BigInt.from(100000),
        ),
      ],
      outputs: [
        TransferOutput(
          id: 'migration-tx:0',
          pool: ZcashRegtestPool.ironwood,
          value: BigInt.from(40000),
          address: 'orchard-receiver',
        ),
        TransferOutput(
          id: 'migration-tx:1',
          pool: ZcashRegtestPool.sapling,
          value: BigInt.from(50000),
        ),
      ],
      fee: BigInt.from(10000),
    );
  }
}

final class _Wallets
    implements
        StagedWalletRegtestDriver<
          _Wallet,
          Uri,
          ZcashRegtestPool,
          ZcashRegtestUpgrade,
          ZcashStackPreparedTransfer
        > {
  _Wallets(this.chain, this.consensusIdentity);

  final _Chain chain;
  final List<String> closedWallets = [];

  @override
  final ConsensusIdentity<ZcashRegtestUpgrade> consensusIdentity;

  @override
  String get name => 'fixture wallets';

  @override
  Future<void> close() async {}

  @override
  Future<void> closeWallet(_Wallet wallet) async {
    closedWallets.add(wallet.name);
  }

  @override
  Future<void> configure(Uri endpoint) async {
    expect(endpoint, chain.endpoint);
  }

  @override
  Future<TransferReceipt<ZcashRegtestPool>> confirm(
    _Wallet wallet,
    PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer> prepared,
  ) async {
    chain.confirmed = true;
    return TransferReceipt(
      txid: 'migration-tx',
      sources: prepared.sources,
      destinationOutputs: [
        TransferOutput(
          id: 'migration-tx:0',
          pool: ZcashRegtestPool.ironwood,
          value: BigInt.from(40000),
          address: 'orchard-receiver',
        ),
      ],
      changeOutputs: [
        TransferOutput(
          id: 'migration-tx:1',
          pool: ZcashRegtestPool.sapling,
          value: BigInt.from(50000),
        ),
      ],
      fee: BigInt.from(10000),
    );
  }

  @override
  Future<_Wallet> create(String name) async => _Wallet(name);

  @override
  String diagnostics({int maxLines = 100}) => 'wallet fixture';

  @override
  Future<WalletObservation<ZcashRegtestPool>> observe(_Wallet wallet) async {
    final values = <ObservedValue<ZcashRegtestPool>>[
      if (chain.funded)
        ObservedValue(
          id: 'source-note',
          txid: 'funding-tx',
          pool: ZcashRegtestPool.sapling,
          value: BigInt.from(100000),
          state: chain.confirmed
              ? ObservedValueState.spent
              : ObservedValueState.available,
        ),
      if (chain.confirmed) ...[
        ObservedValue(
          id: 'destination-note',
          txid: 'migration-tx',
          pool: ZcashRegtestPool.ironwood,
          value: BigInt.from(40000),
          state: ObservedValueState.available,
        ),
        ObservedValue(
          id: 'change-note',
          txid: 'migration-tx',
          pool: ZcashRegtestPool.sapling,
          value: BigInt.from(50000),
          state: ObservedValueState.available,
          isChange: true,
        ),
      ],
    ];
    return WalletObservation(
      height: chain.currentHeight,
      balances: {
        ZcashRegtestPool.transparent: BigInt.zero,
        ZcashRegtestPool.sapling: chain.confirmed
            ? BigInt.from(50000)
            : chain.funded
            ? BigInt.from(100000)
            : BigInt.zero,
        ZcashRegtestPool.orchard: BigInt.zero,
        ZcashRegtestPool.ironwood: chain.confirmed
            ? BigInt.from(40000)
            : BigInt.zero,
      },
      values: values,
    );
  }

  @override
  Future<PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer>>
  prepare(_Wallet wallet, TransferRequest<ZcashRegtestPool> request) async =>
      PreparedTransfer(
        native: ZcashStackPreparedTransfer(
          txData: TxData(txid: 'migration-tx'),
          encodedAddress: request.requestedReceiver,
          selectedReceiver: ZcashRegtestReceiver.orchard,
          selectedReceiverAddress: 'orchard-receiver',
          actualOutputPool: ZcashRegtestPool.ironwood,
          sourcePool: ZcashRegtestPool.sapling,
        ),
        sources: [
          TransferSource(
            id: 'source-note',
            pool: ZcashRegtestPool.sapling,
            value: BigInt.from(100000),
          ),
        ],
        destination: PoolValue(
          pool: ZcashRegtestPool.ironwood,
          value: request.value,
        ),
        change: [
          PoolValue(pool: ZcashRegtestPool.sapling, value: BigInt.from(50000)),
        ],
        fee: BigInt.from(10000),
      );

  @override
  Future<String> receiver(_Wallet wallet, ZcashRegtestPool pool) async =>
      'u-${pool.wireName}';

  @override
  Future<_Wallet> restart(_Wallet wallet) async => _Wallet(wallet.name);

  @override
  Future<_Wallet> restore(String name, String recoveryMaterial) async =>
      _Wallet(name);

  @override
  Future<void> synchronize(_Wallet wallet) async {}
}
