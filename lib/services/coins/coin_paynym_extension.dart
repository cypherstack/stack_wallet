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
import 'package:stackwallet/utilities/bip32_utils.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

const kPaynymDerivePath = "m/47'/0'/0'";

extension PayNym on DogecoinWallet {
  // generate bip32 payment code root
  Future<bip32.BIP32> getRootNode({
    required List<String> mnemonic,
  }) async {
    final root = await Bip32Utils.getBip32Root(mnemonic.join(" "), network);
    return root;
  }

  Future<Uint8List> deriveNotificationPrivateKey({
    required List<String> mnemonic,
  }) async {
    final root = await getRootNode(mnemonic: mnemonic);
    final node = root.derivePath(kPaynymDerivePath).derive(0);
    return node.privateKey!;
  }

  /// fetch or generate this wallet's bip47 payment code
  Future<PaymentCode> getPaymentCode() async {
    final address = await db
        .getAddresses(walletId)
        .filter()
        .subTypeEqualTo(AddressSubType.paynymNotification)
        .and()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .findFirst();
    PaymentCode paymentCode;
    if (address == null) {
      final root = await getRootNode(mnemonic: await mnemonic);
      final node = root.derivePath(kPaynymDerivePath);
      paymentCode = PaymentCode.initFromPubKey(
        node.publicKey,
        node.chainCode,
        network,
      );

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
    final privateKey =
        await deriveNotificationPrivateKey(mnemonic: await mnemonic);
    final pair = btc_dart.ECPair.fromPrivateKey(privateKey, network: network);
    final signed = pair.sign(SHA256Digest().process(data));
    return signed;
  }

  Future<String> signStringWithNotificationKey(String data) async {
    final bytes =
        await signWithNotificationKey(Uint8List.fromList(utf8.encode(data)));
    return Format.uint8listToString(bytes);
  }

  Future<Future<Map<String, dynamic>>> preparePaymentCodeSend(
      PaymentCode paymentCode, int satoshiAmount) async {
    if (!(await hasConnected(paymentCode.notificationAddress()))) {
      throw PaynymSendException(
          "No notification transaction sent to $paymentCode");
    } else {
      final myPrivateKey =
          await deriveNotificationPrivateKey(mnemonic: await mnemonic);
      final sendToAddress = await nextUnusedSendAddressFrom(
        pCode: paymentCode,
        privateKey: myPrivateKey,
      );

      return prepareSend(
          address: sendToAddress.value, satoshiAmount: satoshiAmount);
    }
  }

  /// get the next unused address to send to given the receiver's payment code
  /// and your own private key
  Future<Address> nextUnusedSendAddressFrom({
    required PaymentCode pCode,
    required Uint8List privateKey,
    int startIndex = 0,
  }) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;

    for (int i = startIndex; i < maxCount; i++) {
      final address = await db
          .getAddresses(walletId)
          .filter()
          .subTypeEqualTo(AddressSubType.paynymSend)
          .and()
          .otherDataEqualTo(pCode.toString())
          .and()
          .derivationIndexEqualTo(i)
          .findFirst();

      if (address != null) {
        final count = await getTxCount(address: address.value);
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      } else {
        final pair = PaymentAddress.initWithPrivateKey(
          privateKey,
          pCode,
          i, // index to use
        ).getSendAddressKeyPair();

        // add address to local db
        final address = generatePaynymSendAddressFromKeyPair(
          pair: pair,
          derivationIndex: i,
          derivePathType: DerivePathType.bip44,
          toPaymentCode: pCode,
        );
        await db.putAddress(address);

        final count = await getTxCount(address: address.value);
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      }
    }

    throw PaynymSendException("Exhausted unused send addresses!");
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
      // quick check that may cause problems?
      if (tx.address.value?.value == myNotificationAddress) {
        return true;
      }

      final unBlindedPaymentCode = await unBlindedPaymentCodeFromTransaction(
        transaction: tx,
        myCode: myCode,
      );

      if (paymentCodeString == unBlindedPaymentCode.toString()) {
        return true;
      }
    }

    // otherwise return no
    return false;
  }

  Future<PaymentCode?> unBlindedPaymentCodeFromTransaction({
    required Transaction transaction,
    required PaymentCode myCode,
  }) async {
    if (transaction.address.value != null &&
        transaction.address.value!.value != myCode.notificationAddress()) {
      return null;
    }

    try {
      final blindedCode =
          transaction.outputs.elementAt(1).scriptPubKeyAsm!.split(" ")[1];

      final designatedInput = transaction.inputs.first;

      final txPoint = designatedInput.txid.fromHex.toList();
      final txPointIndex = designatedInput.vout;

      final rev = Uint8List(txPoint.length + 4);
      Util.copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = designatedInput.scriptSigAsm!.split(" ")[1].fromHex;

      final myPrivateKey =
          await deriveNotificationPrivateKey(mnemonic: await mnemonic);

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(blindedCode.fromHex, mask);

      final unBlindedPaymentCode =
          PaymentCode.initFromPayload(unBlindedPayload);

      return unBlindedPaymentCode;
    } catch (e) {
      Logging.instance.log(
        "unBlindedPaymentCodeFromTransaction() failed: $e",
        level: LogLevel.Warning,
      );
      return null;
    }
  }

  Future<List<PaymentCode>>
      getAllPaymentCodesFromNotificationTransactions() async {
    final myCode = await getPaymentCode();
    final txns = await db
        .getTransactions(walletId)
        .filter()
        .subTypeEqualTo(TransactionSubType.bip47Notification)
        .findAll();

    List<PaymentCode> unBlindedList = [];

    for (final tx in txns) {
      final unBlinded = await unBlindedPaymentCodeFromTransaction(
        transaction: tx,
        myCode: myCode,
      );
      if (unBlinded != null) {
        unBlindedList.add(unBlinded);
      }
    }

    return unBlindedList;
  }

  Future<void> restoreHistoryWith(
    PaymentCode other,
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;
    assert(maxNumberOfIndexesToCheck < maxCount);

    final myPrivateKey =
        await deriveNotificationPrivateKey(mnemonic: await mnemonic);

    List<Address> addresses = [];
    int receivingGapCounter = 0;
    int outgoingGapCounter = 0;

    for (int i = 0;
        i < maxNumberOfIndexesToCheck &&
            (receivingGapCounter < maxUnusedAddressGap ||
                outgoingGapCounter < maxUnusedAddressGap);
        i++) {
      final paymentAddress = PaymentAddress.initWithPrivateKey(
        myPrivateKey,
        other,
        i, // index to use
      );

      if (receivingGapCounter < maxUnusedAddressGap) {
        final pair = paymentAddress.getSendAddressKeyPair();
        final address = generatePaynymSendAddressFromKeyPair(
          pair: pair,
          derivationIndex: i,
          derivePathType: DerivePathType.bip44,
          toPaymentCode: other,
        );
        addresses.add(address);

        final count = await getTxCount(address: address.value);

        if (count > 0) {
          receivingGapCounter++;
        } else {
          receivingGapCounter = 0;
        }
      }

      if (outgoingGapCounter < maxUnusedAddressGap) {
        final pair = paymentAddress.getReceiveAddressKeyPair();
        final address = generatePaynymReceivingAddressFromKeyPair(
          pair: pair,
          derivationIndex: i,
          derivePathType: DerivePathType.bip44,
          fromPaymentCode: other,
        );
        addresses.add(address);

        final count = await getTxCount(address: address.value);

        if (count > 0) {
          outgoingGapCounter++;
        } else {
          outgoingGapCounter = 0;
        }
      }
    }
    await db.putAddresses(addresses);
  }

  Address generatePaynymSendAddressFromKeyPair({
    required btc_dart.ECPair pair,
    required int derivationIndex,
    required DerivePathType derivePathType,
    required PaymentCode toPaymentCode,
  }) {
    final data = btc_dart.PaymentData(pubkey: pair.publicKey);

    String addressString;
    switch (derivePathType) {
      case DerivePathType.bip44:
        addressString =
            btc_dart.P2PKH(data: data, network: network).data.address!;
        break;

      // The following doesn't apply to doge currently
      //
      // case DerivePathType.bip49:
      //   addressString = btc_dart.P2SH(
      //       data: btc_dart.PaymentData(
      //           redeem: btc_dart.P2WPKH(data: data, network: network).data),
      //       network:  network)
      //       .data
      //       .address!;
      //   addrType = AddressType.p2sh;
      //    break;
      // case DerivePathType.bip84:
      //   addressString = btc_dart.P2WPKH(network: network, data: data).data.address!;
      //   addrType = AddressType.p2wpkh;
      //    break;

    }

    final address = Address(
      walletId: walletId,
      value: addressString,
      publicKey: pair.publicKey,
      derivationIndex: derivationIndex,
      type: AddressType.nonWallet,
      subType: AddressSubType.paynymSend,
      otherData: toPaymentCode.toString(),
    );

    return address;
  }

  Address generatePaynymReceivingAddressFromKeyPair({
    required btc_dart.ECPair pair,
    required int derivationIndex,
    required DerivePathType derivePathType,
    required PaymentCode fromPaymentCode,
  }) {
    final data = btc_dart.PaymentData(pubkey: pair.publicKey);

    String addressString;
    AddressType addrType;
    switch (derivePathType) {
      case DerivePathType.bip44:
        addressString =
            btc_dart.P2PKH(data: data, network: network).data.address!;
        addrType = AddressType.p2pkh;
        break;

      // The following doesn't apply to doge currently
      //
      // case DerivePathType.bip49:
      //   addressString = btc_dart.P2SH(
      //       data: btc_dart.PaymentData(
      //           redeem: btc_dart.P2WPKH(data: data, network: network).data),
      //       network:  network)
      //       .data
      //       .address!;
      //   addrType = AddressType.p2sh;
      //    break;
      // case DerivePathType.bip84:
      //   addressString = btc_dart.P2WPKH(network: network, data: data).data.address!;
      //   addrType = AddressType.p2wpkh;
      //    break;

    }

    final address = Address(
      walletId: walletId,
      value: addressString,
      publicKey: pair.publicKey,
      derivationIndex: derivationIndex,
      type: addrType,
      subType: AddressSubType.paynymReceive,
      otherData: fromPaymentCode.toString(),
    );

    return address;
  }
}
