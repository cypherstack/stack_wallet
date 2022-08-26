import 'package:stackwallet/models/paymint/utxo_model.dart';

final Map<String, List<Map<String, dynamic>>> batchGetUTXOResponse0 = {
  "some id 0": [
    {
      "tx_pos": 0,
      "value": 17000,
      "tx_hash":
          "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
      "height": 437146
    },
    {
      "tx_pos": 0,
      "value": 36037,
      "tx_hash":
          "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
      "height": 441696
    },
  ],
  "some id 1": [
    {
      "tx_pos": 1,
      "value": 14714,
      "tx_hash":
          "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
      "height": 437146
    },
  ],
  "some id 2": [],
  "some id 3": [
    {
      "tx_pos": 0,
      "value": 8746,
      "tx_hash":
          "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
      "height": 441696
    },
  ],
};

final utxoList = [
  UtxoObject(
    txid: "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    vout: 1,
    status: Status(
      confirmed: true,
      confirmations: 1000,
      blockHeight: 2253622,
      blockTime: 1654182725,
      blockHash:
          "00000000000000914aebb1f2dbc85e5a119437dae67d0df121ccf33243d405af",
    ),
    value: 5500,
    fiatWorth: "\$0",
    txName: "mpMk94ETazqonHutyC1v6ajshgtP8oiFKU",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    vout: 1,
    status: Status(
      confirmed: true,
      confirmations: 1000,
      blockHeight: 2253623,
      blockTime: 1654183929,
      blockHash:
          "0000000000048280441cb896acf650e565917190157cf0f348b0adfdef4e2505",
    ),
    value: 6500,
    fiatWorth: "\$0",
    txName: "2N3GrCAFdpgJ4pJLepapKqiSmNwDYLkrU8W",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    vout: 1,
    status: Status(
      confirmed: true,
      confirmations: 1000,
      blockHeight: 2253623,
      blockTime: 1654183929,
      blockHash:
          "0000000000048280441cb896acf650e565917190157cf0f348b0adfdef4e2505",
    ),
    value: 7000,
    fiatWorth: "\$0",
    txName: "tb1qnf2qmetsr53tezq8qwspzdjnxplmjny4n5pxz3",
    blocked: false,
    isCoinbase: false,
  ),
];
