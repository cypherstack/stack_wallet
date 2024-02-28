import 'dart:convert';
import 'dart:math';

import 'package:bitcoindart/bitcoindart.dart' as btc;
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/signing_data.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/spark_coin.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

const kDefaultSparkIndex = 1;

// TODO dart style constants. Maybe move to spark lib?
const MAX_STANDARD_TX_WEIGHT = 400000;

//https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/include/spark.h#L16
const SPARK_OUT_LIMIT_PER_TX = 16;

const OP_SPARKMINT = 0xd1;
const OP_SPARKSMINT = 0xd2;
const OP_SPARKSPEND = 0xd3;

mixin SparkInterface on Bip39HDWallet, ElectrumXInterface {
  String? _sparkChangeAddressCached;

  /// Spark change address. Should generally not be exposed to end users.
  String get sparkChangeAddress {
    if (_sparkChangeAddressCached == null) {
      throw Exception("_sparkChangeAddressCached was not initialized");
    }
    return _sparkChangeAddressCached!;
  }

  static bool validateSparkAddress({
    required String address,
    required bool isTestNet,
  }) =>
      LibSpark.validateAddress(address: address, isTestNet: isTestNet);

  @override
  Future<void> init() async {
    try {
      Address? address = await getCurrentReceivingSparkAddress();
      if (address == null) {
        address = await generateNextSparkAddress();
        await mainDB.putAddress(address);
      } // TODO add other address types to wallet info?

      if (_sparkChangeAddressCached == null) {
        final root = await getRootHDNode();
        final String derivationPath;
        if (cryptoCurrency.network == CryptoCurrencyNetwork.test) {
          derivationPath =
              "$kSparkBaseDerivationPathTestnet$kDefaultSparkIndex";
        } else {
          derivationPath = "$kSparkBaseDerivationPath$kDefaultSparkIndex";
        }
        final keys = root.derivePath(derivationPath);

        _sparkChangeAddressCached = await LibSpark.getAddress(
          privateKey: keys.privateKey.data,
          index: kDefaultSparkIndex,
          diversifier: kSparkChange,
          isTestNet: cryptoCurrency.network == CryptoCurrencyNetwork.test,
        );
      }
    } catch (e, s) {
      // do nothing, still allow user into wallet
      Logging.instance.log(
        "$runtimeType init() failed: $e\n$s",
        level: LogLevel.Error,
      );
    }

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
    int diversifier = (highestStoredDiversifier ?? 0) + 1;
    // change address check
    if (diversifier == kSparkChange) {
      diversifier++;
    }

    final root = await getRootHDNode();
    final String derivationPath;
    if (cryptoCurrency.network == CryptoCurrencyNetwork.test) {
      derivationPath = "$kSparkBaseDerivationPathTestnet$kDefaultSparkIndex";
    } else {
      derivationPath = "$kSparkBaseDerivationPath$kDefaultSparkIndex";
    }
    final keys = root.derivePath(derivationPath);

    final String addressString = await LibSpark.getAddress(
      privateKey: keys.privateKey.data,
      index: kDefaultSparkIndex,
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
    // int spendAmount = amount.raw.toInt();
    // if (spendAmount == 0) {
    return Amount(
      rawValue: BigInt.from(0),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    // }
    // TODO actual fee estimation
  }

  /// Spark to Spark/Transparent (spend) creation
  Future<TxData> prepareSendSpark({
    required TxData txData,
  }) async {
    // There should be at least one output.
    if (!(txData.recipients?.isNotEmpty == true ||
        txData.sparkRecipients?.isNotEmpty == true)) {
      throw Exception("No recipients provided.");
    }

    if (txData.sparkRecipients?.isNotEmpty == true &&
        txData.sparkRecipients!.length >= SPARK_OUT_LIMIT_PER_TX - 1) {
      throw Exception("Spark shielded output limit exceeded.");
    }

    final transparentSumOut =
        (txData.recipients ?? []).map((e) => e.amount).fold(
            Amount(
              rawValue: BigInt.zero,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            (p, e) => p + e);

    // See SPARK_VALUE_SPEND_LIMIT_PER_TRANSACTION at https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/include/spark.h#L17
    // and COIN https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/bitcoin/amount.h#L17
    // Note that as MAX_MONEY is greater than this limit, we can ignore it.  See https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/bitcoin/amount.h#L31
    if (transparentSumOut >
        Amount.fromDecimal(
          Decimal.parse("10000"),
          fractionDigits: cryptoCurrency.fractionDigits,
        )) {
      throw Exception(
          "Spend to transparent address limit exceeded (10,000 Firo per transaction).");
    }

    final sparkSumOut =
        (txData.sparkRecipients ?? []).map((e) => e.amount).fold(
            Amount(
              rawValue: BigInt.zero,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            (p, e) => p + e);

    final txAmount = transparentSumOut + sparkSumOut;

    // fetch spendable spark coins
    final coins = await mainDB.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(walletId)
        .filter()
        .isUsedEqualTo(false)
        .and()
        .heightIsNotNull()
        .and()
        .not()
        .valueIntStringEqualTo("0")
        .findAll();

    final available = info.cachedBalanceTertiary.spendable;

    if (txAmount > available) {
      throw Exception("Insufficient Spark balance");
    }

    final bool isSendAll = available == txAmount;

    // prepare coin data for ffi
    final serializedCoins = coins
        .map((e) => (
              serializedCoin: e.serializedCoinB64!,
              serializedCoinContext: e.contextB64!,
              groupId: e.groupId,
              height: e.height!,
            ))
        .toList();

    final currentId = await electrumXClient.getSparkLatestCoinId();
    final List<Map<String, dynamic>> setMaps = [];
    final List<({int groupId, String blockHash})> idAndBlockHashes = [];
    for (int i = 1; i <= currentId; i++) {
      final set = await electrumXCachedClient.getSparkAnonymitySet(
        groupId: i.toString(),
        coin: info.coin,
      );
      set["coinGroupID"] = i;
      setMaps.add(set);
      idAndBlockHashes.add(
        (
          groupId: i,
          blockHash: set["blockHash"] as String,
        ),
      );
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

    final root = await getRootHDNode();
    final String derivationPath;
    if (cryptoCurrency.network == CryptoCurrencyNetwork.test) {
      derivationPath = "$kSparkBaseDerivationPathTestnet$kDefaultSparkIndex";
    } else {
      derivationPath = "$kSparkBaseDerivationPath$kDefaultSparkIndex";
    }
    final privateKey = root.derivePath(derivationPath).privateKey.data;

    final txb = btc.TransactionBuilder(
      network: _bitcoinDartNetwork,
    );
    txb.setLockTime(await chainHeight);
    txb.setVersion(3 | (9 << 16));

    List<
        ({
          String address,
          Amount amount,
          bool isChange,
        })>? recipientsWithFeeSubtracted;
    List<
        ({
          String address,
          Amount amount,
          String memo,
          bool isChange,
        })>? sparkRecipientsWithFeeSubtracted;
    final recipientCount = (txData.recipients
            ?.where(
              (e) => e.amount.raw > BigInt.zero,
            )
            .length ??
        0);
    final totalRecipientCount =
        recipientCount + (txData.sparkRecipients?.length ?? 0);
    final BigInt estimatedFee;
    if (isSendAll) {
      final estFee = LibSpark.estimateSparkFee(
        privateKeyHex: privateKey.toHex,
        index: kDefaultSparkIndex,
        sendAmount: txAmount.raw.toInt(),
        subtractFeeFromAmount: true,
        serializedCoins: serializedCoins,
        privateRecipientsCount: (txData.sparkRecipients?.length ?? 0),
      );
      estimatedFee = BigInt.from(estFee);
    } else {
      estimatedFee = BigInt.zero;
    }

    if ((txData.sparkRecipients?.length ?? 0) > 0) {
      sparkRecipientsWithFeeSubtracted = [];
    }
    if (recipientCount > 0) {
      recipientsWithFeeSubtracted = [];
    }

    for (int i = 0; i < (txData.sparkRecipients?.length ?? 0); i++) {
      sparkRecipientsWithFeeSubtracted!.add(
        (
          address: txData.sparkRecipients![i].address,
          amount: Amount(
            rawValue: txData.sparkRecipients![i].amount.raw -
                (estimatedFee ~/ BigInt.from(totalRecipientCount)),
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          memo: txData.sparkRecipients![i].memo,
          isChange: sparkChangeAddress == txData.sparkRecipients![i].address,
        ),
      );
    }

    // temp tx data to show in gui while waiting for real data from server
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    for (int i = 0; i < (txData.recipients?.length ?? 0); i++) {
      if (txData.recipients![i].amount.raw == BigInt.zero) {
        continue;
      }
      recipientsWithFeeSubtracted!.add(
        (
          address: txData.recipients![i].address,
          amount: Amount(
            rawValue: txData.recipients![i].amount.raw -
                (estimatedFee ~/ BigInt.from(totalRecipientCount)),
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          isChange: txData.recipients![i].isChange,
        ),
      );

      final scriptPubKey = btc.Address.addressToOutputScript(
        txData.recipients![i].address,
        _bitcoinDartNetwork,
      );
      txb.addOutput(
        scriptPubKey,
        recipientsWithFeeSubtracted[i].amount.raw.toInt(),
      );

      tempOutputs.add(
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: scriptPubKey.toHex,
          valueStringSats: recipientsWithFeeSubtracted[i].amount.raw.toString(),
          addresses: [
            recipientsWithFeeSubtracted[i].address.toString(),
          ],
          walletOwns: (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .valueEqualTo(recipientsWithFeeSubtracted[i].address)
                  .valueProperty()
                  .findFirst()) !=
              null,
        ),
      );
    }

    if (sparkRecipientsWithFeeSubtracted != null) {
      for (final recip in sparkRecipientsWithFeeSubtracted) {
        tempOutputs.add(
          OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: Uint8List.fromList([OP_SPARKSMINT]).toHex,
            valueStringSats: recip.amount.raw.toString(),
            addresses: [
              recip.address.toString(),
            ],
            walletOwns: (await mainDB.isar.addresses
                    .where()
                    .walletIdEqualTo(walletId)
                    .filter()
                    .valueEqualTo(recip.address)
                    .valueProperty()
                    .findFirst()) !=
                null,
          ),
        );
      }
    }

    final extractedTx = txb.buildIncomplete();
    extractedTx.addInput(
      '0000000000000000000000000000000000000000000000000000000000000000'
          .toUint8ListFromHex,
      0xffffffff,
      0xffffffff,
      "d3".toUint8ListFromHex, // OP_SPARKSPEND
    );
    extractedTx.setPayload(Uint8List(0));

    final spend = await compute(
      _createSparkSend,
      (
        privateKeyHex: privateKey.toHex,
        index: kDefaultSparkIndex,
        recipients: txData.recipients
                ?.map((e) => (
                      address: e.address,
                      amount: e.amount.raw.toInt(),
                      subtractFeeFromAmount: isSendAll,
                    ))
                .toList() ??
            [],
        privateRecipients: txData.sparkRecipients
                ?.map((e) => (
                      sparkAddress: e.address,
                      amount: e.amount.raw.toInt(),
                      subtractFeeFromAmount: isSendAll,
                      memo: e.memo,
                    ))
                .toList() ??
            [],
        serializedCoins: serializedCoins,
        allAnonymitySets: allAnonymitySets,
        idAndBlockHashes: idAndBlockHashes
            .map(
                (e) => (setId: e.groupId, blockHash: base64Decode(e.blockHash)))
            .toList(),
        txHash: extractedTx.getHash(),
      ),
    );

    for (final outputScript in spend.outputScripts) {
      extractedTx.addOutput(outputScript, 0);
    }

    extractedTx.setPayload(spend.serializedSpendPayload);
    final rawTxHex = extractedTx.toHex();

    if (isSendAll) {
      txData = txData.copyWith(
        recipients: recipientsWithFeeSubtracted,
        sparkRecipients: sparkRecipientsWithFeeSubtracted,
      );
    }

    final fee = Amount(
      rawValue: BigInt.from(spend.fee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );

    tempInputs.add(
      InputV2.isarCantDoRequiredInDefaultConstructor(
        scriptSigHex: "d3",
        scriptSigAsm: null,
        sequence: 0xffffffff,
        outpoint: null,
        addresses: [],
        valueStringSats: tempOutputs
            .map((e) => e.value)
            .fold(fee.raw, (p, e) => p + e)
            .toString(),
        witness: null,
        innerRedeemScriptAsm: null,
        coinbase: null,
        walletOwns: true,
      ),
    );

    return txData.copyWith(
      raw: rawTxHex,
      vSize: extractedTx.virtualSize(),
      fee: fee,
      tempTx: TransactionV2(
        walletId: walletId,
        blockHash: null,
        hash: extractedTx.getId(),
        txid: extractedTx.getId(),
        timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(tempInputs),
        outputs: List.unmodifiable(tempOutputs),
        type: tempOutputs.map((e) => e.walletOwns).fold(true, (p, e) => p &= e)
            ? TransactionType.sentToSelf
            : TransactionType.outgoing,
        subType: TransactionSubType.sparkSpend,
        otherData: jsonEncode(
          {
            "overrideFee": fee.toJsonString(),
          },
        ),
        height: null,
        version: 3,
      ),
      usedCoins: spend.usedCoins,
    );
  }

  // this may not be needed for either mints or spends or both
  Future<TxData> confirmSendSpark({
    required TxData txData,
  }) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);

      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      txData = txData.copyWith(
        // TODO revisit setting these both
        txHash: txHash,
        txid: txHash,
      );

      // Update coins as used in database.
      final List<SparkCoin> usedCoins = [];
      for (final usedCoin in txData.usedCoins!) {
        // Find the SparkCoin that matches the usedCoin.
        final sparkCoin = await mainDB.isar.sparkCoins
            .where()
            .walletIdEqualToAnyLTagHash(walletId)
            .filter()
            .serializedCoinB64EqualTo(usedCoin.serializedCoin)
            .findFirst();

        // Add the SparkCoin to usedCoins if it exists.
        if (sparkCoin != null) {
          usedCoins.add(sparkCoin.copyWith(isUsed: true));
        }
      }

      // Update the SparkCoins in the database.
      await _addOrUpdateSparkCoins(usedCoins);

      return await updateSentCachedTxData(txData: txData);
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
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
      final latestSparkCoinId = await electrumXClient.getSparkLatestCoinId();

      final blockHash = await _getCachedSparkBlockHash();

      final anonymitySetFuture = blockHash == null
          ? electrumXCachedClient.getSparkAnonymitySet(
              groupId: latestSparkCoinId.toString(),
              coin: info.coin,
            )
          : electrumXClient.getSparkAnonymitySet(
              coinGroupId: latestSparkCoinId.toString(),
              startBlockHash: blockHash,
            );
      final spentCoinTagsFuture =
          electrumXClient.getSparkUsedCoinsTags(startNumber: 0);
      // electrumXCachedClient.getSparkUsedCoinsTags(coin: info.coin);

      final futureResults = await Future.wait([
        anonymitySetFuture,
        spentCoinTagsFuture,
      ]);

      final anonymitySet = futureResults[0] as Map<String, dynamic>;
      final spentCoinTags = futureResults[1] as Set<String>;

      final List<SparkCoin> myCoins = [];

      if (anonymitySet["coins"] is List &&
          (anonymitySet["coins"] as List).isNotEmpty) {
        final root = await getRootHDNode();
        final privateKeyHexSet = paths
            .map(
              (e) => root.derivePath(e).privateKey.data.toHex,
            )
            .toSet();

        final identifiedCoins = await compute(
          _identifyCoins,
          (
            anonymitySetCoins: anonymitySet["coins"] as List,
            groupId: latestSparkCoinId,
            spentCoinTags: spentCoinTags,
            privateKeyHexSet: privateKeyHexSet,
            walletId: walletId,
            isTestNet: cryptoCurrency.network == CryptoCurrencyNetwork.test,
          ),
        );

        myCoins.addAll(identifiedCoins);

        // update blockHash in cache
        final String newBlockHash =
            base64ToReverseHex(anonymitySet["blockHash"] as String);
        await _setCachedSparkBlockHash(newBlockHash);
      }

      // check current coins
      final currentCoins = await mainDB.isar.sparkCoins
          .where()
          .walletIdEqualToAnyLTagHash(walletId)
          .filter()
          .isUsedEqualTo(false)
          .findAll();
      for (final coin in currentCoins) {
        if (spentCoinTags.contains(coin.lTagHash)) {
          myCoins.add(coin.copyWith(isUsed: true));
        }
      }

      // update wallet spark coins in isar
      await _addOrUpdateSparkCoins(myCoins);

      // refresh spark balance
      await refreshSparkBalance();
    } catch (e, s) {
      // todo logging

      rethrow;
    }
  }

  Future<void> refreshSparkBalance() async {
    final currentHeight = await chainHeight;
    final unusedCoins = await mainDB.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(walletId)
        .filter()
        .isUsedEqualTo(false)
        .findAll();

    final total = Amount(
      rawValue: unusedCoins
          .map((e) => e.value)
          .fold(BigInt.zero, (prev, e) => prev + e),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    final spendable = Amount(
      rawValue: unusedCoins
          .where((e) =>
              e.height != null &&
              e.height! + cryptoCurrency.minConfirms <= currentHeight)
          .map((e) => e.value)
          .fold(BigInt.zero, (prev, e) => prev + e),
      fractionDigits: cryptoCurrency.fractionDigits,
    );

    final sparkBalance = Balance(
      total: total,
      spendable: spendable,
      blockedTotal: Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      pendingSpendable: total - spendable,
    );

    await info.updateBalanceTertiary(
      newBalance: sparkBalance,
      isar: mainDB.isar,
    );
  }

  /// Should only be called within the standard wallet [recover] function due to
  /// mutex locking. Otherwise behaviour MAY be undefined.
  Future<void> recoverSparkWallet({
    required Map<dynamic, dynamic> anonymitySet,
    required Set<String> spentCoinTags,
  }) async {
    //   generate spark addresses if non existing
    if (await getCurrentReceivingSparkAddress() == null) {
      final address = await generateNextSparkAddress();
      await mainDB.putAddress(address);
    }

    final sparkAddresses = await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(AddressType.spark)
        .findAll();

    final Set<String> paths =
        sparkAddresses.map((e) => e.derivationPath!.value).toSet();

    try {
      final root = await getRootHDNode();
      final privateKeyHexSet =
          paths.map((e) => root.derivePath(e).privateKey.data.toHex).toSet();

      final myCoins = await compute(
        _identifyCoins,
        (
          anonymitySetCoins: anonymitySet["coins"] as List,
          groupId: anonymitySet["coinGroupID"] as int,
          spentCoinTags: spentCoinTags,
          privateKeyHexSet: privateKeyHexSet,
          walletId: walletId,
          isTestNet: cryptoCurrency.network == CryptoCurrencyNetwork.test,
        ),
      );

      // update wallet spark coins in isar
      await _addOrUpdateSparkCoins(myCoins);

      // update blockHash in cache
      final String newBlockHash = anonymitySet["blockHash"] as String;
      await _setCachedSparkBlockHash(newBlockHash);

      // refresh spark balance
      await refreshSparkBalance();
    } catch (e, s) {
      // todo logging

      rethrow;
    }
  }

  // modelled on CSparkWallet::CreateSparkMintTransactions https://github.com/firoorg/firo/blob/39c41e5e7ec634ced3700fe3f4f5509dc2e480d0/src/spark/sparkwallet.cpp#L752
  Future<List<TxData>> _createSparkMintTransactions({
    required List<UTXO> availableUtxos,
    required List<MutableSparkRecipient> outputs,
    required bool subtractFeeFromAmount,
    required bool autoMintAll,
  }) async {
    // pre checks
    if (outputs.isEmpty) {
      throw Exception("Cannot mint without some recipients");
    }

    // TODO remove when multiple recipients gui is added. Will need to handle
    // addresses when confirming the transactions later as well
    assert(outputs.length == 1);

    BigInt valueToMint =
        outputs.map((e) => e.value).reduce((value, element) => value + element);

    if (valueToMint <= BigInt.zero) {
      throw Exception("Cannot mint amount=$valueToMint");
    }
    final totalUtxosValue = _sum(availableUtxos);
    if (valueToMint > totalUtxosValue) {
      throw Exception("Insufficient balance to create spark mint(s)");
    }

    // organise utxos
    Map<String, List<UTXO>> utxosByAddress = {};
    for (final utxo in availableUtxos) {
      utxosByAddress[utxo.address!] ??= [];
      utxosByAddress[utxo.address!]!.add(utxo);
    }
    final valueAndUTXOs = utxosByAddress.values.toList();

    // setup some vars
    int nChangePosInOut = -1;
    int nChangePosRequest = nChangePosInOut;
    List<MutableSparkRecipient> outputs_ = outputs
        .map((e) => MutableSparkRecipient(e.address, e.value, e.memo))
        .toList(); // deep copy
    final feesObject = await fees;
    final currentHeight = await chainHeight;
    final random = Random.secure();
    final List<TxData> results = [];

    valueAndUTXOs.shuffle(random);

    while (valueAndUTXOs.isNotEmpty) {
      final lockTime = random.nextInt(10) == 0
          ? max(0, currentHeight - random.nextInt(100))
          : currentHeight;
      const txVersion = 1;
      final List<SigningData> vin = [];
      final List<(dynamic, int, String?)> vout = [];

      BigInt nFeeRet = BigInt.zero;

      final itr = valueAndUTXOs.first;
      BigInt valueToMintInTx = _sum(itr);

      if (!autoMintAll) {
        valueToMintInTx = _min(valueToMintInTx, valueToMint);
      }

      BigInt nValueToSelect, mintedValue;
      final List<SigningData> setCoins = [];
      bool skipCoin = false;

      // Start with no fee and loop until there is enough fee
      while (true) {
        mintedValue = valueToMintInTx;

        if (subtractFeeFromAmount) {
          nValueToSelect = mintedValue;
        } else {
          nValueToSelect = mintedValue + nFeeRet;
        }

        // if not enough coins in this group then subtract fee from mint
        if (nValueToSelect > _sum(itr) && !subtractFeeFromAmount) {
          nValueToSelect = mintedValue;
          mintedValue -= nFeeRet;
        }

        // if (!MoneyRange(mintedValue) || mintedValue == 0) {
        if (mintedValue == BigInt.zero) {
          valueAndUTXOs.remove(itr);
          skipCoin = true;
          break;
        }

        nChangePosInOut = nChangePosRequest;
        vin.clear();
        vout.clear();
        setCoins.clear();

        // deep copy
        final remainingOutputs = outputs_
            .map((e) => MutableSparkRecipient(e.address, e.value, e.memo))
            .toList();
        final List<MutableSparkRecipient> singleTxOutputs = [];

        if (autoMintAll) {
          singleTxOutputs.add(
            MutableSparkRecipient(
              (await getCurrentReceivingSparkAddress())!.value,
              mintedValue,
              "",
            ),
          );
        } else {
          BigInt remainingMintValue = BigInt.parse(mintedValue.toString());

          while (remainingMintValue > BigInt.zero) {
            final singleMintValue =
                _min(remainingMintValue, remainingOutputs.first.value);
            singleTxOutputs.add(
              MutableSparkRecipient(
                remainingOutputs.first.address,
                singleMintValue,
                remainingOutputs.first.memo,
              ),
            );

            // subtract minted amount from remaining value
            remainingMintValue -= singleMintValue;
            remainingOutputs.first.value -= singleMintValue;

            if (remainingOutputs.first.value == BigInt.zero) {
              remainingOutputs.remove(remainingOutputs.first);
            }
          }
        }

        if (subtractFeeFromAmount) {
          final BigInt singleFee =
              nFeeRet ~/ BigInt.from(singleTxOutputs.length);
          BigInt remainder = nFeeRet % BigInt.from(singleTxOutputs.length);

          for (int i = 0; i < singleTxOutputs.length; ++i) {
            if (singleTxOutputs[i].value <= singleFee) {
              singleTxOutputs.removeAt(i);
              remainder += singleTxOutputs[i].value - singleFee;
              --i;
            }
            singleTxOutputs[i].value -= singleFee;
            if (remainder > BigInt.zero &&
                singleTxOutputs[i].value >
                    nFeeRet % BigInt.from(singleTxOutputs.length)) {
              // first receiver pays the remainder not divisible by output count
              singleTxOutputs[i].value -= remainder;
              remainder = BigInt.zero;
            }
          }
        }

        // Generate dummy mint coins to save time
        final dummyRecipients = LibSpark.createSparkMintRecipients(
          outputs: singleTxOutputs
              .map((e) => (
                    sparkAddress: e.address,
                    value: e.value.toInt(),
                    memo: "",
                  ))
              .toList(),
          serialContext: Uint8List(0),
          generate: false,
        );

        final dummyTxb = btc.TransactionBuilder(network: _bitcoinDartNetwork);
        dummyTxb.setVersion(txVersion);
        dummyTxb.setLockTime(lockTime);
        for (int i = 0; i < dummyRecipients.length; i++) {
          final recipient = dummyRecipients[i];
          if (recipient.amount < cryptoCurrency.dustLimit.raw.toInt()) {
            throw Exception("Output amount too small");
          }
          vout.add((
            recipient.scriptPubKey,
            recipient.amount,
            singleTxOutputs[i].address,
          ));
        }

        // Choose coins to use
        BigInt nValueIn = BigInt.zero;
        for (final utxo in itr) {
          if (nValueToSelect > nValueIn) {
            setCoins.add((await fetchBuildTxData([utxo])).first);
            nValueIn += BigInt.from(utxo.value);
          }
        }
        if (nValueIn < nValueToSelect) {
          throw Exception("Insufficient funds");
        }

        // priority stuff???

        BigInt nChange = nValueIn - nValueToSelect;
        if (nChange > BigInt.zero) {
          if (nChange < cryptoCurrency.dustLimit.raw) {
            nChangePosInOut = -1;
            nFeeRet += nChange;
          } else {
            if (nChangePosInOut == -1) {
              nChangePosInOut = random.nextInt(vout.length + 1);
            } else if (nChangePosInOut > vout.length) {
              throw Exception("Change index out of range");
            }

            final changeAddress = await getCurrentChangeAddress();
            vout.insert(
              nChangePosInOut,
              (changeAddress!.value, nChange.toInt(), null),
            );
          }
        }

        // add outputs for dummy tx to check fees
        for (final out in vout) {
          dummyTxb.addOutput(out.$1, out.$2);
        }

        // fill vin
        for (final sd in setCoins) {
          vin.add(sd);

          // add to dummy tx
          dummyTxb.addInput(
            sd.utxo.txid,
            sd.utxo.vout,
            0xffffffff -
                1, // minus 1 is important. 0xffffffff on its own will burn funds
            sd.output,
          );
        }

        // sign dummy tx
        for (var i = 0; i < setCoins.length; i++) {
          dummyTxb.sign(
            vin: i,
            keyPair: setCoins[i].keyPair!,
            witnessValue: setCoins[i].utxo.value,
            redeemScript: setCoins[i].redeemScript,
          );
        }

        final dummyTx = dummyTxb.build();
        final nBytes = dummyTx.virtualSize();

        if (dummyTx.weight() > MAX_STANDARD_TX_WEIGHT) {
          throw Exception("Transaction too large");
        }

        final nFeeNeeded = BigInt.from(
          estimateTxFee(
            vSize: nBytes,
            feeRatePerKB: feesObject.medium,
          ),
        ); // One day we'll do this properly

        if (nFeeRet >= nFeeNeeded) {
          for (final usedCoin in setCoins) {
            itr.removeWhere((e) => e == usedCoin.utxo);
          }
          if (itr.isEmpty) {
            final preLength = valueAndUTXOs.length;
            valueAndUTXOs.remove(itr);
            assert(preLength - 1 == valueAndUTXOs.length);
          }

          // Generate real mint coins
          final serialContext = LibSpark.serializeMintContext(
            inputs: setCoins
                .map((e) => (
                      e.utxo.txid,
                      e.utxo.vout,
                    ))
                .toList(),
          );
          final recipients = LibSpark.createSparkMintRecipients(
            outputs: singleTxOutputs
                .map(
                  (e) => (
                    sparkAddress: e.address,
                    memo: e.memo,
                    value: e.value.toInt(),
                  ),
                )
                .toList(),
            serialContext: serialContext,
            generate: true,
          );

          int i = 0;
          for (int i = 0; i < recipients.length; i++) {
            final recipient = recipients[i];
            final out = (
              recipient.scriptPubKey,
              recipient.amount,
              singleTxOutputs[i].address,
            );
            while (i < vout.length) {
              if (vout[i].$1 is Uint8List &&
                  (vout[i].$1 as Uint8List).isNotEmpty &&
                  (vout[i].$1 as Uint8List)[0] == OP_SPARKMINT) {
                vout[i] = out;
                break;
              }
              ++i;
            }
            ++i;
          }

          // deep copy
          outputs_ = remainingOutputs
              .map((e) => MutableSparkRecipient(e.address, e.value, e.memo))
              .toList();

          break; // Done, enough fee included.
        }

        // Include more fee and try again.
        nFeeRet = nFeeNeeded;
        continue;
      }

      if (skipCoin) {
        continue;
      }

      // temp tx data to show in gui while waiting for real data from server
      final List<InputV2> tempInputs = [];
      final List<OutputV2> tempOutputs = [];

      // sign
      final txb = btc.TransactionBuilder(network: _bitcoinDartNetwork);
      txb.setVersion(txVersion);
      txb.setLockTime(lockTime);
      for (final input in vin) {
        txb.addInput(
          input.utxo.txid,
          input.utxo.vout,
          0xffffffff -
              1, // minus 1 is important. 0xffffffff on its own will burn funds
          input.output,
        );

        tempInputs.add(
          InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: txb.inputs.first.script?.toHex,
            scriptSigAsm: null,
            sequence: 0xffffffff - 1,
            outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
              txid: input.utxo.txid,
              vout: input.utxo.vout,
            ),
            addresses: input.utxo.address == null ? [] : [input.utxo.address!],
            valueStringSats: input.utxo.value.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: true,
          ),
        );
      }

      for (final output in vout) {
        final addressOrScript = output.$1;
        final value = output.$2;
        txb.addOutput(addressOrScript, value);

        tempOutputs.add(
          OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex:
                addressOrScript is Uint8List ? addressOrScript.toHex : "000000",
            valueStringSats: value.toString(),
            addresses: [
              if (addressOrScript is String) addressOrScript.toString(),
            ],
            walletOwns: (await mainDB.isar.addresses
                    .where()
                    .walletIdEqualTo(walletId)
                    .filter()
                    .valueEqualTo(addressOrScript is Uint8List
                        ? output.$3!
                        : addressOrScript as String)
                    .valueProperty()
                    .findFirst()) !=
                null,
          ),
        );
      }

      try {
        for (var i = 0; i < vin.length; i++) {
          txb.sign(
            vin: i,
            keyPair: vin[i].keyPair!,
            witnessValue: vin[i].utxo.value,
            redeemScript: vin[i].redeemScript,
          );
        }
      } catch (e, s) {
        Logging.instance.log(
          "Caught exception while signing spark mint transaction: $e\n$s",
          level: LogLevel.Error,
        );
        rethrow;
      }
      final builtTx = txb.build();

      // TODO: see todo at top of this function
      assert(outputs.length == 1);

      final data = TxData(
        sparkRecipients: vout
            .where((e) => e.$1 is Uint8List) // ignore change
            .map(
              (e) => (
                address: outputs.first
                    .address, // for display purposes on confirm tx screen. See todos above
                memo: "",
                amount: Amount(
                  rawValue: BigInt.from(e.$2),
                  fractionDigits: cryptoCurrency.fractionDigits,
                ),
                isChange: false, // ok?
              ),
            )
            .toList(),
        vSize: builtTx.virtualSize(),
        txid: builtTx.getId(),
        raw: builtTx.toHex(),
        fee: Amount(
          rawValue: nFeeRet,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        usedUTXOs: vin.map((e) => e.utxo).toList(),
        tempTx: TransactionV2(
          walletId: walletId,
          blockHash: null,
          hash: builtTx.getId(),
          txid: builtTx.getId(),
          timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
          inputs: List.unmodifiable(tempInputs),
          outputs: List.unmodifiable(tempOutputs),
          type:
              tempOutputs.map((e) => e.walletOwns).fold(true, (p, e) => p &= e)
                  ? TransactionType.sentToSelf
                  : TransactionType.outgoing,
          subType: TransactionSubType.sparkMint,
          otherData: null,
          height: null,
          version: 3,
        ),
      );

      if (nFeeRet.toInt() < data.vSize!) {
        throw Exception("fee is less than vSize");
      }

      results.add(data);

      if (nChangePosInOut >= 0) {
        final vOut = vout[nChangePosInOut];
        assert(vOut.$1 is String); // check to make sure is change address

        final out = UTXO(
          walletId: walletId,
          txid: data.txid!,
          vout: nChangePosInOut,
          value: vOut.$2,
          address: vOut.$1 as String,
          name: "Spark mint change",
          isBlocked: false,
          blockedReason: null,
          isCoinbase: false,
          blockHash: null,
          blockHeight: null,
          blockTime: null,
        );

        bool added = false;
        for (final utxos in valueAndUTXOs) {
          if (utxos.first.address == out.address) {
            utxos.add(out);
            added = true;
          }
        }

        if (!added) {
          valueAndUTXOs.add([out]);
        }
      }

      if (!autoMintAll) {
        valueToMint -= mintedValue;
        if (valueToMint == BigInt.zero) {
          break;
        }
      }
    }

    if (!autoMintAll && valueToMint > BigInt.zero) {
      // TODO: Is this a valid error message?
      throw Exception("Failed to mint expected amounts");
    }

    return results;
  }

  Future<void> anonymizeAllSpark() async {
    try {
      const subtractFeeFromAmount = true; // must be true for mint all
      final currentHeight = await chainHeight;

      final spendableUtxos = await mainDB.isar.utxos
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .isBlockedEqualTo(false)
          .and()
          .group((q) => q.usedEqualTo(false).or().usedIsNull())
          .and()
          .valueGreaterThan(0)
          .findAll();

      spendableUtxos.removeWhere(
        (e) => !e.isConfirmed(
          currentHeight,
          cryptoCurrency.minConfirms,
        ),
      );

      if (spendableUtxos.isEmpty) {
        throw Exception("No available UTXOs found to anonymize");
      }

      final mints = await _createSparkMintTransactions(
        subtractFeeFromAmount: subtractFeeFromAmount,
        autoMintAll: true,
        availableUtxos: spendableUtxos,
        outputs: [
          MutableSparkRecipient(
            (await getCurrentReceivingSparkAddress())!.value,
            spendableUtxos
                .map((e) => BigInt.from(e.value))
                .fold(BigInt.zero, (p, e) => p + e),
            "",
          ),
        ],
      );

      await confirmSparkMintTransactions(txData: TxData(sparkMints: mints));
    } catch (e, s) {
      Logging.instance.log(
        "Exception caught in anonymizeAllSpark(): $e\n$s",
        level: LogLevel.Warning,
      );
      rethrow;
    }
  }

  /// Transparent to Spark (mint) transaction creation.
  ///
  /// See https://docs.google.com/document/d/1RG52GoYTZDvKlZz_3G4sQu-PpT6JWSZGHLNswWcrE3o
  Future<TxData> prepareSparkMintTransaction({required TxData txData}) async {
    try {
      if (txData.sparkRecipients?.isNotEmpty != true) {
        throw Exception("Missing spark recipients.");
      }
      final recipients = txData.sparkRecipients!
          .map(
            (e) => MutableSparkRecipient(
              e.address,
              e.amount.raw,
              e.memo,
            ),
          )
          .toList();

      final total = recipients
          .map((e) => e.value)
          .reduce((value, element) => value += element);

      if (total < BigInt.zero) {
        throw Exception("Attempted send of negative amount");
      } else if (total == BigInt.zero) {
        throw Exception("Attempted send of zero amount");
      }

      final currentHeight = await chainHeight;

      // coin control not enabled for firo currently so we can ignore this
      // final utxosToUse = txData.utxos?.toList() ??  await mainDB.isar.utxos
      //     .where()
      //     .walletIdEqualTo(walletId)
      //     .filter()
      //     .isBlockedEqualTo(false)
      //     .and()
      //     .group((q) => q.usedEqualTo(false).or().usedIsNull())
      //     .and()
      //     .valueGreaterThan(0)
      //     .findAll();
      final spendableUtxos = await mainDB.isar.utxos
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .isBlockedEqualTo(false)
          .and()
          .group((q) => q.usedEqualTo(false).or().usedIsNull())
          .and()
          .valueGreaterThan(0)
          .findAll();

      spendableUtxos.removeWhere(
        (e) => !e.isConfirmed(
          currentHeight,
          cryptoCurrency.minConfirms,
        ),
      );

      if (spendableUtxos.isEmpty) {
        throw Exception("No available UTXOs found to anonymize");
      }

      final available = spendableUtxos
          .map((e) => BigInt.from(e.value))
          .reduce((value, element) => value += element);

      final bool subtractFeeFromAmount;
      if (available < total) {
        throw Exception("Insufficient balance");
      } else if (available == total) {
        subtractFeeFromAmount = true;
      } else {
        subtractFeeFromAmount = false;
      }

      final mints = await _createSparkMintTransactions(
        subtractFeeFromAmount: subtractFeeFromAmount,
        autoMintAll: false,
        availableUtxos: spendableUtxos,
        outputs: recipients,
      );

      return txData.copyWith(sparkMints: mints);
    } catch (e, s) {
      Logging.instance.log(
        "Exception caught in prepareSparkMintTransaction(): $e\n$s",
        level: LogLevel.Warning,
      );
      rethrow;
    }
  }

  Future<TxData> confirmSparkMintTransactions({required TxData txData}) async {
    final futures = txData.sparkMints!.map((e) => confirmSend(txData: e));
    return txData.copyWith(sparkMints: await Future.wait(futures));
  }

  @override
  Future<void> updateBalance() async {
    // call to super to update transparent balance (and lelantus balance if
    // what ever class this mixin is used on uses LelantusInterface as well)
    final normalBalanceFuture = super.updateBalance();

    // todo: spark balance aka update info.tertiaryBalance here?
    // currently happens on spark coins update/refresh

    // wait for normalBalanceFuture to complete before returning
    await normalBalanceFuture;
  }

  // ====================== Private ============================================

  final _kSparkAnonSetCachedBlockHashKey = "SparkAnonSetCachedBlockHashKey";

  Future<String?> _getCachedSparkBlockHash() async {
    return info.otherData[_kSparkAnonSetCachedBlockHashKey] as String?;
  }

  Future<void> _setCachedSparkBlockHash(String blockHash) async {
    await info.updateOtherData(
      newEntries: {_kSparkAnonSetCachedBlockHashKey: blockHash},
      isar: mainDB.isar,
    );
  }

  Future<void> _addOrUpdateSparkCoins(List<SparkCoin> coins) async {
    if (coins.isNotEmpty) {
      await mainDB.isar.writeTxn(() async {
        await mainDB.isar.sparkCoins.putAll(coins);
      });
    }

    // update wallet spark coin height
    final coinsToCheck = await mainDB.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(walletId)
        .filter()
        .heightIsNull()
        .findAll();
    final List<SparkCoin> updatedCoins = [];
    for (final coin in coinsToCheck) {
      final tx = await electrumXCachedClient.getTransaction(
        txHash: coin.txHash,
        coin: info.coin,
      );
      if (tx["height"] is int) {
        updatedCoins.add(coin.copyWith(height: tx["height"] as int));
      }
    }
    if (updatedCoins.isNotEmpty) {
      await mainDB.isar.writeTxn(() async {
        await mainDB.isar.sparkCoins.putAll(updatedCoins);
      });
    }
  }

  btc.NetworkType get _bitcoinDartNetwork => btc.NetworkType(
        messagePrefix: cryptoCurrency.networkParams.messagePrefix,
        bech32: cryptoCurrency.networkParams.bech32Hrp,
        bip32: btc.Bip32Type(
          public: cryptoCurrency.networkParams.pubHDPrefix,
          private: cryptoCurrency.networkParams.privHDPrefix,
        ),
        pubKeyHash: cryptoCurrency.networkParams.p2pkhPrefix,
        scriptHash: cryptoCurrency.networkParams.p2shPrefix,
        wif: cryptoCurrency.networkParams.wifPrefix,
      );
}

String base64ToReverseHex(String source) =>
    base64Decode(LineSplitter.split(source).join())
        .reversed
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();

/// Top level function which should be called wrapped in [compute]
Future<
    ({
      Uint8List serializedSpendPayload,
      List<Uint8List> outputScripts,
      int fee,
      List<
          ({
            int groupId,
            int height,
            String serializedCoin,
            String serializedCoinContext
          })> usedCoins,
    })> _createSparkSend(
    ({
      String privateKeyHex,
      int index,
      List<
          ({
            String address,
            int amount,
            bool subtractFeeFromAmount
          })> recipients,
      List<
          ({
            String sparkAddress,
            int amount,
            bool subtractFeeFromAmount,
            String memo
          })> privateRecipients,
      List<
          ({
            String serializedCoin,
            String serializedCoinContext,
            int groupId,
            int height,
          })> serializedCoins,
      List<
          ({
            int setId,
            String setHash,
            List<({String serializedCoin, String txHash})> set
          })> allAnonymitySets,
      List<
          ({
            int setId,
            Uint8List blockHash,
          })> idAndBlockHashes,
      Uint8List txHash,
    }) args) async {
  final spend = LibSpark.createSparkSendTransaction(
    privateKeyHex: args.privateKeyHex,
    index: args.index,
    recipients: args.recipients,
    privateRecipients: args.privateRecipients,
    serializedCoins: args.serializedCoins,
    allAnonymitySets: args.allAnonymitySets,
    idAndBlockHashes: args.idAndBlockHashes,
    txHash: args.txHash,
  );

  return spend;
}

/// Top level function which should be called wrapped in [compute]
Future<List<SparkCoin>> _identifyCoins(
    ({
      List<dynamic> anonymitySetCoins,
      int groupId,
      Set<String> spentCoinTags,
      Set<String> privateKeyHexSet,
      String walletId,
      bool isTestNet,
    }) args) async {
  final List<SparkCoin> myCoins = [];

  for (final privateKeyHex in args.privateKeyHexSet) {
    for (final dynData in args.anonymitySetCoins) {
      final data = List<String>.from(dynData as List);

      if (data.length != 3) {
        throw Exception("Unexpected serialized coin info found");
      }

      final serializedCoinB64 = data[0];
      final txHash = base64ToReverseHex(data[1]);
      final contextB64 = data[2];

      final coin = LibSpark.identifyAndRecoverCoin(
        serializedCoinB64,
        privateKeyHex: privateKeyHex,
        index: kDefaultSparkIndex,
        context: base64Decode(contextB64),
        isTestNet: args.isTestNet,
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
            walletId: args.walletId,
            type: coinType,
            isUsed: args.spentCoinTags.contains(coin.lTagHash!),
            groupId: args.groupId,
            nonce: coin.nonceHex?.toUint8ListFromHex,
            address: coin.address!,
            txHash: txHash,
            valueIntString: coin.value!.toString(),
            memo: coin.memo,
            serialContext: coin.serialContext,
            diversifierIntString: coin.diversifier!.toString(),
            encryptedDiversifier: coin.encryptedDiversifier,
            serial: coin.serial,
            tag: coin.tag,
            lTagHash: coin.lTagHash!,
            height: coin.height,
            serializedCoinB64: serializedCoinB64,
            contextB64: contextB64,
          ),
        );
      }
    }
  }

  return myCoins;
}

BigInt _min(BigInt a, BigInt b) {
  if (a <= b) {
    return a;
  } else {
    return b;
  }
}

BigInt _sum(List<UTXO> utxos) => utxos
    .map((e) => BigInt.from(e.value))
    .fold(BigInt.zero, (previousValue, element) => previousValue + element);

class MutableSparkRecipient {
  String address;
  BigInt value;
  String memo;

  MutableSparkRecipient(this.address, this.value, this.memo);

  @override
  String toString() {
    return 'MutableSparkRecipient{ address: $address, value: $value, memo: $memo }';
  }
}
