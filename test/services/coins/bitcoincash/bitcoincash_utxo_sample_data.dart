import 'package:stackwallet/models/paymint/utxo_model.dart';

final Map<String, List<Map<String, dynamic>>> batchGetUTXOResponse0 = {
  "some id 0": [
    {
      "tx_pos": 0,
      "value": 7000000,
      "tx_hash":
          "61fedb3cb994917d2852191785ab59cb0d177d55d860bf10fd671f6a0a83247c",
      "height": 756720
    },
    {
      "tx_pos": 0,
      "value": 3000000,
      "tx_hash":
          "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
      "height": 756732
    },
  ],
  "some id 1": [
    {
      "tx_pos": 1,
      "value": 2000000,
      "tx_hash":
          "070b45d901243b5856a0cccce8c5f5f548c19aaa00cb0059b37a6a9a3632288a",
      "height": 756738
    },
  ],
  "some id 2": [],
};

final utxoList = [
  UtxoObject(
    txid: "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 175,
      blockHeight: 756732,
      blockTime: 1662553616,
      blockHash:
          "000000000000000005d25c8d3722e4486c486bbf864f9261631993afab557832",
    ),
    value: 3000000,
    fiatWorth: "\$0",
    txName: "1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "f716d010786225004b41e35dd5eebfb11a4e5ea116e1a48235e5d3a591650732",
    vout: 1,
    status: Status(
      confirmed: true,
      confirmations: 11867,
      blockHeight: 745443,
      blockTime: 1655792385,
      blockHash:
          "000000000000000000065c982f4d86a402e7182d0c6a49fa6cfbdaf67a57f566",
    ),
    value: 78446451,
    fiatWorth: "\$0",
    txName: "3E1n17NnhVmWTGNbvH6ffKVNFjYT4Jke7G",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "070b45d901243b5856a0cccce8c5f5f548c19aaa00cb0059b37a6a9a3632288a",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 572,
      blockHeight: 756738,
      blockTime: 1662555788,
      blockHash:
          "00000000000000000227adf51d47ac640c7353e873a398901ecf9becbf5988d7",
    ),
    value: 2000000,
    fiatWorth: "\$0",
    txName: "1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM",
    blocked: false,
    isCoinbase: false,
  ),
];
