@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../integration_test/regtest_support/stack_test_environment.dart';
import '../../integration_test/regtest_support/stack_wallet_fixture.dart';
import '../../integration_test/zcash_regtest/zcash_migration_matrix.dart';
import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';
import '../../integration_test/zcash_regtest/zcash_staged_chain_driver.dart';
import '../support/isar_test_utils.dart';

void main() {
  final enabled = Platform.environment['ZCASH_STACK_REGTEST_E2E'] == '1';

  test(
    'real Stack wallet migrates preactivation Sapling value into Ironwood',
    () async {
      await initializeTestIsar();
      final ffiPath = Platform.environment['ZCASH_FFI_LIB']!;
      final mnemonic = zcash.nativeMnemonicFromEntropy(
        '00' * 32,
        bindings: zcash.ZcashFfiBindings.open(ffiPath),
      );
      late ZcashStagedChainDriver chain;
      late ZcashStackTransferCapabilities capabilities;

      final result =
          await TransferScenario.lifecycle<
            ZcashMigrationMatrixResult<ZcashWallet>,
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
                      createRecoveryMaterial: () => mnemonic,
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
            sourceName: 'zcash-sapling-source',
            body: (transfers) => runZcashMigrationCase(
              scenario: transfers.migration<ZcashRegtestUpgrade>(),
              migrationCase: zcashStagedMigrationMatrix.singleWhere(
                (entry) => entry.sourcePool == ZcashRegtestPool.sapling,
              ),
              fundingValue: BigInt.from(10000000),
              migrationValue: BigInt.from(1000000),
              spendabilityProbe: capabilities.verifySpendable,
              restoreName: 'zcash-sapling-restored',
              recoveryMaterial: mnemonic,
            ),
          );

      expect(result.confirmed.actualDestinationPools, {
        ZcashRegtestPool.ironwood,
      });
      expect(
        result.restored.observation.balanceOf(ZcashRegtestPool.ironwood),
        greaterThanOrEqualTo(BigInt.from(1000000)),
      );
    },
    skip: enabled
        ? false
        : 'set ZCASH_STACK_REGTEST_E2E=1 and binary/FFI/parameter paths',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

final class _NoopResource implements RegtestResource {
  const _NoopResource();

  @override
  String get name => 'Stack Zcash native backend';

  @override
  Future<void> close() async {}

  @override
  String diagnostics({int maxLines = 100}) => 'native backend is process-local';
}
