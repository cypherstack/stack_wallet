import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart' as btc;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/spark_coin.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

mixin SparkInterface on Bip39HDWallet, ElectrumXInterface {
  @override
  Future<void> init() async {
    Address? address = await getCurrentReceivingSparkAddress();
    if (address == null) {
      address = await generateNextSparkAddress();
      await mainDB.putAddress(address);
    } // TODO add other address types to wallet info?

    // await info.updateReceivingAddress(
    //   newAddress: address.value,
    //   isar: mainDB.isar,
    // );

    await super.init();
  }

  @override
  Future<List<Address>> fetchAddressesForElectrumXScan() async {
    final allAddresses = await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .group(
          (q) => q
              .typeEqualTo(AddressType.spark)
              .or()
              .typeEqualTo(AddressType.nonWallet)
              .or()
              .subTypeEqualTo(AddressSubType.nonWallet),
        )
        .findAll();
    return allAddresses;
  }

  Future<Address?> getCurrentReceivingSparkAddress() async {
    return await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(AddressType.spark)
        .sortByDerivationIndexDesc()
        .findFirst();
  }

  Future<Address> generateNextSparkAddress() async {
    final highestStoredDiversifier =
        (await getCurrentReceivingSparkAddress())?.derivationIndex;

    // default to starting at 1 if none found
    final int diversifier = (highestStoredDiversifier ?? 0) + 1;

    // TODO: check that this stays constant and only the diversifier changes?
    const index = 1;

    final root = await getRootHDNode();
    final String derivationPath;
    if (cryptoCurrency.network == CryptoCurrencyNetwork.test) {
      derivationPath = "$kSparkBaseDerivationPathTestnet$index";
    } else {
      derivationPath = "$kSparkBaseDerivationPath$index";
    }
    final keys = root.derivePath(derivationPath);

    final String addressString = await LibSpark.getAddress(
      privateKey: keys.privateKey.data,
      index: index,
      diversifier: diversifier,
      isTestNet: cryptoCurrency.network == CryptoCurrencyNetwork.test,
    );

    return Address(
      walletId: walletId,
      value: addressString,
      publicKey: keys.publicKey.data,
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
    // todo fetch
    final List<Uint8List> serializedMintMetas = [];
    final List<LibSparkCoin> myCoins = [];

    final currentId = await electrumXClient.getSparkLatestCoinId();
    final List<Map<String, dynamic>> setMaps = [];
    // for (int i = 0; i <= currentId; i++) {
    for (int i = currentId; i <= currentId; i++) {
      final set = await electrumXCachedClient.getSparkAnonymitySet(
        groupId: i.toString(),
        coin: info.coin,
      );
      set["coinGroupID"] = i;
      setMaps.add(set);
    }

    final allAnonymitySets = setMaps
        .map((e) => (
              setId: e["coinGroupID"] as int,
              setHash: e["setHash"] as String,
              set: (e["coins"] as List)
                  .map((e) => (
                        serializedCoin: e[0] as String,
                        txHash: e[1] as String,
                      ))
                  .toList(),
            ))
        .toList();

    // https://docs.google.com/document/d/1RG52GoYTZDvKlZz_3G4sQu-PpT6JWSZGHLNswWcrE3o/edit
    // To generate  a spark spend we need to call createSparkSpendTransaction,
    // first unlock the wallet and generate all 3 spark keys,
    const index = 1;

    final root = await getRootHDNode();
    final String derivationPath;
    if (cryptoCurrency.network == CryptoCurrencyNetwork.test) {
      derivationPath = "$kSparkBaseDerivationPathTestnet$index";
    } else {
      derivationPath = "$kSparkBaseDerivationPath$index";
    }
    final privateKey = root.derivePath(derivationPath).privateKey.data;
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

    // Amount vOut = Amount(
    //     rawValue: BigInt.zero, fractionDigits: cryptoCurrency.fractionDigits);
    // Amount mintVOut = Amount(
    //     rawValue: BigInt.zero, fractionDigits: cryptoCurrency.fractionDigits);
    // int recipientsToSubtractFee = 0;
    //
    // for (int i = 0; i < (txData.recipients?.length ?? 0); i++) {
    //   vOut += txData.recipients![i].amount;
    // }
    //
    // if (vOut.raw > BigInt.from(SPARK_VALUE_SPEND_LIMIT_PER_TRANSACTION)) {
    //   throw Exception(
    //     "Spend to transparent address limit exceeded (10,000 Firo per transaction).",
    //   );
    // }
    //
    // for (int i = 0; i < (txData.sparkRecipients?.length ?? 0); i++) {
    //   mintVOut += txData.sparkRecipients![i].amount;
    //   if (txData.sparkRecipients![i].subtractFeeFromAmount) {
    //     recipientsToSubtractFee++;
    //   }
    // }
    //
    // int fee;

    final txb = btc.TransactionBuilder(
      network: btc.NetworkType(
        messagePrefix: cryptoCurrency.networkParams.messagePrefix,
        bech32: cryptoCurrency.networkParams.bech32Hrp,
        bip32: btc.Bip32Type(
          public: cryptoCurrency.networkParams.pubHDPrefix,
          private: cryptoCurrency.networkParams.privHDPrefix,
        ),
        pubKeyHash: cryptoCurrency.networkParams.p2pkhPrefix,
        scriptHash: cryptoCurrency.networkParams.p2shPrefix,
        wif: cryptoCurrency.networkParams.wifPrefix,
      ),
    );
    txb.setLockTime(await chainHeight);
    txb.setVersion(3 | (9 << 16));

    // final estimated = LibSpark.selectSparkCoins(
    //   requiredAmount: mintVOut.raw.toInt(),
    //   subtractFeeFromAmount: recipientsToSubtractFee > 0,
    //   coins: myCoins,
    //   privateRecipientsCount: txData.sparkRecipients?.length ?? 0,
    // );
    //
    // fee = estimated.fee;
    // bool remainderSubtracted = false;

    // for (int i = 0; i < (txData.recipients?.length ?? 0); i++) {
    //
    //
    //   if (recipient.fSubtractFeeFromAmount) {
    //     // Subtract fee equally from each selected recipient.
    //     recipient.nAmount -= fee / recipientsToSubtractFee;
    //
    //     if (!remainderSubtracted) {
    //       // First receiver pays the remainder not divisible by output count.
    //       recipient.nAmount -= fee % recipientsToSubtractFee;
    //       remainderSubtracted = true;
    //     }
    //   }
    // }

    // outputs

    // for (int i = 0; i < (txData.sparkRecipients?.length ?? 0); i++) {
    //   if (txData.sparkRecipients![i].subtractFeeFromAmount) {
    //     BigInt amount = txData.sparkRecipients![i].amount.raw;
    //
    //     // Subtract fee equally from each selected recipient.
    //     amount -= BigInt.from(fee / recipientsToSubtractFee);
    //
    //     if (!remainderSubtracted) {
    //       // First receiver pays the remainder not divisible by output count.
    //       amount -= BigInt.from(fee % recipientsToSubtractFee);
    //       remainderSubtracted = true;
    //     }
    //
    //     txData.sparkRecipients![i] = (
    //       address: txData.sparkRecipients![i].address,
    //       amount: Amount(
    //         rawValue: amount,
    //         fractionDigits: cryptoCurrency.fractionDigits,
    //       ),
    //       subtractFeeFromAmount:
    //           txData.sparkRecipients![i].subtractFeeFromAmount,
    //       memo: txData.sparkRecipients![i].memo,
    //     );
    //   }
    // }
    //
    // int spendInCurrentTx = 0;
    // for (final spendCoin in estimated.coins) {
    //   spendInCurrentTx += spendCoin.value?.toInt() ?? 0;
    // }
    // spendInCurrentTx -= fee;
    //
    // int transparentOut = 0;

    for (int i = 0; i < (txData.recipients?.length ?? 0); i++) {
      if (txData.recipients![i].amount.raw == BigInt.zero) {
        continue;
      }
      if (txData.recipients![i].amount < cryptoCurrency.dustLimit) {
        throw Exception("Output below dust limit");
      }
      //
      // transparentOut += txData.recipients![i].amount.raw.toInt();
      txb.addOutput(
        txData.recipients![i].address,
        txData.recipients![i].amount.raw.toInt(),
      );
    }

    // // spendInCurrentTx -= transparentOut;
    // final List<({String address, int amount, String memo})> privOutputs = [];
    //
    // for (int i = 0; i < (txData.sparkRecipients?.length ?? 0); i++) {
    //   if (txData.sparkRecipients![i].amount.raw == BigInt.zero) {
    //     continue;
    //   }
    //
    //   final recipientAmount = txData.sparkRecipients![i].amount.raw.toInt();
    //   // spendInCurrentTx -= recipientAmount;
    //
    //   privOutputs.add(
    //     (
    //       address: txData.sparkRecipients![i].address,
    //       amount: recipientAmount,
    //       memo: txData.sparkRecipients![i].memo,
    //     ),
    //   );
    // }

    // if (spendInCurrentTx < 0) {
    //   throw Exception("Unable to create spend transaction.");
    // }
    //
    // if (privOutputs.isEmpty || spendInCurrentTx > 0) {
    //   final changeAddress = await LibSpark.getAddress(
    //     privateKey: privateKey,
    //     index: index,
    //     diversifier: kSparkChange,
    //   );
    //
    //   privOutputs.add(
    //     (
    //       address: changeAddress,
    //       amount: spendInCurrentTx > 0 ? spendInCurrentTx : 0,
    //       memo: "",
    //     ),
    //   );
    // }

    // inputs

    final opReturnScript = bscript.compile([
      0xd3, // OP_SPARKSPEND
      Uint8List(0),
    ]);

    txb.addInput(
      '0000000000000000000000000000000000000000000000000000000000000000',
      0xffffffff,
      0xffffffff,
      opReturnScript,
    );

    // final sig = extractedTx.getId();

    // for (final coin in estimated.coins) {
    //   final groupId = coin.id!;
    // }

    final spend = LibSpark.createSparkSendTransaction(
      privateKeyHex: privateKey.toHex,
      index: index,
      recipients: [],
      privateRecipients: txData.sparkRecipients
              ?.map((e) => (
                    sparkAddress: e.address,
                    amount: e.amount.raw.toInt(),
                    subtractFeeFromAmount: e.subtractFeeFromAmount,
                    memo: e.memo,
                  ))
              .toList() ??
          [],
      serializedMintMetas: serializedMintMetas,
      allAnonymitySets: allAnonymitySets,
    );

    print("SPARK SPEND ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    print("fee: ${spend.fee}");
    print("spend: ${spend.serializedSpendPayload}");
    print("scripts:");
    spend.outputScripts.forEach(print);
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

    for (final outputScript in spend.outputScripts) {
      txb.addOutput(outputScript, 0);
    }

    final extractedTx = txb.buildIncomplete();

    // TODO: verify encoding
    extractedTx.setPayload(spend.serializedSpendPayload.toUint8ListFromUtf8);

    final rawTxHex = extractedTx.toHex();

    return txData.copyWith(
      raw: rawTxHex,
      vSize: extractedTx.virtualSize(),
      fee: Amount(
        rawValue: BigInt.from(spend.fee),
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      // TODO used coins
    );
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
    final sparkAddresses = await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(AddressType.spark)
        .findAll();

    final Set<String> paths =
        sparkAddresses.map((e) => e.derivationPath!.value).toSet();

    try {
      const index = 1;

      final root = await getRootHDNode();

      final latestSparkCoinId = await electrumXClient.getSparkLatestCoinId();

      final futureResults = await Future.wait([
        electrumXCachedClient.getSparkAnonymitySet(
          groupId: latestSparkCoinId.toString(),
          coin: info.coin,
        ),
        electrumXCachedClient.getSparkUsedCoinsTags(coin: info.coin),
      ]);

      final anonymitySet = futureResults[0] as Map<String, dynamic>;
      final spentCoinTags = futureResults[1] as Set<String>;

      // find our coins
      final List<SparkCoin> myCoins = [];

      for (final path in paths) {
        final keys = root.derivePath(path);

        final privateKeyHex = keys.privateKey.data.toHex;

        for (final dynData in anonymitySet["coins"] as List) {
          final data = List<String>.from(dynData as List);

          if (data.length != 2) {
            throw Exception("Unexpected serialized coin info found");
          }

          final serializedCoin = data.first;
          final txHash = base64ToReverseHex(data.last);

          final coin = LibSpark.identifyAndRecoverCoin(
            serializedCoin,
            privateKeyHex: privateKeyHex,
            index: index,
            isTestNet: cryptoCurrency.network == CryptoCurrencyNetwork.test,
          );

          // its ours
          if (coin != null) {
            final SparkCoinType coinType;
            switch (coin.type.value) {
              case 0:
                coinType = SparkCoinType.mint;
              case 1:
                coinType = SparkCoinType.spend;
              default:
                throw Exception("Unknown spark coin type detected");
            }
            myCoins.add(
              SparkCoin(
                walletId: walletId,
                type: coinType,
                isUsed: spentCoinTags.contains(coin.lTagHash!),
                address: coin.address!,
                txHash: txHash,
                valueIntString: coin.value!.toString(),
                lTagHash: coin.lTagHash!,
                tag: coin.tag,
                memo: coin.memo,
                serial: coin.serial,
                serialContext: coin.serialContext,
                diversifierIntString: coin.diversifier!.toString(),
                encryptedDiversifier: coin.encryptedDiversifier,
              ),
            );
          }
        }
      }

      print("FOUND COINS: $myCoins");

      // update wallet spark coins in isar
      if (myCoins.isNotEmpty) {
        await mainDB.isar.writeTxn(() async {
          await mainDB.isar.sparkCoins.putAll(myCoins);
        });
      }

      // refresh spark balance?

      await prepareSendSpark(
          txData: TxData(
        sparkRecipients: [
          (
            address: (await getCurrentReceivingSparkAddress())!.value,
            amount: Amount(
                rawValue: BigInt.from(100000000),
                fractionDigits: cryptoCurrency.fractionDigits),
            subtractFeeFromAmount: true,
            memo: "LOL MEMO OPK",
          ),
        ],
      ));

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

      final anonymitySet = await electrumXCachedClient.getSparkAnonymitySet(
        groupId: latestSparkCoinId.toString(),
        coin: info.coin,
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

  /// Transparent to Spark (mint) transaction creation.
  ///
  /// See https://docs.google.com/document/d/1RG52GoYTZDvKlZz_3G4sQu-PpT6JWSZGHLNswWcrE3o
  Future<TxData> prepareSparkMintTransaction({required TxData txData}) async {
    // "this kind of transaction is generated like a regular transaction, but in
    // place of [regular] outputs we put spark outputs... we construct the input
    // part of the transaction first then we generate spark related data [and]
    // we sign like regular transactions at the end."

    // Validate inputs.

    // There should be at least one input.
    if (txData.utxos == null || txData.utxos!.isEmpty) {
      throw Exception("No inputs provided.");
    }

    // For now let's limit to one input.
    if (txData.utxos!.length > 1) {
      throw Exception("Only one input supported.");
      // TODO remove and test with multiple inputs.
    }

    // Validate individual inputs.
    for (final utxo in txData.utxos!) {
      // Input amount must be greater than zero.
      if (utxo.value == 0) {
        throw Exception("Input value cannot be zero.");
      }

      // Input value must be greater than dust limit.
      if (BigInt.from(utxo.value) < cryptoCurrency.dustLimit.raw) {
        throw Exception("Input value below dust limit.");
      }
    }

    // Validate outputs.

    // There should be at least one output.
    if (txData.recipients == null || txData.recipients!.isEmpty) {
      throw Exception("No recipients provided.");
    }

    // For now let's limit to one output.
    if (txData.recipients!.length > 1) {
      throw Exception("Only one recipient supported.");
      // TODO remove and test with multiple recipients.
    }

    // Limit outputs per tx to 16.
    //
    // See SPARK_OUT_LIMIT_PER_TX at https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/include/spark.h#L16
    if (txData.recipients!.length > 16) {
      throw Exception("Too many recipients.");
    }

    // Limit spend value per tx to 1000000000000 satoshis.
    //
    // See SPARK_VALUE_SPEND_LIMIT_PER_TRANSACTION at https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/include/spark.h#L17
    // and COIN https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/bitcoin/amount.h#L17
    // Note that as MAX_MONEY is greater than this limit, we can ignore it.  See https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/bitcoin/amount.h#L31
    //
    // This will be added to and checked as we validate outputs.
    Amount amountSent = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );

    // Validate individual outputs.
    for (final recipient in txData.recipients!) {
      // Output amount must be greater than zero.
      if (recipient.amount.raw == BigInt.zero) {
        throw Exception("Output amount cannot be zero.");
        // Could refactor this for loop to use an index and remove this output.
      }

      // Output amount must be greater than dust limit.
      if (recipient.amount < cryptoCurrency.dustLimit) {
        throw Exception("Output below dust limit.");
      }

      // Do not add outputs that would exceed the spend limit.
      amountSent += recipient.amount;
      if (amountSent.raw > BigInt.from(1000000000000)) {
        throw Exception(
          "Spend limit exceeded (10,000 FIRO per tx).",
        );
      }
    }

    // TODO create a transaction builder and add inputs.

    // Create the serial context.
    //
    // "...serial_context is a byte array, which should be unique for each
    // transaction, and for that we serialize and put all inputs into
    // serial_context vector. So we construct the input part of the transaction
    // first then we generate spark related data."
    List<int> serialContext = [];
    // TODO set serialContext to the serialized inputs.

    // Create mint recipients.
    final mintRecipients = LibSpark.createSparkMintRecipients(
      outputs: txData.recipients!
          .map((e) => (
                sparkAddress: e.address,
                value: e.amount.raw.toInt(),
                memo: "Stackwallet spark mint"
              ))
          .toList(),
      serialContext: Uint8List.fromList(serialContext),
      // generate: true // TODO is this needed?
    );

    // TODO finish.

    throw UnimplementedError();
  }

  /// Broadcast a tx and TODO update Spark balance.
  Future<TxData> confirmSparkMintTransaction({required TxData txData}) async {
    // Broadcast tx.
    final txid = await electrumXClient.broadcastTransaction(
      rawTx: txData.raw!,
    );

    // Check txid.
    assert(txid == txData.txid!);

    // TODO update spark balance.

    return txData.copyWith(
      txid: txid,
    );
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

String base64ToReverseHex(String source) =>
    base64Decode(LineSplitter.split(source).join())
        .reversed
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
