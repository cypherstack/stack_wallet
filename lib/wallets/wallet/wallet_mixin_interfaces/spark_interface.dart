import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

mixin SparkInterface on Bip39HDWallet, ElectrumXInterface {
  Future<Address?> getCurrentReceivingSparkAddress() async {
    return await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(AddressType.spark)
        .sortByDerivationIndexDesc()
        .findFirst();
  }

  Future<Uint8List> _getSpendKey() async {
    final mnemonic = await getMnemonic();
    final mnemonicPassphrase = await getMnemonicPassphrase();

    // TODO call ffi lib to generate spend key

    throw UnimplementedError();
  }

  Future<Address> generateNextSparkAddress() async {
    final highestStoredDiversifier =
        (await getCurrentReceivingSparkAddress())?.derivationIndex;

    // default to starting at 1 if none found
    final int diversifier = (highestStoredDiversifier ?? 0) + 1;

    // TODO: use real data
    final String derivationPath = "";
    final Uint8List publicKey = Uint8List(0); // incomingViewKey?
    final String addressString = "";

    return Address(
      walletId: walletId,
      value: addressString,
      publicKey: publicKey,
      derivationIndex: diversifier,
      derivationPath: DerivationPath()..value = derivationPath,
      type: AddressType.spark,
      subType: AddressSubType.receiving,
    );
  }

  Future<Amount> estimateFeeForSpark(Amount amount) async {
    throw UnimplementedError();
  }

  Future<TxData> prepareSendSpark({
    required TxData txData,
  }) async {
    throw UnimplementedError();
  }

  Future<TxData> confirmSendSpark({
    required TxData txData,
  }) async {
    throw UnimplementedError();
  }

  // TODO lots of room for performance improvements here. Should be similar to
  // recoverSparkWallet but only fetch and check anonymity set data that we
  // have not yet parsed.
  Future<void> refreshSparkData() async {
    try {
      final latestSparkCoinId = await electrumXClient.getSparkLatestCoinId();

      // TODO improve performance by adding this call to the cached client
      final anonymitySet = await electrumXClient.getSparkAnonymitySet(
        coinGroupId: latestSparkCoinId.toString(),
      );

      // TODO loop over set and see which coins are ours using the FFI call `identifyCoin`
      List myCoins = [];

      // fetch metadata for myCoins

      // create list of Spark Coin isar objects

      // update wallet spark coins in isar

      // refresh spark balance?

      throw UnimplementedError();
    } catch (e, s) {
      // todo logging

      rethrow;
    }
  }

  /// Should only be called within the standard wallet [recover] function due to
  /// mutex locking. Otherwise behaviour MAY be undefined.
  Future<void> recoverSparkWallet(
      // {
      // required int latestSetId,
      // required Map<dynamic, dynamic> setDataMap,
      // required Set<String> usedSerialNumbers,
      // }
      ) async {
    try {
      // do we need to generate any spark address(es) here?

      final latestSparkCoinId = await electrumXClient.getSparkLatestCoinId();

      // TODO improve performance by adding this call to the cached client
      final anonymitySet = await electrumXClient.getSparkAnonymitySet(
        coinGroupId: latestSparkCoinId.toString(),
      );

      // TODO loop over set and see which coins are ours using the FFI call `identifyCoin`
      List myCoins = [];

      // fetch metadata for myCoins

      // create list of Spark Coin isar objects

      // update wallet spark coins in isar

      throw UnimplementedError();
    } catch (e, s) {
      // todo logging

      rethrow;
    }
  }

  @override
  Future<void> updateBalance() async {
    // call to super to update transparent balance (and lelantus balance if
    // what ever class this mixin is used on uses LelantusInterface as well)
    final normalBalanceFuture = super.updateBalance();

    throw UnimplementedError();

    // wait for normalBalanceFuture to complete before returning
    await normalBalanceFuture;
  }
}
