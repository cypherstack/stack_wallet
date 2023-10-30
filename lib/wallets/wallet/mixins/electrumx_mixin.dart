import 'dart:convert';

import 'package:bip47/src/util.dart';
import 'package:decimal/decimal.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/mixins/paynym_wallet_interface.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/wallet/bip39_hd_wallet.dart';
import 'package:uuid/uuid.dart';

mixin ElectrumXMixin on Bip39HDWallet {
  late ElectrumX electrumX;
  late CachedElectrumX electrumXCached;
  late NodeService nodeService;

  Future<int> fetchChainHeight() async {
    try {
      final result = await electrumX.getBlockHeadTip();
      return result["height"] as int;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<({Transaction transaction, Address address})>>
      fetchTransactionsV1({
    required List<Address> addresses,
    required int currentChainHeight,
  }) async {
    final List<({String txHash, int height, String address})> allTxHashes =
        (await fetchHistory(addresses.map((e) => e.value).toList()))
            .map(
              (e) => (
                txHash: e["tx_hash"] as String,
                height: e["height"] as int,
                address: e["address"] as String,
              ),
            )
            .toList();

    List<Map<String, dynamic>> allTransactions = [];

    for (final data in allTxHashes) {
      final tx = await electrumXCached.getTransaction(
        txHash: data.txHash,
        verbose: true,
        coin: cryptoCurrency.coin,
      );

      // check for duplicates before adding to list
      if (allTransactions
              .indexWhere((e) => e["txid"] == tx["txid"] as String) ==
          -1) {
        tx["address"] = addresses.firstWhere((e) => e.value == data.address);
        tx["height"] = data.height;
        allTransactions.add(tx);
      }
    }

    final List<({Transaction transaction, Address address})> txnsData = [];

    for (final txObject in allTransactions) {
      final data = await _parseTransactionV1(
        txObject,
        addresses,
      );

      txnsData.add(data);
    }

    return txnsData;
  }

  Future<ElectrumXNode> getCurrentNode() async {
    final node = nodeService.getPrimaryNodeFor(coin: cryptoCurrency.coin) ??
        DefaultNodes.getNodeFor(cryptoCurrency.coin);

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  Future<void> updateElectrumX({required ElectrumXNode newNode}) async {
    final failovers = nodeService
        .failoverNodesFor(coin: cryptoCurrency.coin)
        .map((e) => ElectrumXNode(
              address: e.host,
              port: e.port,
              name: e.name,
              id: e.id,
              useSSL: e.useSSL,
            ))
        .toList();

    final newNode = await getCurrentNode();
    electrumX = ElectrumX.from(
      node: newNode,
      prefs: prefs,
      failovers: failovers,
    );
    electrumXCached = CachedElectrumX.from(
      electrumXClient: electrumX,
    );
  }

  //============================================================================

  Future<List<Map<String, dynamic>>> fetchHistory(
    Iterable<String> allAddresses,
  ) async {
    try {
      List<Map<String, dynamic>> allTxHashes = [];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      final Map<String, String> requestIdToAddressMap = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scriptHash = cryptoCurrency.addressToScriptHash(
          address: allAddresses.elementAt(i),
        );
        final id = Logger.isTestEnv ? "$i" : const Uuid().v1();
        requestIdToAddressMap[id] = allAddresses.elementAt(i);
        batches[batchNumber]!.addAll({
          id: [scriptHash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response = await electrumX.getBatchHistory(args: batches[i]!);
        for (final entry in response.entries) {
          for (int j = 0; j < entry.value.length; j++) {
            entry.value[j]["address"] = requestIdToAddressMap[entry.key];
            if (!allTxHashes.contains(entry.value[j])) {
              allTxHashes.add(entry.value[j]);
            }
          }
        }
      }

      return allTxHashes;
    } catch (e, s) {
      Logging.instance.log("_fetchHistory: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<UTXO> parseUTXO({
    required Map<String, dynamic> jsonUTXO,
    ({
      String? blockedReason,
      bool blocked,
    })
        Function(
      Map<String, dynamic>,
      String? scriptPubKeyHex,
    )? checkBlock,
  }) async {
    final txn = await electrumXCached.getTransaction(
      txHash: jsonUTXO["tx_hash"] as String,
      verbose: true,
      coin: cryptoCurrency.coin,
    );

    final vout = jsonUTXO["tx_pos"] as int;

    final outputs = txn["vout"] as List;

    String? scriptPubKey;
    String? utxoOwnerAddress;
    // get UTXO owner address
    for (final output in outputs) {
      if (output["n"] == vout) {
        scriptPubKey = output["scriptPubKey"]?["hex"] as String?;
        utxoOwnerAddress =
            output["scriptPubKey"]?["addresses"]?[0] as String? ??
                output["scriptPubKey"]?["address"] as String?;
      }
    }

    final checkBlockResult = checkBlock?.call(jsonUTXO, scriptPubKey);

    final utxo = UTXO(
      walletId: walletId,
      txid: txn["txid"] as String,
      vout: vout,
      value: jsonUTXO["value"] as int,
      name: "",
      isBlocked: checkBlockResult?.blocked ?? false,
      blockedReason: checkBlockResult?.blockedReason,
      isCoinbase: txn["is_coinbase"] as bool? ?? false,
      blockHash: txn["blockhash"] as String?,
      blockHeight: jsonUTXO["height"] as int?,
      blockTime: txn["blocktime"] as int?,
      address: utxoOwnerAddress,
    );

    return utxo;
  }

  Future<({Transaction transaction, Address address})> _parseTransactionV1(
    Map<String, dynamic> txData,
    List<Address> myAddresses,
  ) async {
    Set<String> receivingAddresses = myAddresses
        .where((e) =>
            e.subType == AddressSubType.receiving ||
            e.subType == AddressSubType.paynymReceive ||
            e.subType == AddressSubType.paynymNotification)
        .map((e) => e.value)
        .toSet();
    Set<String> changeAddresses = myAddresses
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => e.value)
        .toSet();

    Set<String> inputAddresses = {};
    Set<String> outputAddresses = {};

    Amount totalInputValue = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.coin.decimals,
    );
    Amount totalOutputValue = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.coin.decimals,
    );

    Amount amountSentFromWallet = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.coin.decimals,
    );
    Amount amountReceivedInWallet = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.coin.decimals,
    );
    Amount changeAmount = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.coin.decimals,
    );

    // parse inputs
    for (final input in txData["vin"] as List) {
      final prevTxid = input["txid"] as String;
      final prevOut = input["vout"] as int;

      // fetch input tx to get address
      final inputTx = await electrumXCached.getTransaction(
        txHash: prevTxid,
        coin: cryptoCurrency.coin,
      );

      for (final output in inputTx["vout"] as List) {
        // check matching output
        if (prevOut == output["n"]) {
          // get value
          final value = Amount.fromDecimal(
            Decimal.parse(output["value"].toString()),
            fractionDigits: cryptoCurrency.coin.decimals,
          );

          // add value to total
          totalInputValue += value;

          // get input(prevOut) address
          final address = output["scriptPubKey"]?["addresses"]?[0] as String? ??
              output["scriptPubKey"]?["address"] as String?;

          if (address != null) {
            inputAddresses.add(address);

            // if input was from my wallet, add value to amount sent
            if (receivingAddresses.contains(address) ||
                changeAddresses.contains(address)) {
              amountSentFromWallet += value;
            }
          }
        }
      }
    }

    // parse outputs
    for (final output in txData["vout"] as List) {
      // get value
      final value = Amount.fromDecimal(
        Decimal.parse(output["value"].toString()),
        fractionDigits: cryptoCurrency.coin.decimals,
      );

      // add value to total
      totalOutputValue += value;

      // get output address
      final address = output["scriptPubKey"]?["addresses"]?[0] as String? ??
          output["scriptPubKey"]?["address"] as String?;
      if (address != null) {
        outputAddresses.add(address);

        // if output was to my wallet, add value to amount received
        if (receivingAddresses.contains(address)) {
          amountReceivedInWallet += value;
        } else if (changeAddresses.contains(address)) {
          changeAmount += value;
        }
      }
    }

    final mySentFromAddresses = [
      ...receivingAddresses.intersection(inputAddresses),
      ...changeAddresses.intersection(inputAddresses)
    ];
    final myReceivedOnAddresses =
        receivingAddresses.intersection(outputAddresses);
    final myChangeReceivedOnAddresses =
        changeAddresses.intersection(outputAddresses);

    final fee = totalInputValue - totalOutputValue;

    // this is the address initially used to fetch the txid
    Address transactionAddress = txData["address"] as Address;

    TransactionType type;
    Amount amount;
    if (mySentFromAddresses.isNotEmpty && myReceivedOnAddresses.isNotEmpty) {
      // tx is sent to self
      type = TransactionType.sentToSelf;

      // should be 0
      amount =
          amountSentFromWallet - amountReceivedInWallet - fee - changeAmount;
    } else if (mySentFromAddresses.isNotEmpty) {
      // outgoing tx
      type = TransactionType.outgoing;
      amount = amountSentFromWallet - changeAmount - fee;

      // non wallet addresses found in tx outputs
      final nonWalletOutAddresses = outputAddresses.difference(
        myChangeReceivedOnAddresses,
      );

      if (nonWalletOutAddresses.isNotEmpty) {
        final possible = nonWalletOutAddresses.first;

        if (transactionAddress.value != possible) {
          transactionAddress = Address(
            walletId: myAddresses.first.walletId,
            value: possible,
            derivationIndex: -1,
            derivationPath: null,
            subType: AddressSubType.nonWallet,
            type: AddressType.nonWallet,
            publicKey: [],
          );
        }
      } else {
        // some other type of tx where the receiving address is
        // one of my change addresses

        type = TransactionType.sentToSelf;
        amount = changeAmount;
      }
    } else {
      // incoming tx
      type = TransactionType.incoming;
      amount = amountReceivedInWallet;
    }

    List<Output> outs = [];
    List<Input> ins = [];

    for (final json in txData["vin"] as List) {
      bool isCoinBase = json['coinbase'] != null;
      String? witness;
      if (json['witness'] != null && json['witness'] is String) {
        witness = json['witness'] as String;
      } else if (json['txinwitness'] != null) {
        if (json['txinwitness'] is List) {
          witness = jsonEncode(json['txinwitness']);
        }
      }
      final input = Input(
        txid: json['txid'] as String,
        vout: json['vout'] as int? ?? -1,
        scriptSig: json['scriptSig']?['hex'] as String?,
        scriptSigAsm: json['scriptSig']?['asm'] as String?,
        isCoinbase: isCoinBase ? isCoinBase : json['is_coinbase'] as bool?,
        sequence: json['sequence'] as int?,
        innerRedeemScriptAsm: json['innerRedeemscriptAsm'] as String?,
        witness: witness,
      );
      ins.add(input);
    }

    for (final json in txData["vout"] as List) {
      final output = Output(
        scriptPubKey: json['scriptPubKey']?['hex'] as String?,
        scriptPubKeyAsm: json['scriptPubKey']?['asm'] as String?,
        scriptPubKeyType: json['scriptPubKey']?['type'] as String?,
        scriptPubKeyAddress:
            json["scriptPubKey"]?["addresses"]?[0] as String? ??
                json['scriptPubKey']?['type'] as String? ??
                "",
        value: Amount.fromDecimal(
          Decimal.parse(json["value"].toString()),
          fractionDigits: cryptoCurrency.coin.decimals,
        ).raw.toInt(),
      );
      outs.add(output);
    }

    TransactionSubType txSubType = TransactionSubType.none;
    if (this is PaynymWalletInterface && outs.length > 1 && ins.isNotEmpty) {
      for (int i = 0; i < outs.length; i++) {
        List<String>? scriptChunks = outs[i].scriptPubKeyAsm?.split(" ");
        if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
          final blindedPaymentCode = scriptChunks![1];
          final bytes = blindedPaymentCode.fromHex;

          // https://en.bitcoin.it/wiki/BIP_0047#Sending
          if (bytes.length == 80 && bytes.first == 1) {
            txSubType = TransactionSubType.bip47Notification;
          }
        }
      }
    }

    final tx = Transaction(
      walletId: myAddresses.first.walletId,
      txid: txData["txid"] as String,
      timestamp: txData["blocktime"] as int? ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      type: type,
      subType: txSubType,
      // amount may overflow. Deprecated. Use amountString
      amount: amount.raw.toInt(),
      amountString: amount.toJsonString(),
      fee: fee.raw.toInt(),
      height: txData["height"] as int?,
      isCancelled: false,
      isLelantus: false,
      slateId: null,
      otherData: null,
      nonce: null,
      inputs: ins,
      outputs: outs,
      numberOfMessages: null,
    );

    return (transaction: tx, address: transactionAddress);
  }

  //============================================================================

  @override
  Future<void> updateNode() async {
    final node = await getCurrentNode();
    await updateElectrumX(newNode: node);
  }
}
