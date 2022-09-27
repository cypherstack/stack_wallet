import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/models.dart';

import '../services/coins/firo/sample_data/transaction_data_samples.dart';

void main() {
  group("TimeStamp", () {
    test("Timestamp is now", () {
      final date = extractDateFromTimestamp(0);
    });

    test("Timestamp is null", () {
      final date = extractDateFromTimestamp(null);
    });

    test("Timestamp is a random date", () {
      final date = extractDateFromTimestamp(1876352482);
    });
  });
  group("Transaction", () {
    test("Factory transaction", () {
      final tx = Transaction.fromJson({
        "txid": "txid",
        "confirmed_status": true,
        "timestamp": 1876352482,
        "txType": "txType",
        "amount": 10,
        "worthNow": "1",
        "worthAtBlockTimestamp": "1",
        "fees": 1,
        "inputSize": 1,
        "outputSize": 1,
        "inputs": [],
        "outputs": [],
        "address": "address",
        "height": 1,
        "confirmations": 1,
        "aliens": [],
        "subType": "mint",
        "isCancelled": false,
        "slateId": "slateId",
        "otherData": "otherData",
      });
    });

    /// TODO: test TransactionChunk w a transaction in it
    test("TransactionChunk", () {
      final transactionchunk = TransactionChunk.fromJson({
        "timestamp": 45920,
        "transactions": [],
      });
      expect(
          transactionchunk.toString(), "timestamp: 45920 transactions: [\n]");
    });
  });

  group("Input", () {
    test("Input.toString", () {
      final input = Input(
        txid: "txid",
        vout: 1,
        prevout: null,
        scriptsig: "scriptsig",
        scriptsigAsm: "scriptsigAsm",
        witness: [],
        isCoinbase: false,
        sequence: 1,
        innerRedeemscriptAsm: "innerRedeemscriptAsm",
      ); //Input

      expect(input.toString(), "{txid: txid}");
    });

    test("Input.toString", () {
      final input = Input.fromJson({
        "txid": "txid",
        "vout": 1,
        "prevout": null,
        "scriptSig": {"hex": "somehexString", "asm": "someasmthing"},
        "scriptsigAsm": "scriptsigAsm",
        "witness": [],
        "isCoinbase": false,
        "sequence": 1,
        "innerRedeemscriptAsm": "innerRedeemscriptAsm",
      }); //Input

      expect(input.toString(), "{txid: txid}");
    });
  });

  group("Output", () {
    test("Output.toString", () {
      final output = Output.fromJson({
        "scriptPubKey": {
          "hex": "somehexSting",
          "asm": "someasmthing",
          "type": "sometype",
          "addresses": "someaddresses",
        },
        "scriptpubkeyAsm": "scriptpubkeyAsm",
        "scriptpubkeyType": "scriptpubkeyType",
        "scriptpubkeyAddress": "address",
        "value": 2,
      }); //Input

      expect(output.toString(), "Instance of \'Output\'");
    });
  });

  group("Transaction isMinting", () {
    test("Transaction isMinting unconfirmed mint", () {
      final tx = Transaction(
        txid: "txid",
        confirmedStatus: false,
        timestamp: 1,
        subType: "mint",
        txType: "",
        amount: 1,
        worthNow: "1",
        worthAtBlockTimestamp: "1",
        fees: 1,
        inputSize: 1,
        outputSize: 1,
        inputs: [],
        outputs: [],
        address: "address",
        height: 1,
        confirmations: 1,
      );
      expect(tx.isMinting, true);
    });

    test("Transaction isMinting confirmed mint", () {
      final tx = Transaction(
        txid: "txid",
        confirmedStatus: true,
        timestamp: 1,
        subType: "mint",
        txType: "",
        amount: 1,
        worthNow: "1",
        worthAtBlockTimestamp: "1",
        fees: 1,
        inputSize: 1,
        outputSize: 1,
        inputs: [],
        outputs: [],
        address: "address",
        height: 1,
        confirmations: 1,
      );
      expect(tx.isMinting, false);
    });

    test("Transaction isMinting non mint tx", () {
      final tx = Transaction(
        txid: "txid",
        confirmedStatus: false,
        timestamp: 1,
        subType: "",
        txType: "",
        amount: 1,
        worthNow: "1",
        worthAtBlockTimestamp: "1",
        fees: 1,
        inputSize: 1,
        outputSize: 1,
        inputs: [],
        outputs: [],
        address: "address",
        height: 1,
        confirmations: 1,
      );
      expect(tx.isMinting, false);
    });
  });

  test("Transaction.copyWith", () {
    final tx1 = Transaction(
      txid: "txid",
      confirmedStatus: true,
      timestamp: 1,
      subType: "mint",
      txType: "",
      amount: 1,
      worthNow: "1",
      worthAtBlockTimestamp: "1",
      fees: 1,
      inputSize: 1,
      outputSize: 1,
      inputs: [],
      outputs: [],
      address: "address",
      height: 1,
      confirmations: 1,
    );
    final tx2 = tx1.copyWith();

    expect(tx1 == tx2, false);
    expect(tx2.toString(), tx1.toString());
  });
}
