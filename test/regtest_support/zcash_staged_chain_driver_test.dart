import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../integration_test/zcash_regtest/zcash_staged_chain_driver.dart';
import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';

void main() {
  test('staged chain configuration rejects an unusable activation window', () {
    expect(
      () => ZcashStagedChainConfiguration(
        nu63ActivationHeight: ZcashStagedChainConfiguration.coinbaseMaturity,
        zebraBinary: '/zebrad',
        lightwalletdBinary: '/lightwalletd',
        ffiLibrary: '/libzcash_ffi.so',
      ),
      throwsArgumentError,
    );
  });

  test(
    'raw bundle authentication rejects an invented Ironwood destination',
    () {
      final txid = '11' * 32;
      final recorded = ChainTransaction(
        txid: txid,
        confirmations: 0,
        sources: [
          TransferSource(
            id: '${'22' * 32}:0',
            pool: ZcashRegtestPool.transparent,
            value: BigInt.from(100000),
          ),
        ],
        outputs: [
          TransferOutput(
            id: '$txid:destination',
            pool: ZcashRegtestPool.ironwood,
            value: BigInt.from(85000),
          ),
        ],
        fee: BigInt.from(15000),
      );
      final zebra = zcash.TransactionInfo(
        txid: txid,
        hex: '00',
        confirmations: 1,
      );

      expect(
        () => authenticateRecordedZcashTransaction(
          recorded: recorded,
          zebra: zebra,
          decoded: _summary(txid: txid),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'raw bundle authentication forbids Orchard in transparent shielding',
    () {
      final txid = '11' * 32;
      final recorded = ChainTransaction(
        txid: txid,
        confirmations: 0,
        sources: [
          TransferSource(
            id: '${'22' * 32}:0',
            pool: ZcashRegtestPool.transparent,
            value: BigInt.from(100000),
          ),
        ],
        outputs: [
          TransferOutput(
            id: '$txid:destination',
            pool: ZcashRegtestPool.ironwood,
            value: BigInt.from(85000),
          ),
        ],
        fee: BigInt.from(15000),
      );

      expect(
        () => authenticateRecordedZcashTransaction(
          recorded: recorded,
          zebra: zcash.TransactionInfo(txid: txid, hex: '00', confirmations: 1),
          decoded: _summary(txid: txid, ironwoodActions: 1, orchardActions: 1),
        ),
        throwsStateError,
      );
    },
  );

  test('raw bundle authentication binds every mixed destination pool', () {
    final txid = '11' * 32;
    final recorded = ChainTransaction(
      txid: txid,
      confirmations: 1,
      sources: [
        TransferSource(
          id: 'aa' * 32,
          pool: ZcashRegtestPool.ironwood,
          value: BigInt.from(100000),
        ),
      ],
      outputs: [
        TransferOutput(
          id: '$txid:transparent',
          pool: ZcashRegtestPool.transparent,
          value: BigInt.from(10000),
          address: 'tmixed',
        ),
        TransferOutput(
          id: '$txid:sapling',
          pool: ZcashRegtestPool.sapling,
          value: BigInt.from(20000),
        ),
        TransferOutput(
          id: '$txid:ironwood',
          pool: ZcashRegtestPool.ironwood,
          value: BigInt.from(60000),
        ),
      ],
      fee: BigInt.from(10000),
    );
    final zebra = zcash.TransactionInfo(
      txid: txid,
      hex: '00',
      confirmations: 1,
    );

    expect(
      () => authenticateRecordedZcashTransaction(
        recorded: recorded,
        zebra: zebra,
        decoded: _summary(
          txid: txid,
          transparentOutputs: const [
            zcash.ZcashTransparentOutputSummary(
              outputIndex: 0,
              address: 'tmixed',
              scriptHex: '00',
              valueZatoshis: 10000,
            ),
          ],
          saplingOutputs: 1,
          ironwoodActions: 1,
        ),
      ),
      returnsNormally,
    );

    expect(
      () => authenticateRecordedZcashTransaction(
        recorded: recorded,
        zebra: zebra,
        decoded: _summary(
          txid: txid,
          transparentOutputs: const [
            zcash.ZcashTransparentOutputSummary(
              outputIndex: 0,
              address: 'twrong',
              scriptHex: '00',
              valueZatoshis: 10000,
            ),
          ],
          saplingOutputs: 1,
          ironwoodActions: 1,
        ),
      ),
      throwsStateError,
    );

    expect(
      () => authenticateRecordedZcashTransaction(
        recorded: recorded,
        zebra: zebra,
        decoded: _summary(
          txid: txid,
          transparentOutputs: const [
            zcash.ZcashTransparentOutputSummary(
              outputIndex: 0,
              address: 'tmixed',
              scriptHex: '00',
              valueZatoshis: 10000,
            ),
          ],
          ironwoodActions: 1,
        ),
      ),
      throwsStateError,
    );
  });

  test('mined block authentication rejects mismatched provenance', () {
    final txid = '11' * 32;

    expect(
      () => authenticateMinedZcashTransactionBlock(
        txid: txid,
        expectedHash: '22' * 32,
        expectedHeight: 123,
        block: zcash.BlockInfo(
          hash: '33' * 32,
          confirmations: 1,
          height: 124,
          transactions: [txid],
        ),
      ),
      throwsStateError,
    );
  });

  test(
    'v6 block-template auth digest and displayed txid are both recorded',
    () {
      final authDigest = '22' * 32;
      final txid = '11' * 32;

      expect(zcashTemplateTransactionIds({'hash': authDigest, 'txid': txid}), {
        authDigest,
        txid,
      });
    },
  );
}

zcash.ZcashTransactionSummary _summary({
  required String txid,
  int ironwoodActions = 0,
  int orchardActions = 0,
  int saplingOutputs = 0,
  List<zcash.ZcashTransparentOutputSummary> transparentOutputs = const [],
}) => zcash.ZcashTransactionSummary(
  network: zcash.ZcashAddressNetwork.regtest,
  txid: txid,
  version: zcash.ZcashTransactionVersion.v6,
  header: 6,
  versionGroupId: 0,
  consensusBranchId: 'nu6.3',
  lockTime: 0,
  expiryHeight: 200,
  transparent: zcash.ZcashTransparentBundleSummary(
    present: true,
    vin: 1,
    vout: transparentOutputs.length,
    outputs: transparentOutputs,
  ),
  sapling: zcash.ZcashSaplingBundleSummary(
    present: saplingOutputs > 0,
    spends: 0,
    outputs: saplingOutputs,
  ),
  orchard: zcash.ZcashOrchardBundleSummary(
    present: orchardActions > 0,
    actions: orchardActions,
  ),
  ironwood: zcash.ZcashIronwoodBundleSummary(
    present: ironwoodActions > 0,
    actions: ironwoodActions,
  ),
  sprout: const zcash.ZcashSproutBundleSummary(present: false, joinsplits: 0),
);
