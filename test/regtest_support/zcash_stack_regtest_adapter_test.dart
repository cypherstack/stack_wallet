import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';

void main() {
  test('carries the exact wallet consensus identity into staged scenarios', () {
    final configuration = ZcashRegtestConsensusConfiguration(
      genesisId: 'regtest-genesis',
      canonicalPolicy: 'zebra-nu6.3-130',
      nu63ActivationHeight: 130,
      birthdayHeight: 1,
    );
    final delegate = _WalletDriver();
    final adapter = ZcashStackRegtestAdapter<String, Uri>(
      delegate: delegate,
      configuration: configuration,
    );

    expect(adapter.consensusIdentity, same(configuration.consensusIdentity));
    expect(adapter.name, delegate.name);
    final walletInfo = configuration.walletInfo(
      Zcash(CryptoCurrencyNetwork.regtest),
      'alice',
    );
    expect(walletInfo.coinName, 'zcashRegtest');
    expect(walletInfo.restoreHeight, 1);
    expect(
      () => configuration.walletInfo(
        Bitcoin(CryptoCurrencyNetwork.test),
        'wrong coin',
      ),
      throwsStateError,
    );
  });

  test('maps regtest activation and pool names without UI assumptions', () {
    final identity = zcashRegtestConsensusIdentity(
      genesisId: '00' * 32,
      canonicalPolicy: 'zebra-nu6.3-130',
      nu63ActivationHeight: 130,
    );

    expect(identity.activations.heightOf(ZcashRegtestUpgrade.nu63), 130);
    expect(ZcashRegtestPool.values.map((pool) => pool.wireName), [
      'transparent',
      'sapling',
      'orchard',
      'ironwood',
    ]);
  });
}

final class _WalletDriver
    implements
        WalletRegtestDriver<
          String,
          Uri,
          ZcashRegtestPool,
          ZcashStackPreparedTransfer
        > {
  @override
  String get name => 'delegate';

  @override
  Future<void> close() async {}

  @override
  Future<void> closeWallet(String wallet) async {}

  @override
  Future<void> configure(Uri endpoint) async {}

  @override
  Future<TransferReceipt<ZcashRegtestPool>> confirm(
    String wallet,
    PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer> prepared,
  ) => throw UnimplementedError();

  @override
  Future<String> create(String name) async => name;

  @override
  String diagnostics({int maxLines = 100}) => 'delegate diagnostics';

  @override
  Future<WalletObservation<ZcashRegtestPool>> observe(String wallet) =>
      throw UnimplementedError();

  @override
  Future<PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer>>
  prepare(String wallet, TransferRequest<ZcashRegtestPool> request) =>
      throw UnimplementedError();

  @override
  Future<String> receiver(String wallet, ZcashRegtestPool pool) =>
      throw UnimplementedError();

  @override
  Future<String> restart(String wallet) async => wallet;

  @override
  Future<String> restore(String name, String recoveryMaterial) async => name;

  @override
  Future<void> synchronize(String wallet) async {}
}
