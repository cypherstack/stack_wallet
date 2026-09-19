import 'dart:convert';

/// Atomic FIRO amounts (8 decimals), including Rosen's destination network fee.
class RosenQuote {
  final BigInt bridgeFee;
  final BigInt networkFee;
  final BigInt minimum;
  final BigInt receiveAmount;

  const RosenQuote({
    required this.bridgeFee,
    required this.networkFee,
    required this.minimum,
    required this.receiveAmount,
  });

  /// Includes each fee component: an unchanged total can still change metadata.
  String get fingerprint => '$bridgeFee:$networkFee:$receiveAmount';

  bool hasFees(BigInt bridge, BigInt network) =>
      bridgeFee == bridge && networkFee == network;

  /// Rosen minimum-fee registers, selected by source height and destination.
  /// https://github.com/rosen-bridge/utils/tree/dev/packages/minimum-fee
  factory RosenQuote.fromRegisters(
    Map<String, dynamic> registers, {
    required bool fromFiro,
    required int height,
    required BigInt amount,
  }) {
    if (amount.isNegative || height <= 0) {
      throw const FormatException('Invalid Rosen amount or source height');
    }
    final chains = _RegisterReader(registers['R4'], 0x1a).strings();
    final heights = _RegisterReader(registers['R5'], 0x1c).matrix(32);
    final bridgeFees = _RegisterReader(registers['R6'], 0x1d).matrix(64);
    final networkFees = _RegisterReader(registers['R7'], 0x1d).matrix(64);
    final rsnRatios = _RegisterReader(registers['R8'], 0x0c).ratios();
    final ratios = _RegisterReader(registers['R9'], 0x1d).matrix(64);
    final source = chains.indexOf(fromFiro ? 'firo' : 'ethereum');
    final destination = chains.indexOf(fromFiro ? 'ethereum' : 'firo');
    if (source < 0 ||
        destination < 0 ||
        chains.toSet().length != chains.length) {
      throw const FormatException('Rosen route is unavailable');
    }
    for (final matrix in [heights, bridgeFees, networkFees, ratios]) {
      if (matrix.length != heights.length ||
          matrix.any((row) => row.length != chains.length)) {
        throw const FormatException('Invalid Rosen fee register dimensions');
      }
    }
    if (rsnRatios.length != heights.length ||
        rsnRatios.any(
          (row) =>
              row.length != chains.length ||
              row.any((ratio) => ratio.length != 2),
        )) {
      throw const FormatException('Invalid Rosen RSN fee ratio dimensions');
    }
    for (var i = heights.length - 1; i >= 0; i--) {
      if (heights[i][source].isNegative) {
        throw const FormatException('Rosen source chain is disabled');
      }
      // Rosen intentionally activates each configuration AFTER this height.
      if (BigInt.from(height) <= heights[i][source]) continue;
      final base = bridgeFees[i][destination];
      final network = networkFees[i][destination];
      final ratio = ratios[i][destination];
      final divisor = BigInt.from(10000);
      if (base.isNegative ||
          network.isNegative ||
          ratio.isNegative ||
          ratio >= divisor) {
        throw const FormatException('Rosen destination fees are unavailable');
      }
      final variable = amount * ratio ~/ divisor;
      final bridge = base > variable ? base : variable;
      final baseMinimum = base + network + BigInt.one;
      // Includes the percentage fee: the receiver must get at least one atom.
      final ratioMinimum = network * divisor ~/ (divisor - ratio) + BigInt.one;
      return RosenQuote(
        bridgeFee: bridge,
        networkFee: network,
        minimum: baseMinimum > ratioMinimum ? baseMinimum : ratioMinimum,
        receiveAmount: amount - bridge - network,
      );
    }
    throw const FormatException('No active Rosen fee schedule');
  }
}

/// Only the Sigma collection types Rosen uses for chains, heights and fees.
/// Decodes serialized values so large fees never pass through floating point.
class _RegisterReader {
  final List<int> _bytes;
  int _offset = 0;

  _RegisterReader(dynamic register, int type) : _bytes = _hex(register) {
    if (_byte() != type) {
      throw const FormatException('Unexpected Rosen fee register type');
    }
  }

  static List<int> _hex(dynamic register) {
    final value = register is Map ? register['serializedValue'] : null;
    if (value is! String ||
        value.isEmpty ||
        value.length.isOdd ||
        value.length > 65536 ||
        !RegExp(r'^[0-9a-fA-F]+$').hasMatch(value)) {
      throw const FormatException('Invalid Rosen fee register');
    }
    return [
      for (var i = 0; i < value.length; i += 2)
        int.parse(value.substring(i, i + 2), radix: 16),
    ];
  }

  int _byte() {
    if (_offset >= _bytes.length) {
      throw const FormatException('Truncated Rosen fee register');
    }
    return _bytes[_offset++];
  }

  BigInt _unsigned(int bits) {
    var value = BigInt.zero;
    for (var shift = 0; shift < bits; shift += 7) {
      final byte = _byte();
      value |= BigInt.from(byte & 0x7f) << shift;
      if (byte & 0x80 == 0) {
        if (value.bitLength > bits) break;
        return value;
      }
    }
    throw const FormatException('Rosen fee integer overflow');
  }

  int _length() {
    final length = _unsigned(32).toInt();
    if (length > _bytes.length - _offset) {
      throw const FormatException('Invalid Rosen register collection length');
    }
    return length;
  }

  void _finish() {
    if (_offset != _bytes.length) {
      throw const FormatException('Trailing Rosen fee register bytes');
    }
  }

  List<String> strings() {
    final result = <String>[];
    final count = _length();
    for (var i = 0; i < count; i++) {
      final length = _length();
      result.add(utf8.decode(_bytes.sublist(_offset, _offset + length)));
      _offset += length;
    }
    _finish();
    return result;
  }

  List<List<BigInt>> matrix(int bits) {
    final result = _matrix(bits);
    _finish();
    return result;
  }

  List<List<List<BigInt>>> ratios() {
    if (_byte() != 0x1d) {
      throw const FormatException('Unexpected Rosen RSN ratio register type');
    }
    final count = _length();
    final result = [for (var i = 0; i < count; i++) _matrix(64)];
    _finish();
    return result;
  }

  List<List<BigInt>> _matrix(int bits) {
    final result = <List<BigInt>>[];
    final count = _length();
    for (var i = 0; i < count; i++) {
      final length = _length();
      final row = <BigInt>[];
      for (var j = 0; j < length; j++) {
        final value = _unsigned(bits);
        row.add((value >> 1) ^ -(value & BigInt.one));
      }
      result.add(row);
    }
    return result;
  }
}
