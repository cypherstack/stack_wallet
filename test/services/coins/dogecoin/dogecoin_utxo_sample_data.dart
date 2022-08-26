import 'package:stackwallet/models/paymint/utxo_model.dart';
// import 'package:stackwallet/models/utxo_model.dart';

final Map<String, List<Map<String, dynamic>>> batchGetUTXOResponse0 = {
  "some id 0": [
    {
      "tx_pos": 0,
      "value": 500000000,
      "tx_hash":
          "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b",
      "height": 4286283
    },
    {
      "tx_pos": 0,
      "value": 270000000,
      "tx_hash":
          "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
      "height": 4286295
    },
  ],
  "some id 1": [
    {
      "tx_pos": 1,
      "value": 163000000,
      "tx_hash":
          "351a94874379a5444c8891162472acf66de538a1abc647d4753f3e1eb5ec66f9",
      "height": 4286305
    },
  ],
  "some id 2": [],
  "some id 3": [
    {
      "tx_pos": 0,
      "value": 42800000,
      "tx_hash":
          "7b34e60cc37306f866667deb67b14096f4ea2add941fd6e2238a639000642b82",
      "height": 4286316
    },
  ],
};

final utxoList = [
  UtxoObject(
    txid: "e9673acb3bfa928f92a7d5a545151a672e9613fdf972f3849e16094c1ed28268",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 36900,
      blockHeight: 4286435,
      blockTime: 1656525856,
      blockHash:
          "ae2cfcc41e6a32c9aa0a49ccc6806adaa8e765beab7aed785229513249f7f8f3",
    ),
    value: 79000000,
    fiatWorth: "\$0",
    txName: "DRH56X5vNp7wAD6513kDtnssniVvsGZp3Q",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "fa5bfa4eb581bedb28ca96a65ee77d8e81159914b70d5b7e215994221cc02a63",
    vout: 1,
    status: Status(
      confirmed: true,
      confirmations: 36959,
      blockHeight: 4286437,
      blockTime: 1656525997,
      blockHash:
          "cf30c9a9bd78a5a551e5e767c8b1f743b714e9c4f1479e06391e54de351d7d1c",
    ),
    value: 253000000,
    fiatWorth: "\$0",
    txName: "DFjxQATcVTdN1ZttEdMuiv1ukemR7ypTpy",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "694617f0000499be2f6af5f8d1ddbcf1a70ad4710c0cee6f33a13a64bba454ed",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 36953,
      blockHeight: 4286443,
      blockTime: 1656526175,
      blockHash:
          "b7dd89c7d74e3cbf02538583d2d31c9021b82a4221e31257fec6efdada186d2c",
    ),
    value: 120000000,
    fiatWorth: "\$0",
    txName: "DRH56X5vNp7wAD6513kDtnssniVvsGZp3Q",
    blocked: false,
    isCoinbase: false,
  ),
];
