@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_send.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../integration_test/regtest_support/stack_test_environment.dart';
import '../../integration_test/regtest_support/stack_wallet_fixture.dart';
import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';
import '../../integration_test/zcash_regtest/zcash_staged_chain_driver.dart';
import '../support/isar_test_utils.dart';

void main() {
  final enabled = Platform.environment['ZCASH_STACK_REGTEST_E2E'] == '1';

  test(
    'real Stack wallet mines an ordered transparent Sapling Ironwood batch',
    () async {
      await initializeTestIsar();
      final ffiPath = Platform.environment['ZCASH_FFI_LIB']!;
      final bindings = zcash.ZcashFfiBindings.open(ffiPath);
      final batchSourceMnemonic = zcash.nativeMnemonicFromEntropy(
        '00' * 32,
        bindings: bindings,
      );
      final destinationMnemonic = zcash.nativeMnemonicFromEntropy(
        '11' * 32,
        bindings: bindings,
      );
      final newWalletMnemonics = <String>[
        batchSourceMnemonic,
        destinationMnemonic,
      ];
      late ZcashStagedChainDriver chain;
      late ZcashStackTransferCapabilities capabilities;

      await TransferScenario.lifecycle<
        void,
        ZcashWallet,
        EndpointBundle,
        ZcashRegtestPool,
        ZcashStackPreparedTransfer
      >(
        startChain: () async {
          chain = await ZcashStagedChainDriver.open(
            ZcashStagedChainConfiguration(
              nu63ActivationHeight: 130,
              zebraBinary: Platform.environment['ZEBRA_BIN']!,
              lightwalletdBinary: Platform.environment['LIGHTWALLETD_BIN']!,
              ffiLibrary: ffiPath,
              saplingSpendParams:
                  Platform.environment['ZCASH_SAPLING_SPEND_PARAMS']!,
              saplingOutputParams:
                  Platform.environment['ZCASH_SAPLING_OUTPUT_PARAMS']!,
            ),
          );
          return chain;
        },
        startWalletDriver: () async {
          final currency = Zcash(CryptoCurrencyNetwork.regtest);
          final configuration = ZcashRegtestConsensusConfiguration(
            genesisId: chain.consensusIdentity.genesisId,
            canonicalPolicy: chain.consensusIdentity.canonicalPolicy,
            nu63ActivationHeight: 130,
            birthdayHeight: 2,
            saplingSpendParams:
                Platform.environment['ZCASH_SAPLING_SPEND_PARAMS']!,
            saplingOutputParams:
                Platform.environment['ZCASH_SAPLING_OUTPUT_PARAMS']!,
          );
          final environment = await StackTestEnvironment.open();
          capabilities = ZcashStackTransferCapabilities(
            zip318IntentProvider: (wallet, request, inspection) =>
                configuration.zip318Intent(request, inspection),
            confirmedTransferObserver: chain.recordBroadcast,
          );
          final fixture =
              await StackWalletRegtestFixture.open<
                ZcashWallet,
                EndpointBundle,
                ZcashRegtestPool,
                ZcashStackPreparedTransfer
              >(
                environmentFactory: () async => environment,
                backendFactory: (_, _) async => const _NoopResource(),
                endpointInjector: StackNodeEndpointDelivery(
                  currency: currency,
                  endpointName: 'lightwalletd',
                  nodeFactory: (endpoint) => NodeModel(
                    host: endpoint.host,
                    port: endpoint.port,
                    name: 'Zcash staged regtest',
                    id: 'zcash-staged-regtest',
                    useSSL: false,
                    enabled: true,
                    coinName: currency.identifier,
                    isFailover: false,
                    isDown: false,
                    torEnabled: false,
                    clearnetEnabled: true,
                    isPrimary: true,
                  ),
                ).call,
                walletFactory: StackMnemonicWalletFactory<ZcashWallet>(
                  environment: environment,
                  currency: currency,
                  createRecoveryMaterial: () {
                    if (newWalletMnemonics.isEmpty) {
                      throw StateError('unexpected additional wallet');
                    }
                    return newWalletMnemonics.removeAt(0);
                  },
                  initializeWallet: configuration.initializeWallet,
                  walletInfoFactory: configuration.walletInfo,
                ),
                transferCapabilities: capabilities,
                operationTimeout: const Duration(minutes: 3),
              );
          return ZcashStackRegtestAdapter(
            delegate: fixture,
            configuration: configuration,
          );
        },
        sourceName: 'zcash-batch-source',
        destinationName: 'zcash-batch-destination',
        body: (scenario) async {
          // First give the batch source one real Ironwood note through a
          // self-directed production ZIP-318 migration. Keeping this funding
          // transaction self-directed lets its wallet authenticate both its
          // Orchard remainder and Ironwood output; the ordinary batch below
          // still crosses to the independently owned destination wallet.
          final staged = scenario.migration<ZcashRegtestUpgrade>();
          await staged.fundBeforeActivation(
            upgrade: ZcashRegtestUpgrade.nu63,
            value: BigInt.from(10000000),
            sourcePool: ZcashRegtestPool.orchard,
          );
          await staged.verifyOldPoolSpendability(
            upgrade: ZcashRegtestUpgrade.nu63,
            pool: ZcashRegtestPool.orchard,
            probe: capabilities.verifySpendable,
          );
          await staged.advanceToPreActivation(ZcashRegtestUpgrade.nu63);
          await staged.crossActivation(ZcashRegtestUpgrade.nu63);
          await chain.mine(288);

          final batchSource = scenario.sourceWallet;
          final batchDestination = scenario.destinationWallet;
          final funding = await scenario.prepareTransferFrom(
            sourceWallet: batchSource,
            destinationWallet: batchSource,
            value: BigInt.from(1000000),
            destinationPool: ZcashRegtestPool.ironwood,
          );
          expect(
            funding.prepared.sources.map((source) => source.pool).toSet(),
            {ZcashRegtestPool.orchard},
          );
          final funded = await scenario.confirmTransfer(funding);
          expect(funded.receipt.actualDestinationPools, {
            ZcashRegtestPool.ironwood,
          });
          final batchSourceBefore = await capabilities.observe(batchSource);
          await capabilities.verifySpendable(
            batchSource,
            ZcashRegtestPool.ironwood,
            batchSourceBefore,
          );

          final transparentAddress = await capabilities.receiver(
            batchDestination,
            ZcashRegtestPool.transparent,
          );
          final saplingAddress = await capabilities.receiver(
            batchDestination,
            ZcashRegtestPool.sapling,
          );
          final ironwoodAddress = await capabilities.receiver(
            batchDestination,
            ZcashRegtestPool.ironwood,
          );
          final sourceIronwoodAddress = await capabilities.receiver(
            batchSource,
            ZcashRegtestPool.ironwood,
          );
          expect(ironwoodAddress, isNot(sourceIronwoodAddress));

          final amounts = [50000, 60000, 70000, 80000];
          final memos = <Uint8List?>[
            null,
            Uint8List.fromList([0x53, 0x01]),
            Uint8List.fromList([0x49, 0x01]),
            Uint8List.fromList([0x49, 0x02]),
          ];
          final encodedRecipients = [
            transparentAddress,
            saplingAddress,
            ironwoodAddress,
            ironwoodAddress,
          ];
          final requested = TxData(
            recipients: [
              for (var index = 0; index < encodedRecipients.length; index++)
                TxRecipient(
                  address: encodedRecipients[index],
                  amount: Amount(
                    rawValue: BigInt.from(amounts[index]),
                    fractionDigits: 8,
                  ),
                  isChange: false,
                  addressType: batchSource.cryptoCurrency.getAddressType(
                    encodedRecipients[index],
                  )!,
                  memoBytes: memos[index],
                ),
            ],
          );
          final reviewed = await batchSource.prepareSend(txData: requested);
          final native = batchSource.preparedSendFor(reviewed);
          expect(native, isA<ZcashPreparedIronwoodBatch>());
          final batch = native as ZcashPreparedIronwoodBatch;
          batch.requireValueConservation();

          expect(
            batch.outputs.map((output) => output.encodedAddress),
            encodedRecipients,
          );
          expect(batch.outputs.map((output) => output.amountZatoshis), amounts);
          expect(batch.outputs.map((output) => output.actualOutputPool), [
            zcash.ProposalOutputPool.transparent,
            zcash.ProposalOutputPool.sapling,
            zcash.ProposalOutputPool.ironwood,
            zcash.ProposalOutputPool.ironwood,
          ]);
          for (var index = 0; index < memos.length; index++) {
            expect(batch.outputs[index].memo, memos[index]);
            expect(reviewed.recipients![index].memoBytes, memos[index]);
          }
          expect(
            batch.outputs[2].encodedAddress,
            batch.outputs[3].encodedAddress,
          );
          expect(batch.outputs[2].memo, isNot(batch.outputs[3].memo));

          final confirmed = await batchSource.confirmSend(txData: reviewed);
          expect(confirmed.txid, batch.txid);
          final sources = [
            for (final note in batch.selectedNotes)
              TransferSource(
                id: note.nullifier ?? '${note.pool}:${note.tx}:${note.output}',
                pool: ZcashRegtestPool.ironwood,
                value: BigInt.from(note.value),
              ),
          ];
          final destinationOutputs = [
            for (var index = 0; index < batch.outputs.length; index++)
              TransferOutput(
                id: '${batch.txid}:destination:$index',
                pool: _pool(batch.outputs[index].actualOutputPool),
                value: BigInt.from(batch.outputs[index].amountZatoshis),
                address: batch.outputs[index].receiverAddress,
              ),
          ];
          final changeOutputs = [
            if (batch.changeZatoshis > 0)
              TransferOutput(
                id: '${batch.txid}:change:0',
                pool: ZcashRegtestPool.ironwood,
                value: BigInt.from(batch.changeZatoshis),
              ),
          ];
          final receipt = TransferReceipt(
            txid: batch.txid,
            sources: sources,
            destinationOutputs: destinationOutputs,
            changeOutputs: changeOutputs,
            fee: BigInt.from(batch.feeZatoshis),
          );
          receipt.requireValueConserved();
          expect(receipt.actualDestinationPools, {
            ZcashRegtestPool.transparent,
            ZcashRegtestPool.sapling,
            ZcashRegtestPool.ironwood,
          });
          await chain.recordBroadcast(receipt);
          await chain.mine(1);
          final minedHeight = await chain.height();
          final mined = await chain.transaction(batch.txid);
          mined.requireValueConserved();
          expect(mined.txid, batch.txid);
          expect(mined.fee, BigInt.from(batch.feeZatoshis));
          expect(mined.outputs, hasLength(4 + changeOutputs.length));

          await capabilities.synchronize(batchSource);
          await capabilities.synchronize(batchDestination);
          final sourceAfter = await capabilities.observe(batchSource);
          final destinationAfter = await capabilities.observe(batchDestination);
          expect(sourceAfter.spentIds, containsAll(sources.map((e) => e.id)));
          _requireDiscoveredBatch(destinationAfter, batch.txid, amounts);
          await _requireDestinationMemos(
            wallet: batchDestination,
            transactionHex: batch.transactionHex,
            minedHeight: minedHeight,
            bindings: bindings,
            expected: [
              (zcash.ZcashMemoPool.sapling, amounts[1], memos[1]!),
              (zcash.ZcashMemoPool.ironwood, amounts[2], memos[2]!),
              (zcash.ZcashMemoPool.ironwood, amounts[3], memos[3]!),
            ],
          );
          _requireChange(sourceAfter, batch.txid, batch.changeZatoshis);

          final restarted = await scenario.restartAndObserve();
          _requireDiscoveredBatch(restarted.destination, batch.txid, amounts);
          await _requireDestinationMemos(
            wallet: restarted.destinationWallet,
            transactionHex: batch.transactionHex,
            minedHeight: minedHeight,
            bindings: bindings,
            expected: [
              (zcash.ZcashMemoPool.sapling, amounts[1], memos[1]!),
              (zcash.ZcashMemoPool.ironwood, amounts[2], memos[2]!),
              (zcash.ZcashMemoPool.ironwood, amounts[3], memos[3]!),
            ],
          );
          _requireChange(restarted.source, batch.txid, batch.changeZatoshis);

          // A recovery is a replacement lifecycle, not a second live handle
          // for the same account. Close the restarted wallets so recovery
          // proves a clean rescan without sharing native account sessions.
          await scenario.wallets.closeWallet(restarted.sourceWallet);
          await scenario.wallets.closeWallet(restarted.destinationWallet);

          final restoredDestination = await scenario.restoreAndObserve(
            name: 'zcash-batch-destination-restored',
            recoveryMaterial: destinationMnemonic,
          );
          final restoredSource = await scenario.restoreAndObserve(
            name: 'zcash-batch-source-restored',
            recoveryMaterial: batchSourceMnemonic,
          );
          _requireDiscoveredBatch(
            restoredDestination.observation,
            batch.txid,
            amounts,
          );
          await _requireDestinationMemos(
            wallet: restoredDestination.wallet,
            transactionHex: batch.transactionHex,
            minedHeight: minedHeight,
            bindings: bindings,
            expected: [
              (zcash.ZcashMemoPool.sapling, amounts[1], memos[1]!),
              (zcash.ZcashMemoPool.ironwood, amounts[2], memos[2]!),
              (zcash.ZcashMemoPool.ironwood, amounts[3], memos[3]!),
            ],
          );
          _requireChange(
            restoredSource.observation,
            batch.txid,
            batch.changeZatoshis,
          );
          expect(
            restoredSource.observation.spentIds,
            containsAll(sources.map((source) => source.id)),
          );

          for (final pool in const [
            ZcashRegtestPool.transparent,
            ZcashRegtestPool.sapling,
            ZcashRegtestPool.ironwood,
          ]) {
            await capabilities.verifySpendable(
              restoredDestination.wallet,
              pool,
              restoredDestination.observation,
            );
          }
          await capabilities.verifySpendable(
            restoredSource.wallet,
            ZcashRegtestPool.ironwood,
            restoredSource.observation,
          );
        },
      );
    },
    skip: enabled
        ? false
        : 'set ZCASH_STACK_REGTEST_E2E=1 and binary/FFI/parameter paths',
    timeout: const Timeout(Duration(minutes: 25)),
  );
}

Future<void> _requireDestinationMemos({
  required ZcashWallet wallet,
  required String transactionHex,
  required int minedHeight,
  required zcash.ZcashFfiBindings bindings,
  required List<(zcash.ZcashMemoPool, int, Uint8List)> expected,
}) async {
  final seed = zcash.nativeMnemonicToSeed(
    await wallet.getMnemonic(),
    passphrase: await wallet.getMnemonicPassphrase(),
    bindings: bindings,
  );
  final ufvk = zcash
      .deriveNativeAccountMetadata(
        seedHex: seed.seedHex,
        network: zcash.ZcashNetwork.regtest,
        bindings: bindings,
      )
      .ufvk;
  final decrypted = <zcash.ZcashNoteMemo>[];
  for (final pool in expected.map((entry) => entry.$1).toSet()) {
    // Bundle cardinality is authenticated separately from Zebra's raw v6
    // transaction. Reading a small bounded superset lets the destination's
    // own viewing material identify its outputs without assuming action
    // ordering or confusing the source wallet's change for a payment.
    for (var outputIndex = 0; outputIndex < 8; outputIndex++) {
      final memo = zcash.readNativeNoteMemo(
        network: zcash.ZcashNetwork.regtest,
        transactionHex: transactionHex,
        pool: pool,
        outputIndex: outputIndex,
        ufvk: ufvk,
        minedHeight: minedHeight,
        regtestNu63ActivationHeight: 130,
        bindings: bindings,
      );
      if (memo != null) decrypted.add(memo);
    }
  }
  for (final entry in expected) {
    expect(
      decrypted.where(
        (memo) =>
            memo.pool == entry.$1.jsonValue &&
            memo.valueZatoshis == entry.$2 &&
            _bytesEqual(memo.bytes, entry.$3),
      ),
      hasLength(1),
      reason:
          'the active destination wallet must decrypt its exact '
          '${entry.$1.jsonValue} memo after sync, restart, and restore',
    );
  }
}

bool _bytesEqual(Uint8List? left, Uint8List right) {
  if (left == null || left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void _requireDiscoveredBatch(
  WalletObservation<ZcashRegtestPool> observation,
  String txid,
  List<int> amounts,
) {
  final expected = [
    (ZcashRegtestPool.transparent, BigInt.from(amounts[0])),
    (ZcashRegtestPool.sapling, BigInt.from(amounts[1])),
    (ZcashRegtestPool.ironwood, BigInt.from(amounts[2])),
    (ZcashRegtestPool.ironwood, BigInt.from(amounts[3])),
  ];
  for (final value in expected) {
    expect(
      observation.values.where(
        (candidate) =>
            candidate.txid == txid &&
            candidate.pool == value.$1 &&
            candidate.value == value.$2 &&
            candidate.state == ObservedValueState.available,
      ),
      hasLength(1),
    );
  }
}

void _requireChange(
  WalletObservation<ZcashRegtestPool> observation,
  String txid,
  int change,
) {
  if (change <= 0) return;
  expect(
    observation.values.where(
      (candidate) =>
          candidate.txid == txid &&
          candidate.pool == ZcashRegtestPool.ironwood &&
          candidate.value == BigInt.from(change) &&
          candidate.state == ObservedValueState.available &&
          candidate.isChange,
    ),
    hasLength(1),
    reason:
        'expected restored Ironwood change $change for $txid; observed '
        '${observation.values.map((value) => '${value.txid} '
            '${value.pool.wireName} ${value.value} '
            '${value.state.name} change=${value.isChange}').join('; ')}',
  );
}

ZcashRegtestPool _pool(zcash.ProposalOutputPool pool) => switch (pool) {
  zcash.ProposalOutputPool.transparent => ZcashRegtestPool.transparent,
  zcash.ProposalOutputPool.sapling => ZcashRegtestPool.sapling,
  zcash.ProposalOutputPool.orchard => ZcashRegtestPool.orchard,
  zcash.ProposalOutputPool.ironwood => ZcashRegtestPool.ironwood,
};

final class _NoopResource implements RegtestResource {
  const _NoopResource();

  @override
  String get name => 'Stack Zcash native backend';

  @override
  Future<void> close() async {}

  @override
  String diagnostics({int maxLines = 100}) => 'native backend is process-local';
}
