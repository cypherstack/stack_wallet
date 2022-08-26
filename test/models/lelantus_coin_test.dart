import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/lelantus_coin.dart';

void main() {
  test("LelantusFeeData constructor", () {
    final lCoin =
        LelantusCoin(1, 1000, "publicCoin string", "some txid", 1, true);
    expect(lCoin.toString(),
        "{index: 1, value: 1000, publicCoin: publicCoin string, txId: some txid, anonymitySetId: 1, isUsed: true}");
  });
}
