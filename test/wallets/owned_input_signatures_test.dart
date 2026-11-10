import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/wallet/supporting/owned_input_signatures.dart';

final network = coinlib.Network.mainnet;

InputV2 inputV2(
  coinlib.Input input,
  String? address,
  int value, {
  bool walletOwns = true,
}) => InputV2.isarCantDoRequiredInDefaultConstructor(
  scriptSigHex: null,
  scriptSigAsm: null,
  sequence: null,
  outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
    txid: coinlib.bytesToHex(
      Uint8List.fromList(input.prevOut.hash.reversed.toList()),
    ),
    vout: input.prevOut.n,
  ),
  addresses: [if (address != null) address],
  valueStringSats: "$value",
  witness: null,
  innerRedeemScriptAsm: null,
  coinbase: null,
  walletOwns: walletOwns,
);

OutputV2 outputV2(coinlib.Output output, [String? address]) =>
    OutputV2.isarCantDoRequiredInDefaultConstructor(
      scriptPubKeyHex: coinlib.bytesToHex(output.scriptPubKey),
      valueStringSats: "${output.value}",
      addresses: [if (address != null) address],
      walletOwns: false,
    );

void main() {
  setUpAll(coinlib.loadCoinlib);

  final throwsUnauthenticated = throwsA(isA<UnauthenticatedTransaction>());

  // A transaction spending the wallet's p2pkh, p2wpkh and p2tr coins.
  late final coinlib.Transaction Function({coinlib.SigHashType hashType}) sign;
  late final coinlib.Transaction signed;
  late final List<InputV2> inputs;
  late final List<OutputV2> outputs;
  late final String attacker;

  setUpAll(() {
    coinlib.ECPrivateKey key(int n) =>
        coinlib.ECPrivateKey(Uint8List(32)..[31] = n);
    final taproot = coinlib.Taproot(internalKey: key(3).pubkey);

    final p2pkh = coinlib.P2PKHAddress.fromPublicKey(
      key(1).pubkey,
      version: network.p2pkhPrefix,
    );
    final p2wpkh = coinlib.P2WPKHAddress.fromPublicKey(
      key(2).pubkey,
      hrp: network.bech32Hrp,
    );
    final p2tr = coinlib.P2TRAddress.fromTaproot(
      taproot,
      hrp: network.bech32Hrp,
    );
    final recipient = coinlib.P2WPKHAddress.fromPublicKey(
      key(4).pubkey,
      hrp: network.bech32Hrp,
    );
    attacker = coinlib.P2WPKHAddress.fromPublicKey(
      key(5).pubkey,
      hrp: network.bech32Hrp,
    ).toString();

    final prevOuts = [
      coinlib.Output.fromAddress(BigInt.from(100000), p2pkh),
      coinlib.Output.fromAddress(BigInt.from(200000), p2wpkh),
      coinlib.Output.fromAddress(BigInt.from(300000), p2tr),
    ];
    final txOutputs = [
      coinlib.Output.fromAddress(BigInt.from(500000), recipient),
      coinlib.Output.fromAddress(BigInt.from(90000), p2wpkh),
    ];

    sign = ({hashType = const coinlib.SigHashType.all()}) =>
        coinlib.Transaction(
              version: 2,
              inputs: [
                coinlib.P2PKHInput(
                  prevOut: coinlib.OutPoint(Uint8List(32)..[0] = 1, 0),
                  publicKey: key(1).pubkey,
                ),
                coinlib.P2WPKHInput(
                  prevOut: coinlib.OutPoint(Uint8List(32)..[0] = 2, 1),
                  publicKey: key(2).pubkey,
                ),
                coinlib.TaprootKeyInput(
                  prevOut: coinlib.OutPoint(Uint8List(32)..[0] = 3, 2),
                ),
              ],
              outputs: txOutputs,
            )
            .signLegacy(inputN: 0, key: key(1))
            .signLegacyWitness(
              inputN: 1,
              key: key(2),
              value: prevOuts[1].value,
              hashType: hashType,
            )
            .signTaproot(
              inputN: 2,
              key: taproot.tweakPrivateKey(key(3)),
              prevOuts: prevOuts,
            );

    signed = sign();
    inputs = [
      for (final (i, address) in [p2pkh, p2wpkh, p2tr].indexed)
        inputV2(
          signed.inputs[i],
          address.toString(),
          prevOuts[i].value.toInt(),
        ),
    ];
    outputs = [
      outputV2(txOutputs[0], recipient.toString()),
      outputV2(txOutputs[1], p2wpkh.toString()),
    ];
  });

  RawTransactionSize verify({
    String? txid,
    String? rawTxHex,
    List<InputV2>? withInputs,
    List<OutputV2>? withOutputs,
    bool allowMweb = false,
  }) => verifyOwnedInputSignatures(
    txid: txid ?? signed.txid,
    rawTxHex: rawTxHex ?? signed.toHex(),
    inputs: withInputs ?? inputs,
    outputs: withOutputs ?? outputs,
    network: network,
    allowMweb: allowMweb,
  );

  test("accepts inputs signed by the wallet", () {
    expect(verify, returnsNormally);
    // The wallet's own record of a sent transaction has no output scripts.
    expect(
      () => verify(
        withOutputs: [
          for (final e in outputs) e.copyWith(scriptPubKeyHex: "000000"),
        ],
      ),
      returnsNormally,
    );
  });

  test("rejects our signatures with different outputs", () {
    final forged = coinlib.Transaction(
      version: signed.version,
      inputs: signed.inputs,
      outputs: [
        coinlib.Output.fromAddress(
          outputs[0].value,
          coinlib.Address.fromString(attacker, network),
        ),
        signed.outputs[1],
      ],
    );
    expect(
      () => verify(
        txid: forged.txid,
        rawTxHex: forged.toHex(),
        withOutputs: [outputV2(forged.outputs[0], attacker), outputs[1]],
      ),
      throwsUnauthenticated,
    );
  });

  test("rejects details that do not match the raw transaction", () {
    final cases = <String, void Function()>{
      "txid": () => verify(txid: inputs[0].outpoint!.txid),
      "output address": () => verify(
        withOutputs: [
          outputs[0].copyWith(addresses: [attacker]),
          outputs[1],
        ],
      ),
      "output value": () => verify(
        withOutputs: [
          outputs[0].copyWith(valueStringSats: "1"),
          outputs[1],
        ],
      ),
      "output count": () => verify(withOutputs: [outputs[0]]),
      "outpoint": () => verify(withInputs: [inputs[1], inputs[0], inputs[2]]),
      "segwit input value": () => verify(
        withInputs: [
          inputs[0],
          inputs[1].copyWith(valueStringSats: "1"),
          inputs[2],
        ],
      ),
      "spent address": () => verify(
        withInputs: [
          inputs[0],
          inputs[1].copyWith(addresses: inputs[0].addresses),
          inputs[2],
        ],
      ),
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      expect(value, throwsUnauthenticated, reason: key);
    }
  });

  test("rejects signatures that do not commit to every output", () {
    for (final hashType in [
      const coinlib.SigHashType.none(),
      const coinlib.SigHashType.single(),
      const coinlib.SigHashType.all(
        inputs: coinlib.InputSigHashOption.anyOneCanPay,
      ),
    ]) {
      final tx = sign(hashType: hashType);
      expect(
        () => verify(txid: tx.txid, rawTxHex: tx.toHex()),
        throwsUnauthenticated,
        reason: "$hashType",
      );
    }
  });

  test("allows MWEB data only when asked", () {
    final hex = signed.toHex();
    final withMweb =
        "${hex.substring(0, 8)}0009${hex.substring(12, hex.length - 8)}"
        "010203${hex.substring(hex.length - 8)}";
    final withMwebOutput = [
      ...outputs,
      outputV2(signed.outputs[0]).copyWith(scriptPubKeyHex: "mweb"),
    ];

    expect(
      () => verify(
        rawTxHex: withMweb,
        withOutputs: withMwebOutput,
        allowMweb: true,
      ),
      returnsNormally,
    );
    expect(
      () => verify(rawTxHex: withMweb, withOutputs: withMwebOutput),
      throwsUnauthenticated,
    );
    expect(
      () => verify(withOutputs: withMwebOutput, allowMweb: true),
      throwsUnauthenticated,
    );
  });

  test("rejects malformed raw transactions", () {
    final hex = signed.toHex();
    for (final bad in [
      "",
      "zz",
      hex.substring(0, hex.length - 2),
      "${hex}00",
      "02000000ffffffffffffffffff",
    ]) {
      expect(() => verify(rawTxHex: bad), throwsUnauthenticated, reason: bad);
    }
  });

  test("rejects the BIP 143 p2wpkh example, whose first input is not ours", () {
    const hex =
        "01000000000102fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541d"
        "b4e4ad969f00000000494830450221008b9d1dc26ba6a9cb62127b02742fa9d754cd"
        "3bebf337f7a55d114c8e5cdd30be022040529b194ba3f9281a99f2b1c0a19c0489bc"
        "22ede944ccf4ecbab4cc618ef3ed01eeffffffef51e1b804cc89d182d279655c3aa8"
        "9e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000"
        "001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000"
        "001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac000247304402"
        "203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a02"
        "20573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee01"
        "21025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357"
        "11000000";
    final tx = coinlib.Transaction.fromHex(hex);
    final owner = coinlib.P2WPKHAddress.fromPublicKey(
      coinlib.ECPublicKey.fromHex(
        "025476c2e83188368da1ff3e292e7aca"
        "fcdb3566bb0ad253f62fc70f07aeee6357",
      ),
      hrp: network.bech32Hrp,
    ).toString();

    // The first input is p2pk and not ours. A spend of this wallet's has no
    // such input, so the transaction is rejected whatever the second input
    // claims.
    void check(int value) => verify(
      txid: tx.txid,
      rawTxHex: hex,
      withInputs: [
        inputV2(tx.inputs[0], null, 625000000, walletOwns: false),
        inputV2(tx.inputs[1], owner, value),
      ],
      withOutputs: [for (final e in tx.outputs) outputV2(e)],
    );

    expect(() => check(600000000), throwsUnauthenticated);
    expect(() => check(600000001), throwsUnauthenticated);
  });

  test("accepts the BIP 143 p2sh-p2wpkh example", () {
    const hex =
        "01000000000101db6b1b20aa0fd7b23880be2ecbd4a98130974cf4748fb66092ac4d"
        "3ceb1a5477010000001716001479091972186c449eb1ded22b78e40d009bdf0089fe"
        "ffffff02b8b4eb0b000000001976a914a457b684d7f0d539a46a45bbc043f35b59d0"
        "d96388ac0008af2f000000001976a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6"
        "d77c88ac02473044022047ac8e878352d3ebbde1c94ce3a10d057c24175747116f82"
        "88e5d794d12d482f0220217f36a485cae903c713331d877c1f64677e3622ad401072"
        "6870540656fe9dcb012103ad1d8e89212f0b92c74d23bb710c00662ad1470198ac48"
        "c43f7d6f93a2a2687392040000";
    final tx = coinlib.Transaction.fromHex(hex);
    final owner = coinlib.P2SHAddress.fromRedeemScript(
      coinlib.P2WPKH
          .fromPublicKey(
            coinlib.ECPublicKey.fromHex(
              "03ad1d8e89212f0b92c74d23bb710c00"
              "662ad1470198ac48c43f7d6f93a2a26873",
            ),
          )
          .script,
      version: network.p2shPrefix,
    ).toString();

    expect(
      () => verify(
        txid: tx.txid,
        rawTxHex: hex,
        withInputs: [inputV2(tx.inputs[0], owner, 1000000000)],
        withOutputs: [for (final e in tx.outputs) outputV2(e)],
      ),
      returnsNormally,
    );
  });
  test("returns the size and vsize of the raw transaction", () {
    final hex = signed.toHex();
    expect(verify(), (size: hex.length ~/ 2, vSize: signed.vSize()));
    expect(signed.vSize(), lessThan(hex.length ~/ 2), reason: "witness tx");
    expect(() => verify(txid: signed.txid.toUpperCase()), returnsNormally);
  });

  test("does not count MWEB data towards the size", () {
    final hex = signed.toHex();
    final withMweb =
        "${hex.substring(0, 8)}0009${hex.substring(12, hex.length - 8)}"
        "010203${hex.substring(hex.length - 8)}";
    final withMwebOutput = [
      ...outputs,
      outputV2(signed.outputs[0]).copyWith(scriptPubKeyHex: "mweb"),
    ];
    expect(
      verify(rawTxHex: withMweb, withOutputs: withMwebOutput, allowMweb: true),
      (size: hex.length ~/ 2, vSize: signed.vSize()),
    );
  });

  group("parent binding", () {
    // A wallet coin from a parent transaction, spent to a recipient.
    ({
      coinlib.Transaction transaction,
      coinlib.Transaction parent,
      List<InputV2> inputs,
      List<OutputV2> outputs,
    })
    fixture({required bool legacy}) {
      final walletKey = coinlib.ECPrivateKey(Uint8List(32)..[31] = 11);
      final recipient = coinlib.P2WPKHAddress.fromPublicKey(
        coinlib.ECPrivateKey(Uint8List(32)..[31] = 12).pubkey,
        hrp: network.bech32Hrp,
      );
      final coinlib.Address walletAddress = legacy
          ? coinlib.P2PKHAddress.fromPublicKey(
              walletKey.pubkey,
              version: network.p2pkhPrefix,
            )
          : coinlib.P2WPKHAddress.fromPublicKey(
              walletKey.pubkey,
              hrp: network.bech32Hrp,
            );
      final parent = coinlib.Transaction(
        inputs: [
          coinlib.RawInput(
            prevOut: coinlib.OutPoint(Uint8List(32), 0xffffffff),
            scriptSig: Uint8List.fromList([1]),
          ),
        ],
        outputs: [
          coinlib.Output.fromAddress(BigInt.from(100000), walletAddress),
        ],
      );
      final prevOut = coinlib.OutPoint.fromHex(parent.txid, 0);
      final unsigned = coinlib.Transaction(
        version: 2,
        inputs: [
          if (legacy)
            coinlib.P2PKHInput(
              prevOut: prevOut,
              publicKey: walletKey.pubkey,
              sequence: 0xfffffffd,
            )
          else
            coinlib.P2WPKHInput(
              prevOut: prevOut,
              publicKey: walletKey.pubkey,
              sequence: 0xfffffffd,
            ),
        ],
        outputs: [coinlib.Output.fromAddress(BigInt.from(99000), recipient)],
      );
      final transaction = legacy
          ? unsigned.signLegacy(inputN: 0, key: walletKey)
          : unsigned.signLegacyWitness(
              inputN: 0,
              key: walletKey,
              value: parent.outputs.single.value,
            );
      return (
        transaction: transaction,
        parent: parent,
        inputs: [
          inputV2(transaction.inputs.single, walletAddress.toString(), 100000),
        ],
        outputs: [outputV2(transaction.outputs.single, recipient.toString())],
      );
    }

    // Keys can only be created once coinlib is loaded.
    late final ({
      coinlib.Transaction transaction,
      coinlib.Transaction parent,
      List<InputV2> inputs,
      List<OutputV2> outputs,
    }) legacy,
        segwit;
    setUpAll(() {
      legacy = fixture(legacy: true);
      segwit = fixture(legacy: false);
    });

    Future<RawTransactionSize> run(
      ({
        coinlib.Transaction transaction,
        coinlib.Transaction parent,
        List<InputV2> inputs,
        List<OutputV2> outputs,
      })
      f, {
      List<String>? calls,
      List<InputV2>? withInputs,
      String? parentHex,
    }) => fetchAndVerifyOwnedInputSignatures(
      txid: f.transaction.txid,
      rawTxHex: f.transaction.toHex(),
      inputs: withInputs ?? f.inputs,
      outputs: f.outputs,
      network: network,
      // Only parents are fetched; the spend is given, never fetched.
      fetchRawTransaction: (txid) async {
        calls?.add(txid);
        if (txid == f.parent.txid) return parentHex ?? f.parent.toHex();
        throw StateError("Unexpected fetch of $txid");
      },
    );

    test("fetches the parent of legacy inputs only", () async {
      final legacyCalls = <String>[];
      expect(await run(legacy, calls: legacyCalls), (
        size: legacy.transaction.toHex().length ~/ 2,
        vSize: legacy.transaction.vSize(),
      ));
      expect(legacyCalls, [legacy.parent.txid]);

      final segwitCalls = <String>[];
      await run(segwit, calls: segwitCalls);
      expect(segwitCalls, isEmpty);
    });

    test("rejects a misreported legacy input value", () async {
      final misreported = [
        inputV2(
          legacy.transaction.inputs.single,
          legacy.inputs.single.addresses.single,
          100001,
        ),
      ];

      // The legacy signature does not commit to the amount, so only the
      // parent check can catch this.
      expect(
        () => verifyOwnedInputSignatures(
          txid: legacy.transaction.txid,
          rawTxHex: legacy.transaction.toHex(),
          inputs: misreported,
          outputs: legacy.outputs,
          network: network,
        ),
        returnsNormally,
      );
      await expectLater(
        run(legacy, withInputs: misreported),
        throwsUnauthenticated,
      );
    });

    test("rejects a parent that does not hash to the outpoint", () async {
      await expectLater(
        run(legacy, parentHex: legacy.transaction.toHex()),
        throwsUnauthenticated,
      );
    });

    test("rejects malformed parent data", () async {
      for (final bad in ["", "zz", legacy.parent.toHex().substring(2)]) {
        await expectLater(
          run(legacy, parentHex: bad),
          throwsUnauthenticated,
          reason: bad,
        );
      }
    });

    test("does not hide network errors as forgeries", () async {
      await expectLater(
        fetchAndVerifyOwnedInputSignatures(
          txid: legacy.transaction.txid,
          rawTxHex: legacy.transaction.toHex(),
          inputs: legacy.inputs,
          outputs: legacy.outputs,
          network: network,
          fetchRawTransaction: (txid) async => throw StateError("offline"),
        ),
        throwsStateError,
      );
    });

    test("parseAuthenticatedTransaction binds bytes to the txid", () {
      final hex = legacy.parent.toHex();
      final parsed = parseAuthenticatedTransaction(
        txid: legacy.parent.txid,
        rawTxHex: hex,
      );
      expect(parsed.outputs.single.value, BigInt.from(100000));
      expect(
        () => parseAuthenticatedTransaction(
          txid: legacy.transaction.txid,
          rawTxHex: hex,
        ),
        throwsUnauthenticated,
      );
      expect(
        () => parseAuthenticatedTransaction(
          txid: legacy.parent.txid,
          rawTxHex: "${hex}00",
        ),
        throwsUnauthenticated,
      );
    });

    test("recognises p2pkh addresses", () {
      expect(
        isP2pkhAddress(legacy.inputs.single.addresses.single, network),
        isTrue,
      );
      expect(
        isP2pkhAddress(segwit.inputs.single.addresses.single, network),
        isFalse,
      );
      expect(isP2pkhAddress("not an address", network), isFalse);
    });
  });
}
