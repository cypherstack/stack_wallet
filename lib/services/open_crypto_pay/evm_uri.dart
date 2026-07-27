import 'package:decimal/decimal.dart';

/// Minimal EIP-681 parser for Open CryptoPay EVM transaction details.
class OpenCryptoPayEvmUri {
  final String scheme;
  final String targetAddress;
  final int? chainId;
  final String? functionName;
  final String? recipientAddress;
  final BigInt? amountRaw;

  const OpenCryptoPayEvmUri({
    required this.scheme,
    required this.targetAddress,
    required this.chainId,
    required this.functionName,
    required this.recipientAddress,
    required this.amountRaw,
  });

  bool get isTokenTransfer =>
      functionName == 'transfer' &&
      recipientAddress != null &&
      amountRaw != null;

  bool get isNativeTransfer => functionName == null && amountRaw != null;

  Decimal amount({required int fractionDigits}) =>
      Decimal.fromBigInt(amountRaw!).shift(-fractionDigits);

  static OpenCryptoPayEvmUri? tryParse(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null || parsed.scheme != 'ethereum') return null;

    final pathParts = parsed.path.split('/');
    if (pathParts.isEmpty || pathParts.first.isEmpty) return null;

    final targetParts = pathParts.first.split('@');
    final targetAddress = targetParts.first;
    if (!_isHexAddress(targetAddress)) return null;

    if (targetParts.length > 2) return null;
    final int? chainId;
    if (targetParts.length > 1) {
      chainId = int.tryParse(targetParts[1]);
      if (chainId == null) return null;
    } else {
      chainId = null;
    }
    final functionName = pathParts.length > 1 && pathParts[1].isNotEmpty
        ? pathParts[1]
        : null;

    final recipientAddress = parsed.queryParameters['address'];
    final amountParam = functionName == 'transfer'
        ? parsed.queryParameters['uint256']
        : parsed.queryParameters['value'];
    final amountRaw = _parseRawInteger(amountParam);
    if (amountParam != null && amountRaw == null) return null;

    return OpenCryptoPayEvmUri(
      scheme: parsed.scheme,
      targetAddress: targetAddress,
      chainId: chainId,
      functionName: functionName,
      recipientAddress:
          recipientAddress != null && _isHexAddress(recipientAddress)
          ? recipientAddress
          : null,
      amountRaw: amountRaw,
    );
  }

  static bool _isHexAddress(String value) =>
      RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(value);

  static BigInt? _parseRawInteger(String? value) {
    if (value == null) return null;
    if (RegExp(r'^[0-9]+$').hasMatch(value)) return BigInt.tryParse(value);

    final match = RegExp(
      r'^([0-9]+)(?:\.([0-9]+))?[eE]([+-]?[0-9]+)$',
    ).firstMatch(value);
    if (match == null) return null;

    final whole = match.group(1)!;
    final fraction = match.group(2) ?? '';
    final exponent = int.tryParse(match.group(3)!);
    if (exponent == null) return null;
    if (exponent.abs() > 100) return null;

    final digits = whole + fraction;
    final scale = exponent - fraction.length;
    if (scale >= 0) {
      return BigInt.parse(digits) * BigInt.from(10).pow(scale);
    }

    final divisor = BigInt.from(10).pow(-scale);
    final parsed = BigInt.parse(digits);
    if (parsed % divisor != BigInt.zero) return null;
    return parsed ~/ divisor;
  }
}
