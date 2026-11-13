@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';

import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';
import '../../integration_test/zcash_regtest/zcash_staged_chain_driver.dart';

const _testUnifiedAddress =
    'uregtest1t5ljufrslrjkts4ku72pj7cer8qtck0yzv58jna7pg7ygjm2taexqnvcl8eg28ac6'
    'verjfdnsx3p028x2pykav0q2vvp0hu3nk3z72vh2adxjgvp34y47zc2efx98pqvqsp9k30j7cq'
    '9vwx09g9ukzfqxzzcm6sm5qt7l0md4t66uj4fxntqk7mlgy4az57rkk6xwu0ag53g5j2h9rz';

void main() {
  final enabled = Platform.environment['ZCASH_STACK_REGTEST_LIVE'] == '1';

  test(
    'owns Zebra and lightwalletd across Orchard funding and NU6.3 activation',
    () async {
      final driver = await ZcashStagedChainDriver.open(
        ZcashStagedChainConfiguration(
          nu63ActivationHeight: 130,
          zebraBinary: Platform.environment['ZEBRA_BIN']!,
          lightwalletdBinary: Platform.environment['LIGHTWALLETD_BIN']!,
          ffiLibrary: Platform.environment['ZCASH_FFI_LIB']!,
        ),
      );
      addTearDown(driver.close);

      expect(
        await driver.height(),
        ZcashStagedChainConfiguration.coinbaseMaturity,
      );
      expect(driver.endpoint.host('lightwalletd').port, greaterThan(0));

      final funding = await driver.fund(
        address: _testUnifiedAddress,
        value: BigInt.from(1000000),
        pool: ZcashRegtestPool.orchard,
      );
      await driver.mine(1);
      final confirmed = await driver.transaction(funding.txid);
      expect(confirmed.confirmations, greaterThanOrEqualTo(1));
      expect(
        confirmed.outputs
            .singleWhere((output) => output.pool == ZcashRegtestPool.orchard)
            .value,
        funding.value,
      );

      final transparentFunding = await driver.fund(
        address: 'tmNuoMzZxTiBkEbHVNwUsr3a1iELSeNZkRA',
        value: BigInt.from(2000000),
        pool: ZcashRegtestPool.transparent,
      );
      await driver.mine(1);
      final transparentConfirmed = await driver.transaction(
        transparentFunding.txid,
      );
      expect(
        transparentConfirmed.outputs
            .singleWhere(
              (output) =>
                  output.pool == ZcashRegtestPool.transparent &&
                  output.address == transparentFunding.address,
            )
            .value,
        transparentFunding.value,
      );

      final crossing = await driver.crossActivation(ZcashRegtestUpgrade.nu63);
      expect(crossing.activationHeight, 130);
      expect(crossing.height, 130);
    },
    skip: enabled
        ? false
        : 'set ZCASH_STACK_REGTEST_LIVE=1 and binary/FFI paths',
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
