import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/keys/wallet_recovery_material.dart';

void main() {
  test("rejects empty mnemonic material", () {
    expect(
      () => MnemonicWalletRecoveryMaterial(walletId: "wallet-id", words: []),
      throwsArgumentError,
    );
  });

  test("defensively copies mnemonic words", () {
    final words = ["one", "two"];
    final material = MnemonicWalletRecoveryMaterial(
      walletId: "wallet-id",
      words: words,
    );

    words.clear();

    expect(material.words, ["one", "two"]);
    expect(() => material.words.add("three"), throwsUnsupportedError);
  });
}
