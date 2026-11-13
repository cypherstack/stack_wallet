import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_send.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state_controller.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

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

  test('builds a due regtest ZIP-318 intent from exact consensus state', () {
    final configuration = ZcashRegtestConsensusConfiguration(
      genesisId: 'regtest-genesis',
      canonicalPolicy: 'zebra-nu6.3-130',
      nu63ActivationHeight: 130,
      birthdayHeight: 1,
    );
    final intent = configuration.zip318Intent(
      TransferRequest(
        address: 'uregtest1destination',
        pool: ZcashRegtestPool.ironwood,
        value: BigInt.from(1000000),
      ),
      ZcashWalletStateInspection(
        chainHeight: 420,
        balances: const {},
        values: const [],
      ),
    );

    expect(intent.scheduledTransfer.denominationZatoshis, 1000000);
    expect(intent.scheduledTransfer.feeZatoshis, 15000);
    expect(intent.scheduledTransfer.broadcastHeight, 420);
    expect(intent.parameters.nu63ActivationHeight, 130);
    expect(intent.consent.isSatisfied, isTrue);
  });

  test('routes an Orchard-only wallet through the typed production migration '
      'entrypoint', () async {
    const phrase =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';
    final seed = zcash.nativeMnemonicToSeed(phrase);
    final address = await zcash.deriveAddress(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.regtest,
    );
    final wallet = _MigrationWallet(address.ua);
    final capabilities = ZcashStackTransferCapabilities(
      zip318IntentProvider: (_, request, inspection) =>
          ZcashRegtestConsensusConfiguration(
            genesisId: 'regtest-genesis',
            canonicalPolicy: 'zebra-nu6.3-130',
            nu63ActivationHeight: 130,
            birthdayHeight: 1,
          ).zip318Intent(request, inspection, anchorBoundaryModulus: 5),
    );

    final prepared = await capabilities.prepare(
      wallet,
      TransferRequest(
        address: address.ua,
        pool: ZcashRegtestPool.ironwood,
        value: BigInt.from(1000000),
      ),
    );

    expect(wallet.migrationInvoked, isTrue);
    expect(prepared.native.encodedAddress, address.ua);
    expect(prepared.native.selectedReceiver, ZcashRegtestReceiver.orchard);
    expect(prepared.native.actualOutputPool, ZcashRegtestPool.ironwood);
    expect(prepared.native.sourcePool, ZcashRegtestPool.orchard);
    expect(prepared.sources.single.value, BigInt.from(2000000));
    expect(prepared.change.single.value, BigInt.from(985000));
    expect(prepared.fee, BigInt.from(15000));
    prepared.requireValueConserved();
  });
}

final class _MigrationWallet extends ZcashWallet {
  _MigrationWallet(String recipient)
    : prepared = _AdapterMigrationPrepared(recipient),
      super(CryptoCurrencyNetwork.regtest);

  final ZcashPreparedWalletSend prepared;
  bool migrationInvoked = false;

  @override
  ZcashWalletStateInspection get synchronizedStateInspection =>
      ZcashWalletStateInspection(
        chainHeight: 420,
        balances: {'orchard': BigInt.from(2000000)},
        values: [
          ZcashWalletValueInspection(
            id: 'orchard:${'11' * 32}:0',
            protocolTxid: '11' * 32,
            outputIndex: 0,
            pool: 'orchard',
            value: BigInt.from(2000000),
            isSpent: false,
            isChange: false,
            isSpendable: true,
          ),
        ],
      );

  @override
  Future<TxData> prepareOrchardMigration({
    required TxData txData,
    required zcash.Zip318ScheduledTransfer scheduledTransfer,
    required zcash.Zip318Parameters parameters,
    required zcash.Zip318ConsentChecklist consent,
  }) async {
    migrationInvoked = true;
    return txData.copyWith(raw: prepared.transactionHex, txid: prepared.txid);
  }

  @override
  ZcashPreparedWalletSend preparedSendFor(TxData txData) => prepared;
}

final class _AdapterMigrationPrepared extends ZcashPreparedWalletSend {
  _AdapterMigrationPrepared(String recipient)
    : super(
        encodedRecipient: recipient,
        selectedReceiver: zcash.ZcashAddressReceiverType.orchard,
        selectedReceiverAddress: recipient,
        actualOutputPool: zcash.ProposalOutputPool.ironwood,
        memo: null,
        sessionGeneration: 1,
      );

  @override
  int get amountZatoshis => 1000000;
  @override
  int get changeZatoshis => 985000;
  @override
  int get expiryHeight => 500;
  @override
  int get feeZatoshis => 15000;
  @override
  int get inputZatoshis => 2000000;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes => [
    zcash.ZcashScannedNote(
      height: 120,
      tx: '11' * 32,
      output: 0,
      value: 2000000,
      pool: 'orchard',
      nullifier: '22' * 32,
    ),
  ];
  @override
  ZcashSendSourcePool get sourcePool => ZcashSendSourcePool.orchard;
  @override
  String get transactionHex => '010203';
  @override
  String get txid => '33' * 32;
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
