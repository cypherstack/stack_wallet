import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart';

extension CLTransactionExt on Transaction {
  int weight() {
    final base = _byteLength(false);
    final total = _byteLength(true);
    return base * 3 + total;
  }

  int vSize() => (weight() / 4).ceil();

  int _byteLength(final bool allowWitness) {
    final hasWitness = allowWitness && isWitness;
    return (hasWitness ? 10 : 8) +
        _encodingLength(inputs.length) +
        _encodingLength(outputs.length) +
        inputs.fold<int>(0, (sum, input) => sum + input.size) +
        outputs.fold<int>(0, (sum, output) => sum + output.size) +
        (hasWitness
            ? inputs.fold(0, (sum, input) {
                if (input is! WitnessInput) {
                  return sum;
                } else {
                  return sum + _vectorSize(input.witness);
                }
              })
            : 0);
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
