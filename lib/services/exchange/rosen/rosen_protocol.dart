import 'dart:typed_data';

import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

/// Rosen's v1 metadata, shared by FIRO OP_RETURN and appended ERC-20 calldata.
/// https://github.com/rosen-bridge/ui/tree/dev/networks/firo/src/utils.ts
class RosenProtocol {
  static const decimals = 8;
  static final maxAmount = (BigInt.one << 64) - BigInt.one;

  static bool isTransactionId(String? txid) =>
      txid != null && RegExp(r'^(0x)?[0-9a-fA-F]{64}$').hasMatch(txid);

  static String swapStatus(String status, String? payoutTxid) =>
      switch (status.toLowerCase()) {
        'completed' ||
        'successful' => isTransactionId(payoutTxid) ? 'Finished' : 'Sending',
        'fraud' => 'Failed',
        _ => 'Exchanging',
      };

  static BigInt parseAmount(String value) {
    if (!RegExp(r'^\d+(\.\d{1,8})?$').hasMatch(value)) {
      throw const FormatException(
        'Use an amount with at most 8 decimal places.',
      );
    }
    final parts = value.split('.');
    final amount =
        BigInt.parse(parts[0]) * BigInt.from(100000000) +
        BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(8, '0'));
    if (amount > maxAmount) throw const FormatException('Amount is too large.');
    return amount;
  }

  static String formatAmount(BigInt value) {
    if (value.isNegative) throw ArgumentError.value(value, 'value');
    final padded = value.toString().padLeft(9, '0');
    final fraction = padded
        .substring(padded.length - 8)
        .replaceFirst(RegExp(r'0+$'), '');
    return '${padded.substring(0, padded.length - 8)}${fraction.isEmpty ? '' : '.$fraction'}';
  }

  static String _uint(BigInt value, int bytes) {
    if (value.isNegative || value >= BigInt.one << (bytes * 8)) {
      throw ArgumentError(
        'Value does not fit an unsigned $bytes-byte integer.',
      );
    }
    return value.toRadixString(16).padLeft(bytes * 2, '0');
  }

  static String hex(Iterable<int> bytes) =>
      bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List bytes(String hex) {
    if (hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(hex)) {
      throw const FormatException('Invalid hexadecimal data.');
    }
    return Uint8List.fromList([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }

  static String ethereumAddress(String address) {
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address) ||
        BigInt.parse(address.substring(2), radix: 16) == BigInt.zero) {
      throw const FormatException('Enter a valid Ethereum mainnet address.');
    }
    return EthereumAddress.fromHex(address, enforceEip55: true).without0x;
  }

  /// address-codec encodes FIRO as its output script, not its Base58 payload.
  static String firoScript(String address) {
    final decoded = bs58check.decode(address);
    if (decoded.length != 21) {
      throw const FormatException('Use a transparent FIRO mainnet address.');
    }
    final hash = hex(decoded.sublist(1));
    return switch (decoded.first) {
      0x52 => '76a914${hash}88ac',
      0x07 => 'a914${hash}87',
      _ => throw const FormatException(
        'Use a transparent FIRO mainnet address.',
      ),
    };
  }

  static String metadata({
    required bool fromFiro,
    required String destination,
    required BigInt bridgeFee,
    required BigInt networkFee,
  }) {
    final address = fromFiro
        ? ethereumAddress(destination)
        : firoScript(destination);
    return '${fromFiro ? '03' : '07'}'
        '${_uint(bridgeFee, 8)}${_uint(networkFee, 8)}'
        '${_uint(BigInt.from(address.length ~/ 2), 1)}$address';
  }

  static String transferData({
    required String lockAddress,
    required BigInt amount,
    required String metadata,
  }) {
    if (amount <= BigInt.zero || amount > maxAmount) {
      throw ArgumentError('Invalid rsFIRO amount.');
    }
    bytes(metadata);
    return 'a9059cbb${ethereumAddress(lockAddress).padLeft(64, '0')}'
        '${_uint(amount, 32)}$metadata';
  }
}
