import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/services/coins/bitcoincash/bch_utils.dart';
import 'package:stackwallet/services/coins/bitcoincash/cashtokens.dart'
    as cash_tokens;
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/wallet/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/electrumx_mixin.dart';

class BitcoincashWallet extends Bip39HDWallet with ElectrumXMixin {
  @override
  int get isarTransactionVersion => 2;

  BitcoincashWallet(
    super.cryptoCurrency, {
    required NodeService nodeService,
  }) {
    // TODO: [prio=low] ensure this hack isn't needed
    assert(cryptoCurrency is Bitcoin);

    this.nodeService = nodeService;
  }

  // ===========================================================================

  Future<List<Address>> _fetchAllOwnAddresses() async {
    final allAddresses = await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .and()
        .group((q) => q
            .subTypeEqualTo(AddressSubType.receiving)
            .or()
            .subTypeEqualTo(AddressSubType.change))
        .findAll();
    return allAddresses;
  }

  // ===========================================================================

  @override
  Future<void> updateBalance() async {
    final utxos = await mainDB.getUTXOs(walletId).findAll();

    final currentChainHeight = await fetchChainHeight();

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

    await walletInfo.updateBalance(newBalance: balance, isar: mainDB.isar);
  }

  @override
  Future<void> updateTransactions() async {
    List<Address> allAddressesOld = await _fetchAllOwnAddresses();

    Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) {
      if (bitbox.Address.detectFormat(e.value) == bitbox.Address.formatLegacy &&
          (cryptoCurrency.addressType(address: e.value) ==
                  DerivePathType.bip44 ||
              cryptoCurrency.addressType(address: e.value) ==
                  DerivePathType.bch44)) {
        return bitbox.Address.toCashAddress(e.value);
      } else {
        return e.value;
      }
    }).toSet();

    Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) {
      if (bitbox.Address.detectFormat(e.value) == bitbox.Address.formatLegacy &&
          (cryptoCurrency.addressType(address: e.value) ==
                  DerivePathType.bip44 ||
              cryptoCurrency.addressType(address: e.value) ==
                  DerivePathType.bch44)) {
        return bitbox.Address.toCashAddress(e.value);
      } else {
        return e.value;
      }
    }).toSet();

    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddressesSet);

    List<Map<String, dynamic>> allTransactions = [];

    for (final txHash in allTxHashes) {
      final storedTx = await mainDB.isar.transactionV2s
          .where()
          .txidWalletIdEqualTo(txHash["tx_hash"] as String, walletId)
          .findFirst();

      if (storedTx == null ||
          storedTx.height == null ||
          (storedTx.height != null && storedTx.height! <= 0)) {
        final tx = await electrumXCached.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          coin: cryptoCurrency.coin,
        );

        // check for duplicates before adding to list
        if (allTransactions
                .indexWhere((e) => e["txid"] == tx["txid"] as String) ==
            -1) {
          tx["height"] = txHash["height"];
          allTransactions.add(tx);
        }
      }
    }

    final List<TransactionV2> txns = [];

    for (final txData in allTransactions) {
      // set to true if any inputs were detected as owned by this wallet
      bool wasSentFromThisWallet = false;

      // set to true if any outputs were detected as owned by this wallet
      bool wasReceivedInThisWallet = false;
      BigInt amountReceivedInThisWallet = BigInt.zero;
      BigInt changeAmountReceivedInThisWallet = BigInt.zero;

      // parse inputs
      final List<InputV2> inputs = [];
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);

        final List<String> addresses = [];
        String valueStringSats = "0";
        OutpointV2? outpoint;

        final coinbase = map["coinbase"] as String?;

        if (coinbase == null) {
          final txid = map["txid"] as String;
          final vout = map["vout"] as int;

          final inputTx = await electrumXCached.getTransaction(
            txHash: txid,
            coin: cryptoCurrency.coin,
          );

          final prevOutJson = Map<String, dynamic>.from(
              (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout)
                  as Map);

          final prevOut = OutputV2.fromElectrumXJson(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
            walletOwns: false, // doesn't matter here as this is not saved
          );

          outpoint = OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: txid,
            vout: vout,
          );
          valueStringSats = prevOut.valueStringSats;
          addresses.addAll(prevOut.addresses);
        }

        InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: map["scriptSig"]?["hex"] as String?,
          sequence: map["sequence"] as int?,
          outpoint: outpoint,
          valueStringSats: valueStringSats,
          addresses: addresses,
          witness: map["witness"] as String?,
          coinbase: coinbase,
          innerRedeemScriptAsm: map["innerRedeemscriptAsm"] as String?,
          // don't know yet if wallet owns. Need addresses first
          walletOwns: false,
        );

        if (allAddressesSet.intersection(input.addresses.toSet()).isNotEmpty) {
          wasSentFromThisWallet = true;
          input = input.copyWith(walletOwns: true);
        }

        inputs.add(input);
      }

      // parse outputs
      final List<OutputV2> outputs = [];
      for (final outputJson in txData["vout"] as List) {
        OutputV2 output = OutputV2.fromElectrumXJson(
          Map<String, dynamic>.from(outputJson as Map),
          decimalPlaces: cryptoCurrency.fractionDigits,
          // don't know yet if wallet owns. Need addresses first
          walletOwns: false,
        );

        // if output was to my wallet, add value to amount received
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

      // at least one input was owned by this wallet
      if (wasSentFromThisWallet) {
        type = TransactionType.outgoing;

        if (wasReceivedInThisWallet) {
          if (changeAmountReceivedInThisWallet + amountReceivedInThisWallet ==
              totalOut) {
            // definitely sent all to self
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // most likely just a typical send
            // do nothing here yet
          }

          // check vout 0 for special scripts
          if (outputs.isNotEmpty) {
            final output = outputs.first;

            // check for fusion
            if (BchUtils.isFUZE(output.scriptPubKeyHex.toUint8ListFromHex)) {
              subType = TransactionSubType.cashFusion;
            } else {
              // check other cases here such as SLP or cash tokens etc
            }
          }
        }
      } else if (wasReceivedInThisWallet) {
        // only found outputs owned by this wallet
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
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  ({String? blockedReason, bool blocked}) checkBlock(
      Map<String, dynamic> jsonUTXO, String? scriptPubKeyHex) {
    bool blocked = false;
    String? blockedReason;

    if (scriptPubKeyHex != null) {
      // check for cash tokens
      try {
        final ctOutput =
            cash_tokens.unwrap_spk(scriptPubKeyHex.toUint8ListFromHex);
        if (ctOutput.token_data != null) {
          // found a token!
          blocked = true;
          blockedReason = "Cash token output detected";
        }
      } catch (e, s) {
        // Probably doesn't contain a cash token so just log failure
        Logging.instance.log(
          "Script pub key \"$scriptPubKeyHex\" cash token"
          " parsing check failed: $e\n$s",
          level: LogLevel.Warning,
        );
      }

      // check for SLP tokens if not already blocked
      if (!blocked && BchUtils.isSLP(scriptPubKeyHex.toUint8ListFromHex)) {
        blocked = true;
        blockedReason = "SLP token output detected";
      }
    }

    return (blockedReason: blockedReason, blocked: blocked);
  }

  @override
  Future<void> updateUTXOs() async {
    final allAddresses = await _fetchAllOwnAddresses();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      const batchSizeMax = 10;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scriptHash = cryptoCurrency.addressToScriptHash(
          address: allAddresses[i].value,
        );

        batches[batchNumber]!.addAll({
          scriptHash: [scriptHash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response = await electrumX.getBatchUTXOs(args: batches[i]!);
        for (final entry in response.entries) {
          if (entry.value.isNotEmpty) {
            fetchedUtxoList.add(entry.value);
          }
        }
      }

      final List<UTXO> outputArray = [];

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          final utxo = await parseUTXO(jsonUTXO: fetchedUtxoList[i][j]);

          outputArray.add(utxo);
        }
      }

      await mainDB.updateUTXOs(walletId, outputArray);
    } catch (e, s) {
      Logging.instance.log(
        "Output fetch unsuccessful: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final result = await electrumX.ping();
      return result;
    } catch (_) {
      return false;
    }
  }
}
