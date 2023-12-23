import 'dart:convert';
import 'dart:math';

import 'package:bitcoindart/bitcoindart.dart' as btc;
import 'package:flutter/foundation.dart';
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
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

const MAX_STANDARD_TX_WEIGHT = 400000;

const OP_SPARKMINT = 0xd1;
const OP_SPARKSMINT = 0xd2;
const OP_SPARKSPEND = 0xd3;

mixin SparkInterface on Bip39HDWallet, ElectrumXInterface {
  static bool validateSparkAddress({
    required String address,
    required bool isTestNet,
  }) =>
      LibSpark.validateAddress(address: address, isTestNet: isTestNet);

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

    final txAmount = (txData.recipients ?? []).map((e) => e.amount).fold(
            Amount(
              rawValue: BigInt.zero,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            (p, e) => p + e) +
        (txData.sparkRecipients ?? []).map((e) => e.amount).fold(
            Amount(
              rawValue: BigInt.zero,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            (p, e) => p + e);

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

    List<({String address, Amount amount})>? recipientsWithFeeSubtracted;
    List<
        ({
          String address,
          Amount amount,
          String memo,
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
        ),
      );
    }

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
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);

      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      txData = txData.copyWith(
        // TODO mark spark coins as spent locally and update balance before waiting to check via electrumx?

        // usedUTXOs:
        // txData.usedUTXOs!.map((e) => e.copyWith(used: true)).toList(),

        // TODO revisit setting these both
        txHash: txHash,
        txid: txHash,
      );
      // // mark utxos as used
      // await mainDB.putUTXOs(txData.usedUTXOs!);

      return txData;
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

  Future<List<TxData>> createSparkMintTransactions({
    required List<UTXO> availableUtxos,
    required List<MutableSparkRecipient> outputs,
    required bool subtractFeeFromAmount,
    required bool autoMintAll,
  }) async {
    // pre checks
    if (outputs.isEmpty) {
      throw Exception("Cannot mint without some recipients");
    }
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
    List<MutableSparkRecipient> outputs_ = outputs.toList();
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
      final List<(dynamic, int)> vout = [];

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
        final remainingOutputs = outputs_.toList();
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
          BigInt remainingMintValue = mintedValue;
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
        for (final recipient in dummyRecipients) {
          if (recipient.amount < cryptoCurrency.dustLimit.raw.toInt()) {
            throw Exception("Output amount too small");
          }
          vout.add((
            recipient.scriptPubKey,
            recipient.amount,
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
              (changeAddress!.value, nChange.toInt()),
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

        final nFeeNeeded =
            BigInt.from(nBytes); // One day we'll do this properly

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
          for (final recipient in recipients) {
            final out = (recipient.scriptPubKey, recipient.amount);
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

          outputs_ = remainingOutputs;

          break; // Done, enough fee included.
        }

        // Include more fee and try again.
        nFeeRet = nFeeNeeded;
        continue;
      }

      if (skipCoin) {
        continue;
      }

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
      }

      for (final output in vout) {
        txb.addOutput(output.$1, output.$2);
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
      final data = TxData(
        // TODO: add fee output to recipients?
        sparkRecipients: vout
            .map(
              (e) => (
                address: "lol",
                memo: "",
                amount: Amount(
                  rawValue: BigInt.from(e.$2),
                  fractionDigits: cryptoCurrency.fractionDigits,
                ),
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
      );

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
    const subtractFeeFromAmount = true; // must be true for mint all
    final currentHeight = await chainHeight;

    // TODO: this is broken?
    final spendableUtxos = await mainDB.isar.utxos
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .isBlockedEqualTo(false)
        .and()
        .valueGreaterThan(0)
        .and()
        .usedEqualTo(false)
        .and()
        .blockHeightIsNotNull()
        .and()
        .blockHeightLessThan(
          currentHeight + cryptoCurrency.minConfirms,
          include: true,
        )
        .findAll();

    if (spendableUtxos.isEmpty) {
      throw Exception("No available UTXOs found to anonymize");
    }

    final results = await createSparkMintTransactions(
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

    int i = 0;
    for (final data in results) {
      print("Results data $i=$data");
      i++;
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
    Amount totalAmount = Amount(
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
      totalAmount += recipient.amount;
      if (totalAmount.raw > BigInt.from(1000000000000)) {
        throw Exception(
          "Spend limit exceeded (10,000 FIRO per tx).",
        );
      }
    }

    // Create a transaction builder and set locktime and version.
    final txb = btc.TransactionBuilder(
      network: _bitcoinDartNetwork,
    );
    txb.setLockTime(await chainHeight);
    txb.setVersion(1);

    final signingData = await fetchBuildTxData(txData.utxos!.toList());

    // Create the serial context.
    //
    // "...serial_context is a byte array, which should be unique for each
    // transaction, and for that we serialize and put all inputs into
    // serial_context vector."
    final serialContext = LibSpark.serializeMintContext(
      inputs: signingData
          .map((e) => (
                e.utxo.txid,
                e.utxo.vout,
              ))
          .toList(),
    );

    // Add inputs.
    for (final sd in signingData) {
      txb.addInput(
        sd.utxo.txid,
        sd.utxo.vout,
        0xffffffff -
            1, // minus 1 is important. 0xffffffff on its own will burn funds
        sd.output,
      );
    }

    // Create mint recipients.
    final mintRecipients = LibSpark.createSparkMintRecipients(
      outputs: txData.recipients!
          .map((e) => (
                sparkAddress: e.address,
                value: e.amount.raw.toInt(),
                memo: "",
              ))
          .toList(),
      serialContext: Uint8List.fromList(serialContext),
      generate: true,
    );

    // Add mint output(s).
    for (final mint in mintRecipients) {
      txb.addOutput(
        mint.scriptPubKey,
        mint.amount,
      );
    }

    try {
      // Sign the transaction accordingly
      for (var i = 0; i < signingData.length; i++) {
        txb.sign(
          vin: i,
          keyPair: signingData[i].keyPair!,
          witnessValue: signingData[i].utxo.value,
          redeemScript: signingData[i].redeemScript,
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

    // TODO any changes to this txData object required?
    return txData.copyWith(
      // recipients: [
      //   (
      //   amount: Amount(
      //     rawValue: BigInt.from(incomplete.outs[0].value!),
      //     fractionDigits: cryptoCurrency.fractionDigits,
      //   ),
      //   address: "no address for lelantus mints",
      //   )
      // ],
      vSize: builtTx.virtualSize(),
      txid: builtTx.getId(),
      raw: builtTx.toHex(),
    );
  }

  /// Broadcast a tx and TODO update Spark balance.
  Future<TxData> confirmSparkMintTransaction({required TxData txData}) async {
    // Broadcast tx.
    final txid = await electrumXClient.broadcastTransaction(
      rawTx: txData.raw!,
    );

    // Check txid.
    if (txid == txData.txid!) {
      print("SPARK TXIDS MATCH!!");
    } else {
      print("SUBMITTED SPARK TXID DOES NOT MATCH WHAT WE GENERATED");
    }

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
}
