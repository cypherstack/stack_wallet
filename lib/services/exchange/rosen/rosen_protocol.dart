import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' as web3;

import '../../../utilities/default_eth_tokens.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';

/// Rosen's v1 metadata, shared by FIRO OP_RETURN and appended ERC-20 calldata.
/// https://github.com/rosen-bridge/ui/tree/dev/networks/firo/src/utils.ts
class RosenProtocol {
  static final maxAmount = (BigInt.one << 64) - BigInt.one;

  static final tokenContract = web3.DeployedContract(
    web3.ContractAbi.fromJson('''[
      {"type":"function","name":"balanceOf","stateMutability":"view","inputs":[{"name":"account","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},
      {"type":"function","name":"decimals","stateMutability":"view","inputs":[],"outputs":[{"name":"","type":"uint8"}]},
      {"type":"function","name":"transfer","stateMutability":"nonpayable","inputs":[{"name":"to","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]}
    ]''', DefaultTokens.rsFiro.name),
    EthereumAddress.fromHex(DefaultTokens.rsFiro.address),
  );

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

  static String ethereumAddress(String address) {
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address) ||
        BigInt.parse(address.substring(2), radix: 16) == BigInt.zero) {
      throw const FormatException('Enter a valid Ethereum mainnet address.');
    }
    return EthereumAddress.fromHex(address, enforceEip55: true).without0x;
  }

  /// address-codec encodes FIRO as its output script, not its Base58 payload.
  static String firoScript(String address) {
    try {
      final program = coinlib.Address.fromString(
        address,
        Firo(CryptoCurrencyNetwork.main).networkParams,
      ).program;
      if (program is coinlib.P2PKH || program is coinlib.P2SH) {
        return program.script.compiled.toHex;
      }
    } on Exception {
      // Normalize malformed and wrong-network address errors.
    }
    throw const FormatException('Use a transparent FIRO mainnet address.');
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
    if (metadata.length.isOdd ||
        !RegExp(r'^[0-9a-fA-F]*$').hasMatch(metadata)) {
      throw const FormatException('Invalid hexadecimal data.');
    }
    final encoded = tokenContract.function('transfer').encodeCall([
      EthereumAddress.fromHex('0x${ethereumAddress(lockAddress)}'),
      amount,
    ]);
    return '${encoded.toHex}${metadata.toUint8ListFromHex.toHex}';
  }
}
