import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/firo_op_return.dart';
import 'package:test/test.dart';

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
    for (final hex in ['', '0', 'zz', '0x', 'aa bb', 'aa\n', 'aa' * 81]) {
      expect(() => firoOpReturnOutput(hex), throwsFormatException);
    }
  });

  test('coin selection funds the serialized data output before signing', () {
    final program = coinlib.P2PKH.fromHash(Uint8List(20));
    final payment = coinlib.Output.fromProgram(BigInt.from(10000), program);
    final data = firoOpReturnOutput('aa' * 80);

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

  test(
    'signed transparent FIRO bytes retain and enforce bridge outputs',
    () async {
      await coinlib.loadCoinlib();
      // Public test key and synthetic outpoint: no network or wallet funds are used.
      final key = coinlib.ECPrivateKey.fromHex('01'.padLeft(64, '0'));
      const metadata =
          '03000000000000007b00000000000001c81400112233445566778899aabbccddeeff00112233';
      final lock = coinlib.Address.fromString(
        'aEF6fyd5jjCPcbiEBZJ2g8583caUme8T7Y',
        coinlib.Network.mainnet.copyWith(p2pkhPrefix: 0x52, p2shPrefix: 0x07),
      ).program;
      final amount = BigInt.from(100000000);
      final payment = coinlib.Output.fromProgram(amount, lock);
      final change = coinlib.Output.fromProgram(
        BigInt.from(50000000),
        coinlib.P2PKH.fromHash(coinlib.hash160(key.pubkey.data)),
      );
      final data = firoOpReturnOutput(metadata);
      coinlib.Transaction sign(List<coinlib.Output> outputs) =>
          coinlib.Transaction(
            version: 1,
            inputs: [
              coinlib.P2PKHInput(
                prevOut: coinlib.OutPoint(
                  Uint8List.fromList(List.filled(32, 1)),
                  0,
                ),
                publicKey: key.pubkey,
              ),
            ],
            outputs: outputs,
          ).signLegacy(inputN: 0, key: key);
      void verify(String raw) => verifyFiroOpReturnTransaction(
        raw: raw,
        data: metadata,
        paymentScript: coinlib.bytesToHex(payment.scriptPubKey),
        paymentAmount: amount,
      );

      final signed = sign([payment, change, data]);
      expect(signed.complete, isTrue);
      expect(signed.inputs.single, isA<coinlib.P2PKHInput>());
      expect(
        signed.toHex(),
        endsWith('0000000000000000286a26${metadata}00000000'),
      );
      verify(signed.toHex());
      // Output order is not part of Rosen's protocol.
      verify(sign([data, payment, change]).toHex());

      for (final outputs in [
        [
          payment,
          change,
        ], // Sidecar metadata cannot replace an on-chain output.
        [payment, change, firoOpReturnOutput('${metadata.substring(0, 74)}ff')],
        [payment, change, data, data],
        [
          payment,
          change,
          coinlib.Output.fromScriptBytes(BigInt.one, data.scriptPubKey),
        ],
        [coinlib.Output.fromProgram(amount - BigInt.one, lock), change, data],
        [change, data],
      ]) {
        expect(() => verify(sign(outputs).toHex()), throwsStateError);
      }
      expect(() => verify('${signed.toHex()}00'), throwsStateError);
      final unsigned = coinlib.Transaction(
        version: 1,
        inputs: [
          coinlib.P2PKHInput(
            prevOut: signed.inputs.single.prevOut,
            publicKey: key.pubkey,
          ),
        ],
        outputs: signed.outputs,
      );
      expect(() => verify(unsigned.toHex()), throwsStateError);
      final nonTransparent = coinlib.Transaction(
        version: 1,
        inputs: [
          coinlib.RawInput(
            prevOut: signed.inputs.single.prevOut,
            scriptSig: Uint8List.fromList([0xd3]),
          ),
        ],
        outputs: signed.outputs,
      );
      expect(() => verify(nonTransparent.toHex()), throwsStateError);
    },
    skip: Platform.isLinux
        ? 'Requires build/libsecp256k1.so for coinlib-backed signing checks on Ubuntu.'
        : false,
  );
}
