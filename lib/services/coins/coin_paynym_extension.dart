import 'dart:convert';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart';
import 'package:bip47/src/util.dart';
import 'package:bitcoindart/bitcoindart.dart' as btc_dart;
import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:isar/isar.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:stackwallet/exceptions/wallet/insufficient_balance_exception.dart';
import 'package:stackwallet/exceptions/wallet/paynym_send_exception.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/bip32_utils.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

const kPaynymDerivePath = "m/47'/0'/0'";

extension PayNym on DogecoinWallet {
  // generate bip32 payment code root
  Future<bip32.BIP32> getRootNode({required List<String> mnemonic}) async {
    final root = await Bip32Utils.getBip32Root(mnemonic.join(" "), network);
    return root;
  }

  /// fetch or generate this wallet's bip47 payment code
  Future<PaymentCode> getPaymentCode() async {
    final address = await db
        .getAddresses(walletId)
        .filter()
        .subTypeEqualTo(AddressSubType.paynymNotification)
        .findFirst();
    PaymentCode paymentCode;
    if (address == null) {
      final root = await getRootNode(mnemonic: await mnemonic);
      final node = root.derivePath(kPaynymDerivePath);
      paymentCode =
          PaymentCode.initFromPubKey(node.publicKey, node.chainCode, network);

      await db.putAddress(
        Address(
          walletId: walletId,
          value: paymentCode.notificationAddress(),
          publicKey: paymentCode.getPubKey(),
          derivationIndex: 0,
          type: AddressType.p2pkh, // todo change this for btc
          subType: AddressSubType.paynymNotification,
          otherData: paymentCode.toString(),
        ),
      );
    } else {
      paymentCode = PaymentCode.fromPaymentCode(address.otherData!, network);
    }
    return paymentCode;
  }

  Future<Uint8List> signWithNotificationKey(Uint8List data) async {
    final root = await getRootNode(mnemonic: await mnemonic);
    final node = root.derivePath(kPaynymDerivePath);
    final pair =
        btc_dart.ECPair.fromPrivateKey(node.privateKey!, network: network);
    final signed = pair.sign(SHA256Digest().process(data));
    return signed;
  }

  Future<String> signStringWithNotificationKey(String data) async {
    final bytes =
        await signWithNotificationKey(Uint8List.fromList(utf8.encode(data)));
    return Format.uint8listToString(bytes);
  }

  void preparePaymentCodeSend(PaymentCode pCode) async {
    if (!(await hasConnected(pCode.notificationAddress()))) {
      throw PaynymSendException("No notification transaction sent to $pCode");
    } else {
      final root = await getRootNode(mnemonic: await mnemonic);
      final node = root.derivePath(kPaynymDerivePath);
      final sendToAddress = await nextUnusedSendAddressFrom(
        pCode: pCode,
        privateKey: node.derive(0).privateKey!,
      );

      // todo: Actual transaction build
    }
  }

  /// get the next unused address to send to given the receiver's payment code
  /// and your own private key
  Future<String> nextUnusedSendAddressFrom({
    required PaymentCode pCode,
    required Uint8List privateKey,
    int startIndex = 0,
  }) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;

    final paymentAddress = PaymentAddress.initWithPrivateKey(
      privateKey,
      pCode,
      startIndex, // initial index to check
    );

    for (; paymentAddress.index <= maxCount; paymentAddress.index++) {
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

  Future<Map<String, dynamic>> prepareNotificationTx({
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
        return prepareNotificationTx(
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

  Future<String> broadcastNotificationTx(
      {required Map<String, dynamic> preparedTx}) async {
    try {
      Logging.instance.log("confirmNotificationTx txData: $preparedTx",
          level: LogLevel.Info);
      final txHash = await electrumXClient.broadcastTransaction(
          rawTx: preparedTx["hex"] as String);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      // TODO: only refresh transaction data
      try {
        await refresh();
      } catch (e) {
        Logging.instance.log(
          "refresh() failed in confirmNotificationTx ($walletName::$walletId): $e",
          level: LogLevel.Error,
        );
      }

      return txHash;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  // TODO optimize
  Future<bool> hasConnected(String paymentCodeString) async {
    final myCode = await getPaymentCode();
    final myNotificationAddress = myCode.notificationAddress();

    final txns = await db
        .getTransactions(walletId)
        .filter()
        .subTypeEqualTo(TransactionSubType.bip47Notification)
        .findAll();

    for (final tx in txns) {
      if (tx.address.value?.value == myNotificationAddress) {
        return true;
      }

      final blindedCode =
          tx.outputs.elementAt(1).scriptPubKeyAsm!.split(" ")[1];

      final designatedInput = tx.inputs.first;

      final txPoint = designatedInput.txid.fromHex.toList();
      final txPointIndex = designatedInput.vout;

      final rev = Uint8List(txPoint.length + 4);
      Util.copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = designatedInput.scriptSigAsm!.split(" ")[1].fromHex;

      final root = await getRootNode(mnemonic: await mnemonic);
      final myPrivateKey =
          root.derivePath(kPaynymDerivePath).derive(0).privateKey!;

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(blindedCode.fromHex, mask);

      final unBlindedPaymentCode =
          PaymentCode.initFromPayload(unBlindedPayload);

      if (paymentCodeString == unBlindedPaymentCode.toString()) {
        return true;
      }
    }

    // otherwise return no
    return false;
  }
}
