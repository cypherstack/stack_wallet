import 'dart:typed_data';

import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_spark_interface.dart';

void main() {
  test('Spark Name validation rejects underscores before construction', () {
    final pattern = RegExp(kNameRegexString);
    expect(pattern.hasMatch('NAME-FOR.TESTING'), isTrue);
    expect(pattern.hasMatch('NAME_FOR_TESTING'), isFalse);
  });

  test('Spark Name fee output includes the name and address tag', () {
    final baseScript = Uint8List(25);
    final feeScript = sparkNameFeeScript(
      baseScript: baseScript,
      name: 'alice',
      sparkAddress: List.filled(144, 'a').join(),
    );

    expect(feeScript.length - baseScript.length, 155);
    expect(feeScript.length, 180);
    expect(feeScript[25], OP_SPARKNAMEID);
    expect(feeScript[32], OP_DROP);
    expect(feeScript.last, OP_DROP);
  });

  test('Spark Name payments never have the miner fee subtracted', () {
    expect(
      shouldSubtractSparkFeeFromAmount(
        isSparkNameRegistration: true,
        spendsAll: true,
      ),
      isFalse,
    );
    expect(
      shouldSubtractSparkFeeFromAmount(
        isSparkNameRegistration: false,
        spendsAll: true,
      ),
      isTrue,
    );
  });

  group('Spark H2 activation', () {
    test('mainnet uses V1 before the activation block', () {
      final version = sparkSpendVersionForNextBlock(
        network: CryptoCurrencyNetwork.main,
        nextBlockHeight: 1370999,
      );

      expect(version, LibSparkSpendVersion.chaumV1);
      expect(version.allowsMultipleInputs, isFalse);
      expect(version.transactionVersion, 3 | (9 << 16));
    });

    test('mainnet uses V2 at activation and later', () {
      for (final nextBlockHeight in [1371000, 1371001]) {
        final version = sparkSpendVersionForNextBlock(
          network: CryptoCurrencyNetwork.main,
          nextBlockHeight: nextBlockHeight,
        );

        expect(version, LibSparkSpendVersion.chaumV2);
        expect(version.allowsMultipleInputs, isTrue);
        expect(version.transactionVersion, 3 | (11 << 16));
      }
    });

    test('non-mainnet networks remain on V1', () {
      for (final network in CryptoCurrencyNetwork.values.where(
        (network) => network != CryptoCurrencyNetwork.main,
      )) {
        expect(
          sparkSpendVersionForNextBlock(
            network: network,
            nextBlockHeight: 1371000,
          ),
          LibSparkSpendVersion.chaumV1,
        );
      }
    });

    test('only the Chaum V2 transaction version permits multiple inputs', () {
      expect(
        isChaumV2SparkTransactionVersion(
          LibSparkSpendVersion.chaumV1.transactionVersion,
        ),
        isFalse,
      );
      expect(
        isChaumV2SparkTransactionVersion(
          LibSparkSpendVersion.chaumV2.transactionVersion,
        ),
        isTrue,
      );
    });
  });
}
