import 'package:isar_community/isar.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_send.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../regtest_support/stack_wallet_fixture.dart';

enum ZcashRegtestPool {
  transparent('transparent'),
  sapling('sapling'),
  orchard('orchard'),
  ironwood('ironwood');

  const ZcashRegtestPool(this.wireName);

  final String wireName;
}

enum ZcashRegtestUpgrade { nu63 }

enum ZcashRegtestReceiver { transparent, sapling, orchard, unified }

ConsensusIdentity<ZcashRegtestUpgrade> zcashRegtestConsensusIdentity({
  required String genesisId,
  required String canonicalPolicy,
  required int nu63ActivationHeight,
}) {
  if (nu63ActivationHeight < 2) {
    throw ArgumentError.value(
      nu63ActivationHeight,
      'nu63ActivationHeight',
      'must stage NU6.3 above genesis',
    );
  }
  return ConsensusIdentity(
    network: 'zcash-regtest',
    genesisId: genesisId,
    canonicalPolicy: canonicalPolicy,
    activations: ActivationSchedule({
      ZcashRegtestUpgrade.nu63: nu63ActivationHeight,
    }),
  );
}

/// One consensus configuration reused for the typed identity, wallet birth
/// height, and native regtest builder activation height.
final class ZcashRegtestConsensusConfiguration {
  ZcashRegtestConsensusConfiguration({
    required String genesisId,
    required String canonicalPolicy,
    required this.nu63ActivationHeight,
    required this.birthdayHeight,
  }) : consensusIdentity = zcashRegtestConsensusIdentity(
         genesisId: genesisId,
         canonicalPolicy: canonicalPolicy,
         nu63ActivationHeight: nu63ActivationHeight,
       ) {
    if (birthdayHeight < 1 || birthdayHeight >= nu63ActivationHeight) {
      throw ArgumentError.value(
        birthdayHeight,
        'birthdayHeight',
        'must be positive and precede staged NU6.3 activation',
      );
    }
  }

  final int nu63ActivationHeight;
  final int birthdayHeight;
  final ConsensusIdentity<ZcashRegtestUpgrade> consensusIdentity;

  WalletInfo walletInfo(CryptoCurrency currency, String name) {
    if (currency is! Zcash ||
        currency.network != CryptoCurrencyNetwork.regtest) {
      throw StateError('Zcash regtest configuration requires a regtest coin');
    }
    return WalletInfo.createNew(
      coin: currency,
      name: name,
      restoreHeight: birthdayHeight,
    );
  }

  Future<void> initializeWallet(ZcashWallet wallet, bool isRestore) async {
    wallet.configureRegtestConsensus(
      nu63ActivationHeight: nu63ActivationHeight,
    );
    await wallet.init(isRestore: isRestore);
  }
}

/// The exact Stack review artifact and independently resolved destination.
final class ZcashStackPreparedTransfer {
  ZcashStackPreparedTransfer({
    required this.txData,
    required this.encodedAddress,
    required this.selectedReceiver,
    required this.selectedReceiverAddress,
    required this.actualOutputPool,
    required this.sourcePool,
  });

  final TxData txData;
  final String encodedAddress;
  final ZcashRegtestReceiver selectedReceiver;
  final String selectedReceiverAddress;
  final ZcashRegtestPool actualOutputPool;
  final ZcashRegtestPool sourcePool;
}

final class ZcashStackCapabilityUnavailableException implements Exception {
  const ZcashStackCapabilityUnavailableException(this.capability);

  final String capability;

  @override
  String toString() =>
      'ZcashStackCapabilityUnavailableException: $capability is not exposed '
      'by the production Stack Zcash wallet';
}

/// Production transfer capabilities backed by [ZcashWallet].
///
/// The adapter reads note-level inspection data that the wallet has already
/// synchronized and uses the exact backend artifact retained by
/// `prepareSend`; it does not infer actual output pools from UA encoding.
final class ZcashStackTransferCapabilities
    implements
        StackRegtestTransferCapabilities<
          ZcashWallet,
          ZcashRegtestPool,
          ZcashStackPreparedTransfer
        > {
  const ZcashStackTransferCapabilities();

  @override
  Future<String> receiver(ZcashWallet wallet, ZcashRegtestPool pool) async {
    _requireRegtest(wallet);
    final rows = await wallet.mainDB.getAddresses(wallet.walletId).findAll();
    Address? one(AddressType type) {
      final matches = rows.where(
        (row) => row.type == type && row.subType == AddressSubType.receiving,
      );
      return matches.length == 1 ? matches.single : null;
    }

    return switch (pool) {
      ZcashRegtestPool.sapling =>
        one(AddressType.zcashSapling)?.value ??
            (throw const ZcashStackCapabilityUnavailableException(
              'Sapling receiver',
            )),
      ZcashRegtestPool.transparent =>
        one(AddressType.p2pkh)?.value ??
            (throw const ZcashStackCapabilityUnavailableException(
              'transparent receiver',
            )),
      // ZIP 229 gives Ironwood no distinct address encoding. Orchard and
      // Ironwood therefore both use the UA; target height and consensus
      // policy select the actual pool, which prepare() verifies separately.
      ZcashRegtestPool.orchard || ZcashRegtestPool.ironwood =>
        one(AddressType.zcashUnified)?.value ??
            (throw const ZcashStackCapabilityUnavailableException(
              'Unified Address receiver',
            )),
    };
  }

  @override
  Future<void> synchronize(ZcashWallet wallet) {
    _requireRegtest(wallet);
    return wallet.refresh();
  }

  Future<void> verifySpendable(
    ZcashWallet wallet,
    ZcashRegtestPool pool,
    WalletObservation<ZcashRegtestPool> observation,
  ) async {
    _requireRegtest(wallet);
    final availableIds = {
      for (final value in observation.values)
        if (value.pool == pool && value.state == ObservedValueState.available)
          value.id,
    };
    final inspection = wallet.synchronizedStateInspection;
    if (!inspection.values.any(
      (value) =>
          availableIds.contains(value.id) &&
          value.pool == pool.wireName &&
          value.isSpendable,
    )) {
      throw StateError(
        'No proof-ready, spendable value is available in ${pool.wireName}',
      );
    }
  }

  @override
  Future<WalletObservation<ZcashRegtestPool>> observe(
    ZcashWallet wallet,
  ) async {
    _requireRegtest(wallet);
    final inspection = wallet.synchronizedStateInspection;
    return WalletObservation(
      height: inspection.chainHeight,
      balances: {
        for (final pool in ZcashRegtestPool.values)
          pool: inspection.balances[pool.wireName] ?? BigInt.zero,
      },
      values: [
        for (final value in inspection.values)
          ObservedValue(
            id: value.id,
            txid: value.txid,
            pool: _pool(value.pool),
            value: value.value,
            state: value.isSpent
                ? ObservedValueState.spent
                : ObservedValueState.available,
            isChange: value.isChange,
          ),
      ],
    );
  }

  @override
  Future<PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer>>
  prepare(ZcashWallet wallet, TransferRequest<ZcashRegtestPool> request) async {
    _requireRegtest(wallet);
    final before = wallet.synchronizedStateInspection;
    final spendable = [
      ...before.values.where(
        (value) =>
            !value.isSpent &&
            (value.pool == ZcashRegtestPool.sapling.wireName ||
                value.pool == ZcashRegtestPool.ironwood.wireName),
      ),
    ];
    if (spendable.isEmpty &&
        before.values.any(
          (value) =>
              !value.isSpent && value.pool == ZcashRegtestPool.orchard.wireName,
        )) {
      throw const ZcashStackCapabilityUnavailableException(
        'Orchard to Ironwood ZIP-318 migration',
      );
    }
    final reviewed = await wallet.prepareSend(
      txData: TxData(
        recipients: [
          TxRecipient(
            address: request.requestedReceiver,
            amount: Amount(rawValue: request.value, fractionDigits: 8),
            isChange: false,
            addressType:
                wallet.cryptoCurrency.getAddressType(
                  request.requestedReceiver,
                ) ??
                (throw ArgumentError.value(
                  request.requestedReceiver,
                  'request.requestedReceiver',
                  'is not a valid Zcash receiver',
                )),
          ),
        ],
      ),
    );
    final native = wallet.preparedSendFor(reviewed);
    final sourcePool = switch (native.sourcePool) {
      ZcashSendSourcePool.sapling => ZcashRegtestPool.sapling,
      ZcashSendSourcePool.transparent => ZcashRegtestPool.transparent,
      ZcashSendSourcePool.ironwood => ZcashRegtestPool.ironwood,
    };
    final actualPool = _pool(native.actualOutputPool.jsonValue);
    final prepared = ZcashStackPreparedTransfer(
      txData: reviewed,
      encodedAddress: native.encodedRecipient,
      selectedReceiver: _receiver(native.selectedReceiver),
      selectedReceiverAddress: native.selectedReceiverAddress,
      actualOutputPool: actualPool,
      sourcePool: sourcePool,
    );
    return PreparedTransfer(
      native: prepared,
      sources: [
        for (final note in native.selectedNotes)
          TransferSource(
            id: note.nullifier ?? '${note.pool}:${note.tx}:${note.output}',
            pool: _pool(note.pool),
            value: BigInt.from(note.value),
          ),
      ],
      destination: PoolValue(pool: actualPool, value: request.value),
      change: [
        if (native.changeZatoshis > 0)
          PoolValue(
            pool: sourcePool,
            value: BigInt.from(native.changeZatoshis),
          ),
      ],
      fee: BigInt.from(native.feeZatoshis),
    );
  }

  @override
  Future<TransferReceipt<ZcashRegtestPool>> confirm(
    ZcashWallet wallet,
    PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer> prepared,
  ) async {
    _requireRegtest(wallet);
    final native = prepared.native;
    final confirmed = await wallet.confirmSend(txData: native.txData);
    final txid = confirmed.txid;
    if (txid == null || txid != native.txData.txid) {
      throw StateError('Zcash broadcast did not acknowledge the prepared txid');
    }
    return TransferReceipt(
      txid: txid,
      sources: prepared.sources,
      destinationOutputs: [
        TransferOutput(
          id: '$txid:destination',
          pool: native.actualOutputPool,
          value: prepared.destination.value,
          address: native.selectedReceiverAddress,
        ),
      ],
      changeOutputs: [
        for (var index = 0; index < prepared.change.length; index++)
          TransferOutput(
            id: '$txid:change:$index',
            pool: prepared.change[index].pool,
            value: prepared.change[index].value,
          ),
      ],
      fee: prepared.fee,
    );
  }

  static ZcashRegtestPool _pool(String value) => switch (value) {
    'transparent' => ZcashRegtestPool.transparent,
    'sapling' => ZcashRegtestPool.sapling,
    'orchard' => ZcashRegtestPool.orchard,
    'ironwood' => ZcashRegtestPool.ironwood,
    _ => throw StateError('Unsupported Zcash pool: $value'),
  };

  static ZcashRegtestReceiver _receiver(
    zcash.ZcashAddressReceiverType receiver,
  ) => switch (receiver) {
    zcash.ZcashAddressReceiverType.p2pkh ||
    zcash.ZcashAddressReceiverType.p2sh ||
    zcash.ZcashAddressReceiverType.tex => ZcashRegtestReceiver.transparent,
    zcash.ZcashAddressReceiverType.sapling => ZcashRegtestReceiver.sapling,
    zcash.ZcashAddressReceiverType.orchard => ZcashRegtestReceiver.orchard,
    zcash.ZcashAddressReceiverType.unified => ZcashRegtestReceiver.unified,
    _ => throw StateError('Unsupported Zcash receiver: $receiver'),
  };

  static void _requireRegtest(ZcashWallet wallet) {
    if (wallet.cryptoCurrency.network != CryptoCurrencyNetwork.regtest) {
      throw StateError('Zcash Stack regtest capabilities are regtest-only');
    }
  }
}

/// Adds the consensus contract required by staged scenarios to a Stack wallet
/// driver without changing its lifecycle, endpoint, or cleanup behavior.
final class ZcashStackRegtestAdapter<Wallet, Endpoint>
    implements
        StagedWalletRegtestDriver<
          Wallet,
          Endpoint,
          ZcashRegtestPool,
          ZcashRegtestUpgrade,
          ZcashStackPreparedTransfer
        > {
  ZcashStackRegtestAdapter({
    required this.delegate,
    required ZcashRegtestConsensusConfiguration configuration,
  }) : consensusIdentity = configuration.consensusIdentity;

  final WalletRegtestDriver<
    Wallet,
    Endpoint,
    ZcashRegtestPool,
    ZcashStackPreparedTransfer
  >
  delegate;

  @override
  final ConsensusIdentity<ZcashRegtestUpgrade> consensusIdentity;

  @override
  String get name => delegate.name;

  @override
  Future<void> close() => delegate.close();

  @override
  Future<void> closeWallet(Wallet wallet) => delegate.closeWallet(wallet);

  @override
  Future<void> configure(Endpoint endpoint) => delegate.configure(endpoint);

  @override
  Future<TransferReceipt<ZcashRegtestPool>> confirm(
    Wallet wallet,
    PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer> prepared,
  ) => delegate.confirm(wallet, prepared);

  @override
  Future<Wallet> create(String name) => delegate.create(name);

  @override
  String diagnostics({int maxLines = 100}) =>
      delegate.diagnostics(maxLines: maxLines);

  @override
  Future<WalletObservation<ZcashRegtestPool>> observe(Wallet wallet) =>
      delegate.observe(wallet);

  @override
  Future<PreparedTransfer<ZcashRegtestPool, ZcashStackPreparedTransfer>>
  prepare(Wallet wallet, TransferRequest<ZcashRegtestPool> request) =>
      delegate.prepare(wallet, request);

  @override
  Future<String> receiver(Wallet wallet, ZcashRegtestPool pool) =>
      delegate.receiver(wallet, pool);

  @override
  Future<Wallet> restart(Wallet wallet) => delegate.restart(wallet);

  @override
  Future<Wallet> restore(String name, String recoveryMaterial) =>
      delegate.restore(name, recoveryMaterial);

  @override
  Future<void> synchronize(Wallet wallet) => delegate.synchronize(wallet);
}
