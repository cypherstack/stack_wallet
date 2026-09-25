import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/app_config.dart";
import "package:stackwallet/wallets/crypto_currency/crypto_currency.dart";

void main() {
  group("Monero stagenet", () {
    final coin = Monero(CryptoCurrencyNetwork.stage);

    test("uses a distinct test-network identity", () {
      expect(coin.identifier, "moneroStagenet");
      expect(coin.mainNetId, "monero");
      expect(coin.prettyName, "sMonero");
      expect(coin.ticker, "sXMR");
      expect(coin.network.isTestNet, isTrue);
      expect(
        AppConfig.getCryptoCurrencyFor(coin.identifier)?.network,
        CryptoCurrencyNetwork.stage,
      );
    });

    test("uses the stagenet native network type", () {
      expect(moneroNetworkType(CryptoCurrencyNetwork.main), 0);
      expect(moneroNetworkType(CryptoCurrencyNetwork.test), 1);
      expect(moneroNetworkType(CryptoCurrencyNetwork.stage), 2);
      expect(
        () => moneroNetworkType(CryptoCurrencyNetwork.test4),
        throwsArgumentError,
      );
    });

    test("ships an enabled untrusted stagenet node", () {
      final node = coin.defaultNode(isPrimary: true);

      expect(node.host, "http://node3.monerodevs.org");
      expect(node.port, 38089);
      expect(node.useSSL, isFalse);
      expect(node.enabled, isTrue);
      expect(node.trusted, isFalse);
      expect(node.torEnabled, isTrue);
      expect(node.clearnetEnabled, isTrue);
      expect(node.coinName, coin.identifier);
      expect(node.isPrimary, isTrue);
    });

    test("validates stagenet addresses only", () {
      // Standard, subaddress and integrated addresses as emitted by wallet2
      // for each network.
      const stagenetStandard =
          "51sbLsg3J6WVp94FTL8a7ZF1necALFgyrf5iEq1qimCQdpRkCnvYsDiHXFKFs1mgx"
          "kXqkpNQ7jGmk54sDTXM462vRPCoCSt";
      const stagenetSubaddress =
          "7Abytm8ALcw8FqY6CN2DjWiCPZz9QwmJBZURKj4fcYcCY4FcYas5JDSauov46qyd1"
          "487PV2SnRy7heShW5nwt9mP8nm8RGt";
      const stagenetIntegrated =
          "5BaGMgVXuN2Vp94FTL8a7ZF1necALFgyrf5iEq1qimCQdpRkCnvYsDiHXFKFs1mgx"
          "kXqkpNQ7jGmk54sDTXM462vd8WWVLS5NRL1xFubBN";
      const testnetStandard =
          "A1dPgbuoBQJPP17FZuikpxGYYgU3P8sv4ZQB1e15nWxQgbJH69j1zqqCnRH6BbJqt"
          "iePfiNtH8Ut86GaU8p8MnFNMJoiMp1";
      const testnetSubaddress =
          "Baw6uy8ZHyBAnKJG4VZAAXXXR19Ax2bp9AthZYkhA5AN3xkWz4HhX8T8C8iGBKxs1"
          "dc8zmRGuDdrBRNwBdEpqm221sYnAt6";
      const mainnetStandard =
          "44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBY"
          "Bb98uNbr2VBBEt7f2wfn3RVGQBEP3A";

      expect(coin.validateAddress(stagenetStandard), isTrue);
      expect(coin.validateAddress(stagenetSubaddress), isTrue);
      expect(coin.validateAddress(stagenetIntegrated), isTrue);

      expect(coin.validateAddress(testnetStandard), isFalse);
      expect(coin.validateAddress(testnetSubaddress), isFalse);
      expect(coin.validateAddress(mainnetStandard), isFalse);

      expect(coin.validateAddress(""), isFalse);
      expect(coin.validateAddress("not an address"), isFalse);
      // A single character typo must fail the address checksum.
      expect(
        coin.validateAddress(stagenetStandard.replaceRange(10, 11, "Z")),
        isFalse,
      );
      expect(coin.validateAddress(stagenetStandard.substring(1)), isFalse);
    });

    test("uses the stagenet block explorer", () {
      expect(
        coin.defaultBlockExplorer("abc").toString(),
        "https://stagenet.xmrchain.net/tx/abc",
      );
    });
  });

  test("Xelis stagenet has a selectable default node", () {
    final coin = Xelis(CryptoCurrencyNetwork.stage);
    final node = coin.defaultNode(isPrimary: false);

    expect(coin.network.isTestNet, isTrue);
    expect(node.host, "stagenet-node.xelis.io");
    expect(node.port, 443);
    expect(node.useSSL, isTrue);
    expect(node.coinName, coin.identifier);
  });
}
