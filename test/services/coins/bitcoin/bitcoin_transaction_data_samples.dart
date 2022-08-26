import 'package:stackwallet/models/paymint/transactions_model.dart';

final transactionData = TransactionData.fromMap({
  "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c": tx1,
  "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528": tx2,
  "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3": tx3,
  "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa": tx4,
});

final tx1 = Transaction(
  txid: "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
  confirmedStatus: true,
  confirmations: 100,
  txType: "Received",
  amount: 17000,
  fees: 603,
  height: 2226326,
  address: "2Mv83bPh2HzPRXptuQg9ejbKpSp87Zi52zT",
  timestamp: 1652994245,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 2,
  outputSize: 1,
  inputs: [
    Input(
      txid: "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
      vout: 1,
    ),
    Input(
      txid: "46b1f19763ac68e39b8218429f4e29b150f850901562fe44a05fade9e0acd65f",
      vout: 1,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "2Mv83bPh2HzPRXptuQg9ejbKpSp87Zi52zT",
      value: 17000,
    ),
  ],
);

final tx2 = Transaction(
  txid: "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
  confirmedStatus: false,
  confirmations: 0,
  txType: "Sent",
  amount: 249,
  fees: 249,
  height: 457377,
  address: "2NCxQqUPYGiAKX59NyemdoYEENGvJtL4obG",
  timestamp: 1652923129,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 3,
  outputSize: 1,
  inputs: [
    Input(
      txid: "717080fc0054f655260b1591a0059bf377a589a98284173d20a1c8f3316c086e",
      vout: 0,
    ),
    Input(
      txid: "1baec51e7630e3640ccf0e34f160c8ad3eb6021ecafe3618a1afae328f320f53",
      vout: 0,
    ),
    Input(
      txid: "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "2NCxQqUPYGiAKX59NyemdoYEENGvJtL4obG",
      value: 36037,
    ),
  ],
);

final tx3 = Transaction(
  txid: "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
  confirmedStatus: false,
  confirmations: 0,
  txType: "Received",
  amount: 5000,
  fees: 286,
  height: 457374,
  address: "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
  timestamp: 1646687820,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 1,
  outputSize: 2,
  inputs: [
    Input(
      txid: "6261002b30122ab3b2ba8c481134e8a3ce08a3a1a429b8ebb3f28228b100ac1a",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
      value: 5000,
    ),
    Output(
      scriptpubkeyAddress: "tb1q34ed0ghwvcw499gl734uwc5xcyh4zj4w5v5peg",
      value: 14714,
    ),
  ],
);

final tx4 = Transaction(
  txid: "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
  confirmedStatus: true,
  confirmations: 100,
  txType: "Sent",
  amount: 8746,
  fees: 111,
  height: 457374,
  address: "tb1qy6rwx5qtd25j6tgvx3yvfk2yjt9va058q6rtfh",
  timestamp: 1646687820,
  worthNow: "0.00",
  worthAtBlockTimestamp: "0.00",
  inputSize: 1,
  outputSize: 1,
  inputs: [
    Input(
      txid: "46b1f19763ac68e39b8218429f4e29b150f850901562fe44a05fade9e0acd65f",
      vout: 0,
    ),
  ],
  outputs: [
    Output(
      scriptpubkeyAddress: "tb1qy6rwx5qtd25j6tgvx3yvfk2yjt9va058q6rtfh",
      value: 8746,
    ),
  ],
);

final tx1Raw = {
  "txid": "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
  "hash": "c3c6d7b1756bf0a95ef9a99e62d72e7ee31cd5257b32209640ed59679dd5926d",
  "version": 1,
  "size": 363,
  "vsize": 201,
  "weight": 804,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "304402205bead29613536890834a8cb6267ac3f9e3330af40407c6d0c57e3f805eff93bc022067115ce5731de45995c90c3c7c5d71f8bb3b4f7501b2b6268dd4b76da94a57c901",
        "02bdc758cb2fa3153b52d2ec61102cc06ec9a541359c205f83a646a7cf15b3e5f9"
      ],
      "sequence": 4294967295
    },
    {
      "txid":
          "46b1f19763ac68e39b8218429f4e29b150f850901562fe44a05fade9e0acd65f",
      "vout": 1,
      "scriptSig": {
        "asm": "0014cd5479b8f2ee71037c99b7d864eccbde605adca5",
        "hex": "160014cd5479b8f2ee71037c99b7d864eccbde605adca5"
      },
      "txinwitness": [
        "304402200a089b72e661402c2812a91baed159a3a633b10b937efbc95512920fd66c2dc90220546c2c73809df80af13824c33a81b639c5e7cd16ccdcb27f1bc4a1321726511301",
        "02711353556322a96722f0692ec7b25949417e794169f9c239ee5daa1c94239099"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.00017,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_HASH160 1f8cc9dfb76a2dd16566fdb05c9c1899be0afbd7 OP_EQUAL",
        "hex": "a9141f8cc9dfb76a2dd16566fdb05c9c1899be0afbd787",
        "address": "2Mv83bPh2HzPRXptuQg9ejbKpSp87Zi52zT",
        "type": "scripthash"
      }
    }
  ],
  "hex":
      "01000000000102fa104ea06855e3538fd89573625ddd00ca24fe785298e2496af45ab602ac9bb30000000000ffffffff5fd6ace0e9ad5fa044fe62159050f850b1294e9f4218829be368ac6397f1b1460100000017160014cd5479b8f2ee71037c99b7d864eccbde605adca5ffffffff01684200000000000017a9141f8cc9dfb76a2dd16566fdb05c9c1899be0afbd7870247304402205bead29613536890834a8cb6267ac3f9e3330af40407c6d0c57e3f805eff93bc022067115ce5731de45995c90c3c7c5d71f8bb3b4f7501b2b6268dd4b76da94a57c9012102bdc758cb2fa3153b52d2ec61102cc06ec9a541359c205f83a646a7cf15b3e5f90247304402200a089b72e661402c2812a91baed159a3a633b10b937efbc95512920fd66c2dc90220546c2c73809df80af13824c33a81b639c5e7cd16ccdcb27f1bc4a13217265113012102711353556322a96722f0692ec7b25949417e794169f9c239ee5daa1c9423909900000000",
  "blockhash":
      "00000000000000198ca8300deab26c5c1ec1df0da5afd30c9faabd340d8fc194",
  "confirmations": 100,
  "time": 1652994245,
  "blocktime": 1652994245
};

final tx2Raw = {
  "txid": "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
  "hash": "0ae34d492569e0db5d4f70568e6126f6f544f80e688b190c1aa65d3f1f13167f",
  "version": 1,
  "size": 489,
  "vsize": 246,
  "weight": 984,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "717080fc0054f655260b1591a0059bf377a589a98284173d20a1c8f3316c086e",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "30440220782cca30842a9700458328823aad9dfafe570d08e77d069704d673de52229e6f02201aae3f966f0e89efdc45e3691fa58c3cfb61e107e1e8184183de4cc374fa0cf201",
        "02d8de083e7c08ef29627263fac8323d19f190b16f029a4ce161f757d5530bfd5c"
      ],
      "sequence": 4294967295
    },
    {
      "txid":
          "1baec51e7630e3640ccf0e34f160c8ad3eb6021ecafe3618a1afae328f320f53",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3045022100a5a76dff657eb01bfdea7ae97a2508f55cb110eddc19c49a68c74d40b01d223902207202a7ed3b554160230cbabcd3fc3ce2eb54ceee4e80b54d19d91e93df51e12401",
        "02a137adce3423c031bb501a9836dea5aab1282ca3d6936ae1cca2cc05f2f81c74"
      ],
      "sequence": 4294967295
    },
    {
      "txid":
          "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3044022059297b84a8a7d938bd71898c921bff108ffb5a9b149a94b2d5d832e67279216702202b99aef9c72e09f931de715e95c1e12f4a5024bff05057b7dafea76825ab138a01",
        "02d8de083e7c08ef29627263fac8323d19f190b16f029a4ce161f757d5530bfd5c"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.00036037,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_HASH160 d8347ff657c310d4925d97388d1214f17d3cad70 OP_EQUAL",
        "hex": "a914d8347ff657c310d4925d97388d1214f17d3cad7087",
        "address": "2NCxQqUPYGiAKX59NyemdoYEENGvJtL4obG",
        "type": "scripthash"
      }
    }
  ],
  "hex":
      "010000000001036e086c31f3c8a1203d178482a989a577f39b05a091150b2655f65400fc8070710000000000ffffffff530f328f32aeafa11836feca1e02b63eadc860f1340ecf0c64e330761ec5ae1b0000000000ffffffffd306a08972440e82c0cdcade9f13e001583f9b6c260b8f473448b4609722cadc0000000000ffffffff01c58c00000000000017a914d8347ff657c310d4925d97388d1214f17d3cad7087024730440220782cca30842a9700458328823aad9dfafe570d08e77d069704d673de52229e6f02201aae3f966f0e89efdc45e3691fa58c3cfb61e107e1e8184183de4cc374fa0cf2012102d8de083e7c08ef29627263fac8323d19f190b16f029a4ce161f757d5530bfd5c02483045022100a5a76dff657eb01bfdea7ae97a2508f55cb110eddc19c49a68c74d40b01d223902207202a7ed3b554160230cbabcd3fc3ce2eb54ceee4e80b54d19d91e93df51e124012102a137adce3423c031bb501a9836dea5aab1282ca3d6936ae1cca2cc05f2f81c7402473044022059297b84a8a7d938bd71898c921bff108ffb5a9b149a94b2d5d832e67279216702202b99aef9c72e09f931de715e95c1e12f4a5024bff05057b7dafea76825ab138a012102d8de083e7c08ef29627263fac8323d19f190b16f029a4ce161f757d5530bfd5c00000000",
  "blockhash":
      "000000000000003db63ad679a539f2088dcc97a149c99ca790ce0c5f7b5acff0",
  "confirmations": 0,
  "time": 1652923129,
  "blocktime": 1652923129
};

final tx3Raw = {
  "txid": "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
  "hash": "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
  "version": 1,
  "size": 220,
  "vsize": 220,
  "weight": 880,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "6261002b30122ab3b2ba8c481134e8a3ce08a3a1a429b8ebb3f28228b100ac1a",
      "vout": 0,
      "scriptSig": {
        "asm":
            "3045022100e929d5d356aca929f28426c6bb205a73baa7d655f08aa9b0a044021731a411ab02205916293a3e53333c430a9f81a74eb621a7692ee4e55d67ca74543b5688b7cb72[ALL] 031e4cb72bf83add6f4e1d9b1edd5d3fb520971568786d8f4a0261dec73a8c3658",
        "hex":
            "483045022100e929d5d356aca929f28426c6bb205a73baa7d655f08aa9b0a044021731a411ab02205916293a3e53333c430a9f81a74eb621a7692ee4e55d67ca74543b5688b7cb720121031e4cb72bf83add6f4e1d9b1edd5d3fb520971568786d8f4a0261dec73a8c3658"
      },
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 5e-05,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 891d9be42f25876e82cb7dc68800938577312bf0",
        "hex": "0014891d9be42f25876e82cb7dc68800938577312bf0",
        "address": "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
        "type": "witness_v0_keyhash"
      }
    },
    {
      "value": 0.00014714,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 8d72d7a2ee661d52951ff46bc76286c12f514aae",
        "hex": "00148d72d7a2ee661d52951ff46bc76286c12f514aae",
        "address": "tb1q34ed0ghwvcw499gl734uwc5xcyh4zj4w5v5peg",
        "type": "witness_v0_keyhash"
      }
    }
  ],
  "hex":
      "01000000011aac00b12882f2b3ebb829a4a1a308cea3e83411488cbab2b32a12302b006162000000006b483045022100e929d5d356aca929f28426c6bb205a73baa7d655f08aa9b0a044021731a411ab02205916293a3e53333c430a9f81a74eb621a7692ee4e55d67ca74543b5688b7cb720121031e4cb72bf83add6f4e1d9b1edd5d3fb520971568786d8f4a0261dec73a8c3658ffffffff028813000000000000160014891d9be42f25876e82cb7dc68800938577312bf07a390000000000001600148d72d7a2ee661d52951ff46bc76286c12f514aae00000000",
  "blockhash":
      "0000000000000030bec9bc58a3ab4857de1cc63cfed74204a6be57f125fb2fa7",
  "confirmations": 0,
  "time": 1652888705,
  "blocktime": 1652888705
};

final tx4Raw = {
  "txid": "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
  "hash": "037622195fc13a8d8937c6d682676e7f5f2ce2af2c7abc224eeca2ffd25295db",
  "version": 1,
  "size": 191,
  "vsize": 110,
  "weight": 437,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "46b1f19763ac68e39b8218429f4e29b150f850901562fe44a05fade9e0acd65f",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "304402206bde026a43a6926b4fe5c3b8aaef78765e2e4bdad86896cd54ac83120cb3d680022027be938536ef98ff59c03349760bb480f529018d6e2c94f6d70c40b345600d3f01",
        "02a888c62b2539cf444591924ddb6fc0aecf94b384d3ddf201d3a49d8b382b6724"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 8.746e-05,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 2686e3500b6aa92d2d0c3448c4d94492cacebe87",
        "hex": "00142686e3500b6aa92d2d0c3448c4d94492cacebe87",
        "address": "tb1qy6rwx5qtd25j6tgvx3yvfk2yjt9va058q6rtfh",
        "type": "witness_v0_keyhash"
      }
    }
  ],
  "hex":
      "010000000001015fd6ace0e9ad5fa044fe62159050f850b1294e9f4218829be368ac6397f1b1460000000000ffffffff012a220000000000001600142686e3500b6aa92d2d0c3448c4d94492cacebe870247304402206bde026a43a6926b4fe5c3b8aaef78765e2e4bdad86896cd54ac83120cb3d680022027be938536ef98ff59c03349760bb480f529018d6e2c94f6d70c40b345600d3f012102a888c62b2539cf444591924ddb6fc0aecf94b384d3ddf201d3a49d8b382b672400000000",
  "blockhash":
      "0000000039b80e9a10b7bcaf0f193b51cb870a4febe9b427c1f41a3f42eaa80b",
  "confirmations": 22861,
  "time": 1652993683,
  "blocktime": 1652993683
};

final tx5Raw = {
  "txid": "6261002b30122ab3b2ba8c481134e8a3ce08a3a1a429b8ebb3f28228b100ac1a",
  "hash": "1f899b4ce3b778e8282e7cb4c10c0ec37f54a93cb61b8a0c34201b9a80728972",
  "version": 1,
  "size": 226,
  "vsize": 144,
  "weight": 574,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "7732fee8944d86cbcada0954f21312fa7ab423dc86911b6ada569dea51c5a13f",
      "vout": 1,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3045022100a004c1e11a4b4f3c4532024b589c57403d599196e0aa2a80139329ebfec33e8c0220620c6e1a9a3ed1b9057122eff122c103ffd31019d7fe9b142b94d6f8f7d2de2201",
        "02eb38cea8257b00d05fb4795001148633967bff77674e2c143b1499e9687dee5d"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.0002,
      "n": 0,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 85c5660b3318c3630a2fa3e0cba016d97df2eda8 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91485c5660b3318c3630a2fa3e0cba016d97df2eda888ac",
        "address": "msiGe4cwxHqs6ssdjG8GADtRF91W84mXSV",
        "type": "pubkeyhash"
      }
    },
    {
      "value": 0.00040076,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 d2dbe84f7f75e86197c2e27d6b6b60461b4c9ee2",
        "hex": "0014d2dbe84f7f75e86197c2e27d6b6b60461b4c9ee2",
        "address": "tb1q6td7snmlwh5xr97zuf7kk6mqgcd5e8hz7pjha4",
        "type": "witness_v0_keyhash"
      }
    }
  ],
  "hex":
      "010000000001013fa1c551ea9d56da6a1b9186dc23b47afa1213f25409dacacb864d94e8fe32770100000000ffffffff02204e0000000000001976a91485c5660b3318c3630a2fa3e0cba016d97df2eda888ac8c9c000000000000160014d2dbe84f7f75e86197c2e27d6b6b60461b4c9ee202483045022100a004c1e11a4b4f3c4532024b589c57403d599196e0aa2a80139329ebfec33e8c0220620c6e1a9a3ed1b9057122eff122c103ffd31019d7fe9b142b94d6f8f7d2de22012102eb38cea8257b00d05fb4795001148633967bff77674e2c143b1499e9687dee5d00000000",
  "blockhash":
      "000000000000002cefad7fdfb691b23a4f93b471dbb8d5f56582d268c234ebf5",
  "confirmations": 23174,
  "time": 1652887266,
  "blocktime": 1652887266
};

final tx6Raw = {
  "txid": "717080fc0054f655260b1591a0059bf377a589a98284173d20a1c8f3316c086e",
  "hash": "ed23d9e1d244883be8d3f17e682d7bb3022820dc8bdf0a42e54ce30117e42265",
  "version": 1,
  "size": 223,
  "vsize": 141,
  "weight": 562,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "d71b680a915544a6459677719433f11bc9a9e4fdf56fb284af905d063d1d43f3",
      "vout": 1,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3045022100ac93972d2f7f2d3826cd92c61fc6d3a26e526621612b8cb7f4616a91b563a4d50220064c7361f9cd75b287a5833c9f9df836b12331959111f887abe651b8b39e440701",
        "03918929648fc80cbd2bb9884e0e038e4290b54a0386bdda4bd92265262bc026cf"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 1.428e-05,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 891d9be42f25876e82cb7dc68800938577312bf0",
        "hex": "0014891d9be42f25876e82cb7dc68800938577312bf0",
        "address": "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
        "type": "witness_v0_keyhash"
      }
    },
    {
      "value": 4.714e-05,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 78d1ab0d6b69e1061b0c84459c3ca0d936c3e71e",
        "hex": "001478d1ab0d6b69e1061b0c84459c3ca0d936c3e71e",
        "address": "tb1q0rg6krttd8ssvxcvs3zec09qmymv8ec79myn2y",
        "type": "witness_v0_keyhash"
      }
    }
  ],
  "hex":
      "01000000000101f3431d3d065d90af84b26ff5fde4a9c91bf1339471779645a64455910a681bd70100000000ffffffff029405000000000000160014891d9be42f25876e82cb7dc68800938577312bf06a1200000000000016001478d1ab0d6b69e1061b0c84459c3ca0d936c3e71e02483045022100ac93972d2f7f2d3826cd92c61fc6d3a26e526621612b8cb7f4616a91b563a4d50220064c7361f9cd75b287a5833c9f9df836b12331959111f887abe651b8b39e4407012103918929648fc80cbd2bb9884e0e038e4290b54a0386bdda4bd92265262bc026cf00000000",
  "blockhash":
      "0000000000000045fd17129a040162575785283c9952d707faa19a7c773756a0",
  "confirmations": 23177,
  "time": 1652888318,
  "blocktime": 1652888318
};

final tx7Raw = {
  "txid": "1baec51e7630e3640ccf0e34f160c8ad3eb6021ecafe3618a1afae328f320f53",
  "hash": "c6edb66af49d4e91512e55a46173c0b145a19ebf8c98fe63f5dc7b66c6f20173",
  "version": 1,
  "size": 222,
  "vsize": 141,
  "weight": 561,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "29cdb7bf5d94c016572e51ae01e4411fc3369026626c4e1605073198b79b6fbc",
      "vout": 1,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "30440220631dfe5021080696853cca6615bf4fd9207e0f3c1032252f2be3f0c01ddf7768022015fbfa2046966a4a1cbc13a2328279afa90ecf4813078953ad46eabbf55c915401",
        "026a3d8c9cd38821e46c68c60cd13cd4455de0163ab17b8aeefb16e5e8a70b7ca6"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.00029858,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 6a6cb49ab8413f0935b38b3d4962a74bf8a3ace1",
        "hex": "00146a6cb49ab8413f0935b38b3d4962a74bf8a3ace1",
        "address": "tb1qdfktfx4cgylsjddn3v75jc48f0u28t8p8z0g5n",
        "type": "witness_v0_keyhash"
      }
    },
    {
      "value": 5.79e-05,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 2da265260f2a2b6b95d1a9af7188d67b23931eea",
        "hex": "00142da265260f2a2b6b95d1a9af7188d67b23931eea",
        "address": "tb1q9k3x2fs09g4kh9w34xhhrzxk0v3ex8h2q33avx",
        "type": "witness_v0_keyhash"
      }
    }
  ],
  "hex":
      "01000000000101bc6f9bb798310705164e6c62269036c31f41e401ae512e5716c0945dbfb7cd290100000000ffffffff02a2740000000000001600146a6cb49ab8413f0935b38b3d4962a74bf8a3ace19e160000000000001600142da265260f2a2b6b95d1a9af7188d67b23931eea024730440220631dfe5021080696853cca6615bf4fd9207e0f3c1032252f2be3f0c01ddf7768022015fbfa2046966a4a1cbc13a2328279afa90ecf4813078953ad46eabbf55c91540121026a3d8c9cd38821e46c68c60cd13cd4455de0163ab17b8aeefb16e5e8a70b7ca600000000",
  "blockhash":
      "0000000000000045b3b435c711ca209ad67b858aae20b6dbd1d3b888cc555c3b",
  "confirmations": 23175,
  "time": 1652890248,
  "blocktime": 1652890248
};

final tx8Raw = {
  "txid": "46b1f19763ac68e39b8218429f4e29b150f850901562fe44a05fade9e0acd65f",
  "hash": "79f0f58ac254c66768d5ad3bd160fabf6c77984ca1508f2b2dc5627885f3431e",
  "version": 1,
  "size": 223,
  "vsize": 142,
  "weight": 565,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "0042c3a6ec3266519345621d70a4fe59b03bfd4c085a65786a0ef222e732ce01",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "304402205dfa1c956d68a37147e6bb3a7cfb390f543122840914e4e98a3279185963065a02207d84d3ad36d55dedfc12c3b55d7a51b9060ad7d7221d5577ffd57755d694887401",
        "033b74c034fc26a00dc82ca4d55b8a4ad2a6eaed6a2f5faecccefddf0e696a37cf"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 8.857e-05,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 eccf6bfefec01d0d84106a7626764bcd923e48e9",
        "hex": "0014eccf6bfefec01d0d84106a7626764bcd923e48e9",
        "address": "tb1qan8khlh7cqwsmpqsdfmzvajtekfruj8ft0tej8",
        "type": "witness_v0_keyhash"
      }
    },
    {
      "value": 8.857e-05,
      "n": 1,
      "scriptPubKey": {
        "asm": "OP_HASH160 3b02b41fdc988c1430dc34b86e7762be673b5415 OP_EQUAL",
        "hex": "a9143b02b41fdc988c1430dc34b86e7762be673b541587",
        "address": "2MxdF6TBGUCx47s9SoW5Wpfvs8eWX9n3Zj4",
        "type": "scripthash"
      }
    }
  ],
  "hex":
      "0100000000010101ce32e722f20e6a78655a084cfd3bb059fea4701d624593516632eca6c342000000000000ffffffff029922000000000000160014eccf6bfefec01d0d84106a7626764bcd923e48e9992200000000000017a9143b02b41fdc988c1430dc34b86e7762be673b5415870247304402205dfa1c956d68a37147e6bb3a7cfb390f543122840914e4e98a3279185963065a02207d84d3ad36d55dedfc12c3b55d7a51b9060ad7d7221d5577ffd57755d69488740121033b74c034fc26a00dc82ca4d55b8a4ad2a6eaed6a2f5faecccefddf0e696a37cf00000000",
  "blockhash":
      "0000000039b80e9a10b7bcaf0f193b51cb870a4febe9b427c1f41a3f42eaa80b",
  "confirmations": 22869,
  "time": 1652993683,
  "blocktime": 1652993683
};

final tx9Raw = {
  "txid": "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
  "hash": "e193c66fa7ced85e471ad3cd21d6789bc708202958b555cf15af7da7ec69f56f",
  "version": 1,
  "size": 373,
  "vsize": 291,
  "weight": 1162,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "8b911bfacbf7d281e04f104f88b737b0a946b328dd3b4ac887225242258156e8",
      "vout": 1,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3044022064e164c12e916bf36a2c216157b7405bd410dcf05310db98c9c2bd4bb61d51c6022079cf39dc337b59b4d2670a4274ab95733fc646eafbbe8057b1aa12ab61fa010801",
        "02a7c9a87ba540266b3aa43ba8e6e046281494aa03144f463e8a5677a7b4f260fc"
      ],
      "sequence": 4294967295
    },
    {
      "txid":
          "7a46f6b80e1f3ec5910eafcd3b3b4c634624acdfb312cdab85c45c04ebc5d007",
      "vout": 1,
      "scriptSig": {
        "asm":
            "30440220674d02d7ad703551c835ccd31256bff4e38fa844e78583287d82197257e6e2b102206b422a984fe35b1ca89810a639b548a2b14316983d749eb37e20c5ecef7f92af[ALL] 035ac55a5f1b0e0ad2a1e70f1e44280cef7d306b16a3fdc6d7ab56ffa08ba5d070",
        "hex":
            "4730440220674d02d7ad703551c835ccd31256bff4e38fa844e78583287d82197257e6e2b102206b422a984fe35b1ca89810a639b548a2b14316983d749eb37e20c5ecef7f92af0121035ac55a5f1b0e0ad2a1e70f1e44280cef7d306b16a3fdc6d7ab56ffa08ba5d070"
      },
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 5.756e-05,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 bb6982d511d6db7cab445c93b0cc89be563d72ae",
        "hex": "0014bb6982d511d6db7cab445c93b0cc89be563d72ae",
        "address": "tb1qhd5c94g36mdhe26ytjfmpnyfhetr6u4w25n55x",
        "type": "witness_v0_keyhash"
      }
    },
    {
      "value": 5.5e-05,
      "n": 1,
      "scriptPubKey": {
        "asm":
            "OP_DUP OP_HASH160 60fb3de713f73cba9e33c9bcb67776f4415ba406 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91460fb3de713f73cba9e33c9bcb67776f4415ba40688ac",
        "address": "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ",
        "type": "pubkeyhash"
      }
    }
  ],
  "hex":
      "01000000000102e856812542522287c84a3bdd28b346a9b037b7884f104fe081d2f7cbfa1b918b0100000000ffffffff07d0c5eb045cc485abcd12b3dfac2446634c3b3bcdaf0e91c53e1f0eb8f6467a010000006a4730440220674d02d7ad703551c835ccd31256bff4e38fa844e78583287d82197257e6e2b102206b422a984fe35b1ca89810a639b548a2b14316983d749eb37e20c5ecef7f92af0121035ac55a5f1b0e0ad2a1e70f1e44280cef7d306b16a3fdc6d7ab56ffa08ba5d070ffffffff027c16000000000000160014bb6982d511d6db7cab445c93b0cc89be563d72ae7c150000000000001976a91460fb3de713f73cba9e33c9bcb67776f4415ba40688ac02473044022064e164c12e916bf36a2c216157b7405bd410dcf05310db98c9c2bd4bb61d51c6022079cf39dc337b59b4d2670a4274ab95733fc646eafbbe8057b1aa12ab61fa0108012102a7c9a87ba540266b3aa43ba8e6e046281494aa03144f463e8a5677a7b4f260fc0000000000",
  "blockhash":
      "00000000000000914aebb1f2dbc85e5a119437dae67d0df121ccf33243d405af",
  "confirmations": 704,
  "time": 1654182725,
  "blocktime": 1654182725
};

final tx10Raw = {
  "txid": "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
  "hash": "a740d973b5d162a3646509a45bb1029beb8ef9cccc36408cffa7362e97b42be3",
  "version": 1,
  "size": 224,
  "vsize": 142,
  "weight": 566,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "6b4d616aeeb10c14828017fab083f64636a8b14afa22ed85323d230eae0ad0c6",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3045022100e7e37c80287d2be5e4d2dc80d211c4322b2c647b94e0fce4627fa4f5125135060220024aaa90637e84f88c7d4fffc68bc9ffb0f670ba60acfb3636b1641a9d9482f501",
        "03d53fbe04bb74509e53bf2be7f5db0e35316a1ff4f15d3c4671a08c55510b0901"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.00148831,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 395af4343f1fc1865f557dfda882c1b928964b1e",
        "hex": "0014395af4343f1fc1865f557dfda882c1b928964b1e",
        "address": "tb1q89d0gdplrlqcvh640h763qkphy5fvjc7lmp2fw",
        "type": "witness_v0_keyhash"
      }
    },
    {
      "value": 6.5e-05,
      "n": 1,
      "scriptPubKey": {
        "asm": "OP_HASH160 6dffe561482ee3a5557faae9f4acb5368f945a8c OP_EQUAL",
        "hex": "a9146dffe561482ee3a5557faae9f4acb5368f945a8c87",
        "address": "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g",
        "type": "scripthash"
      }
    }
  ],
  "hex":
      "01000000000101c6d00aae0e233d3285ed22fa4ab1a83646f683b0fa178082140cb1ee6a614d6b0000000000ffffffff025f45020000000000160014395af4343f1fc1865f557dfda882c1b928964b1e641900000000000017a9146dffe561482ee3a5557faae9f4acb5368f945a8c8702483045022100e7e37c80287d2be5e4d2dc80d211c4322b2c647b94e0fce4627fa4f5125135060220024aaa90637e84f88c7d4fffc68bc9ffb0f670ba60acfb3636b1641a9d9482f5012103d53fbe04bb74509e53bf2be7f5db0e35316a1ff4f15d3c4671a08c55510b090100000000",
  "blockhash":
      "0000000000048280441cb896acf650e565917190157cf0f348b0adfdef4e2505",
  "confirmations": 703,
  "time": 1654183929,
  "blocktime": 1654183929
};

final tx11Raw = {
  "txid": "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
  "hash": "e8b3c3058ccc64cbad9d7868b7fdfe9d159f4f74b5cd3ad589a7578060a827c8",
  "version": 1,
  "size": 222,
  "vsize": 141,
  "weight": 561,
  "locktime": 0,
  "vin": [
    {
      "txid":
          "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
      "vout": 0,
      "scriptSig": {"asm": "", "hex": ""},
      "txinwitness": [
        "3044022076704f1a3f90c1488dde9ad7da1d5270a573dbac66768c5fe3f33b575efb5d9e022060bff5a3bc82d15de27d18a440711c42b5d297ac1ece5e7a9a6d081001b182fb01",
        "0362e8150949ac1e765d589ffe8fc8820e90d77af42f154fb936e83586780d0e3e"
      ],
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 0.00141689,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 742bc6d18003acad5f24ac68290146134b4f24bd",
        "hex": "0014742bc6d18003acad5f24ac68290146134b4f24bd",
        "address": "tb1qws4ud5vqqwk26hey435zjq2xzd957f9awkus2g",
        "type": "witness_v0_keyhash"
      }
    },
    {
      "value": 7e-05,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 9a540de5701d22bc880703a0113653307fb94c95",
        "hex": "00149a540de5701d22bc880703a0113653307fb94c95",
        "address": "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
        "type": "witness_v0_keyhash"
      }
    }
  ],
  "hex":
      "01000000000101d73ba9fb86a9d021dbd8cdba5ff5f0509cbcb92b1cc29a66516de8a067c932ed0000000000ffffffff027929020000000000160014742bc6d18003acad5f24ac68290146134b4f24bd581b0000000000001600149a540de5701d22bc880703a0113653307fb94c9502473044022076704f1a3f90c1488dde9ad7da1d5270a573dbac66768c5fe3f33b575efb5d9e022060bff5a3bc82d15de27d18a440711c42b5d297ac1ece5e7a9a6d081001b182fb01210362e8150949ac1e765d589ffe8fc8820e90d77af42f154fb936e83586780d0e3e00000000",
  "blockhash":
      "0000000000048280441cb896acf650e565917190157cf0f348b0adfdef4e2505",
  "confirmations": 703,
  "time": 1654183929,
  "blocktime": 1654183929
};
