import 'package:stackwallet/models/paymint/utxo_model.dart';

final Map<String, List<Map<String, dynamic>>> batchGetUTXOResponse0 = {
  "some id 0": [
    {
      "tx_pos": 0,
      "value": 9973187,
      "tx_hash":
          "7b932948c95cf483798011da3fc77b6d53ee26d3d2ba4d90748cd007bdce48e8",
      "height": 1314869
    },
    {
      "tx_pos": 0,
      "value": 50000000,
      "tx_hash":
          "aae9e712e26e5ff77ac2258c47a845ad6e952d580c2ad805e2b5d7667f3d4e42",
      "height": 1297229
    },
  ],
  "some id 1": [],
};

final utxoList = [
  UtxoObject(
    txid: "aab01876c4db40b35ba00bbfb7c58aaec32cad7dc136214b7344a944606cbe73",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 516,
      blockHeight: 1314869,
      blockTime: 1669740688,
      blockHash:
          "6146005e4b21b72d0e2afe5b0cce3abd6e9e9e71c6cf6a1e1150d33e33ba81d4",
    ),
    value: 9973187,
    fiatWorth: "\$0",
    txName: "pw1qj6t0kvsmx8qd95pdh4rwxaz5qp5qtfz0xq2rja",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "909bdf555736c272df0e1df52ca5fcce4f1090b74c0e5d9319bb40e02f4b3add",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 18173,
      blockHeight: 1297229,
      blockTime: 1667469296,
      blockHash:
          "5c5c1a4e2d9cc77a1df4337359f901c92bb4907cff85312599b06141fd1d96d9",
    ),
    value: 50000000,
    fiatWorth: "\$0",
    txName: "PhDSyHLt7ejdPXGve3HFr93pSdFLHUBwdr",
    blocked: false,
    isCoinbase: false,
  ),
];
