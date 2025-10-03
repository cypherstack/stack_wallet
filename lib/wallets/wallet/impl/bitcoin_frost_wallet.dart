import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:frostdart/frostdart.dart' as frost;
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:frostdart/util.dart';
import 'package:isar_community/isar.dart';

import '../../../electrumx_rpc/cached_electrumx_client.dart';
import '../../../electrumx_rpc/electrumx_client.dart';
import '../../../models/balance.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/frost.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/intermediate/frost_currency.dart';
import '../../isar/models/frost_wallet_info.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/multi_address_interface.dart';

const kFrostSecureStartingIndex = 1;

class BitcoinFrostWallet<T extends FrostCurrency> extends Wallet<T>
    with MultiAddressInterface {
  BitcoinFrostWallet(CryptoCurrencyNetwork network)
    : super(BitcoinFrost(network) as T);

  FrostWalletInfo get frostInfo =>
      mainDB.isar.frostWalletInfo
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
    Logging.instance.i("Generating new FROST wallet.");

    try {
      final salt = frost.multisigSalt(multisigConfig: multisigConfig).toHex;

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

      Address? address;
      int index = kFrostSecureStartingIndex;
      while (address == null) {
        try {
          address = await _generateAddress(
            change: 0,
            index: index,
            serializedKeys: serializedKeys,
            secure: true,
          );
        } on FrostdartException catch (e) {
          if (e.errorCode == 72) {
            // rust doesn't like the addressDerivationData
            index++;
            continue;
          } else {
            rethrow;
          }
        }
      }

      await mainDB.putAddresses([address]);
    } catch (e, s) {
      Logging.instance.f(
        "Exception rethrown from initializeNewFrost(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<TxData> frostCreateSignConfig({
    required TxData txData,
    required int feePerWeight,
  }) async {
    try {
      if (txData.recipients == null || txData.recipients!.isEmpty) {
        throw Exception("No recipients found!");
      }

      final total = txData.recipients!
          .map((e) => e.amount)
          .reduce((value, e) => value += e);

      final utxos =
          await mainDB
              .getUTXOs(walletId)
              .filter()
              .isBlockedEqualTo(false)
              .findAll();

      if (utxos.isEmpty) {
        throw Exception("No UTXOs found");
      } else {
        final currentHeight = await chainHeight;
        utxos.removeWhere(
          (e) =>
              !e.isConfirmed(
                currentHeight,
                cryptoCurrency.minConfirms,
                cryptoCurrency.minCoinbaseConfirms,
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
      final Set<UTXO> utxosRemaining = {};
      for (int i = 0; i < utxos.length; i++) {
        final utxo = utxos[i];
        sum += Amount(
          rawValue: BigInt.from(utxo.value),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
        utxosToUse.add(utxo);
        if (sum > total) {
          if (i + 1 < utxos.length) {
            utxosRemaining.addAll(utxos.sublist(i));
          }
          break;
        }
      }

      final int network =
          cryptoCurrency.network == CryptoCurrencyNetwork.main
              ? Network.Mainnet
              : Network.Testnet;

      final List<
        ({
          UTXO utxo,
          Uint8List scriptPubKey,
          ({int account, int index, bool change, bool secure})
          addressDerivationData,
        })
      >
      inputs = [];

      for (final utxo in utxosToUse) {
        final dData = await getDerivationData(utxo.address);
        final publicKey = cryptoCurrency.addressToPubkey(
          address: utxo.address!,
        );

        inputs.add((
          utxo: utxo,
          scriptPubKey: publicKey,
          addressDerivationData: dData,
        ));
      }
      await checkChangeAddressForTransactions();
      final changeAddress = await getCurrentChangeAddress();

      String? config;

      while (config == null) {
        try {
          config = Frost.createSignConfig(
            network: network,
            inputs: inputs,
            outputs: txData.recipients!,
            changeAddress: changeAddress!.value,
            feePerWeight: feePerWeight,
            serializedKeys: (await getSerializedKeys())!,
          );
        } on FrostdartException catch (e) {
          if (e.errorCode == NOT_ENOUGH_FUNDS_ERROR &&
              utxosRemaining.isNotEmpty) {
            // add extra utxo
            final utxo = utxosRemaining.take(1).first;
            final dData = await getDerivationData(utxo.address);
            final publicKey = cryptoCurrency.addressToPubkey(
              address: utxo.address!,
            );
            inputs.add((
              utxo: utxo,
              scriptPubKey: publicKey,
              addressDerivationData: dData,
            ));
          } else {
            rethrow;
          }
        }
      }

      return txData.copyWith(
        frostMSConfig: config,
        utxos: utxosToUse.map((e) => StandardInput(e)).toSet(),
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<({int account, int index, bool change, bool secure})>
  getDerivationData(String? address) async {
    if (address == null) {
      throw Exception("Missing address required for FROST signing");
    }

    final addr = await mainDB.getAddress(walletId, address);
    if (addr == null) {
      throw Exception("Missing address in DB required for FROST signing");
    }

    final dPath = addr.derivationPath?.value ?? "0/0/0";

    try {
      final components = dPath.split("/").map((e) => int.parse(e)).toList();

      if (components.length != 3) {
        throw Exception(
          "Unexpected derivation data `$components` for FROST signing",
        );
      }
      if (components[1] != 0 && components[1] != 1) {
        throw Exception("${components[1]} must be 1 or 0 for change");
      }

      return (
        account: components[0],
        change: components[1] == 1,
        index: components[2],
        secure: addr.zSafeFrost ?? false,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<
    ({Pointer<TransactionSignMachineWrapper> machinePtr, String preprocess})
  >
  frostAttemptSignConfig({required String config}) async {
    final int network =
        cryptoCurrency.network == CryptoCurrencyNetwork.main
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
      frost.getThresholdFromKeys(serializedKeys: serializedKeys),
    );

    final myNameIndex = frost.getParticipantIndexFromKeys(
      serializedKeys: serializedKeys,
    );
    final participants = Frost.getParticipants(multisigConfig: multisigConfig);
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

  Future<Amount> sweepAllEstimate(BigInt feeRate) async {
    int available = 0;
    int inputCount = 0;
    final height = await chainHeight;
    for (final output in (await mainDB.getUTXOs(walletId).findAll())) {
      if (!output.isBlocked &&
          output.isConfirmed(
            height,
            cryptoCurrency.minConfirms,
            cryptoCurrency.minCoinbaseConfirms,
          )) {
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

  Amount _roughFeeEstimate(
    int inputCount,
    int outputCount,
    BigInt feeRatePerKB,
  ) {
    return Amount(
      rawValue: BigInt.from(
        ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
            (feeRatePerKB.toInt() / 1000).ceil(),
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
  FilterOperation? get changeAddressFilterOperation => FilterGroup.and([
    FilterCondition.equalTo(property: r"type", value: info.mainAddressType),
    const FilterCondition.equalTo(
      property: r"subType",
      value: AddressSubType.change,
    ),
    const FilterCondition.equalTo(property: r"zSafeFrost", value: true),
    const FilterCondition.greaterThan(property: r"derivationIndex", value: 0),
  ]);

  @override
  FilterOperation? get receivingAddressFilterOperation => FilterGroup.and([
    FilterCondition.equalTo(property: r"type", value: info.mainAddressType),
    const FilterCondition.equalTo(
      property: r"subType",
      value: AddressSubType.receiving,
    ),
    const FilterCondition.equalTo(property: r"zSafeFrost", value: true),
    const FilterCondition.greaterThan(property: r"derivationIndex", value: 0),
  ]);

  @override
  Future<void> updateTransactions() async {
    // Get all addresses.
    final List<Address> allAddressesOld =
        await _fetchAddressesForElectrumXScan();

    // Separate receiving and change addresses.
    final Set<String> receivingAddresses =
        allAddressesOld
            .where((e) => e.subType == AddressSubType.receiving)
            .map((e) => e.value)
            .toSet();
    final Set<String> changeAddresses =
        allAddressesOld
            .where((e) => e.subType == AddressSubType.change)
            .map((e) => e.value)
            .toSet();

    // Remove duplicates.
    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final currentHeight = await chainHeight;

    // Fetch history from ElectrumX.
    final List<Map<String, dynamic>> allTxHashes = await _fetchHistory(
      allAddressesSet,
    );

    final List<Map<String, dynamic>> allTransactions = [];

    for (final txHash in allTxHashes) {
      final storedTx =
          await mainDB.isar.transactionV2s
              .where()
              .walletIdEqualTo(walletId)
              .filter()
              .txidEqualTo(txHash["tx_hash"] as String)
              .findFirst();

      if (storedTx == null ||
          !storedTx.isConfirmed(
            currentHeight,
            cryptoCurrency.minConfirms,
            cryptoCurrency.minCoinbaseConfirms,
          )) {
        final tx = await electrumXCachedClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          cryptoCurrency: cryptoCurrency,
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
      BigInt changeAmountReceivedInThisWallet = BigInt.zero;
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
            cryptoCurrency: cryptoCurrency,
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
        if (allAddressesSet.intersection(input.addresses.toSet()).isNotEmpty) {
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
        if (receivingAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          amountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        } else if (changeAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          changeAmountReceivedInThisWallet += output.value;
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
          final List<String>? scriptChunks = outputs[i].scriptPubKeyAsm?.split(
            " ",
          );
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
          if (changeAmountReceivedInThisWallet + amountReceivedInThisWallet ==
              totalOut) {
            // Definitely sent all to self.
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // Most likely just a typical send, do nothing here yet.
          }
        }
      } else if (wasReceivedInThisWallet) {
        // Only found outputs owned by this wallet.
        type = TransactionType.incoming;

        // TODO: [prio=none] Check for special Bitcoin outputs like ordinals.
      } else {
        Logging.instance.e("Unexpected tx found (ignoring it): $txData");
        continue;
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp:
            txData["blocktime"] as int? ??
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
        int index = kFrostSecureStartingIndex;
        const someSaneMaximum = 200;
        Address? address;
        while (index < someSaneMaximum) {
          try {
            address = await _generateAddress(
              change: 0,
              index: index,
              serializedKeys: serializedKeys,
              secure: true,
            );

            await mainDB.updateOrPutAddresses([address]);
          } catch (_) {}
          if (address != null) {
            break;
          }
          index++;
        }

        if (index >= someSaneMaximum) {
          throw Exception(
            "index < kFrostSecureStartingIndex hit someSaneMaximum",
          );
        }
      } else {
        Logging.instance.f(
          "$runtimeType.checkSaveInitialReceivingAddress() failed due"
          " to missing serialized keys",
        );
      }
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      Logging.instance.d("confirmSend txData: $txData");

      final hex = txData.raw!;

      final txHash = await electrumXClient.broadcastTransaction(rawTx: hex);
      Logging.instance.d("Sent txHash: $txHash");

      // mark utxos as used
      final usedUTXOs = txData.utxos!.whereType<StandardInput>().map(
        (e) => e.utxo.copyWith(used: true),
      );
      await mainDB.putUTXOs(usedUTXOs.toList());

      txData = txData.copyWith(
        utxos: usedUTXOs.map((e) => StandardInput(e)).toSet(),
        txHash: txHash,
        txid: txHash,
      );

      return txData;
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from confirmSend(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
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
        fast:
            Amount.fromDecimal(
              fast,
              fractionDigits: cryptoCurrency.fractionDigits,
            ).raw,
        medium:
            Amount.fromDecimal(
              medium,
              fractionDigits: cryptoCurrency.fractionDigits,
            ).raw,
        slow:
            Amount.fromDecimal(
              slow,
              fractionDigits: cryptoCurrency.fractionDigits,
            ).raw,
      );

      Logging.instance.i("fetched fees: $feeObject");
      return feeObject;
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _getFees(): $e",
        error: e,
        stackTrace: s,
      );
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
      Logging.instance.f(err, stackTrace: StackTrace.current);
      throw Exception(err);
      // TODO [prio=low]: handle null keys or config.  This should not happen.
    }

    final coin = info.coin;

    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(WalletSyncStatus.syncing, walletId, coin),
    );

    try {
      await refreshMutex.protect(() async {
        if (!isRescan) {
          final salt =
              frost.multisigSalt(multisigConfig: multisigConfig!).toHex;
          final knownSalts = _getKnownSalts();
          if (knownSalts.contains(salt)) {
            throw Exception("Known frost multisig salt found!");
          }
          final List<String> updatedKnownSalts = List<String>.from(knownSalts);
          updatedKnownSalts.add(salt);
          await _updateKnownSalts(updatedKnownSalts);
        } else {
          // clear cache
          await electrumXCachedClient.clearSharedTransactionCache(
            cryptoCurrency: coin,
          );
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        await _saveSerializedKeys(serializedKeys!);
        await _saveMultisigConfig(multisigConfig!);

        const receiveChain = 0;
        const changeChain = 1;
        final List<Future<({int index, List<Address> addresses})>>
        receiveFutures = [
          _checkGapsLinearly(serializedKeys, receiveChain, secure: true),
        ];
        final List<Future<({int index, List<Address> addresses})>>
        changeFutures = [
          _checkGapsLinearly(serializedKeys, changeChain, secure: true),
        ];

        // io limitations may require running these linearly instead
        final futuresResult = await Future.wait([
          Future.wait(receiveFutures),
          Future.wait(changeFutures),
        ]);

        final receiveResults = futuresResult[0];
        final changeResults = futuresResult[1];

        final List<Address> addressesToStore = [];

        int highestReceivingIndexWithHistory = 0;

        for (final tuple in receiveResults) {
          if (tuple.addresses.isEmpty) {
            await checkReceivingAddressForTransactions();
          } else {
            highestReceivingIndexWithHistory = max(
              tuple.index,
              highestReceivingIndexWithHistory,
            );
            addressesToStore.addAll(tuple.addresses);
          }
        }

        int highestChangeIndexWithHistory = 0;
        // If restoring a wallet that never sent any funds with change, then set changeArray
        // manually. If we didn't do this, it'd store an empty array.
        for (final tuple in changeResults) {
          if (tuple.addresses.isEmpty) {
            await checkChangeAddressForTransactions();
          } else {
            highestChangeIndexWithHistory = max(
              tuple.index,
              highestChangeIndexWithHistory,
            );
            addressesToStore.addAll(tuple.addresses);
          }
        }

        // remove extra addresses to help minimize risk of creating a large gap
        addressesToStore.removeWhere(
          (e) =>
              e.subType == AddressSubType.change &&
              e.derivationIndex > highestChangeIndexWithHistory,
        );
        addressesToStore.removeWhere(
          (e) =>
              e.subType == AddressSubType.receiving &&
              e.derivationIndex > highestReceivingIndexWithHistory,
        );

        await mainDB.updateOrPutAddresses(addressesToStore);

        await _legacyInsecureScan(serializedKeys);
      });

      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(WalletSyncStatus.synced, walletId, coin),
      );

      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.f(
        "recoverFromSerializedKeys failed: ",
        error: e,
        stackTrace: s,
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

  // for legacy support secure is set to false to see
  // funds received on insecure addresses
  Future<void> _legacyInsecureScan(String serializedKeys) async {
    const receiveChain = 0;
    const changeChain = 1;

    final List<Future<({int index, List<Address> addresses})>> receiveFutures =
        [_checkGapsLinearly(serializedKeys, receiveChain, secure: false)];
    final List<Future<({int index, List<Address> addresses})>> changeFutures = [
      // for legacy support secure is set to false to see
      // funds received on insecure addresses
      _checkGapsLinearly(serializedKeys, changeChain, secure: false),
    ];

    // io limitations may require running these linearly instead
    final futuresResult = await Future.wait([
      Future.wait(receiveFutures),
      Future.wait(changeFutures),
    ]);

    final receiveResults = futuresResult[0];
    final changeResults = futuresResult[1];

    final List<Address> addressesToStore = [];

    int highestReceivingIndexWithHistory = 0;
    for (final tuple in receiveResults) {
      if (tuple.addresses.isNotEmpty) {
        highestReceivingIndexWithHistory = max(
          tuple.index,
          highestReceivingIndexWithHistory,
        );
        addressesToStore.addAll(tuple.addresses);
      }
    }

    int highestChangeIndexWithHistory = 0;
    for (final tuple in changeResults) {
      if (tuple.addresses.isNotEmpty) {
        highestChangeIndexWithHistory = max(
          tuple.index,
          highestChangeIndexWithHistory,
        );
        addressesToStore.addAll(tuple.addresses);
      }
    }

    // remove extra addresses to help minimize risk of creating a large gap
    addressesToStore.removeWhere(
      (e) =>
          e.subType == AddressSubType.change &&
          e.derivationIndex > highestChangeIndexWithHistory,
    );
    addressesToStore.removeWhere(
      (e) =>
          e.subType == AddressSubType.receiving &&
          e.derivationIndex > highestReceivingIndexWithHistory,
    );

    if (addressesToStore.isNotEmpty) {
      await mainDB.updateOrPutAddresses(addressesToStore);
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
          cryptoCurrency.minCoinbaseConfirms,
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

    await info.updateCachedChainHeight(newHeight: height, isar: mainDB.isar);
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
    final allAddresses = await _fetchAddressesForElectrumXScan();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];
      for (int i = 0; i < allAddresses.length; i++) {
        final scriptHash = cryptoCurrency.addressToScriptHash(
          address: allAddresses[i].value,
        );

        final utxos = await electrumXClient.getUTXOs(scripthash: scriptHash);
        if (utxos.isNotEmpty) {
          fetchedUtxoList.add(utxos);
        }
      }

      final List<UTXO> outputArray = [];

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          final utxo = await _parseUTXO(jsonUTXO: fetchedUtxoList[i][j]);

          outputArray.add(utxo);
        }
      }

      return await mainDB.updateUTXOs(walletId, outputArray);
    } catch (e, s) {
      Logging.instance.e(
        "Output fetch unsuccessful: ",
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  // =================== Secure storage ========================================

  Future<String?> getSerializedKeys() async =>
      await secureStorageInterface.read(key: "{$walletId}_serializedFROSTKeys");

  Future<void> _saveSerializedKeys(String keys) async {
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
      await secureStorageInterface.read(key: "{$walletId}_multisigConfig");

  Future<String?> getMultisigConfigPrevGen() async =>
      await secureStorageInterface.read(
        key: "{$walletId}_multisigConfigPrevGen",
      );

  Future<void> _saveMultisigConfig(String multisigConfig) async {
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

  Future<void> _saveMultisigId(Uint8List id) async =>
      await secureStorageInterface.write(
        key: "{$walletId}_multisigIdFROST",
        value: id.toHex,
      );

  Future<String?> _recoveryString() async =>
      await secureStorageInterface.read(key: "{$walletId}_recoveryStringFROST");

  Future<void> _saveRecoveryString(String recoveryString) async =>
      await secureStorageInterface.write(
        key: "{$walletId}_recoveryStringFROST",
        value: recoveryString,
      );

  // =================== DB ====================================================

  List<String> _getKnownSalts() =>
      mainDB.isar.frostWalletInfo
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

  List<String> _getParticipants() =>
      mainDB.isar.frostWalletInfo
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

  int _getThreshold() =>
      mainDB.isar.frostWalletInfo
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

  String _getMyName() =>
      mainDB.isar.frostWalletInfo
          .where()
          .walletIdEqualTo(walletId)
          .myNameProperty()
          .findFirstSync()!;

  Future<void> _updateMyName(String myName) async {
    final info = frostInfo;

    await mainDB.isar.writeTxn(() async {
      await mainDB.isar.frostWalletInfo.delete(info.id);
      await mainDB.isar.frostWalletInfo.put(info.copyWith(myName: myName));
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
      torEnabled: node.torEnabled,
      clearnetEnabled: node.clearnetEnabled,
    );
  }

  // TODO [prio=low]: Use ElectrumXInterface method.
  Future<void> _updateElectrumX() async {
    final failovers =
        nodeService
            .failoverNodesFor(currency: cryptoCurrency)
            .map(
              (e) => ElectrumXNode(
                address: e.host,
                port: e.port,
                name: e.name,
                id: e.id,
                useSSL: e.useSSL,
                torEnabled: e.torEnabled,
                clearnetEnabled: e.clearnetEnabled,
              ),
            )
            .toList();

    final newNode = await _getCurrentElectrumXNode();
    try {
      await electrumXClient.closeAdapter();
    } catch (e, s) {
      if (e.toString().contains("initialized")) {
        // Ignore.  This should happen every first time the wallet is opened.
      } else {
        Logging.instance.e(
          "Error closing electrumXClient",
          error: e,
          stackTrace: s,
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

  Future<UTXO> _parseUTXO({required Map<String, dynamic> jsonUTXO}) async {
    final txn = await electrumXCachedClient.getTransaction(
      txHash: jsonUTXO["tx_hash"] as String,
      verbose: true,
      cryptoCurrency: cryptoCurrency,
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

  @override
  Future<void> checkChangeAddressForTransactions() async {
    try {
      final currentChange = await getCurrentChangeAddress();

      final bool needsGenerate;
      if (currentChange == null) {
        // no addresses in db yet for some reason.
        // Should not happen at this point...

        needsGenerate = true;
      } else {
        final txCount = await _fetchTxCount(address: currentChange);
        needsGenerate = txCount > 0 || currentChange.derivationIndex < 0;
      }

      if (needsGenerate) {
        await generateNewChangeAddress();

        // TODO: get rid of this? Could cause problems (long loading/infinite loop or something)
        // keep checking until address with no tx history is set as current
        await checkChangeAddressForTransactions();
      }
    } catch (e, s) {
      Logging.instance.i(
        "Exception rethrown from _checkChangeAddressForTransactions"
        "($cryptoCurrency): $e\n$s",
      );
      rethrow;
    }
  }

  @override
  Future<void> checkReceivingAddressForTransactions() async {
    if (info.otherData[WalletInfoKeys.reuseAddress] == true) {
      try {
        throw Exception();
      } catch (_, s) {
        Logging.instance.e(
          "checkReceivingAddressForTransactions called but reuse address flag set: $s",
          stackTrace: s,
        );
      }
    }

    try {
      final currentReceiving = await getCurrentReceivingAddress();

      final bool needsGenerate;
      if (currentReceiving == null) {
        // no addresses in db yet for some reason.
        // Should not happen at this point...

        needsGenerate = true;
      } else {
        final txCount = await _fetchTxCount(address: currentReceiving);
        needsGenerate = txCount > 0 || currentReceiving.derivationIndex < 0;
      }

      if (needsGenerate) {
        await generateNewReceivingAddress();

        // TODO: [prio=low] Make sure we scan all addresses but only show one.
        if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
          // TODO: get rid of this? Could cause problems (long loading/infinite loop or something)
          // keep checking until address with no tx history is set as current
          await checkReceivingAddressForTransactions();
        }
      }
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _checkReceivingAddressForTransactions"
        "($cryptoCurrency)",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> generateNewChangeAddress() async {
    final current = await getCurrentChangeAddress();
    int index =
        current == null
            ? kFrostSecureStartingIndex
            : current.derivationIndex + 1;
    const chain = 1; // change address

    final serializedKeys = (await getSerializedKeys())!;

    Address? address;
    while (address == null) {
      try {
        address = await _generateAddress(
          change: chain,
          index: index,
          serializedKeys: serializedKeys,
          secure: true,
        );
      } on FrostdartException catch (e) {
        if (e.errorCode == 72) {
          // rust doesn't like the addressDerivationData
          index++;
          continue;
        } else {
          rethrow;
        }
      }
    }

    await mainDB.updateOrPutAddresses([address]);
  }

  @override
  Future<void> generateNewReceivingAddress() async {
    final current = await getCurrentReceivingAddress();
    int index =
        current == null
            ? kFrostSecureStartingIndex
            : current.derivationIndex + 1;
    const chain = 0; // receiving address

    final serializedKeys = (await getSerializedKeys())!;

    Address? address;
    while (address == null) {
      try {
        address = await _generateAddress(
          change: chain,
          index: index,
          serializedKeys: serializedKeys,
          secure: true,
        );
      } on FrostdartException catch (e) {
        if (e.errorCode == 72) {
          // rust doesn't like the addressDerivationData
          index++;
          continue;
        } else {
          rethrow;
        }
      }
    }

    await mainDB.updateOrPutAddresses([address]);
    await info.updateReceivingAddress(
      newAddress: address.value,
      isar: mainDB.isar,
    );
  }

  Future<void> lookAhead() async {
    Address? currentReceiving = await getCurrentReceivingAddress();
    if (currentReceiving == null) {
      await generateNewReceivingAddress();
      currentReceiving = await getCurrentReceivingAddress();
    }
    Address? currentChange = await getCurrentChangeAddress();
    if (currentChange == null) {
      await generateNewChangeAddress();
      currentChange = await getCurrentChangeAddress();
    }

    final List<Address> nextReceivingAddresses = [];
    final List<Address> nextChangeAddresses = [];

    int receiveIndex = currentReceiving!.derivationIndex;
    int changeIndex = currentChange!.derivationIndex;
    for (int i = 0; i < 10; i++) {
      final receiveAddress = await _generateAddressSafe(
        chain: 0,
        startingIndex: receiveIndex + 1,
      );
      receiveIndex = receiveAddress.derivationIndex;
      nextReceivingAddresses.add(receiveAddress);

      final changeAddress = await _generateAddressSafe(
        chain: 1,
        startingIndex: changeIndex + 1,
      );
      changeIndex = changeAddress.derivationIndex;
      nextChangeAddresses.add(changeAddress);
    }

    int activeReceiveIndex = currentReceiving.derivationIndex;
    int activeChangeIndex = currentChange.derivationIndex;
    for (final address in nextReceivingAddresses) {
      final txCount = await _fetchTxCount(address: address);
      if (txCount > 0) {
        activeReceiveIndex = max(activeReceiveIndex, address.derivationIndex);
      }
    }
    for (final address in nextChangeAddresses) {
      final txCount = await _fetchTxCount(address: address);
      if (txCount > 0) {
        activeChangeIndex = max(activeChangeIndex, address.derivationIndex);
      }
    }

    nextReceivingAddresses.removeWhere(
      (e) => e.derivationIndex > activeReceiveIndex,
    );
    if (nextReceivingAddresses.isNotEmpty) {
      await mainDB.updateOrPutAddresses(nextReceivingAddresses);
      await info.updateReceivingAddress(
        newAddress: nextReceivingAddresses.last.value,
        isar: mainDB.isar,
      );
    }
    nextChangeAddresses.removeWhere(
      (e) => e.derivationIndex > activeChangeIndex,
    );
    if (nextChangeAddresses.isNotEmpty) {
      await mainDB.updateOrPutAddresses(nextChangeAddresses);
    }
  }

  Future<Address> _generateAddressSafe({
    required final int chain,
    required int startingIndex,
  }) async {
    final serializedKeys = (await getSerializedKeys())!;

    Address? address;
    while (address == null) {
      try {
        address = await _generateAddress(
          change: chain,
          index: startingIndex,
          serializedKeys: serializedKeys,
          secure: true,
        );
      } on FrostdartException catch (e) {
        if (e.errorCode == 72) {
          // rust doesn't like the addressDerivationData
          startingIndex++;
          continue;
        } else {
          rethrow;
        }
      }
    }

    return address;
  }

  /// Can and will often throw unless [index], [change], and [account] are zero.
  /// Caller MUST handle exception!
  Future<Address> _generateAddress({
    int account = 0,
    required int change,
    required int index,
    required String serializedKeys,
    required bool secure,
  }) async {
    final addressDerivationData = (
      account: account,
      change: change == 1,
      index: index,
      secure: secure,
    );

    final keys = frost.deserializeKeys(keys: serializedKeys);

    final addressString = frost.addressForKeys(
      network:
          cryptoCurrency.network == CryptoCurrencyNetwork.main
              ? Network.Mainnet
              : Network.Testnet,
      keys: keys,
      addressDerivationData: addressDerivationData,
      secure: secure,
    );

    return Address(
      walletId: info.walletId,
      value: addressString,
      publicKey: cryptoCurrency.addressToPubkey(address: addressString),
      derivationIndex: index,
      derivationPath: DerivationPath()..value = "$account/$change/$index",
      subType:
          change == 0
              ? AddressSubType.receiving
              : change == 1
              ? AddressSubType.change
              : AddressSubType.unknown,
      type: AddressType.frostMS,
      zSafeFrost: secure && index >= kFrostSecureStartingIndex,
    );
  }

  Future<({List<Address> addresses, int index})> _checkGapsLinearly(
    String serializedKeys,
    int chain, {
    required bool secure,
  }) async {
    final List<Address> addressArray = [];
    int gapCounter = 0;
    int index = secure ? kFrostSecureStartingIndex : 0;
    for (; gapCounter < 20; index++) {
      Logging.instance.d(
        "Frost index: $index, \t GapCounter chain=$chain: $gapCounter",
      );

      Address? address;
      while (address == null) {
        try {
          address = await _generateAddress(
            change: chain,
            index: index,
            serializedKeys: serializedKeys,
            secure: secure,
          );
        } on FrostdartException catch (e) {
          if (e.errorCode == 72) {
            // rust doesn't like the addressDerivationData
            index++;
            continue;
          } else {
            rethrow;
          }
        }
      }

      // get address tx count
      final count = await _fetchTxCount(address: address);

      // check and add appropriate addresses
      if (count > 0) {
        // add address to array
        addressArray.add(address);
        // reset counter
        gapCounter = 0;
        // add info to derivations
      } else {
        // increase counter when no tx history found
        gapCounter++;
      }
    }

    return (addresses: addressArray, index: index);
  }

  Future<int> _fetchTxCount({required Address address}) async {
    final transactions = await electrumXClient.getHistory(
      scripthash: cryptoCurrency.addressToScriptHash(address: address.value),
    );
    return transactions.length;
  }

  Future<List<Address>> _fetchAddressesForElectrumXScan() async {
    final allAddresses =
        await mainDB
            .getAddresses(walletId)
            .filter()
            .not()
            .group(
              (q) => q
                  .typeEqualTo(AddressType.nonWallet)
                  .or()
                  .subTypeEqualTo(AddressSubType.nonWallet),
            )
            .findAll();
    return allAddresses;
  }

  Future<List<Map<String, dynamic>>> _fetchHistory(
    Iterable<String> allAddresses,
  ) async {
    try {
      final List<Map<String, dynamic>> allTxHashes = [];
      for (int i = 0; i < allAddresses.length; i++) {
        final addressString = allAddresses.elementAt(i);
        final scriptHash = cryptoCurrency.addressToScriptHash(
          address: addressString,
        );

        final response = await electrumXClient.getHistory(
          scripthash: scriptHash,
        );

        for (int j = 0; j < response.length; j++) {
          response[j]["address"] = addressString;
          if (!allTxHashes.contains(response[j])) {
            allTxHashes.add(response[j]);
          }
        }
      }

      return allTxHashes;
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType._fetchHistory: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}
