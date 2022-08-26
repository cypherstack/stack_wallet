import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/models.dart';

void main() {
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
