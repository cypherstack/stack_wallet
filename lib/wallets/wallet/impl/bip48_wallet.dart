import 'dart:async';
import 'dart:math';

import 'package:isar/isar.dart';

import '../../../electrumx_rpc/cached_electrumx_client.dart';
import '../../../electrumx_rpc/electrumx_client.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/intermediate/bip39_hd_currency.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/multi_address_interface.dart';

class BIP48Wallet<T extends Bip39HDCurrency> extends Wallet<T>
    with MultiAddressInterface {
  BIP48Wallet(CryptoCurrencyNetwork network) : super(Bitcoin(network) as T);

  late ElectrumXClient electrumXClient;
  late CachedElectrumXClient electrumXCachedClient;

  Future<Amount> sweepAllEstimate(int feeRate) async {
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
          const FilterCondition.greaterThan(
            property: r"derivationIndex",
            value: 0,
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
          const FilterCondition.greaterThan(
            property: r"derivationIndex",
            value: 0,
          ),
        ],
      );

  @override
  Future<void> updateTransactions() async {
    // Get all addresses.
    final List<Address> allAddressesOld =
        await _fetchAddressesForElectrumXScan();

    // Separate receiving and change addresses.
    final Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => e.value)
        .toSet();
    final Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => e.value)
        .toSet();

    // Remove duplicates.
    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final currentHeight = await chainHeight;

    // Fetch history from ElectrumX.
    final List<Map<String, dynamic>> allTxHashes =
        await _fetchHistory(allAddressesSet);

    final List<Map<String, dynamic>> allTransactions = [];

    for (final txHash in allTxHashes) {
      final storedTx = await mainDB.isar.transactionV2s
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
      // TODO derive address.
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
    // TODO.
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
          final utxo = await _parseUTXO(
            jsonUTXO: fetchedUtxoList[i][j],
          );

          outputArray.add(utxo);
        }
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
    final failovers = nodeService
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
      Logging.instance.log(
        "Exception rethrown from _checkChangeAddressForTransactions"
        "($cryptoCurrency): $e\n$s",
        level: LogLevel.Error,
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
        Logging.instance.log(
          "checkReceivingAddressForTransactions called but reuse address flag set: $s",
          level: LogLevel.Error,
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
      Logging.instance.log(
        "Exception rethrown from _checkReceivingAddressForTransactions"
        "($cryptoCurrency): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<void> generateNewChangeAddress() async {
    final current = await getCurrentChangeAddress();
    const chain = 0; // TODO.
    const index = 0; // TODO.

    Address? address;
    while (address == null) {
      try {
        // TODO.
        // address = await _generateAddress(
        //   change: chain,
        //   index: index,
        // );
      } catch (e) {
        rethrow;
      }
    }

    await mainDB.updateOrPutAddresses([address]);
  }

  @override
  Future<void> generateNewReceivingAddress() async {
    final current = await getCurrentReceivingAddress();
    // TODO: Handle null assertion below.
    int index = current!.derivationIndex + 1;
    const chain = 0; // receiving address

    Address? address;
    while (address == null) {
      try {
        // TODO.
        // address = await _generateAddress(
        //   change: chain,
        //   index: index,
        // );
      } catch (e) {
        rethrow;
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

    nextReceivingAddresses
        .removeWhere((e) => e.derivationIndex > activeReceiveIndex);
    if (nextReceivingAddresses.isNotEmpty) {
      await mainDB.updateOrPutAddresses(nextReceivingAddresses);
      await info.updateReceivingAddress(
        newAddress: nextReceivingAddresses.last.value,
        isar: mainDB.isar,
      );
    }
    nextChangeAddresses
        .removeWhere((e) => e.derivationIndex > activeChangeIndex);
    if (nextChangeAddresses.isNotEmpty) {
      await mainDB.updateOrPutAddresses(nextChangeAddresses);
    }
  }

  Future<Address> _generateAddressSafe({
    required final int chain,
    required int startingIndex,
  }) async {
    Address? address;
    while (address == null) {
      try {
        // TODO.
        // address = await _generateAddress(
        //   change: chain,
        //   index: startingIndex,
        // );
      } catch (e) {
        rethrow;
      }
    }

    return address;
  }

  Future<int> _fetchTxCount({required Address address}) async {
    final transactions = await electrumXClient.getHistory(
      scripthash: cryptoCurrency.addressToScriptHash(
        address: address.value,
      ),
    );
    return transactions.length;
  }

  Future<List<Address>> _fetchAddressesForElectrumXScan() async {
    final allAddresses = await mainDB
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
      Logging.instance.log(
        "$runtimeType._fetchHistory: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }
}
