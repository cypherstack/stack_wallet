import 'package:stackwallet/models/paymint/utxo_model.dart';

final Map<String, List<Map<String, dynamic>>> batchGetUTXOResponse0 = {
  "some id 0": [
    {
      "tx_pos": 0,
      "value": 988567,
      "tx_hash":
          "32dbc0d21327e0cb94ec6069a8d235affd99689ffc5f68959bfb720bafc04bcf",
      "height": 629695
    },
    {
      "tx_pos": 0,
      "value": 1000000,
      "tx_hash":
          "40c8dd876cf111dc00d3aa2fedc93a77c18b391931939d4f99a760226cbff675",
      "height": 629633
    },
  ],
  "some id 1": [],
};

final utxoList = [
  UtxoObject(
    txid: "dffa9543852197f9fb90f8adafaab8a0b9b4925e9ada8c6bdcaf00bf2e9f60d7",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 150,
      blockHeight: 629695,
      blockTime: 1663142110,
      blockHash:
          "32dbc0d21327e0cb94ec6069a8d235affd99689ffc5f68959bfb720bafc04bcf",
    ),
    value: 988567,
    fiatWorth: "\$0",
    txName: "nc1qraffwaq3cxngwp609e03ynwsx8ykgjnjve9f3y",
    blocked: false,
    isCoinbase: false,
  ),
  UtxoObject(
    txid: "3ef543d0887c3e9f9924f1b2d3b21410d0238937364663ed3414a2c2ddf4ccc6",
    vout: 0,
    status: Status(
      confirmed: true,
      confirmations: 212,
      blockHeight: 629633,
      blockTime: 1663093275,
      blockHash:
          "40c8dd876cf111dc00d3aa2fedc93a77c18b391931939d4f99a760226cbff675",
    ),
    value: 1000000,
    fiatWorth: "\$0",
    txName: "nc1qwfda4s9qmdqpnykgpjf85n09ath983srtuxcqx",
    blocked: false,
    isCoinbase: false,
  ),
];
