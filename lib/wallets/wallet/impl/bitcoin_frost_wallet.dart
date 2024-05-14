import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:frostdart/frostdart.dart' as frost;
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx_client.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin_frost.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

class BitcoinFrostWallet<T extends FrostCurrency> extends Wallet<T> {
  BitcoinFrostWallet(CryptoCurrencyNetwork network)
      : super(BitcoinFrost(network) as T);

  FrostWalletInfo get frostInfo => mainDB.isar.frostWalletInfo
      .where()
      .walletIdEqualTo(walletId)
      .findFirstSync()!;

  late ElectrumXClient electrumXClient;
  late CachedElectrumXClient electrumXCachedClient;

  Future<void> initializeNewFrost({
    required String multisigConfig,
    required String recoveryString,
    required String serializedKeys,
    required Uint8List multisigId,
    required String myName,
    required List<String> participants,
    required int threshold,
  }) async {
    Logging.instance.log(
      "Generating new FROST wallet.",
      level: LogLevel.Info,
    );

    try {
      final salt = frost
          .multisigSalt(
            multisigConfig: multisigConfig,
          )
          .toHex;

      final FrostWalletInfo frostWalletInfo = FrostWalletInfo(
        walletId: info.walletId,
        knownSalts: [salt],
        participants: participants,
        myName: myName,
        threshold: threshold,
      );

      await _saveSerializedKeys(serializedKeys);
      await _saveRecoveryString(recoveryString);
      await _saveMultisigId(multisigId);
      await _saveMultisigConfig(multisigConfig);

      await mainDB.isar.writeTxn(() async {
        await mainDB.isar.frostWalletInfo.put(frostWalletInfo);
      });

      final keys = frost.deserializeKeys(keys: serializedKeys);

      final addressString = frost.addressForKeys(
        network: cryptoCurrency.network == CryptoCurrencyNetwork.main
            ? Network.Mainnet
            : Network.Testnet,
        keys: keys,
      );

      final publicKey = frost.scriptPubKeyForKeys(keys: keys);

      final address = Address(
        walletId: info.walletId,
        value: addressString,
        publicKey: publicKey.toUint8ListFromHex,
        derivationIndex: 0,
        derivationPath: null,
        subType: AddressSubType.receiving,
        type: AddressType.unknown,
      );

      await mainDB.putAddresses([address]);
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from initializeNewFrost(): $e\n$s",
        level: LogLevel.Fatal,
      );
      rethrow;
    }
  }

  Future<TxData> frostCreateSignConfig({
    required TxData txData,
    required String changeAddress,
    required int feePerWeight,
  }) async {
    try {
      if (txData.recipients == null || txData.recipients!.isEmpty) {
        throw Exception("No recipients found!");
      }

      final total = txData.recipients!
          .map((e) => e.amount)
          .reduce((value, e) => value += e);

      final utxos = await mainDB
          .getUTXOs(walletId)
          .filter()
          .isBlockedEqualTo(false)
          .findAll();

      if (utxos.isEmpty) {
        throw Exception("No UTXOs found");
      } else {
        final currentHeight = await chainHeight;
        utxos.removeWhere(
          (e) => !e.isConfirmed(
            currentHeight,
            cryptoCurrency.minConfirms,
          ),
        );
        if (utxos.isEmpty) {
          throw Exception("No confirmed UTXOs found");
        }
      }

      if (total.raw >
          utxos.map((e) => BigInt.from(e.value)).reduce((v, e) => v += e)) {
        throw Exception("Insufficient available funds");
      }

      Amount sum = Amount.zeroWith(
        fractionDigits: cryptoCurrency.fractionDigits,
      );
      final Set<UTXO> utxosToUse = {};
      for (final utxo in utxos) {
        sum += Amount(
          rawValue: BigInt.from(utxo.value),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
        utxosToUse.add(utxo);
        if (sum > total) {
          break;
        }
      }

      final serializedKeys = await getSerializedKeys();
      final keys = frost.deserializeKeys(keys: serializedKeys!);

      final int network = cryptoCurrency.network == CryptoCurrencyNetwork.main
          ? Network.Mainnet
          : Network.Testnet;

      final publicKey = frost
          .scriptPubKeyForKeys(
            keys: keys,
          )
          .toUint8ListFromHex;

      final config = Frost.createSignConfig(
        network: network,
        inputs: utxosToUse
            .map(
              (e) => (
                utxo: e,
                scriptPubKey: publicKey,
              ),
            )
            .toList(),
        outputs: txData.recipients!,
        changeAddress: (await getCurrentReceivingAddress())!.value,
        feePerWeight: feePerWeight,
      );

      return txData.copyWith(frostMSConfig: config, utxos: utxosToUse);
    } catch (_) {
      rethrow;
    }
  }

  Future<
      ({
        Pointer<TransactionSignMachineWrapper> machinePtr,
        String preprocess,
      })> frostAttemptSignConfig({
    required String config,
  }) async {
    final int network = cryptoCurrency.network == CryptoCurrencyNetwork.main
        ? Network.Mainnet
        : Network.Testnet;
    final serializedKeys = await getSerializedKeys();

    return Frost.attemptSignConfig(
      network: network,
      config: config,
      serializedKeys: serializedKeys!,
    );
  }

  Future<void> updateWithResharedData({
    required String serializedKeys,
    required String multisigConfig,
    required bool isNewWallet,
  }) async {
    await _saveSerializedKeys(serializedKeys);
    await _saveMultisigConfig(multisigConfig);

    await _updateThreshold(
      frost.getThresholdFromKeys(
        serializedKeys: serializedKeys,
      ),
    );

    final myNameIndex = frost.getParticipantIndexFromKeys(
      serializedKeys: serializedKeys,
    );
    final participants = Frost.getParticipants(
      multisigConfig: multisigConfig,
    );
    final myName = participants[myNameIndex];

    await _updateParticipants(participants);
    await _updateMyName(myName);

    if (isNewWallet) {
      await recover(
        serializedKeys: serializedKeys,
        multisigConfig: multisigConfig,
        isRescan: false,
      );
    }
  }

  Future<Amount> sweepAllEstimate(int feeRate) async {
    int available = 0;
    int inputCount = 0;
    final height = await chainHeight;
    for (final output in (await mainDB.getUTXOs(walletId).findAll())) {
      if (!output.isBlocked &&
          output.isConfirmed(height, cryptoCurrency.minConfirms)) {
        available += output.value;
        inputCount++;
      }
    }

    // transaction will only have 1 output minus the fee
    final estimatedFee = _roughFeeEstimate(inputCount, 1, feeRate);

    return Amount(
          rawValue: BigInt.from(available),
          fractionDigits: cryptoCurrency.fractionDigits,
        ) -
        estimatedFee;
  }

  // int _estimateTxFee({required int vSize, required int feeRatePerKB}) {
  //   return vSize * (feeRatePerKB / 1000).ceil();
  // }

  Amount _roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
        ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
            (feeRatePerKB / 1000).ceil(),
      ),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  // ==================== Overrides ============================================

  @override
  bool get supportsMultiRecipient => true;

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get changeAddressFilterOperation => FilterGroup.and(
        [
          FilterCondition.equalTo(
            property: r"type",
            value: info.mainAddressType,
          ),
          const FilterCondition.equalTo(
            property: r"subType",
            value: AddressSubType.change,
          ),
        ],
      );

  @override
  FilterOperation? get receivingAddressFilterOperation => FilterGroup.and(
        [
          FilterCondition.equalTo(
            property: r"type",
            value: info.mainAddressType,
          ),
          const FilterCondition.equalTo(
            property: r"subType",
            value: AddressSubType.receiving,
          ),
        ],
      );

  @override
  Future<void> updateTransactions() async {
    final myAddress = (await getCurrentReceivingAddress())!;

    final scriptHash = cryptoCurrency.pubKeyToScriptHash(
      pubKey: Uint8List.fromList(myAddress.publicKey),
    );
    final allTxHashes =
        (await electrumXClient.getHistory(scripthash: scriptHash)).toSet();

    final currentHeight = await chainHeight;
    final coin = info.coin;

    final List<Map<String, dynamic>> allTransactions = [];

    for (final txHash in allTxHashes) {
      final storedTx = await mainDB.isar.transactionV2s
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .txidEqualTo(txHash["tx_hash"] as String)
          .findFirst();

      if (storedTx == null ||
          !storedTx.isConfirmed(currentHeight, cryptoCurrency.minConfirms)) {
        final tx = await electrumXCachedClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          coin: coin,
        );

        if (!_duplicateTxCheck(allTransactions, tx["txid"] as String)) {
          tx["height"] = txHash["height"];
          allTransactions.add(tx);
        }
      }
    }

    // Parse all new txs.
    final List<TransactionV2> txns = [];
    for (final txData in allTransactions) {
      bool wasSentFromThisWallet = false;
      // Set to true if any inputs were detected as owned by this wallet.

      bool wasReceivedInThisWallet = false;
      // Set to true if any outputs were detected as owned by this wallet.

      // Parse inputs.
      BigInt amountReceivedInThisWallet = BigInt.zero;
      final List<InputV2> inputs = [];
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);

        final List<String> addresses = [];
        String valueStringSats = "0";
        OutpointV2? outpoint;

        final coinbase = map["coinbase"] as String?;

        if (coinbase == null) {
          // Not a coinbase (ie a typical input).
          final txid = map["txid"] as String;
          final vout = map["vout"] as int;

          final inputTx = await electrumXCachedClient.getTransaction(
            txHash: txid,
            coin: cryptoCurrency.coin,
          );

          final prevOutJson = Map<String, dynamic>.from(
            (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout) as Map,
          );

          final prevOut = OutputV2.fromElectrumXJson(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
            isFullAmountNotSats: true,
            walletOwns: false, // Doesn't matter here as this is not saved.
          );

          outpoint = OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: txid,
            vout: vout,
          );
          valueStringSats = prevOut.valueStringSats;
          addresses.addAll(prevOut.addresses);
        }

        InputV2 input = InputV2.fromElectrumxJson(
          json: map,
          outpoint: outpoint,
          valueStringSats: valueStringSats,
          addresses: addresses,
          coinbase: coinbase,
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // Check if input was from this wallet.
        if (input.addresses.contains(myAddress.value)) {
          wasSentFromThisWallet = true;
          input = input.copyWith(walletOwns: true);
        }

        inputs.add(input);
      }

      // Parse outputs.
      final List<OutputV2> outputs = [];
      for (final outputJson in txData["vout"] as List) {
        OutputV2 output = OutputV2.fromElectrumXJson(
          Map<String, dynamic>.from(outputJson as Map),
          decimalPlaces: cryptoCurrency.fractionDigits,
          isFullAmountNotSats: true,
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // If output was to my wallet, add value to amount received.
        if (output.addresses.contains(myAddress.value)) {
          wasReceivedInThisWallet = true;
          amountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        }

        outputs.add(output);
      }

      final totalOut = outputs
          .map((e) => e.value)
          .fold(BigInt.zero, (value, element) => value + element);

      TransactionType type;
      TransactionSubType subType = TransactionSubType.none;
      if (outputs.length > 1 && inputs.isNotEmpty) {
        for (int i = 0; i < outputs.length; i++) {
          final List<String>? scriptChunks =
              outputs[i].scriptPubKeyAsm?.split(" ");
          if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
            final blindedPaymentCode = scriptChunks![1];
            final bytes = blindedPaymentCode.toUint8ListFromHex;

            // https://en.bitcoin.it/wiki/BIP_0047#Sending
            if (bytes.length == 80 && bytes.first == 1) {
              subType = TransactionSubType.bip47Notification;
              break;
            }
          }
        }
      }

      // At least one input was owned by this wallet.
      if (wasSentFromThisWallet) {
        type = TransactionType.outgoing;

        if (wasReceivedInThisWallet) {
          if (amountReceivedInThisWallet == totalOut) {
            // Definitely sent all to self.
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // Most likely just a typical send, do nothing here yet.
          }
        }
      } else if (wasReceivedInThisWallet) {
        // Only found outputs owned by this wallet.
        type = TransactionType.incoming;
      } else {
        Logging.instance.log(
          "Unexpected tx found (ignoring it): $txData",
          level: LogLevel.Error,
        );
        continue;
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp: txData["blocktime"] as int? ??
            DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
        type: type,
        subType: subType,
        otherData: null,
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    final address = await getCurrentReceivingAddress();
    if (address == null) {
      final serializedKeys = await getSerializedKeys();
      if (serializedKeys != null) {
        final keys = frost.deserializeKeys(keys: serializedKeys);

        final addressString = frost.addressForKeys(
          network: cryptoCurrency.network == CryptoCurrencyNetwork.main
              ? Network.Mainnet
              : Network.Testnet,
          keys: keys,
        );

        final publicKey = frost.scriptPubKeyForKeys(keys: keys);

        final address = Address(
          walletId: walletId,
          value: addressString,
          publicKey: publicKey.toUint8ListFromHex,
          derivationIndex: 0,
          derivationPath: null,
          subType: AddressSubType.receiving,
          type: AddressType.frostMS,
        );

        await mainDB.updateOrPutAddresses([address]);
      } else {
        Logging.instance.log(
          "$runtimeType.checkSaveInitialReceivingAddress() failed due"
          " to missing serialized keys",
          level: LogLevel.Fatal,
        );
      }
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);

      final hex = txData.raw!;

      final txHash = await electrumXClient.broadcastTransaction(rawTx: hex);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      // mark utxos as used
      final usedUTXOs = txData.utxos!.map((e) => e.copyWith(used: true));
      await mainDB.putUTXOs(usedUTXOs.toList());

      txData = txData.copyWith(
        utxos: usedUTXOs.toSet(),
        txHash: txHash,
        txid: txHash,
      );

      return txData;
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from confirmSend(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    final available = info.cachedBalance.spendable;

    if (available == amount) {
      return amount - (await sweepAllEstimate(feeRate));
    } else if (amount <= Amount.zero || amount > available) {
      return _roughFeeEstimate(1, 2, feeRate);
    }

    Amount runningBalance = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    int inputCount = 0;
    for (final output in (await mainDB.getUTXOs(walletId).findAll())) {
      if (!output.isBlocked) {
        runningBalance += Amount(
          rawValue: BigInt.from(output.value),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
        inputCount++;
        if (runningBalance > amount) {
          break;
        }
      }
    }

    final oneOutPutFee = _roughFeeEstimate(inputCount, 1, feeRate);
    final twoOutPutFee = _roughFeeEstimate(inputCount, 2, feeRate);

    if (runningBalance - amount > oneOutPutFee) {
      if (runningBalance - amount > oneOutPutFee + cryptoCurrency.dustLimit) {
        final change = runningBalance - amount - twoOutPutFee;
        if (change > cryptoCurrency.dustLimit &&
            runningBalance - amount - change == twoOutPutFee) {
          return runningBalance - amount - change;
        } else {
          return runningBalance - amount;
        }
      } else {
        return runningBalance - amount;
      }
    } else if (runningBalance - amount == oneOutPutFee) {
      return oneOutPutFee;
    } else {
      return twoOutPutFee;
    }
  }

  @override
  Future<FeeObject> get fees async {
    try {
      // adjust numbers for different speeds?
      const int f = 1, m = 5, s = 20;

      final fast = await electrumXClient.estimateFee(blocks: f);
      final medium = await electrumXClient.estimateFee(blocks: m);
      final slow = await electrumXClient.estimateFee(blocks: s);

      final feeObject = FeeObject(
        numberOfBlocksFast: f,
        numberOfBlocksAverage: m,
        numberOfBlocksSlow: s,
        fast: Amount.fromDecimal(
          fast,
          fractionDigits: cryptoCurrency.fractionDigits,
        ).raw.toInt(),
        medium: Amount.fromDecimal(
          medium,
          fractionDigits: cryptoCurrency.fractionDigits,
        ).raw.toInt(),
        slow: Amount.fromDecimal(
          slow,
          fractionDigits: cryptoCurrency.fractionDigits,
        ).raw.toInt(),
      );

      Logging.instance.log("fetched fees: $feeObject", level: LogLevel.Info);
      return feeObject;
    } catch (e) {
      Logging.instance
          .log("Exception rethrown from _getFees(): $e", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    // TODO: implement prepareSendpu
    throw UnimplementedError();
  }

  @override
  Future<void> recover({
    required bool isRescan,
    String? serializedKeys,
    String? multisigConfig,
  }) async {
    if (serializedKeys == null || multisigConfig == null) {
      serializedKeys = await getSerializedKeys();
      multisigConfig = await getMultisigConfig();
    }
    if (serializedKeys == null || multisigConfig == null) {
      final err = "${info.coinName} wallet ${info.walletId} had null keys/cfg";
      Logging.instance.log(err, level: LogLevel.Fatal);
      throw Exception(err);
      // TODO [prio=low]: handle null keys or config.  This should not happen.
    }

    final coin = info.coin;

    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        coin,
      ),
    );

    try {
      await refreshMutex.protect(() async {
        if (!isRescan) {
          final salt = frost
              .multisigSalt(
                multisigConfig: multisigConfig!,
              )
              .toHex;
          final knownSalts = _getKnownSalts();
          if (knownSalts.contains(salt)) {
            throw Exception("Known frost multisig salt found!");
          }
          final List<String> updatedKnownSalts = List<String>.from(knownSalts);
          updatedKnownSalts.add(salt);
          await _updateKnownSalts(updatedKnownSalts);
        } else {
          // clear cache
          await electrumXCachedClient.clearSharedTransactionCache(coin: coin);
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        final keys = frost.deserializeKeys(keys: serializedKeys!);
        await _saveSerializedKeys(serializedKeys!);
        await _saveMultisigConfig(multisigConfig!);

        final addressString = frost.addressForKeys(
          network: cryptoCurrency.network == CryptoCurrencyNetwork.main
              ? Network.Mainnet
              : Network.Testnet,
          keys: keys,
        );

        final publicKey = frost.scriptPubKeyForKeys(keys: keys);

        final address = Address(
          walletId: walletId,
          value: addressString,
          publicKey: publicKey.toUint8ListFromHex,
          derivationIndex: 0,
          derivationPath: null,
          subType: AddressSubType.receiving,
          type: AddressType.frostMS,
        );

        await mainDB.updateOrPutAddresses([address]);
      });

      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );

      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.log(
        "recoverFromSerializedKeys failed: $e\n$s",
        level: LogLevel.Fatal,
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateBalance() async {
    final utxos = await mainDB.getUTXOs(walletId).findAll();

    final currentChainHeight = await chainHeight;

    Amount satoshiBalanceTotal = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    Amount satoshiBalancePending = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    Amount satoshiBalanceSpendable = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    Amount satoshiBalanceBlocked = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );

    for (final utxo in utxos) {
      final utxoAmount = Amount(
        rawValue: BigInt.from(utxo.value),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      satoshiBalanceTotal += utxoAmount;

      if (utxo.isBlocked) {
        satoshiBalanceBlocked += utxoAmount;
      } else {
        if (utxo.isConfirmed(
          currentChainHeight,
          cryptoCurrency.minConfirms,
        )) {
          satoshiBalanceSpendable += utxoAmount;
        } else {
          satoshiBalancePending += utxoAmount;
        }
      }
    }

    final balance = Balance(
      total: satoshiBalanceTotal,
      spendable: satoshiBalanceSpendable,
      blockedTotal: satoshiBalanceBlocked,
      pendingSpendable: satoshiBalancePending,
    );

    await info.updateBalance(newBalance: balance, isar: mainDB.isar);
  }

  @override
  Future<void> updateChainHeight() async {
    final int height;
    try {
      final result = await electrumXClient.getBlockHeadTip();
      height = result["height"] as int;
    } catch (e) {
      rethrow;
    }

    await info.updateCachedChainHeight(
      newHeight: height,
      isar: mainDB.isar,
    );
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final result = await electrumXClient.ping();
      return result;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateNode() async {
    await _updateElectrumX();
  }

  @override
  Future<bool> updateUTXOs() async {
    final address = await getCurrentReceivingAddress();

    try {
      final scriptHash = cryptoCurrency.pubKeyToScriptHash(
        pubKey: Uint8List.fromList(address!.publicKey),
      );

      final utxos = await electrumXClient.getUTXOs(scripthash: scriptHash);

      final List<UTXO> outputArray = [];

      for (int i = 0; i < utxos.length; i++) {
        final utxo = await _parseUTXO(
          jsonUTXO: utxos[i],
        );

        outputArray.add(utxo);
      }

      return await mainDB.updateUTXOs(walletId, outputArray);
    } catch (e, s) {
      Logging.instance.log(
        "Output fetch unsuccessful: $e\n$s",
        level: LogLevel.Error,
      );
      return false;
    }
  }

  // =================== Secure storage ========================================

  Future<String?> getSerializedKeys() async =>
      await secureStorageInterface.read(
        key: "{$walletId}_serializedFROSTKeys",
      );

  Future<void> _saveSerializedKeys(
    String keys,
  ) async {
    final current = await getSerializedKeys();

    if (current == null) {
      // do nothing
    } else if (current == keys) {
      // should never occur
    } else {
      // save current as prev gen before updating current
      await secureStorageInterface.write(
        key: "{$walletId}_serializedFROSTKeysPrevGen",
        value: current,
      );
    }

    await secureStorageInterface.write(
      key: "{$walletId}_serializedFROSTKeys",
      value: keys,
    );
  }

  Future<String?> getSerializedKeysPrevGen() async =>
      await secureStorageInterface.read(
        key: "{$walletId}_serializedFROSTKeysPrevGen",
      );

  Future<String?> getMultisigConfig() async =>
      await secureStorageInterface.read(
        key: "{$walletId}_multisigConfig",
      );

  Future<String?> getMultisigConfigPrevGen() async =>
      await secureStorageInterface.read(
        key: "{$walletId}_multisigConfigPrevGen",
      );

  Future<void> _saveMultisigConfig(
    String multisigConfig,
  ) async {
    final current = await getMultisigConfig();

    if (current == null) {
      // do nothing
    } else if (current == multisigConfig) {
      // should never occur
    } else {
      // save current as prev gen before updating current
      await secureStorageInterface.write(
        key: "{$walletId}_multisigConfigPrevGen",
        value: current,
      );
    }

    await secureStorageInterface.write(
      key: "{$walletId}_multisigConfig",
      value: multisigConfig,
    );
  }

  Future<Uint8List?> _multisigId() async {
    final id = await secureStorageInterface.read(
      key: "{$walletId}_multisigIdFROST",
    );
    if (id == null) {
      return null;
    } else {
      return id.toUint8ListFromHex;
    }
  }

  Future<void> _saveMultisigId(
    Uint8List id,
  ) async =>
      await secureStorageInterface.write(
        key: "{$walletId}_multisigIdFROST",
        value: id.toHex,
      );

  Future<String?> _recoveryString() async => await secureStorageInterface.read(
        key: "{$walletId}_recoveryStringFROST",
      );

  Future<void> _saveRecoveryString(
    String recoveryString,
  ) async =>
      await secureStorageInterface.write(
        key: "{$walletId}_recoveryStringFROST",
        value: recoveryString,
      );

  // =================== DB ====================================================

  List<String> _getKnownSalts() => mainDB.isar.frostWalletInfo
      .where()
      .walletIdEqualTo(walletId)
      .knownSaltsProperty()
      .findFirstSync()!;

  Future<void> _updateKnownSalts(List<String> knownSalts) async {
    final info = frostInfo;

    await mainDB.isar.writeTxn(() async {
      await mainDB.isar.frostWalletInfo.delete(info.id);
      await mainDB.isar.frostWalletInfo.put(
        info.copyWith(knownSalts: knownSalts),
      );
    });
  }

  List<String> _getParticipants() => mainDB.isar.frostWalletInfo
      .where()
      .walletIdEqualTo(walletId)
      .participantsProperty()
      .findFirstSync()!;

  Future<void> _updateParticipants(List<String> participants) async {
    final info = frostInfo;

    await mainDB.isar.writeTxn(() async {
      await mainDB.isar.frostWalletInfo.delete(info.id);
      await mainDB.isar.frostWalletInfo.put(
        info.copyWith(participants: participants),
      );
    });
  }

  int _getThreshold() => mainDB.isar.frostWalletInfo
      .where()
      .walletIdEqualTo(walletId)
      .thresholdProperty()
      .findFirstSync()!;

  Future<void> _updateThreshold(int threshold) async {
    final info = frostInfo;

    await mainDB.isar.writeTxn(() async {
      await mainDB.isar.frostWalletInfo.delete(info.id);
      await mainDB.isar.frostWalletInfo.put(
        info.copyWith(threshold: threshold),
      );
    });
  }

  String _getMyName() => mainDB.isar.frostWalletInfo
      .where()
      .walletIdEqualTo(walletId)
      .myNameProperty()
      .findFirstSync()!;

  Future<void> _updateMyName(String myName) async {
    final info = frostInfo;

    await mainDB.isar.writeTxn(() async {
      await mainDB.isar.frostWalletInfo.delete(info.id);
      await mainDB.isar.frostWalletInfo.put(
        info.copyWith(myName: myName),
      );
    });
  }

  // =================== Private ===============================================

  Future<ElectrumXNode> _getCurrentElectrumXNode() async {
    final node = getCurrentNode();

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  // TODO [prio=low]: Use ElectrumXInterface method.
  Future<void> _updateElectrumX() async {
    final failovers = nodeService
        .failoverNodesFor(coin: cryptoCurrency.coin)
        .map(
          (e) => ElectrumXNode(
            address: e.host,
            port: e.port,
            name: e.name,
            id: e.id,
            useSSL: e.useSSL,
          ),
        )
        .toList();

    final newNode = await _getCurrentElectrumXNode();
    try {
      await electrumXClient.closeAdapter();
    } catch (e) {
      if (e.toString().contains("initialized")) {
        // Ignore.  This should happen every first time the wallet is opened.
      } else {
        Logging.instance.log(
          "Error closing electrumXClient: $e",
          level: LogLevel.Error,
        );
      }
    }
    electrumXClient = ElectrumXClient.from(
      node: newNode,
      prefs: prefs,
      failovers: failovers,
      cryptoCurrency: cryptoCurrency,
    );

    electrumXCachedClient = CachedElectrumXClient.from(
      electrumXClient: electrumXClient,
    );
  }

  bool _duplicateTxCheck(
    List<Map<String, dynamic>> allTransactions,
    String txid,
  ) {
    for (int i = 0; i < allTransactions.length; i++) {
      if (allTransactions[i]["txid"] == txid) {
        return true;
      }
    }
    return false;
  }

  Future<UTXO> _parseUTXO({
    required Map<String, dynamic> jsonUTXO,
  }) async {
    final txn = await electrumXCachedClient.getTransaction(
      txHash: jsonUTXO["tx_hash"] as String,
      verbose: true,
      coin: cryptoCurrency.coin,
    );

    final vout = jsonUTXO["tx_pos"] as int;

    final outputs = txn["vout"] as List;

    // String? scriptPubKey;
    String? utxoOwnerAddress;
    // get UTXO owner address
    for (final output in outputs) {
      if (output["n"] == vout) {
        // scriptPubKey = output["scriptPubKey"]?["hex"] as String?;
        utxoOwnerAddress =
            output["scriptPubKey"]?["addresses"]?[0] as String? ??
                output["scriptPubKey"]?["address"] as String?;
      }
    }

    final utxo = UTXO(
      walletId: walletId,
      txid: txn["txid"] as String,
      vout: vout,
      value: jsonUTXO["value"] as int,
      name: "",
      isBlocked: false,
      blockedReason: null,
      isCoinbase: txn["is_coinbase"] as bool? ?? false,
      blockHash: txn["blockhash"] as String?,
      blockHeight: jsonUTXO["height"] as int?,
      blockTime: txn["blocktime"] as int?,
      address: utxoOwnerAddress,
    );

    return utxo;
  }
}
