import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:bip47/bip47.dart';
import 'package:bip47/src/util.dart';
import 'package:bitcoindart/bitcoindart.dart' as btc_dart;
import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

class SWException with Exception {
  SWException(this.message);

  final String message;

  @override
  toString() => message;
}

class InsufficientBalanceException extends SWException {
  InsufficientBalanceException(super.message);
}

class PaynymSendException extends SWException {
  PaynymSendException(super.message);
}

extension PayNym on DogecoinWallet {
  // fetch or generate this wallet's bip47 payment code
  Future<PaymentCode> getPaymentCode() async {
    final paymentCodeString = DB.instance
        .get<dynamic>(boxName: walletId, key: "paymentCodeString") as String?;
    PaymentCode paymentCode;
    if (paymentCodeString == null) {
      final node = getBip32Root((await mnemonic).join(" "), network)
          .derivePath("m/47'/0'/0'");
      paymentCode =
          PaymentCode.initFromPubKey(node.publicKey, node.chainCode, network);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: "paymentCodeString",
          value: paymentCode.toString());
    } else {
      paymentCode = PaymentCode.fromPaymentCode(paymentCodeString, network);
    }
    return paymentCode;
  }

  Future<Uint8List> signWithNotificationKey(Uint8List data) async {
    final node = getBip32Root((await mnemonic).join(" "), network)
        .derivePath("m/47'/0'/0'");
    final pair =
        btc_dart.ECPair.fromPrivateKey(node.privateKey!, network: network);
    final signed = pair.sign(SHA256Digest().process(data));
    return signed;
  }

  Future<String> signStringWithNotificationKey(String data) async {
    final bytes =
        await signWithNotificationKey(Uint8List.fromList(utf8.encode(data)));
    return Format.uint8listToString(bytes);
    // final bytes =
    //     await signWithNotificationKey(Uint8List.fromList(utf8.encode(data)));
    // return Format.uint8listToString(bytes);
  }

  /// Update cached lists of notification transaction IDs.
  /// Returns true if there are new notification transactions found since last
  /// checked.
  Future<bool> checkForNotificationTransactions() async {
    final myPCode = await getPaymentCode();

    final transactionIds = await electrumXClient.getHistory(
      scripthash: AddressUtils.convertToScriptHash(
        myPCode.notificationAddress(),
        network,
      ),
    );

    final confirmedNotificationTransactionIds = DB.instance.get<dynamic>(
          boxName: walletId,
          key: "confirmedNotificationTransactionIds",
        ) as Set? ??
        {};

    final unconfirmedNotificationTransactionIds = DB.instance.get<dynamic>(
          boxName: walletId,
          key: "unconfirmedNotificationTransactionIds",
        ) as Set? ??
        {};

    // since we are only checking for newly found transactions here we can use the sum
    final totalCount = confirmedNotificationTransactionIds.length +
        unconfirmedNotificationTransactionIds.length;

    for (final entry in transactionIds) {
      final txid = entry["tx_hash"] as String;

      final tx = await cachedElectrumXClient.getTransaction(
        txHash: txid,
        coin: coin,
      );

      // check if tx is confirmed
      if ((tx["confirmations"] as int? ?? 0) > MINIMUM_CONFIRMATIONS) {
        // remove it from unconfirmed set
        unconfirmedNotificationTransactionIds.remove(txid);

        // add it to confirmed set
        confirmedNotificationTransactionIds.add(txid);
      } else {
        // otherwise add it to the unconfirmed set
        unconfirmedNotificationTransactionIds.add(txid);
      }
    }

    final newTotalCount = confirmedNotificationTransactionIds.length +
        unconfirmedNotificationTransactionIds.length;

    return newTotalCount > totalCount;
  }

  /// return the notification tx sent from my wallet if it exists
  Future<Transaction?> hasSentNotificationTx(PaymentCode pCode) async {
    final tx = await isar.transactions
        .filter()
        .addressEqualTo(pCode.notificationAddress())
        .findFirst();
    return tx;
  }

  void preparePaymentCodeSend(PaymentCode pCode) async {
    final notifTx = await hasSentNotificationTx(pCode);
    final currentHeight = await chainHeight;

    if (notifTx == null) {
      throw PaynymSendException("No notification transaction sent to $pCode");
    } else if (!notifTx.isConfirmed(currentHeight, MINIMUM_CONFIRMATIONS)) {
      throw PaynymSendException(
          "Notification transaction sent to $pCode has not confirmed yet");
    } else {
      final node = getBip32Root((await mnemonic).join(" "), network)
          .derivePath("m/47'/0'/0'");
      final sendToAddress = await nextUnusedSendAddressFrom(
        pCode,
        node.derive(0).privateKey!,
      );

      // todo: Actual transaction build
    }
  }

  /// get the next unused address to send to given the receiver's payment code
  /// and your own private key
  Future<String> nextUnusedSendAddressFrom(
    PaymentCode pCode,
    Uint8List privateKey,
  ) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;

    final paymentAddress = PaymentAddress.initWithPrivateKey(
      privateKey,
      pCode,
      0, // initial index to check
    );

    for (paymentAddress.index = 0;
        paymentAddress.index <= maxCount;
        paymentAddress.index++) {
      final address = paymentAddress.getSendAddress();

      final transactionIds = await electrumXClient.getHistory(
        scripthash: AddressUtils.convertToScriptHash(
          address,
          network,
        ),
      );

      if (transactionIds.isEmpty) {
        return address;
      }
    }

    throw PaynymSendException("Exhausted unused send addresses!");
  }

  /// get your receiving addresses given the sender's payment code and your own
  /// private key
  List<String> deriveReceivingAddressesFor(
    PaymentCode pCode,
    Uint8List privateKey,
    int count,
  ) {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;
    assert(count <= maxCount);

    final paymentAddress = PaymentAddress.initWithPrivateKey(
      privateKey,
      pCode,
      0, // initial index
    );

    final List<String> result = [];
    for (paymentAddress.index = 0;
        paymentAddress.index < count;
        paymentAddress.index++) {
      final address = paymentAddress.getReceiveAddress();

      result.add(address);
    }

    return result;
  }

  Future<Map<String, dynamic>> buildNotificationTx({
    required int selectedTxFeeRate,
    required String targetPaymentCodeString,
    int additionalOutputs = 0,
    List<UTXO>? utxos,
  }) async {
    const amountToSend = DUST_LIMIT;
    final List<UTXO> availableOutputs = utxos ?? await this.utxos;
    final List<UTXO> spendableOutputs = [];
    int spendableSatoshiValue = 0;

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].isBlocked == false &&
          availableOutputs[i]
                  .isConfirmed(await chainHeight, MINIMUM_CONFIRMATIONS) ==
              true) {
        spendableOutputs.add(availableOutputs[i]);
        spendableSatoshiValue += availableOutputs[i].value;
      }
    }

    if (spendableSatoshiValue < amountToSend) {
      // insufficient balance
      throw InsufficientBalanceException(
          "Spendable balance is less than the minimum required for a notification transaction.");
    } else if (spendableSatoshiValue == amountToSend) {
      // insufficient balance due to missing amount to cover fee
      throw InsufficientBalanceException(
          "Remaining balance does not cover the network fee.");
    }

    // sort spendable by age (oldest first)
    spendableOutputs.sort((a, b) => b.blockTime!.compareTo(a.blockTime!));

    int satoshisBeingUsed = 0;
    int outputsBeingUsed = 0;
    List<UTXO> utxoObjectsToUse = [];

    for (int i = 0;
        satoshisBeingUsed < amountToSend && i < spendableOutputs.length;
        i++) {
      utxoObjectsToUse.add(spendableOutputs[i]);
      satoshisBeingUsed += spendableOutputs[i].value;
      outputsBeingUsed += 1;
    }

    // add additional outputs if required
    for (int i = 0;
        i < additionalOutputs && outputsBeingUsed < spendableOutputs.length;
        i++) {
      utxoObjectsToUse.add(spendableOutputs[outputsBeingUsed]);
      satoshisBeingUsed += spendableOutputs[outputsBeingUsed].value;
      outputsBeingUsed += 1;
    }

    // gather required signing data
    final utxoSigningData = await fetchBuildTxData(utxoObjectsToUse);

    final int vSizeForNoChange = (await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            utxosToUse: utxoObjectsToUse,
            utxoSigningData: utxoSigningData,
            change: 0))
        .item2;

    final int vSizeForWithChange = (await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            utxosToUse: utxoObjectsToUse,
            utxoSigningData: utxoSigningData,
            change: satoshisBeingUsed - amountToSend))
        .item2;

    // Assume 2 outputs, for recipient and payment code script
    int feeForNoChange = estimateTxFee(
      vSize: vSizeForNoChange,
      feeRatePerKB: selectedTxFeeRate,
    );

    // Assume 3 outputs, for recipient, payment code script, and change
    int feeForWithChange = estimateTxFee(
      vSize: vSizeForWithChange,
      feeRatePerKB: selectedTxFeeRate,
    );

    if (feeForNoChange < vSizeForNoChange * 1000) {
      feeForNoChange = vSizeForNoChange * 1000;
    }
    if (feeForWithChange < vSizeForWithChange * 1000) {
      feeForWithChange = vSizeForWithChange * 1000;
    }

    if (satoshisBeingUsed - amountToSend > feeForNoChange + DUST_LIMIT) {
      // try to add change output due to "left over" amount being greater than
      // the estimated fee + the dust limit
      int changeAmount = satoshisBeingUsed - amountToSend - feeForWithChange;

      // check estimates are correct and build notification tx
      if (changeAmount >= DUST_LIMIT &&
          satoshisBeingUsed - amountToSend - changeAmount == feeForWithChange) {
        final txn = await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          utxosToUse: utxoObjectsToUse,
          utxoSigningData: utxoSigningData,
          change: changeAmount,
        );

        int feeBeingPaid = satoshisBeingUsed - amountToSend - changeAmount;

        Map<String, dynamic> transactionObject = {
          "hex": txn.item1,
          "recipientPaynym": targetPaymentCodeString,
          "amount": amountToSend,
          "fee": feeBeingPaid,
          "vSize": txn.item2,
        };
        return transactionObject;
      } else {
        // something broke during fee estimation or the change amount is smaller
        // than the dust limit. Try without change
        final txn = await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          utxosToUse: utxoObjectsToUse,
          utxoSigningData: utxoSigningData,
          change: 0,
        );

        int feeBeingPaid = satoshisBeingUsed - amountToSend;

        Map<String, dynamic> transactionObject = {
          "hex": txn.item1,
          "recipientPaynym": targetPaymentCodeString,
          "amount": amountToSend,
          "fee": feeBeingPaid,
          "vSize": txn.item2,
        };
        return transactionObject;
      }
    } else if (satoshisBeingUsed - amountToSend >= feeForNoChange) {
      // since we already checked if we need to add a change output we can just
      // build without change here
      final txn = await _createNotificationTx(
        targetPaymentCodeString: targetPaymentCodeString,
        utxosToUse: utxoObjectsToUse,
        utxoSigningData: utxoSigningData,
        change: 0,
      );

      int feeBeingPaid = satoshisBeingUsed - amountToSend;

      Map<String, dynamic> transactionObject = {
        "hex": txn.item1,
        "recipientPaynym": targetPaymentCodeString,
        "amount": amountToSend,
        "fee": feeBeingPaid,
        "vSize": txn.item2,
      };
      return transactionObject;
    } else {
      // if we get here we do not have enough funds to cover the tx total so we
      // check if we have any more available outputs and try again
      if (spendableOutputs.length > outputsBeingUsed) {
        return buildNotificationTx(
          selectedTxFeeRate: selectedTxFeeRate,
          targetPaymentCodeString: targetPaymentCodeString,
          additionalOutputs: additionalOutputs + 1,
        );
      } else {
        throw InsufficientBalanceException(
            "Remaining balance does not cover the network fee.");
      }
    }
  }

  // return tuple with string value equal to the raw tx hex and the int value
  // equal to its vSize
  Future<Tuple2<String, int>> _createNotificationTx({
    required String targetPaymentCodeString,
    required List<UTXO> utxosToUse,
    required Map<String, dynamic> utxoSigningData,
    required int change,
  }) async {
    final targetPaymentCode =
        PaymentCode.fromPaymentCode(targetPaymentCodeString, network);
    final myCode = await getPaymentCode();

    final utxo = utxosToUse.first;
    final txPoint = utxo.txid.fromHex.toList();
    final txPointIndex = utxo.vout;

    final rev = Uint8List(txPoint.length + 4);
    Util.copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
    final buffer = rev.buffer.asByteData();
    buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

    final myKeyPair = utxoSigningData[utxo.txid]["keyPair"] as btc_dart.ECPair;

    final S = SecretPoint(
      myKeyPair.privateKey!,
      targetPaymentCode.notificationPublicKey(),
    );

    final blindingMask = PaymentCode.getMask(S.ecdhSecret(), rev);

    final blindedPaymentCode = PaymentCode.blind(
      myCode.getPayload(),
      blindingMask,
    );

    final opReturnScript = bscript.compile([
      (op.OPS["OP_RETURN"] as int),
      blindedPaymentCode,
    ]);

    // build a notification tx
    final txb = btc_dart.TransactionBuilder(network: network);
    txb.setVersion(1);

    txb.addInput(
      utxo.txid,
      txPointIndex,
    );

    txb.addOutput(targetPaymentCode.notificationAddress(), DUST_LIMIT);
    txb.addOutput(opReturnScript, 0);

    // TODO: add possible change output and mark output as dangerous
    if (change > 0) {
      // generate new change address if current change address has been used
      await checkChangeAddressForTransactions();
      final String changeAddress = await currentChangeAddress;
      txb.addOutput(changeAddress, change);
    }

    txb.sign(
      vin: 0,
      keyPair: myKeyPair,
    );

    // sign rest of possible inputs
    for (var i = 1; i < utxosToUse.length - 1; i++) {
      final txid = utxosToUse[i].txid;
      txb.sign(
        vin: i,
        keyPair: utxoSigningData[txid]["keyPair"] as btc_dart.ECPair,
        // witnessValue: utxosToUse[i].value,
      );
    }

    final builtTx = txb.build();

    return Tuple2(builtTx.toHex(), builtTx.virtualSize());
  }

  Future<String> confirmNotificationTx(
      {required Map<String, dynamic> preparedTx}) async {
    try {
      Logging.instance.log("confirmNotificationTx txData: $preparedTx",
          level: LogLevel.Info);
      final txHash = await electrumXClient.broadcastTransaction(
          rawTx: preparedTx["hex"] as String);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      await updatePaynymNotificationInfo(
        txid: txHash,
        confirmed: false,
        paymentCodeString: preparedTx["address"] as String,
      );
      return txHash;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  // Future<bool> hasConfirmedNotificationTxSentTo(
  //     String paymentCodeString) async {
  //   final targetPaymentCode =
  //       PaymentCode.fromPaymentCode(paymentCodeString, network);
  //   final targetNotificationAddress = targetPaymentCode.notificationAddress();
  //
  //   final myTxHistory = (await transactionData)
  //       .getAllTransactions()
  //       .entries
  //       .map((e) => e.value)
  //       .where((e) =>
  //           e.txType == "Sent" && e.address == targetNotificationAddress);
  //
  //   return myTxHistory.isNotEmpty;
  // }

  bool hasConnected(String paymentCodeString) {
    return getPaynymNotificationTxInfo()
        .values
        .where((e) => e["paymentCodeString"] == paymentCodeString)
        .isNotEmpty;
  }

  bool hasConnectedConfirmed(String paymentCodeString) {
    return getPaynymNotificationTxInfo()
        .values
        .where((e) =>
            e["paymentCodeString"] == paymentCodeString &&
            e["confirmed"] == true)
        .isNotEmpty;
  }

  // fetch paynym notification tx meta data
  Map<String, dynamic> getPaynymNotificationTxInfo() {
    final map = DB.instance.get<dynamic>(
            boxName: walletId, key: "paynymNotificationTxInfo") as Map? ??
        {};

    return Map<String, dynamic>.from(map);
  }

  // add/update paynym notification tx meta data entry
  Future<void> updatePaynymNotificationInfo({
    required String txid,
    required bool confirmed,
    required String paymentCodeString,
  }) async {
    final data = getPaynymNotificationTxInfo();
    data[txid] = {
      "txid": txid,
      "confirmed": confirmed,
      "paymentCodeString": paymentCodeString,
    };
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: "paynymNotificationTxInfo",
      value: data,
    );
  }
}

Future<Transaction> parseTransaction(
  Map<String, dynamic> txData,
  dynamic electrumxClient,
  List<Address> myAddresses,
  Coin coin,
  int minConfirms,
) async {
  Set<String> receivingAddresses = myAddresses
      .where((e) => e.subType == AddressSubType.receiving)
      .map((e) => e.value)
      .toSet();
  Set<String> changeAddresses = myAddresses
      .where((e) => e.subType == AddressSubType.change)
      .map((e) => e.value)
      .toSet();

  Set<String> inputAddresses = {};
  Set<String> outputAddresses = {};

  int totalInputValue = 0;
  int totalOutputValue = 0;

  int amountSentFromWallet = 0;
  int amountReceivedInWallet = 0;
  int changeAmount = 0;

  // parse inputs
  for (final input in txData["vin"] as List) {
    final prevTxid = input["txid"] as String;
    final prevOut = input["vout"] as int;

    // fetch input tx to get address
    final inputTx = await electrumxClient.getTransaction(
      txHash: prevTxid,
      coin: coin,
    );

    for (final output in inputTx["vout"] as List) {
      // check matching output
      if (prevOut == output["n"]) {
        // get value
        final value = Format.decimalAmountToSatoshis(
          Decimal.parse(output["value"].toString()),
          coin,
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
    final value = Format.decimalAmountToSatoshis(
      Decimal.parse(output["value"].toString()),
      coin,
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

  final tx = Transaction();
  tx.txid = txData["txid"] as String;
  tx.timestamp = txData["blocktime"] as int? ??
      (DateTime.now().millisecondsSinceEpoch ~/ 1000);

  // this should be the address we used to originally fetch the tx so we should
  // be able to easily figure out if the tx is a send or receive
  tx.address.value = txData["address"] as Address;

  if (mySentFromAddresses.isNotEmpty && myReceivedOnAddresses.isNotEmpty) {
    // tx is sent to self
    tx.type = TransactionType.sentToSelf;
    tx.amount =
        amountSentFromWallet - amountReceivedInWallet - fee - changeAmount;
  } else if (mySentFromAddresses.isNotEmpty) {
    // outgoing tx
    tx.type = TransactionType.outgoing;
    tx.amount = amountSentFromWallet - changeAmount - fee;
  } else {
    // incoming tx
    tx.type = TransactionType.incoming;
    tx.amount = amountReceivedInWallet;
  }

  // TODO: other subtypes
  tx.subType = TransactionSubType.none;

  tx.fee = fee;

  log("tx.address: ${tx.address}");
  log("mySentFromAddresses: $mySentFromAddresses");
  log("myReceivedOnAddresses: $myReceivedOnAddresses");
  log("myChangeReceivedOnAddresses: $myChangeReceivedOnAddresses");

  for (final json in txData["vin"] as List) {
    bool isCoinBase = json['coinbase'] != null;
    final input = Input();
    input.txid = json['txid'] as String;
    input.vout = json['vout'] as int? ?? -1;
    input.scriptSig = json['scriptSig']?['hex'] as String?;
    input.scriptSigAsm = json['scriptSig']?['asm'] as String?;
    input.isCoinbase = isCoinBase ? isCoinBase : json['is_coinbase'] as bool?;
    input.sequence = json['sequence'] as int?;
    input.innerRedeemScriptAsm = json['innerRedeemscriptAsm'] as String?;
    tx.inputs.add(input);
  }

  for (final json in txData["vout"] as List) {
    final output = Output();
    output.scriptPubKey = json['scriptPubKey']?['hex'] as String?;
    output.scriptPubKeyAsm = json['scriptPubKey']?['asm'] as String?;
    output.scriptPubKeyType = json['scriptPubKey']?['type'] as String?;
    output.scriptPubKeyAddress =
        json["scriptPubKey"]?["addresses"]?[0] as String? ??
            json['scriptPubKey']['type'] as String;
    output.value = Format.decimalAmountToSatoshis(
      Decimal.parse(json["value"].toString()),
      coin,
    );
    tx.outputs.add(output);
  }

  tx.height = txData["height"] as int?;

  //TODO: change these for epic (or other coins that need it)
  tx.isCancelled = false;
  tx.slateId = null;
  tx.otherData = null;
  tx.isLelantus = null;

  return tx;
}
