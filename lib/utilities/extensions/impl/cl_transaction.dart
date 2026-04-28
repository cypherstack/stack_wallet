import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;

extension CoinTxExt on coin.Tx {
  int weight() {
    final base = _byteLength(false);
    final total = _byteLength(true);
    return base * 3 + total;
  }

  int vSize() => (weight() / 4).ceil();

  String get hashHex {
    final hash = coin.sha256d(toBytes());
    return coin.hexEncode(Uint8List.fromList(hash.reversed.toList()));
  }

  int _byteLength(final bool allowWitness) {
    final hasWitness = allowWitness && isWitness;
    return (hasWitness ? 10 : 8) +
        _encodingLength(inputs.length) +
        _encodingLength(outputs.length) +
        inputs.fold<int>(0, (sum, input) => sum + _inputSize(input)) +
        outputs.fold<int>(0, (sum, output) => sum + output.wireSize) +
        (hasWitness
            ? inputs.fold(0, (sum, input) {
                if (input is! coin.WitnessInput) {
                  return sum;
                } else {
                  return sum + _vectorSize(input.witness);
                }
              })
            : 0);
  }

  int _inputSize(coin.TxInput input) {
    final measure = coin.WireMeasure();
    input.writeTo(measure);
    return measure.size;
  }

  int _varSliceSize(Uint8List someScript) {
    final length = someScript.length;
    return _encodingLength(length) + length;
  }

  int _vectorSize(List<Uint8List> someVector) {
    final length = someVector.length;
    return _encodingLength(length) +
        someVector.fold(
          0,
          (sum, witness) => sum + _varSliceSize(witness),
        );
  }

  int _encodingLength(int number) => number < 0xfd
      ? 1
      : number <= 0xffff
          ? 3
          : number <= 0xffffffff
              ? 5
              : 9;
}
