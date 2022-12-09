import 'package:flutter_test/flutter_test.dart';
import 'package:epicmobile/models/paymint/utxo_model.dart';

void main() {
  group("Status", () {
    test("Status constructor", () {
      final status = Status(
        confirmed: true,
        blockHash: "some block hash",
        blockHeight: 67254372,
        blockTime: 87263547764,
        confirmations: 1,
      );

      expect(status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764, confirmations: 1}");
    });

    test("Status.fromJson factory", () {
      final status = Status.fromJson({
        "confirmed": true,
        "block_hash": "some block hash",
        "block_height": 67254372,
        "block_time": 87263547764,
      });

      expect(status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764, confirmations: 0}");
    });
  });

  group("UtxoObject", () {
    test("UtxoObject constructor", () {
      final utxoObject = UtxoObject(
        txid: "some txid",
        vout: 1,
        value: 1000,
        fiatWorth: "2",
        status: Status(
          confirmed: true,
          blockHash: "some block hash",
          blockHeight: 67254372,
          blockTime: 87263547764,
          confirmations: 1,
        ),
        txName: '',
        blocked: false,
        isCoinbase: false,
      );

      expect(utxoObject.toString(),
          "{txid: some txid, vout: 1, value: 1000, fiat: 2, blocked: false, status: {confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764, confirmations: 1}, is_coinbase: false}");
      expect(utxoObject.status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764, confirmations: 1}");
    });

    test("UtxoObject.fromJson factory", () {
      final utxoObject = UtxoObject.fromJson({
        "txid": "some txid",
        "vout": 1,
        "value": 1000,
        "fiatWorth": "2",
        "status": {
          "confirmed": true,
          "block_hash": "some block hash",
          "block_height": 67254372,
          "block_time": 87263547764,
        }
      });

      expect(utxoObject.toString(),
          "{txid: some txid, vout: 1, value: 1000, fiat: 2, blocked: false, status: {confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764, confirmations: 0}, is_coinbase: false}");
      expect(utxoObject.status.toString(),
          "{confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764, confirmations: 0}");
    });
  });

  group("UtxoData", () {
    test("UtxoData constructor", () {
      final utxoData = UtxoData(
        totalUserCurrency: "100.0",
        satoshiBalance: 100000000,
        bitcoinBalance: "2",
        unspentOutputArray: [],
        satoshiBalanceUnconfirmed: 0,
      );

      expect(utxoData.toString(),
          "{totalUserCurrency: 100.0, satoshiBalance: 100000000, bitcoinBalance: 2, unspentOutputArray: []}");
    });

    test("UtxoData.fromJson factory", () {
      final utxoData = UtxoData.fromJson({
        "total_user_currency": "100.0",
        "total_sats": 100000000,
        "total_btc": "1",
        "outputArray": [
          {
            "txid": "some txid",
            "vout": 1,
            "value": 1000,
            "fiatWorth": "2",
            "status": {
              "confirmed": true,
              "block_hash": "some block hash",
              "block_height": 67254372,
              "block_time": 87263547764,
            }
          },
          {
            "txid": "some txid2",
            "vout": 0,
            "value": 100,
            "fiatWorth": "1",
            "status": {
              "confirmed": false,
              "block_hash": "some block hash",
              "block_height": 2836375,
              "block_time": 5634236123,
            }
          }
        ],
      });

      expect(utxoData.toString(),
          "{totalUserCurrency: 100.0, satoshiBalance: 100000000, bitcoinBalance: 1, unspentOutputArray: [{txid: some txid, vout: 1, value: 1000, fiat: 2, blocked: false, status: {confirmed: true, blockHash: some block hash, blockHeight: 67254372, blockTime: 87263547764, confirmations: 0}, is_coinbase: false}, {txid: some txid2, vout: 0, value: 100, fiat: 1, blocked: false, status: {confirmed: false, blockHash: some block hash, blockHeight: 2836375, blockTime: 5634236123, confirmations: 0}, is_coinbase: false}]}");
    });
  });
}
