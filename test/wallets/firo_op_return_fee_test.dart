import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

void main() {
  setUpAll(coinlib.loadCoinlib);

  test('Firo OP_RETURN is included in the optimal selection fee', () {
    final publicKey = coinlib.ECPublicKey.fromHex(
      '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
    );
    final program = coinlib.P2PKH.fromPublicKey(publicKey);
    final candidate = coinlib.InputCandidate(
      input: coinlib.P2PKHInput(
        prevOut: coinlib.OutPoint(Uint8List(32), 0),
        publicKey: publicKey,
      ),
      value: BigInt.from(200000),
    );
    final recipientOutput = coinlib.Output.fromProgram(
      BigInt.from(100000),
      program,
    );

    coinlib.CoinSelection select({String? opReturnData}) =>
        selectOptimalElectrumxCoins(
          candidates: [candidate],
          recipientOutput: recipientOutput,
          changeProgram: program,
          feePerKb: BigInt.from(1000),
          minFee: BigInt.zero,
          minChange: BigInt.from(546),
          firoOpReturnData: opReturnData,
        );

    final withoutMetadata = select();
    final withMetadata = select(opReturnData: List.filled(75, 'ab').join());
    final metadataOutput = withMetadata.recipients.last;

    expect(withoutMetadata.recipients, [recipientOutput]);
    expect(metadataOutput.value, BigInt.zero);
    expect(metadataOutput.scriptPubKey.take(2), [0x6a, 75]);
    expect(metadataOutput.size, 86);
    expect(
      withMetadata.signedSize,
      withoutMetadata.signedSize + metadataOutput.size,
    );
    expect(withMetadata.fee, BigInt.from(withMetadata.signedSize));
  });
}
