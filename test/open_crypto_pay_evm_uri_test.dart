import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/open_crypto_pay/evm_uri.dart';

void main() {
  test("parses native Ethereum payment URI", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC@1"
      "?value=660720000000000",
    );

    expect(result, isNotNull);
    expect(result!.targetAddress, "0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC");
    expect(result.chainId, 1);
    expect(result.functionName, isNull);
    expect(result.amountRaw, BigInt.parse("660720000000000"));
    expect(result.isNativeTransfer, true);
    expect(result.isTokenTransfer, false);
  });

  test("parses EIP-681 scientific notation atomic amounts", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC@1"
      "?value=6.6072e14",
    );

    expect(result, isNotNull);
    expect(result!.amountRaw, BigInt.parse("660720000000000"));
  });

  test("parses ERC20 transfer URI", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@1/transfer"
      "?address=0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC&uint256=1261570",
    );

    expect(result, isNotNull);
    expect(result!.targetAddress, "0xdAC17F958D2ee523a2206206994597C13D831ec7");
    expect(result.chainId, 1);
    expect(result.functionName, "transfer");
    expect(
      result.recipientAddress,
      "0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC",
    );
    expect(result.amountRaw, BigInt.from(1261570));
    expect(result.isTokenTransfer, true);
  });

  test("parses non-mainnet chain id for caller validation", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@5/transfer"
      "?address=0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC&uint256=1",
    );

    expect(result, isNotNull);
    expect(result!.chainId, 5);
    expect(result.isTokenTransfer, true);
  });

  test("rejects malformed chain id", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@abc/transfer"
      "?address=0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC&uint256=1",
    );

    expect(result, isNull);
  });

  test("rejects malformed contract address", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:not-a-contract@1/transfer"
      "?address=0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC&uint256=1",
    );

    expect(result, isNull);
  });

  test("does not mark unsupported contract calls as ERC20 transfers", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@1/approve"
      "?address=0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC&uint256=1",
    );

    expect(result, isNotNull);
    expect(result!.functionName, "approve");
    expect(result.isTokenTransfer, false);
  });

  test("does not mark token transfer missing recipient as valid", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@1/transfer"
      "?uint256=1",
    );

    expect(result, isNotNull);
    expect(result!.isTokenTransfer, false);
  });

  test("does not mark token transfer missing amount as valid", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@1/transfer"
      "?address=0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC",
    );

    expect(result, isNotNull);
    expect(result!.isTokenTransfer, false);
  });

  test("rejects scientific notation with excessive exponent", () {
    final result = OpenCryptoPayEvmUri.tryParse(
      "ethereum:0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC@1"
      "?value=1e999",
    );

    expect(result, isNull);
  });
}
