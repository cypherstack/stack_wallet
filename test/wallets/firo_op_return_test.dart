import 'dart:typed_data';

import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/firo_op_return.dart';

class _SizedInput extends coinlib.RawInput {
  _SizedInput()
    : super(
        prevOut: coinlib.OutPoint(Uint8List(32), 0),
        scriptSig: Uint8List(106),
      );

  @override
  int get signedSize => size;
}

void main() {
  test('FIRO data output preserves payload and handles PUSHDATA1 boundary', () {
    for (final length in [1, 75, 76, 80]) {
      final hex = List.filled(length, 'aa').join();
      final output = firoOpReturnOutput(hex);
      final prefix = length <= 75 ? [0x6a, length] : [0x6a, 0x4c, length];

      expect(output.value, BigInt.zero);
      expect(output.scriptPubKey, [...prefix, ...List.filled(length, 0xaa)]);
      expect(output.size, 9 + prefix.length + length);
      expect(firoOpReturnOutput('0x$hex').scriptPubKey, output.scriptPubKey);
    }
    for (final hex in ['00', '01', '10', '81', 'ff']) {
      expect(firoOpReturnOutput(hex).scriptPubKey, [
        0x6a,
        1,
        int.parse(hex, radix: 16),
      ]);
    }
  });

  test('FIRO data output rejects malformed or oversized payloads', () {
    for (final hex in [
      '',
      '0',
      'zz',
      '0x',
      'aa bb',
      'aa\n',
      List.filled(81, 'aa').join(),
    ]) {
      expect(() => firoOpReturnOutput(hex), throwsFormatException);
    }
  });

  test('coin selection funds the serialized data output before signing', () {
    final program = coinlib.P2PKH.fromHash(Uint8List(20));
    final payment = coinlib.Output.fromProgram(BigInt.from(10000), program);
    final data = firoOpReturnOutput(List.filled(80, 'aa').join());

    coinlib.CoinSelection select(int inputValue, {required bool withData}) =>
        coinlib.CoinSelection(
          selected: [
            coinlib.InputCandidate(
              input: _SizedInput(),
              value: BigInt.from(inputValue),
            ),
          ],
          recipients: [payment, if (withData) data],
          changeProgram: program,
          feePerKb: BigInt.from(1000),
          minFee: BigInt.zero,
          minChange: BigInt.from(546),
        );

    final plain = select(20000, withData: false);
    final bridge = select(20000, withData: true);
    expect(bridge.ready, isTrue);
    expect(bridge.fee - plain.fee, BigInt.from(data.size));
    expect(plain.changeValue - bridge.changeValue, BigInt.from(data.size));
    expect(bridge.transaction.outputs.where((o) => o.value == BigInt.zero), [
      data,
    ]);
    expect(bridge.transaction.size, bridge.signedSize);

    // A UTXO that covers the payment alone must not pass bridge fee selection.
    final exactPlainValue = 10000 + plain.signedSize - payment.size;
    expect(select(exactPlainValue, withData: false).ready, isTrue);
    expect(select(exactPlainValue, withData: true).ready, isFalse);
  });

  test('decodes complete v3 special transactions and derives their txid', () {
    const inputTxid =
        '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
    const raw =
        '0300090001'
        '1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100'
        '0700000000ffffffff'
        '01010000000000000000'
        '00000000'
        '03aabbcc';
    const txid =
        '41630f29d16f8e4c246cba40d58dac6c69b3821ec319c5140e58fde5b2c356bc';

    final decoded = decodeFiroTransaction(raw);
    expect(decoded.txid, txid);
    expect(decoded.prevouts.single, (txid: inputTxid, vout: 7));
    expect(
      decodeFiroTransaction(raw.replaceFirst('aabbcc', 'aabbcd')).txid,
      isNot(txid),
    );
    expect(
      () => decodeFiroTransaction(raw.substring(0, raw.length - 8)),
      throwsFormatException,
    );
    expect(() => decodeFiroTransaction('${raw}00'), throwsFormatException);
  });

  test('structurally signed FIRO bytes match the prepared envelope', () {
    const metadata =
        '03000000000000007b00000000000001c81400112233445566778899aabbccdd'
        'eeff00112233';
    const inputTxid =
        '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
    const serializedInputHash =
        '1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100';
    const otherTxid =
        '202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f';
    const otherSerializedInputHash =
        '3f3e3d3c3b3a393837363534333231302f2e2d2c2b2a29282726252423222120';
    const paymentScript = '76a914111111111111111111111111111111111111111188ac';
    const changeScript = '76a914222222222222222222222222222222222222222288ac';
    // Fixed low-R/low-S SIGHASH_ALL signature for private key 1 and its P2PKH
    // previous output; no platform-native signing is needed at test time.
    const derSignature =
        '304402206687c87c5f80c4e2a4e63fed02b0de65bcd38b77255b1de3f375f5d7'
        'a1b124c9'
        '02202d5997a82c65d254e08ecc2ef7ba15995df3adfefa509b6ce0fdd65642a4062f';
    const publicKey =
        '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    const invalidPublicKey =
        '02ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
    const paymentOutput =
        '00e1f505000000001976a914111111111111111111111111111111111111111188ac';
    const changeOutput =
        '80f0fa02000000001976a914222222222222222222222222222222222222222288ac';
    const dataOutput = '0000000000000000286a26$metadata';
    const transactionPrefix =
        '0100000001${serializedInputHash}000000006a47${derSignature}0121'
        '${publicKey}feffffff';
    const signedRaw =
        '${transactionPrefix}03$paymentOutput$changeOutput$dataOutput'
        '00000000';
    const witnessRaw =
        '01000000000101$serializedInputHash'
        '000000006a47$derSignature'
        '0121${publicKey}feffffff'
        '03$paymentOutput$changeOutput$dataOutput'
        '0000000000';
    const signedTxid =
        '3bd009801405a65f11f0e1c635025d115e93b175433a99958ac3cd5cd16ef64c';
    final inputValue = BigInt.from(150001000);
    final amount = BigInt.from(100000000);
    final change = BigInt.from(50000000);
    final fee = BigInt.from(1000);
    final inputs = <FiroTransactionInput>[
      (txid: inputTxid, vout: 0, value: inputValue),
    ];
    final outputs = <FiroTransactionOutput>[
      (script: paymentScript, value: amount),
      (script: changeScript, value: change),
    ];
    String verify({
      String? raw,
      String? opReturn,
      Iterable<FiroTransactionInput>? expectedInputs,
      Iterable<FiroTransactionOutput>? expectedOutputs,
      BigInt? expectedFee,
    }) => verifyFiroOpReturnTransaction(
      raw: raw ?? signedRaw,
      data: opReturn ?? metadata,
      expectedInputs: expectedInputs ?? inputs,
      expectedOutputs: expectedOutputs ?? outputs,
      expectedFee: expectedFee ?? fee,
    );

    expect(verify(), signedTxid);
    expect(decodeFiroTransaction(witnessRaw).txid, signedTxid);
    expect(
      verify(
        expectedInputs: inputs.reversed,
        expectedOutputs: outputs.reversed,
      ),
      signedTxid,
    );

    for (final raw in [
      '${transactionPrefix}02$paymentOutput$dataOutput'
          '00000000',
      '${transactionPrefix}04$paymentOutput$changeOutput$dataOutput$dataOutput'
          '00000000',
      signedRaw.replaceFirst(
        paymentOutput,
        paymentOutput.replaceFirst('00e1f505', 'ffe0f505'),
      ),
      signedRaw.replaceFirst(dataOutput, '0100000000000000286a26$metadata'),
      signedRaw.replaceFirst(metadata, '${metadata.substring(0, 74)}ff'),
      signedRaw.replaceFirst(serializedInputHash, otherSerializedInputHash),
      signedRaw.replaceFirst('3044', '3144'),
      signedRaw.replaceFirst('30440220', '30440320'),
      signedRaw.replaceFirst('022066', '0220e6'),
      signedRaw.replaceFirst(publicKey, invalidPublicKey),
      '${signedRaw}00',
      '0100000001${serializedInputHash}0000000000feffffff'
          '03$paymentOutput$changeOutput$dataOutput'
          '00000000',
      '0100000001${serializedInputHash}0000000001d3feffffff'
          '03$paymentOutput$changeOutput$dataOutput'
          '00000000',
      witnessRaw,
    ]) {
      expect(() => verify(raw: raw), throwsStateError);
    }

    for (final expectedInputs in [
      <FiroTransactionInput>[],
      [(txid: inputTxid, vout: 1, value: inputValue)],
      [(txid: otherTxid, vout: 0, value: inputValue)],
      [(txid: inputTxid, vout: 0, value: inputValue + BigInt.one)],
      [...inputs, ...inputs],
    ]) {
      expect(() => verify(expectedInputs: expectedInputs), throwsStateError);
    }
    for (final expectedOutputs in [
      <FiroTransactionOutput>[],
      [(script: paymentScript, value: amount)],
      [(script: paymentScript, value: amount - BigInt.one), outputs[1]],
      [
        (script: paymentScript.replaceFirst('11', '12'), value: amount),
        outputs[1],
      ],
      [...outputs, outputs.first],
    ]) {
      expect(() => verify(expectedOutputs: expectedOutputs), throwsStateError);
    }
    expect(() => verify(expectedFee: fee + BigInt.one), throwsStateError);
    expect(
      () => verify(opReturn: '${metadata.substring(0, 74)}ff'),
      throwsStateError,
    );
  });
}
