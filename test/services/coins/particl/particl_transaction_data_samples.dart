// TODO these test vectors are valid for Namecoin: update for Particl

import 'package:stackwallet/models/paymint/transactions_model.dart';

final transactionData = TransactionData.fromMap({
  "3ef543d0887c3e9f9924f1b2d3b21410d0238937364663ed3414a2c2ddf4ccc6": tx1,
  "dffa9543852197f9fb90f8adafaab8a0b9b4925e9ada8c6bdcaf00bf2e9f60d7": tx2,
  "71b56532e9e7321bd8c30d0f8b14530743049d2f3edd5623065c46eee1dda04d": tx3,
  "c7e700f7e23a85bbdd9de86d502322a933607ee7ea7e16adaf02e477cdd849b9": tx4,
});

final tx1 = Transaction(
  txid: "3ef543d0887c3e9f9924f1b2d3b21410d0238937364663ed3414a2c2ddf4ccc6",
  confirmedStatus: true,
  confirmations: 212,
  txType: "Received",
  amount: 1000000,
  fees: 23896,
  height: 629633,
  address: "nc1qwfda4s9qmdqpnykgpjf85n09ath983srtuxcqx",
  timestamp: 1663093275,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 2,
  outputSize: 2,
  inputs: [
    Input(
      txid: "290904699ccbebd0921c4acc4f7a10f41141ee6a07bc64ebca5674c1e5ee8dfa",
      vout: 1,
    ),
    Input(
      txid: "bd84ae7e09414b0ccf5dcbf70a1f89f2fd42119a98af35dd4ecc80210fed0487",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "nc1qwfda4s9qmdqpnykgpjf85n09ath983srtuxcqx",
      value: 1000000,
    ),
    Output(
      scriptpubkeyAddress: "nc1qp7h7fxcnkqcpul202z6nh8yjy8jpt39jcpeapj",
      value: 29853562,
    )
  ],
);

final tx2 = Transaction(
  txid: "dffa9543852197f9fb90f8adafaab8a0b9b4925e9ada8c6bdcaf00bf2e9f60d7",
  confirmedStatus: true,
  confirmations: 150,
  txType: "Sent",
  amount: 988567,
  fees: 11433,
  height: 629695,
  address: "nc1qraffwaq3cxngwp609e03ynwsx8ykgjnjve9f3y",
  timestamp: 1663142110,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 1,
  outputSize: 1,
  inputs: [
    Input(
      txid: "3ef543d0887c3e9f9924f1b2d3b21410d0238937364663ed3414a2c2ddf4ccc6",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "nc1qraffwaq3cxngwp609e03ynwsx8ykgjnjve9f3y",
      value: 988567,
    ),
  ],
);

final tx3 = Transaction(
  txid: "71b56532e9e7321bd8c30d0f8b14530743049d2f3edd5623065c46eee1dda04d",
  confirmedStatus: true,
  confirmations: 147,
  txType: "Received",
  amount: 988567,
  fees: 11433,
  height: 629699,
  address: "nc1qw4srwqq2semrxje4x6zcrg53g07q0pr3yqv5kr",
  timestamp: 1663145287,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 2,
  outputSize: 1,
  inputs: [
    Input(
      txid: "dffa9543852197f9fb90f8adafaab8a0b9b4925e9ada8c6bdcaf00bf2e9f60d7",
      vout: 0,
    ),
    Input(
      txid: "80f8c6de5be2243013348219bbb7043a6d8d00ddc716baf6a69eab517f9a6fc1",
      vout: 1,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "nc1qw4srwqq2semrxje4x6zcrg53g07q0pr3yqv5kr",
      value: 1000000,
    ),
    Output(
      scriptpubkeyAddress: "nc1qsgr7u4hd22rc64r9vlef69en9wzlvmjt8dzyrm",
      value: 28805770,
    ),
  ],
);

final tx4 = Transaction(
  txid: "c7e700f7e23a85bbdd9de86d502322a933607ee7ea7e16adaf02e477cdd849b9",
  confirmedStatus: true,
  confirmations: 130,
  txType: "Sent",
  amount: 988567,
  fees: 11433,
  height: 629717,
  address: "nc1qmdt0fxhpwx7x5ymmm9gvh229adu0kmtukfcsjk",
  timestamp: 1663155739,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 1,
  outputSize: 1,
  inputs: [
    Input(
      txid: "71b56532e9e7321bd8c30d0f8b14530743049d2f3edd5623065c46eee1dda04d",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "nc1qmdt0fxhpwx7x5ymmm9gvh229adu0kmtukfcsjk",
      value: 988567,
    ),
  ],
);

final tx1Raw = {
  "txid": "3ef543d0887c3e9f9924f1b2d3b21410d0238937364663ed3414a2c2ddf4ccc6",
  "hash": "40c8dd876cf111dc00d3aa2fedc93a77c18b391931939d4f99a760226cbff675",
  "version": 2,
  "size": 394,
  "vsize": 232,
  "weight": 925,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "290904699ccbebd0921c4acc4f7a10f41141ee6a07bc64ebca5674c1e5ee8dfa",
      "vout": 1,
      "scriptSig": {
        "asm": "001466d2173325f3d379c6beb0a4949e937308edb152",
        "hex": "16001466d2173325f3d379c6beb0a4949e937308edb152"
      },
      "txinwitness": [
        "3044022062d0f32dc051ed1e91889a96070121c77d895f69d2ed5a307d8b320e0352186702206a0c2613e708e5ef8a935aba61b8fa14ddd6ca4e9a80a8b4ded126a879217dd101",
        "0303cd92ed121ef22398826af055f3006769210e019f8fb43bd2f5556282d84997"
      ],
      "sequence": 4294967295
    },
    {
      "txid":
          "bd84ae7e09414b0ccf5dcbf70a1f89f2fd42119a98af35dd4ecc80210fed0487",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3045022100e8814706766a2d7588908c51209c3b7095241bbc681febdd6b317b7e9b6ea97502205c33c63e4d8a675c19122bfe0057afce2159e6bd86f2c9aced214de77099dc8b01",
        "03c35212e3a4c0734735eccae9219987dc78d9cf6245ab247942d430d0a01d61be"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.01,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 725bdac0a0db401992c80c927a4de5eaee53c603",
        "hex": "0014725bdac0a0db401992c80c927a4de5eaee53c603",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": ["nc1qwfda4s9qmdqpnykgpjf85n09ath983srtuxcqx"]
      }
    },
    {
      "value": 0.29853562,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 0fafe49b13b0301e7d4f50b53b9c9221e415c4b2",
        "hex": "00140fafe49b13b0301e7d4f50b53b9c9221e415c4b2",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": ["nc1qp7h7fxcnkqcpul202z6nh8yjy8jpt39jcpeapj"]
      }
    }
  ],
  "hex":
      "02000000000102fa8deee5c17456caeb64bc076aee4111f4107a4fcc4a1c92d0ebcb9c69040929010000001716001466d2173325f3d379c6beb0a4949e937308edb152ffffffff8704ed0f2180cc4edd35af989a1142fdf2891f0af7cb5dcf0c4b41097eae84bd0000000000ffffffff0240420f0000000000160014725bdac0a0db401992c80c927a4de5eaee53c6037a87c701000000001600140fafe49b13b0301e7d4f50b53b9c9221e415c4b202473044022062d0f32dc051ed1e91889a96070121c77d895f69d2ed5a307d8b320e0352186702206a0c2613e708e5ef8a935aba61b8fa14ddd6ca4e9a80a8b4ded126a879217dd101210303cd92ed121ef22398826af055f3006769210e019f8fb43bd2f5556282d8499702483045022100e8814706766a2d7588908c51209c3b7095241bbc681febdd6b317b7e9b6ea97502205c33c63e4d8a675c19122bfe0057afce2159e6bd86f2c9aced214de77099dc8b012103c35212e3a4c0734735eccae9219987dc78d9cf6245ab247942d430d0a01d61be00000000",
  "blockhash":
      "c9f53cc7cbf654cbcc400e17b33e03a32706d6e6647ad7085c688540f980a378",
  "confirmations": 212,
  "time": 1663093275,
  "blocktime": 1663093275
};

final tx2Raw = {
  "txid": "dffa9543852197f9fb90f8adafaab8a0b9b4925e9ada8c6bdcaf00bf2e9f60d7",
  "hash": "32dbc0d21327e0cb94ec6069a8d235affd99689ffc5f68959bfb720bafc04bcf",
  "version": 2,
  "size": 192,
  "vsize": 110,
  "weight": 438,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "3ef543d0887c3e9f9924f1b2d3b21410d0238937364663ed3414a2c2ddf4ccc6",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "30450221009d58ebfaab8eae297910bca93a7fd48f94ce52a1731cf27fb4c043368fa10e8d02207e88f5d868113d9567999793be0a5b752ad704d04224046839763cefe46463a501",
        "02f6ca5274b59dfb014f6a0d690671964290dac7f97fe825f723204e6cb8daf086"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.00988567,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 1f52977411c1a687074f2e5f124dd031c9644a72",
        "hex": "00141f52977411c1a687074f2e5f124dd031c9644a72",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": ["nc1qraffwaq3cxngwp609e03ynwsx8ykgjnjve9f3y"]
      }
    }
  ],
  "hex":
      "02000000000101c6ccf4ddc2a21434ed634636378923d01014b2d3b2f124999f3e7c88d043f53e0000000000ffffffff0197150f00000000001600141f52977411c1a687074f2e5f124dd031c9644a72024830450221009d58ebfaab8eae297910bca93a7fd48f94ce52a1731cf27fb4c043368fa10e8d02207e88f5d868113d9567999793be0a5b752ad704d04224046839763cefe46463a5012102f6ca5274b59dfb014f6a0d690671964290dac7f97fe825f723204e6cb8daf08600000000",
  "blockhash":
      "ae1129ee834853c45b9edbb7228497c7fa423d7d1bdec8fd155f9e3c429c84d3",
  "confirmations": 150,
  "time": 1663142110,
  "blocktime": 1663142110
};

final tx3Raw = {
  "txid": "71b56532e9e7321bd8c30d0f8b14530743049d2f3edd5623065c46eee1dda04d",
  "hash": "bb25567e1ffb2fd6ec9aa3925a7a8dd3055a29521f7811b2b2bc01ce7d8a216e",
  "version": 2,
  "size": 370,
  "vsize": 208,
  "weight": 832,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "dffa9543852197f9fb90f8adafaab8a0b9b4925e9ada8c6bdcaf00bf2e9f60d7",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "304402203535cf570aca7c1acfa6e8d2f43e0b188b76d0b7a75ffca448e6af953ffe8b6302202ea52b312aaaf6d615d722bd92535d1e8b25fa9584a8dbe34dfa1ea9c18105ca01",
        "038b68078a95f73f8710e8464dec52c61f9e21675ddf69d4f61b93cc417cf73d74"
      ],
      "sequence": 4294967295
    },
    {
      "txid":
          "80f8c6de5be2243013348219bbb7043a6d8d00ddc716baf6a69eab517f9a6fc1",
      "vout": 1,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3044022045268613674326251c46caeaf435081ca753e4ee2018d79480c4930ad7d5e19f022050090a9add82e7272b8206b9d369675e7e9a5f1396fc93490143f0053666102901",
        "028e2ede901e69887cb80603c8e207839f61a477d59beff17705162a2045dd974e"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.01,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 756037000a8676334b35368581a29143fc078471",
        "hex": "0014756037000a8676334b35368581a29143fc078471",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": ["nc1qw4srwqq2semrxje4x6zcrg53g07q0pr3yqv5kr"]
      }
    },
    {
      "value": 0.2880577,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 8207ee56ed52878d546567f29d17332b85f66e4b",
        "hex": "00148207ee56ed52878d546567f29d17332b85f66e4b",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": ["nc1qsgr7u4hd22rc64r9vlef69en9wzlvmjt8dzyrm"]
      }
    }
  ],
  "hex":
      "02000000000102d7609f2ebf00afdc6b8cda9a5e92b4b9a0b8aaafadf890fbf99721854395fadf0000000000ffffffffc16f9a7f51ab9ea6f6ba16c7dd008d6d3a04b7bb198234133024e25bdec6f8800100000000ffffffff0240420f0000000000160014756037000a8676334b35368581a29143fc0784718a8ab701000000001600148207ee56ed52878d546567f29d17332b85f66e4b0247304402203535cf570aca7c1acfa6e8d2f43e0b188b76d0b7a75ffca448e6af953ffe8b6302202ea52b312aaaf6d615d722bd92535d1e8b25fa9584a8dbe34dfa1ea9c18105ca0121038b68078a95f73f8710e8464dec52c61f9e21675ddf69d4f61b93cc417cf73d7402473044022045268613674326251c46caeaf435081ca753e4ee2018d79480c4930ad7d5e19f022050090a9add82e7272b8206b9d369675e7e9a5f1396fc93490143f005366610290121028e2ede901e69887cb80603c8e207839f61a477d59beff17705162a2045dd974e00000000",
  "blockhash":
      "98f388ba99e3b6fc421c23edf3c699ada082b01e5a5d130af7550b7fa6184f2f",
  "confirmations": 147,
  "time": 1663145287,
  "blocktime": 1663145287
};

final tx4Raw = {
  "txid": "c7e700f7e23a85bbdd9de86d502322a933607ee7ea7e16adaf02e477cdd849b9",
  "hash": "c6b544ddd7d901fcc7218208a6cfc8e1819c403a22cc8a1f1a7029aafa427925",
  "version": 2,
  "size": 192,
  "vsize": 110,
  "weight": 438,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "71b56532e9e7321bd8c30d0f8b14530743049d2f3edd5623065c46eee1dda04d",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3045022100c664c6ad206999e019954c5206a26c2eca1ae2572288c0f78074c279a4a210ce022017456fdf85f744d694fa2e4638acee782d809268ea4808c04d91da3ac4fe7fd401",
        "035456b63e86c0a6235cb3debfb9654966a4c2362ec678ae3b9beec53d31a25eba"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.00988567,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 db56f49ae171bc6a137bd950cba945eb78fb6d7c",
        "hex": "0014db56f49ae171bc6a137bd950cba945eb78fb6d7c",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": ["nc1qmdt0fxhpwx7x5ymmm9gvh229adu0kmtukfcsjk"]
      }
    }
  ],
  "hex":
      "020000000001014da0dde1ee465c062356dd3e2f9d04430753148b0f0dc3d81b32e7e93265b5710000000000ffffffff0197150f0000000000160014db56f49ae171bc6a137bd950cba945eb78fb6d7c02483045022100c664c6ad206999e019954c5206a26c2eca1ae2572288c0f78074c279a4a210ce022017456fdf85f744d694fa2e4638acee782d809268ea4808c04d91da3ac4fe7fd40121035456b63e86c0a6235cb3debfb9654966a4c2362ec678ae3b9beec53d31a25eba00000000",
  "blockhash":
      "6f60029ff3a32ca2d7e7e23c02b9cb35f61e7f9481992f9c3ded2c60c7b1de9b",
  "confirmations": 130,
  "time": 1663155739,
  "blocktime": 1663155739
};
