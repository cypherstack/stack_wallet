import 'package:stackwallet/models/paymint/transactions_model.dart';

final transactionData = TransactionData.fromMap({
  "61fedb3cb994917d2852191785ab59cb0d177d55d860bf10fd671f6a0a83247c": tx1,
  "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba": tx2,
  "070b45d901243b5856a0cccce8c5f5f548c19aaa00cb0059b37a6a9a3632288a": tx3,
  "84aecde036ebe013aa3bd2fcb4741db504c7c040d34f7c33732c967646991855": tx4,
});

final tx1 = Transaction(
  txid: "61fedb3cb994917d2852191785ab59cb0d177d55d860bf10fd671f6a0a83247c",
  confirmedStatus: true,
  confirmations: 187,
  txType: "Received",
  amount: 7000000,
  fees: 742,
  height: 756720,
  address: "12QZH44735UHWAXFgb4hfdq756GjzXtZG7",
  timestamp: 1662544771,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 1,
  outputSize: 2,
  inputs: [
    Input(
      txid: "f716d010786225004b41e35dd5eebfb11a4e5ea116e1a48235e5d3a591650732",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "12QZH44735UHWAXFgb4hfdq756GjzXtZG7",
      value: 7000000,
    ),
    Output(
      scriptpubkeyAddress: "3E1n17NnhVmWTGNbvH6ffKVNFjYT4Jke7G",
      value: 71445709,
    )
  ],
);

final tx2 = Transaction(
  txid: "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
  confirmedStatus: true,
  confirmations: 175,
  txType: "Sent",
  amount: 3000000,
  fees: 227000,
  height: 756732,
  address: "1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM",
  timestamp: 1662553616,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.0",
  inputSize: 1,
  outputSize: 2,
  inputs: [
    Input(
      txid: "61fedb3cb994917d2852191785ab59cb0d177d55d860bf10fd671f6a0a83247c",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM",
      value: 3000000,
    ),
    Output(
      scriptpubkeyAddress: "16GbR1Xau2hKFTr1STgB39NbP8CEkGZjYG",
      value: 3773000,
    ),
  ],
);

final tx3 = Transaction(
  txid: "070b45d901243b5856a0cccce8c5f5f548c19aaa00cb0059b37a6a9a3632288a",
  confirmedStatus: true,
  confirmations: 177,
  txType: "Received",
  amount: 2000000,
  fees: 227,
  height: 756738,
  address: "1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM",
  timestamp: 1662555788,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.0",
  inputSize: 1,
  outputSize: 2,
  inputs: [
    Input(
      txid: "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM",
      value: 2000000,
    ),
    Output(
      scriptpubkeyAddress: "16GbR1Xau2hKFTr1STgB39NbP8CEkGZjYG",
      value: 1772773,
    ),
  ],
);

final tx4 = Transaction(
  txid: "84aecde036ebe013aa3bd2fcb4741db504c7c040d34f7c33732c967646991855",
  confirmedStatus: false,
  confirmations: 0,
  txType: "Received",
  amount: 4000000,
  fees: 400,
  height: 757303,
  address: "1PQaBto5KmiW3R2YeexYYoDWksMpEvhYZE",
  timestamp: 1662893734,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 1,
  outputSize: 2,
  inputs: [
    Input(
      txid: "070b45d901243b5856a0cccce8c5f5f548c19aaa00cb0059b37a6a9a3632288a",
      vout: 0,
    ),
    Input(
      txid: "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "1JHcZyhgctuDCznjkxR51pQzKEJUujuc2j",
      value: 999600,
    ),
    Output(
      scriptpubkeyAddress: "1PQaBto5KmiW3R2YeexYYoDWksMpEvhYZE",
      value: 4000000,
    )
  ],
);

final tx1Raw = {
  "in_mempool": false,
  "in_orphanpool": false,
  "txid": "61fedb3cb994917d2852191785ab59cb0d177d55d860bf10fd671f6a0a83247c",
  "size": 372,
  "version": 1,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "f716d010786225004b41e35dd5eebfb11a4e5ea116e1a48235e5d3a591650732",
      "vout": 1,
      "scriptSig": {
        "asm":
            "0 3045022100d80e1d056e8787d7fac8e59ce14d56a2dbb2aceb43da1fee47e687e318049abd02204bb06be6e8af85250b93e0f5377da535557176557563a4d0121b607ffbf3e7c1[ALL|FORKID] 304402200c528edd5f1c0aa169178f5a4c1ec5044559326f1608db6987398bdc0761aaae02205a94bb7f8dac69400823a0093e0303eaa2905b9fadbb8bbb111c3fef0a452ef0[ALL|FORKID] 522103ff1450283f08568acdb4d5f569f32e4cd4d8c1960ea049a205436f69f9916df8210230ee6aec65bc0db7e9cf507b33067f681047e180e91906e1fde1bb549f233b24210366058482ecccb47075be9d1d3edb46df331c04fa5126cd6fd9dc6cee071237b453ae",
        "hex":
            "00483045022100d80e1d056e8787d7fac8e59ce14d56a2dbb2aceb43da1fee47e687e318049abd02204bb06be6e8af85250b93e0f5377da535557176557563a4d0121b607ffbf3e7c14147304402200c528edd5f1c0aa169178f5a4c1ec5044559326f1608db6987398bdc0761aaae02205a94bb7f8dac69400823a0093e0303eaa2905b9fadbb8bbb111c3fef0a452ef0414c69522103ff1450283f08568acdb4d5f569f32e4cd4d8c1960ea049a205436f69f9916df8210230ee6aec65bc0db7e9cf507b33067f681047e180e91906e1fde1bb549f233b24210366058482ecccb47075be9d1d3edb46df331c04fa5126cd6fd9dc6cee071237b453ae"
      },
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.07,
      "n": 0,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 0f6ca2ddb50a473f809440f77d3d931335ac2940 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a9140f6ca2ddb50a473f809440f77d3d931335ac294088ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": ["12QZH44735UHWAXFgb4hfdq756GjzXtZG7"]
      }
    },
    {
      "value": 0.71445709,
      "n": 1,
      "scriptPubKey": {
        "asm": "OP_HASH160 872dcab340b7a8500b2585781e51e9217f11dced OP_EQUAL",
        "hex": "a914872dcab340b7a8500b2585781e51e9217f11dced87",
        "reqSigs": 1,
        "type": "scripthash",
        "addresses": ["3E1n17NnhVmWTGNbvH6ffKVNFjYT4Jke7G"]
      }
    }
  ],
  "blockhash":
      "00000000000000000529d5816d2f9c97cfbe8c06bb87e9a15d9e778281ff9225",
  "confirmations": 187,
  "time": 1662544771,
  "blocktime": 1662544771,
  "hex":
      "010000000132076591a5d3e53582a4e116a15e4e1ab1bfeed55de3414b0025627810d016f701000000fdfd0000483045022100d80e1d056e8787d7fac8e59ce14d56a2dbb2aceb43da1fee47e687e318049abd02204bb06be6e8af85250b93e0f5377da535557176557563a4d0121b607ffbf3e7c14147304402200c528edd5f1c0aa169178f5a4c1ec5044559326f1608db6987398bdc0761aaae02205a94bb7f8dac69400823a0093e0303eaa2905b9fadbb8bbb111c3fef0a452ef0414c69522103ff1450283f08568acdb4d5f569f32e4cd4d8c1960ea049a205436f69f9916df8210230ee6aec65bc0db7e9cf507b33067f681047e180e91906e1fde1bb549f233b24210366058482ecccb47075be9d1d3edb46df331c04fa5126cd6fd9dc6cee071237b453aeffffffff02c0cf6a00000000001976a9140f6ca2ddb50a473f809440f77d3d931335ac294088accd2c42040000000017a914872dcab340b7a8500b2585781e51e9217f11dced8700000000"
};

final tx2Raw = {
  "in_mempool": false,
  "in_orphanpool": false,
  "txid": "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
  "size": 225,
  "version": 2,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "61fedb3cb994917d2852191785ab59cb0d177d55d860bf10fd671f6a0a83247c",
      "vout": 0,
      "scriptSig": {
        "asm":
            "304402207b3301ec0ab0c7dbba32690b71e369a6872ff2d0c0cacaddc831bb04d22cef7102206e0bb6d039c408e301d49978aa34597f57d075b9a69e1a9f120e08af159b167a[ALL|FORKID] 02cb6cdf3e5758112206b4b02f21838b3d8a26c601a88030f3c5705e357d8e4ea8",
        "hex":
            "47304402207b3301ec0ab0c7dbba32690b71e369a6872ff2d0c0cacaddc831bb04d22cef7102206e0bb6d039c408e301d49978aa34597f57d075b9a69e1a9f120e08af159b167a412102cb6cdf3e5758112206b4b02f21838b3d8a26c601a88030f3c5705e357d8e4ea8"
      },
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.03,
      "n": 0,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 87f3c240183ef0f3efe4b056029dd16d3e3d5d4f OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91487f3c240183ef0f3efe4b056029dd16d3e3d5d4f88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": ["1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM"]
      }
    },
    {
      "value": 0.03773,
      "n": 1,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 7fa80c90c0f8aa021074702c06b3300c0b247244 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a9147fa80c90c0f8aa021074702c06b3300c0b24724488ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": ["1Cdz8cpH3ZRuZViuah32YaTkNGryCS3DZj"]
      }
    }
  ],
  "blockhash":
      "000000000000000005d25c8d3722e4486c486bbf864f9261631993afab557832",
  "confirmations": 175,
  "time": 1662553616,
  "blocktime": 1662553616,
  "hex":
      "02000000017c24830a6a1f67fd10bf60d8557d170dcb59ab85171952287d9194b93cdbfe61000000006a47304402207b3301ec0ab0c7dbba32690b71e369a6872ff2d0c0cacaddc831bb04d22cef7102206e0bb6d039c408e301d49978aa34597f57d075b9a69e1a9f120e08af159b167a412102cb6cdf3e5758112206b4b02f21838b3d8a26c601a88030f3c5705e357d8e4ea8ffffffff02c0c62d00000000001976a91487f3c240183ef0f3efe4b056029dd16d3e3d5d4f88ac48923900000000001976a9147fa80c90c0f8aa021074702c06b3300c0b24724488ac00000000"
};

final tx3Raw = {
  "in_mempool": false,
  "in_orphanpool": false,
  "txid": "070b45d901243b5856a0cccce8c5f5f548c19aaa00cb0059b37a6a9a3632288a",
  "size": 226,
  "version": 2,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
      "vout": 1,
      "scriptSig": {
        "asm":
            "3045022100ed38dc64e40a5cfe137d38fbe9b7c4fe8a09ef923d7f999f35c65b029aa233ac02206f119c8d881a1b475697ec1eef815cde2e0e456ce4e234c5762fc7ddbe04ac27[ALL|FORKID] 029845663b31ebf3136039db97b3413b939b61c5bef45e4ee23544165a28ed452b",
        "hex":
            "483045022100ed38dc64e40a5cfe137d38fbe9b7c4fe8a09ef923d7f999f35c65b029aa233ac02206f119c8d881a1b475697ec1eef815cde2e0e456ce4e234c5762fc7ddbe04ac274121029845663b31ebf3136039db97b3413b939b61c5bef45e4ee23544165a28ed452b"
      },
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.02,
      "n": 0,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 87f3c240183ef0f3efe4b056029dd16d3e3d5d4f OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91487f3c240183ef0f3efe4b056029dd16d3e3d5d4f88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": ["1DPrEZBKKVG1Pf4HXeuCkw2Xk65EunR7CM"]
      }
    },
    {
      "value": 0.01772773,
      "n": 1,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 39cb987d75cbe99ec577de2f1918ff2b3539491a OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91439cb987d75cbe99ec577de2f1918ff2b3539491a88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": ["16GbR1Xau2hKFTr1STgB39NbP8CEkGZjYG"]
      }
    }
  ],
  "blockhash":
      "00000000000000000227adf51d47ac640c7353e873a398901ecf9becbf5988d7",
  "confirmations": 179,
  "time": 1662555788,
  "blocktime": 1662555788,
  "hex":
      "0200000001ba348354bc44422c189ad10ea05821cfe43d04aee686ecb5dfff42fa2ecc6597010000006b483045022100ed38dc64e40a5cfe137d38fbe9b7c4fe8a09ef923d7f999f35c65b029aa233ac02206f119c8d881a1b475697ec1eef815cde2e0e456ce4e234c5762fc7ddbe04ac274121029845663b31ebf3136039db97b3413b939b61c5bef45e4ee23544165a28ed452bffffffff0280841e00000000001976a91487f3c240183ef0f3efe4b056029dd16d3e3d5d4f88ace50c1b00000000001976a91439cb987d75cbe99ec577de2f1918ff2b3539491a88ac00000000"
};

final tx4Raw = {
  "in_mempool": false,
  "in_orphanpool": false,
  "txid": "84aecde036ebe013aa3bd2fcb4741db504c7c040d34f7c33732c967646991855",
  "size": 360,
  "version": 1,
  "locktime": 757301,
  "vin": [
    {
      "txid":
          "070b45d901243b5856a0cccce8c5f5f548c19aaa00cb0059b37a6a9a3632288a",
      "vout": 0,
      "scriptSig": {
        "asm":
            "95a4d53e9059dc478b2f79dc486b4dd1ea2f34f3f2f870ba26a9c16530305ddc3e25b1d1d5adc42df75b4666b9fe6ec5b41813c0e82a579ce2167f6f7ed1b305[ALL|FORKID] 02d0825e4d527c9c24e0d423187055904f91218c82652b3fe575a212fef15531fd",
        "hex":
            "4195a4d53e9059dc478b2f79dc486b4dd1ea2f34f3f2f870ba26a9c16530305ddc3e25b1d1d5adc42df75b4666b9fe6ec5b41813c0e82a579ce2167f6f7ed1b305412102d0825e4d527c9c24e0d423187055904f91218c82652b3fe575a212fef15531fd"
      },
      "sequence": 4294967294
    },
    {
      "txid":
          "9765cc2efa42ffdfb5ec86e6ae043de4cf2158a00ed19a182c4244bc548334ba",
      "vout": 0,
      "scriptSig": {
        "asm":
            "f2557ee7ae3eaf6488cc24972c73578ffc6ea2db047ffc4ff0b220f5d4efe491de01e1024ee77dc88d2cfa2f44b686bf394bd2a7114aac4fac48007547e2d313[ALL|FORKID] 02d0825e4d527c9c24e0d423187055904f91218c82652b3fe575a212fef15531fd",
        "hex":
            "41f2557ee7ae3eaf6488cc24972c73578ffc6ea2db047ffc4ff0b220f5d4efe491de01e1024ee77dc88d2cfa2f44b686bf394bd2a7114aac4fac48007547e2d313412102d0825e4d527c9c24e0d423187055904f91218c82652b3fe575a212fef15531fd"
      },
      "sequence": 4294967294
    }
  ],
  "vout": [
    {
      "value": 0.009996,
      "n": 0,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 bd9e7c204b6d0d90ba018250fafa398d5ec1b39d OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a914bd9e7c204b6d0d90ba018250fafa398d5ec1b39d88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": ["1JHcZyhgctuDCznjkxR51pQzKEJUujuc2j"]
      }
    },
    {
      "value": 0.04,
      "n": 1,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 f5c809c469d24bc0bf4f6a17a9218df1a79cd247 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a914f5c809c469d24bc0bf4f6a17a9218df1a79cd24788ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": ["1PQaBto5KmiW3R2YeexYYoDWksMpEvhYZE"]
      }
    }
  ],
  "blockhash":
      "000000000000000005aa6b3094801ec56f36f74d4b25cad38b22dc3d24cd3e43",
  "confirmations": 1,
  "time": 1662893734,
  "blocktime": 1662893734,
  "hex":
      "01000000028a2832369a6a7ab35900cb00aa9ac148f5f5c5e8cccca056583b2401d9450b0700000000644195a4d53e9059dc478b2f79dc486b4dd1ea2f34f3f2f870ba26a9c16530305ddc3e25b1d1d5adc42df75b4666b9fe6ec5b41813c0e82a579ce2167f6f7ed1b305412102d0825e4d527c9c24e0d423187055904f91218c82652b3fe575a212fef15531fdfeffffffba348354bc44422c189ad10ea05821cfe43d04aee686ecb5dfff42fa2ecc6597000000006441f2557ee7ae3eaf6488cc24972c73578ffc6ea2db047ffc4ff0b220f5d4efe491de01e1024ee77dc88d2cfa2f44b686bf394bd2a7114aac4fac48007547e2d313412102d0825e4d527c9c24e0d423187055904f91218c82652b3fe575a212fef15531fdfeffffff02b0400f00000000001976a914bd9e7c204b6d0d90ba018250fafa398d5ec1b39d88ac00093d00000000001976a914f5c809c469d24bc0bf4f6a17a9218df1a79cd24788ac358e0b00"
};
