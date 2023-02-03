import 'package:bip47/src/util.dart';
import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/mixins/paynym_wallet_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:tuple/tuple.dart';

mixin ElectrumXParsing {
  Future<Tuple2<Transaction, Address>> parseTransaction(
    Map<String, dynamic> txData,
    dynamic electrumxClient,
    List<Address> myAddresses,
    Coin coin,
    int minConfirms,
    String walletId,
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

    // this is the address initially used to fetch the txid
    Address transactionAddress = txData["address"] as Address;

    TransactionType type;
    int amount;
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

      final possible =
          outputAddresses.difference(myChangeReceivedOnAddresses).first;

      if (transactionAddress.value != possible) {
        transactionAddress = Address(
          walletId: walletId,
          value: possible,
          derivationIndex: -1,
          subType: AddressSubType.nonWallet,
          type: AddressType.nonWallet,
          publicKey: [],
        );
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
      final input = Input(
        txid: json['txid'] as String,
        vout: json['vout'] as int? ?? -1,
        scriptSig: json['scriptSig']?['hex'] as String?,
        scriptSigAsm: json['scriptSig']?['asm'] as String?,
        isCoinbase: isCoinBase ? isCoinBase : json['is_coinbase'] as bool?,
        sequence: json['sequence'] as int?,
        innerRedeemScriptAsm: json['innerRedeemscriptAsm'] as String?,
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
        value: Format.decimalAmountToSatoshis(
          Decimal.parse(json["value"].toString()),
          coin,
        ),
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
      walletId: walletId,
      txid: txData["txid"] as String,
      timestamp: txData["blocktime"] as int? ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      type: type,
      subType: txSubType,
      amount: amount,
      fee: fee,
      height: txData["height"] as int?,
      isCancelled: false,
      isLelantus: false,
      slateId: null,
      otherData: null,
      inputs: ins,
      outputs: outs,
    );

    return Tuple2(tx, transactionAddress);
  }
}
