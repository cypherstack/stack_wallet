import 'dart:convert';
import 'dart:typed_data';

import 'package:bip47/bip47.dart';
import 'package:bip47/src/util.dart';
import 'package:bitcoindart/bitcoindart.dart';
import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:decimal/decimal.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';

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
    final pair = ECPair.fromPrivateKey(node.privateKey!, network: network);
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

  // Future<Map<String, dynamic>> prepareNotificationTransaction(
  //     String targetPaymentCode) async {}

  Future<String> createNotificationTx(
    String targetPaymentCodeString,
    List<UtxoObject> utxosToUse,
    int dustLimit,
  ) async {
    final utxoSigningData = await fetchBuildTxData(utxosToUse);
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

    final myKeyPair = utxoSigningData[utxo.txid]["keyPair"] as ECPair;

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

    final bobP2PKH = P2PKH(
      data: PaymentData(
        pubkey: targetPaymentCode.notificationPublicKey(),
      ),
    ).data;
    final notificationScript = bscript.compile([bobP2PKH.output]);

    // build a notification tx
    final txb = TransactionBuilder();
    txb.setVersion(1);

    txb.addInput(
      utxo.txid,
      txPointIndex,
    );

    txb.addOutput(targetPaymentCode.notificationAddress(), dustLimit);
    txb.addOutput(opReturnScript, 0);

    // TODO: add possible change output and mark output as dangerous

    txb.sign(
      vin: 0,
      keyPair: myKeyPair,
    );

    final builtTx = txb.build();

    return builtTx.toHex();
  }
}

Future<Map<String, dynamic>> parseTransaction(
  Map<String, dynamic> txData,
  dynamic electrumxClient,
  Set<String> myAddresses,
  Set<String> myChangeAddresses,
  Coin coin,
  int minConfirms,
  Decimal currentPrice,
) async {
  Set<String> inputAddresses = {};
  Set<String> outputAddresses = {};

  int totalInputValue = 0;
  int totalOutputValue = 0;

  int amountSentFromWallet = 0;
  int amountReceivedInWallet = 0;

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
          if (myAddresses.contains(address)) {
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
    final address = output["scriptPubKey"]["addresses"][0] as String? ??
        output["scriptPubKey"]["address"] as String?;
    if (address != null) {
      outputAddresses.add(address);

      // if output was from my wallet, add value to amount received
      if (myAddresses.contains(address)) {
        amountReceivedInWallet += value;
      }
    }
  }

  final mySentFromAddresses = myAddresses.intersection(inputAddresses);
  final myReceivedOnAddresses = myAddresses.intersection(outputAddresses);

  final fee = totalInputValue - totalOutputValue;

  // create normalized tx data map
  Map<String, dynamic> normalizedTx = {};

  final int confirms = txData["confirmations"] as int? ?? 0;

  normalizedTx["txid"] = txData["txid"] as String;
  normalizedTx["confirmed_status"] = confirms >= minConfirms;
  normalizedTx["confirmations"] = confirms;
  normalizedTx["timestamp"] = txData["blocktime"] as int? ??
      (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  normalizedTx["aliens"] = <dynamic>[];
  normalizedTx["fees"] = fee;
  normalizedTx["address"] = txData["address"] as String;
  normalizedTx["inputSize"] = txData["vin"].length;
  normalizedTx["outputSize"] = txData["vout"].length;
  normalizedTx["inputs"] = txData["vin"];
  normalizedTx["outputs"] = txData["vout"];
  normalizedTx["height"] = txData["height"] as int;

  int amount;
  String type;
  if (mySentFromAddresses.isNotEmpty && myReceivedOnAddresses.isNotEmpty) {
    // tx is sent to self
    type = "Sent to self";
    amount = amountSentFromWallet - amountReceivedInWallet - fee;
  } else if (mySentFromAddresses.isNotEmpty) {
    // outgoing tx
    type = "Sent";
    amount = amountSentFromWallet;
  } else {
    // incoming tx
    type = "Received";
    amount = amountReceivedInWallet;
  }

  normalizedTx["txType"] = type;
  normalizedTx["amount"] = amount;
  normalizedTx["worthNow"] = (Format.satoshisToAmount(
            amount,
            coin: coin,
          ) *
          currentPrice)
      .toStringAsFixed(2);

  return normalizedTx;
}
