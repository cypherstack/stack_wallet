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

  /// Spark to Spark/Transparent (spend) creation
  Future<TxData> prepareSendSpark({
    required TxData txData,
  }) async {
    // https://docs.google.com/document/d/1RG52GoYTZDvKlZz_3G4sQu-PpT6JWSZGHLNswWcrE3o/edit
    // To generate  a spark spend we need to call createSparkSpendTransaction,
    // first unlock the wallet and generate all 3 spark keys,
    final spendKey = await _getSpendKey();

    //
    // recipients is a list of pairs of amounts and bools, this is for transparent
    // outputs, first how much to send and second, subtractFeeFromAmount argument
    // for each receiver.
    //
    // privateRecipients is again the list of pairs, first the receiver data
    // which has following members, Address which is any spark address,
    // amount (v) how much we want to send, and memo which can be any string
    // with 32 length (any string we want to send to receiver), and the second
    // subtractFeeFromAmount,
    //
    // coins is the list of all our available spark coins
    //
    // cover_set_data_all is the list of all anonymity sets,
    //
    // idAndBlockHashes_all is the list of block hashes for each anonymity set
    //
    // txHashSig is the transaction hash only without spark data, tx version,
    // type, transparent outputs and everything else should be set before generating it.
    //
    // fee is a output data
    //
    // serializedSpend is a output data, byte array with spark spend, we need
    // to put it into vExtraPayload (this naming can be different in your codebase)
    //
    // outputScripts is a output data, it is a list of scripts, which we need
    // to put in separate tx outputs, and keep the order,

    throw UnimplementedError();
  }

  // this may not be needed for either mints or spends or both
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

      // check against spent list (this call could possibly also be cached later on)
      final spentCoinTags = await electrumXClient.getSparkUsedCoinsTags(
        startNumber: 0,
      );

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

  /// Transparent to Spark (mint) transaction creation
  Future<TxData> prepareSparkMintTransaction({required TxData txData}) async {
    // https://docs.google.com/document/d/1RG52GoYTZDvKlZz_3G4sQu-PpT6JWSZGHLNswWcrE3o/edit

    // this kind of transaction is generated like a regular transaction, but in
    // place of regulart outputs we put spark outputs, so for that we call
    // createSparkMintRecipients function, we get spark related data,
    // everything else we do like for regular transaction, and we put CRecipient
    // object as a tx outputs, we need to keep the order..
    // First we pass spark::MintedCoinData>, has following members, Address
    // which is any spark address, amount (v) how much we want to send, and
    // memo which can be any string with 32 length (any string we want to send
    // to receiver), serial_context is a byte array, which should be unique for
    // each transaction, and for that we serialize and put all inputs into
    // serial_context vector. So we construct the input part of the transaction
    // first then we generate spark related data. And we sign like regular
    // transactions at the end.

    throw UnimplementedError();
  }

  @override
  Future<void> updateBalance() async {
    // call to super to update transparent balance (and lelantus balance if
    // what ever class this mixin is used on uses LelantusInterface as well)
    final normalBalanceFuture = super.updateBalance();

    // todo: spark balance aka update info.tertiaryBalance

    // wait for normalBalanceFuture to complete before returning
    await normalBalanceFuture;
  }
}
