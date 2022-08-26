import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/lelantus_fee_data.dart';

void main() {
  test("LelantusFeeData constructor", () {
    final lfData = LelantusFeeData(10000, 3794, [1, 2, 1, 0, 1]);
    expect(lfData.toString(),
        "{changeToMint: 10000, fee: 3794, spendCoinIndexes: [1, 2, 1, 0, 1]}");
  });
}
