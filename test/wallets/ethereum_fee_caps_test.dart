import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart";

void main() {
  test("preset max fee includes priority after base-fee headroom", () {
    final caps = resolveEip1559FeeCaps(
      baseFee: BigInt.from(10),
      priorityFeePerGas: BigInt.two,
    );

    expect(caps.maxFeePerGas, BigInt.from(22));
    expect(caps.maxPriorityFeePerGas, BigInt.two);
  });

  test("custom max fee remains the total EIP-1559 cap", () {
    final caps = resolveEip1559FeeCaps(
      baseFee: BigInt.from(10),
      priorityFeePerGas: BigInt.two,
      customMaxFeePerGas: BigInt.from(15),
    );

    expect(caps.maxFeePerGas, BigInt.from(15));
    expect(caps.maxPriorityFeePerGas, BigInt.two);
  });

  test("rejects a priority cap above the total max fee", () {
    expect(
      () => resolveEip1559FeeCaps(
        baseFee: BigInt.from(10),
        priorityFeePerGas: BigInt.from(11),
        customMaxFeePerGas: BigInt.from(10),
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          "message",
          contains("Max priority fee per gas exceeds max fee per gas"),
        ),
      ),
    );
  });
}
